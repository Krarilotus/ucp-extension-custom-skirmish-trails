-- Writing files where UCP's io.open does not: UCP refuses to write inside ucp/plugins and
-- ucp/modules, which is where trail csv files usually live. Export and Import therefore write
-- through Windows' own ANSI functions: LoadLibraryA through the game's own import of it,
-- GetProcAddress from kernel32's export table, the rest through GetProcAddress. Trail paths must
-- resolve inside the game folder.

local winfiles = {}

local OFFSET_NT_HEADERS = 0x3C
local OFFSET_EXPORT_DIRECTORY = 0x78
-- the game loads DDRAW.DLL with "push name / call dword [LoadLibraryA import]" (both 1.41
-- executables); the capture is the import slot
local LOAD_LIBRARY_CALL = "51 56 68 ? ? ? ? FF 15 I(? ? ? ?) 8B F0 85 F6"
local MAX_FORWARDS = 4
local PATH_BUFFER_SIZE = 1024
local FIND_DATA_SIZE = 320
local FIND_DATA_ATTRIBUTES = 0x00
local FIND_DATA_NAME = 0x2C
local FILE_ATTRIBUTE_DIRECTORY = 0x10
local INVALID_HANDLE = 0xFFFFFFFF
local GENERIC_WRITE = 0x40000000
local CREATE_ALWAYS = 2
local FILE_ATTRIBUTE_NORMAL = 0x80
local MOVEFILE_REPLACE_EXISTING = 1
local MOVEFILE_WRITE_THROUGH = 8
local ERROR_ALREADY_EXISTS = 183
local FILE_ATTRIBUTE_REPARSE_POINT = 0x400
local ERROR_FILE_NOT_FOUND, ERROR_PATH_NOT_FOUND = 2, 3

local win = {}
local pathBuffer, tempPathBuffer, tempPrefix, findData, writtenBuffer, gameDirectory
local dataBuffer, dataBufferSize = nil, 0

---A cdecl function that forwards its arguments to the stdcall function whose pointer is at `slot`.
local function stdcallThunk(slot, argumentCount)
  local code = {}
  for _ = 1, argumentCount do
    for _, byte in ipairs({ 0xFF, 0x74, 0x24, 4 * argumentCount }) do -- push dword [esp + 4n]
      table.insert(code, byte)
    end
  end
  table.insert(code, 0xFF)
  table.insert(code, 0x15) -- call dword [slot]
  for _, byte in ipairs(core.itob(slot)) do
    table.insert(code, byte)
  end
  table.insert(code, 0xC3)
  return core.exposeCode(core.allocateCode(code), argumentCount, 0)
end

