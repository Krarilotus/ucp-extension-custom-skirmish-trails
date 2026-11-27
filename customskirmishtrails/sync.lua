-- Mission files are read at startup. Legacy automatic mode may also select CSV rows.
local winfiles = require("customskirmishtrails.winfiles")
local conversion = require("customskirmishtrails.conversion")

local sync = {}

---The mission files { number, path } of `missions`: the files a route names, in its order, or the
---numbered files of the folder.
local function missionFiles(missions)
  local files = {}
  for number, path in ipairs(missions.files or {}) do
    files[number] = { number = number, path = path }
  end
  if missions.files == nil then
    for _, file in ipairs(conversion.listMissionFiles(missions.folder, missions.name)) do
      table.insert(files, { number = file.number, path = missions.folder .. "/" .. file.name })
    end
  end
  return files
end

---Returns in-memory CSV and its source rows, or nil for the legacy CSV fallback.
function sync.run(missions, aiMapping, knownHeaders, legacy)
  local csv = legacy and conversion.readTable(missions.csv) or nil
  local files = missionFiles(missions)
  if #files == 0 then
    if missions.mode == "automatic" then return nil end
    error(string.format("there are no mission files in %s", missions.folder), 0)
  end

  local reverse = conversion.reverseMapping(aiMapping)
  local byNumber = {}
  for index, file in ipairs(files) do
    if not legacy and file.number ~= index then
      error(string.format("expected mission file %d in %s", index, missions.folder), 0)
    end
    byNumber[file.number] = { cells = conversion.readMission(file.path, reverse), path = file.path }
  end

  local csvTime = (missions.mode == "automatic" and csv ~= nil) and (winfiles.fileTime(missions.csv) or 0) or nil
  local highest = files[#files].number
  local rows = {}
  for number = 1, csvTime and math.max(#csv.missions, highest) or highest do
    local file = byNumber[number]
    if file ~= nil and (csvTime == nil or (winfiles.fileTime(file.path) or 0) > csvTime) then
      table.insert(rows, file.cells)
    elseif csvTime ~= nil and csv.missions[number] ~= nil then
      table.insert(rows, csv.missions[number])
    end
  end
  local header = conversion.columnOrder(csv and csv.header or nil, rows, knownHeaders, legacy)
  return conversion.csvText(header, rows, "\r\n"), rows
end

return sync
