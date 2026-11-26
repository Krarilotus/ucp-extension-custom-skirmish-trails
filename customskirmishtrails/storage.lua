-- The module's own files (progress, route results, caches, Export and Import output) in its UCP
-- user data folder: <Crusader user folder>/ucp/userdata/custom-skirmish-trails/. The folder is
-- ready once the game has started (afterInit).

local storage = {}

local EXTENSION = "custom-skirmish-trails"

local folder = nil

---`name` as the user data folder takes it: letters, digits, '.', '~' and '-' in each part. '_' becomes
---'~', which a trail_id cannot contain, so distinct trail_ids keep distinct files.
local function safeName(name)
  return (name:gsub("_", "~"):gsub("[^%w.~/-]", "-"))
end

local function interface()
  if folder == nil then
    local ok, result = pcall(userdata.interface)
    if not ok then
      log(WARNING, "custom-skirmish-trails: the user data folder cannot be opened: " .. tostring(result))
      return nil, tostring(result)
    end
    folder = result
  end
  if folder == nil then
    log(WARNING, "custom-skirmish-trails: the user data folder is used before the game has started")
    return nil, "the user data folder is not ready"
  end
  return folder
end

---Opens the file `name` of the user data folder, as io.open does.
function storage.open(name, mode)
  local f, err = interface()
  if f == nil then
    return nil, err
  end
  return f:open(safeName(name), mode)
end

---Writes `contents` to the file `name` of the user data folder, replacing it. True, or false and
---the reason.
function storage.write(name, contents)
  local f, err = interface()
  if f == nil then
    return false, err
  end
  local directory = name:match("^(.+)/[^/]+$")
  if directory ~= nil then
    f:mkdir(safeName(directory), true)
  end
  local file, openError = f:open(safeName(name), "wb")
  if file == nil then
    return false, string.format("cannot write %s: %s", name, tostring(openError))
  end
  local written, writeError = file:write(contents)
  file:close()
  if written == nil then
    return false, string.format("cannot write %s: %s", name, tostring(writeError))
  end
  return true
end

---The contents of the file `name` of the user data folder, or nil.
function storage.read(name)
  local file = storage.open(name, "rb")
  if file == nil then
    return nil
  end
  local contents = file:read("a")
  file:close()
  return contents
end

---The absolute path of the file `name` of the user data folder, for code that opens it by path.
function storage.path(name)
  if interface() == nil then
    return nil
  end
  return data.userdata.getPathInUserDataFolder(EXTENSION .. "/" .. safeName(name))
end

return storage