local function writeCString(buffer, text)
  core.writeString(buffer, text)
  core.writeByte(buffer + #text, 0)
end

local function setPath(path)
  if #path >= PATH_BUFFER_SIZE then
    error("path too long: " .. path)
  end
  writeCString(pathBuffer, path)
  return pathBuffer
end

local function findExport(base, functionName, depth)
  local ntHeaders = base + core.readInteger(base + OFFSET_NT_HEADERS)
  local directoryRva = core.readInteger(ntHeaders + OFFSET_EXPORT_DIRECTORY)
  local directorySize = core.readInteger(ntHeaders + OFFSET_EXPORT_DIRECTORY + 4)
  local directory = base + directoryRva
  local nameCount = core.readInteger(directory + 0x18)
  local functionTable = base + core.readInteger(directory + 0x1C)
  local nameTable = base + core.readInteger(directory + 0x20)
  local ordinalTable = base + core.readInteger(directory + 0x24)
  for index = 0, nameCount - 1 do
    if core.readString(base + core.readInteger(nameTable + index * 4)) == functionName then
      local ordinal = core.readSmallInteger(ordinalTable + index * 2) & 0xFFFF
      local rva = core.readInteger(functionTable + ordinal * 4)
      if rva >= directoryRva and rva < directoryRva + directorySize then
        -- a forwarder, "OTHERDLL.Function"
        local dll, forwarded = core.readString(base + rva):match("^(.-)%.(.+)$")
        if dll == nil or depth >= MAX_FORWARDS then
          return nil
        end
        local forwardBase = win.LoadLibraryA(setPath(dll .. ".dll")) & 0xFFFFFFFF
        if forwardBase == 0 then
          return nil
        end
        return findExport(forwardBase, forwarded, depth + 1)
      end
      return base + rva
    end
  end
  return nil
end

local initialized = false
local failure = nil
local kernel32

local function bindFunctions(functions)
  for _, entry in ipairs(functions) do
    local name, argumentCount = entry[1], entry[2]
    local address = win.GetProcAddress(kernel32, setPath(name)) & 0xFFFFFFFF
    if address == 0 then
      error("kernel32 has no " .. name)
    end
    local slot = core.allocate(4, true)
    core.writeInteger(slot, address)
    win[name] = stdcallThunk(slot, argumentCount)
  end
end

local function setUp()
  pathBuffer = core.allocate(PATH_BUFFER_SIZE, true)
  findData = core.allocate(FIND_DATA_SIZE, true)

  local found, _, loadLibrarySlot = pcall(utils.AOBExtract, LOAD_LIBRARY_CALL)
  if not found or loadLibrarySlot == nil then
    error("cannot find the game's LoadLibraryA import")
  end
  win.LoadLibraryA = stdcallThunk(loadLibrarySlot, 1)
  kernel32 = win.LoadLibraryA(setPath("kernel32.dll")) & 0xFFFFFFFF
  local getProcAddress = kernel32 ~= 0 and findExport(kernel32, "GetProcAddress", 0) or nil
  if getProcAddress == nil then
    error("kernel32 has no GetProcAddress")
  end
  local getProcAddressSlot = core.allocate(4, true)
  core.writeInteger(getProcAddressSlot, getProcAddress)
  win.GetProcAddress = stdcallThunk(getProcAddressSlot, 2)

  bindFunctions({
    { "FindFirstFileA", 2 }, { "FindNextFileA", 2 }, { "FindClose", 1 },
    { "GetModuleFileNameA", 3 },
    { "GetLastError", 0 }, { "MultiByteToWideChar", 6 }, { "GetFileAttributesExA", 3 },
    { "GetFileAttributesA", 1 },
  })

  local length = win.GetModuleFileNameA(0, pathBuffer, PATH_BUFFER_SIZE)
  assert(length > 0 and length < PATH_BUFFER_SIZE, "cannot resolve the game directory")
  gameDirectory = assert(core.readString(pathBuffer, length):gsub("/", "\\"):match("^(.*\\)"))
end

local writerFailure
local function initializeWriter()
  if writerFailure ~= nil then error(writerFailure, 0) end
  if writtenBuffer ~= nil then return end
  local ok, err = pcall(function()
    bindFunctions({
      { "CreateDirectoryA", 2 }, { "DeleteFileA", 1 },
      { "GetTempFileNameA", 4 }, { "MoveFileExA", 3 },
      { "CreateFileA", 7 }, { "WriteFile", 5 }, { "CloseHandle", 1 },
    })
    tempPathBuffer = core.allocate(PATH_BUFFER_SIZE, true)
    tempPrefix = core.allocate(4, true)
    writeCString(tempPrefix, "cst")
    writtenBuffer = core.allocate(4, true)
  end)
  if not ok then
    writerFailure = tostring(err)
    error(writerFailure, 0)
  end
end

---Resolves the Windows functions once; a failure is kept and raised again on later calls.
local function initialize()
  if initialized then
    return
  end
  if failure ~= nil then
    error(failure, 0)
  end
  local ok, err = pcall(setUp)
  if not ok then
    failure = tostring(err)
    error(failure, 0)
  end
  initialized = true
end

---Resolve a trail path without allowing traversal, device paths or reparse points.
---Keep a relative spelling for the framework, which also opens paths inside extension ZIP files.
function winfiles.scopedPath(path)
  initialize()
  if type(path) ~= "string" or path == "" or path:find("%c") then
    return nil, "invalid trail path"
  end
  -- UCP registers its aliases (ucp/plugins/<name>-*/) with forward slashes
  local resolved = ucp.internal.resolveAliasedPath((path:gsub("\\", "/"))):gsub("/", "\\")
  if resolved:sub(1, #gameDirectory):lower() == gameDirectory:lower() then
    resolved = resolved:sub(#gameDirectory + 1)
  end
  if resolved:sub(1, 1) == "\\" or resolved:find('[:"<>|?*%c]') then
    return nil, "trail path must be inside the game folder"
  end
  local parts = {}
  for part in resolved:gmatch("[^\\]+") do
    if part == ".." then
      if #parts == 0 then return nil, "trail path leaves the game folder" end
      parts[#parts] = nil
    elseif part ~= "." then
      if part:find("[%. ]$") then return nil, "ambiguous Windows path component" end
      local stem = (part:match("^[^.]*") or ""):gsub(" +$", ""):upper()
      if stem == "CON" or stem == "PRN" or stem == "NUL" or stem == "AUX"
          or stem == "CONIN$" or stem == "CONOUT$" or stem:match("^COM[1-9]$")
          or stem:match("^LPT[1-9]$") or stem:match("^COM[\185\178\179]$")
          or stem:match("^LPT[\185\178\179]$") then
        return nil, "Windows device names cannot be used for trail paths"
      end
      parts[#parts + 1] = part
    end
  end
  local absolute = gameDirectory:sub(1, -2)
  for _, part in ipairs(parts) do
    absolute = absolute .. "\\" .. part
    local attributes = win.GetFileAttributesA(setPath(absolute)) & 0xFFFFFFFF
    if attributes == INVALID_HANDLE then
      local reason = win.GetLastError()
      if reason ~= ERROR_FILE_NOT_FOUND and reason ~= ERROR_PATH_NOT_FOUND then
        return nil, "cannot inspect trail path (Windows error " .. reason .. ")"
      end
    elseif attributes & FILE_ATTRIBUTE_REPARSE_POINT ~= 0 then
      return nil, "trail paths cannot pass through reparse points"
    end
  end
  return #parts == 0 and "." or table.concat(parts, "/"), absolute
end

local function checkedPath(path)
  local relative, absolute = winfiles.scopedPath(path)
  if relative == nil then error(absolute, 2) end
  return absolute
end

---Like checkedPath, for paths that must name something inside the game folder (not the
---game folder itself): files to write or delete.
local function checkedEntryPath(path)
  local relative, absolute = winfiles.scopedPath(path)
  if relative == nil then error(absolute, 2) end
  if relative == "." then error("trail path must name a file inside the game folder", 2) end
  return absolute
end

local function lastError()
  return string.format("Windows error %d", win.GetLastError())
end

---Creates the folder `path`, with any missing parent folders inside the game folder.
---True when it exists afterwards.
function winfiles.createDirectory(path)
  initialize()
  initializeWriter()
  local relative, absolute = winfiles.scopedPath(path)
  if relative == nil then error(absolute, 2) end
  if relative == "." then
    return true
  end
  local current = gameDirectory:sub(1, -2)
  for part in relative:gmatch("[^/]+") do
    current = current .. "\\" .. part
    if win.CreateDirectoryA(setPath(current), 0) == 0 then
      local err = win.GetLastError()
      if err ~= ERROR_ALREADY_EXISTS then
        return false, string.format("cannot create the folder %s (Windows error %d)", current, err)
      end
    end
  end
  return true
end

---The names of the files (not folders) in the folder `path` that match `pattern` ("*.json").
function winfiles.listFiles(path, pattern)
  initialize()
  local absolute = checkedPath(path):gsub("\\$", "")
  assert(pattern == "*.json", "unsupported trail file search")
  local handle = win.FindFirstFileA(setPath(absolute .. "\\" .. pattern), findData) & 0xFFFFFFFF
  local names = {}
  if handle == INVALID_HANDLE then
    return names
  end
  repeat
    local attributes = core.readInteger(findData + FIND_DATA_ATTRIBUTES) & 0xFFFFFFFF
    if attributes & FILE_ATTRIBUTE_DIRECTORY == 0 then
      table.insert(names, core.readString(findData + FIND_DATA_NAME))
    end
  until win.FindNextFileA(handle, findData) == 0
  win.FindClose(handle)
  return names
end

---Copies the bytes of a Lua string to `address`. Binary safe (zero bytes included), unlike
---core.writeString.
local COPY_CHUNK = 4096
function winfiles.writeMemory(address, contents)
  for offset = 1, #contents, COPY_CHUNK do
    local last = math.min(offset + COPY_CHUNK - 1, #contents)
    core.writeBytes(address + offset - 1, { contents:byte(offset, last) })
  end
end

---A Lua function calling the stdcall function `name` exported by `dll` (loaded if needed).
function winfiles.dllFunction(dll, name, argumentCount)
  initialize()
  local base = win.LoadLibraryA(setPath(dll)) & 0xFFFFFFFF
  if base == 0 then
    return nil, "cannot load " .. dll
  end
  local address = findExport(base, name, 0)
  if address == nil then
    return nil, dll .. " has no " .. name
  end
  local slot = core.allocate(4, true)
  core.writeInteger(slot, address)
  return stdcallThunk(slot, argumentCount)
end

---A new zero-terminated UTF-16 copy of the ANSI path `path` (for GDI+). Free it with core.deallocate.
function winfiles.widePath(path)
  initialize()
  local relative, absolute = winfiles.scopedPath(path)
  if relative == nil then return nil end
  local characters = win.MultiByteToWideChar(0, 0, setPath(absolute), -1, 0, 0)
  if characters <= 0 then
    return nil
  end
  local buffer = core.allocate(characters * 2 + 2, true)
  win.MultiByteToWideChar(0, 0, setPath(absolute), -1, buffer, characters)
  return buffer
end

---"size:time" of the file `path` (changes whenever the file does), or nil when it is missing.
function winfiles.fileStamp(path)
  initialize()
  local data = core.allocate(36, true) -- WIN32_FILE_ATTRIBUTE_DATA
  local stamp = nil
  if win.GetFileAttributesExA(setPath(checkedPath(path)), 0, data) ~= 0 then
    stamp = string.format("%u:%u:%u", core.readInteger(data + 32) & 0xFFFFFFFF,
      core.readInteger(data + 20) & 0xFFFFFFFF, core.readInteger(data + 24) & 0xFFFFFFFF)
  end
  core.deallocate(data)
  return stamp
end

---The last write time of the file `path` as a number (larger = newer), or nil when it is missing.
function winfiles.fileTime(path)
  initialize()
  local data = core.allocate(36, true)
  local time = nil
  if win.GetFileAttributesExA(setPath(checkedPath(path)), 0, data) ~= 0 then
    time = (core.readInteger(data + 24) & 0xFFFFFFFF) * 4294967296 + (core.readInteger(data + 20) & 0xFFFFFFFF)
  end
  core.deallocate(data)
  return time
end

---Deletes the file `path`. True when it is gone afterwards.
function winfiles.deleteFile(path)
  initialize()
  initializeWriter()
  if win.DeleteFileA(setPath(checkedEntryPath(path))) ~= 0 then
    return true
  end
  return winfiles.fileStamp(path) == nil
end

---Writes `contents` (any bytes) to the file `path`, replacing it.
function winfiles.writeFile(path, contents)
  initialize()
  initializeWriter()
  local absolute = checkedEntryPath(path)
  local directory = absolute:match("^(.*\\)[^\\]+$")
  if directory == nil or directory:sub(1, #gameDirectory):lower() ~= gameDirectory:lower() then
    return false, "invalid output path"
  end
  if win.GetTempFileNameA(setPath(directory), tempPrefix, 0, tempPathBuffer) == 0 then
    return false, string.format("cannot stage %s (%s)", absolute, lastError())
  end
  local handle = win.CreateFileA(tempPathBuffer, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0)
    & 0xFFFFFFFF
  if handle == INVALID_HANDLE then
    local reason = lastError()
    win.DeleteFileA(tempPathBuffer)
    return false, string.format("cannot write %s (%s)", absolute, reason)
  end
  local ok, err = true, nil
  if #contents > 0 then
    if #contents + 1 > dataBufferSize then
      if dataBuffer ~= nil then
        core.deallocate(dataBuffer)
      end
      dataBufferSize = math.max(#contents + 1, 64 * 1024)
      dataBuffer = core.allocate(dataBufferSize, true)
    end
    winfiles.writeMemory(dataBuffer, contents)
    if win.WriteFile(handle, dataBuffer, #contents, writtenBuffer, 0) == 0
      or core.readInteger(writtenBuffer) ~= #contents then
      ok, err = false, string.format("cannot write %s (%s)", absolute, lastError())
    end
  end
  if win.CloseHandle(handle) == 0 then
    ok, err = false, err or lastError()
  end
  -- Replace the directory entry. An existing hard link keeps its other links
  -- intact, and an interrupted write leaves the previous destination intact.
  if ok and win.MoveFileExA(tempPathBuffer, setPath(absolute),
      MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH) ~= 0 then
    return true
  end
  err = err or string.format("cannot replace %s (%s)", absolute, lastError())
  win.DeleteFileA(tempPathBuffer)
  return false, err
end

return winfiles
