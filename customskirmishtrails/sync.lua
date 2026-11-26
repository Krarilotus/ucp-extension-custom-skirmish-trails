-- trail_missions: a trail's missions as a csv file and/or a folder of mission JSON files. At every
-- game start the game loads the missions data_mode gives; the trail's own files are only read.
--
--   data_mode "csv":         the csv file.
--   data_mode "json_folder": the mission files.
--   data_mode "automatic":   per mission, whichever was edited last.
--
-- With a language folder, a template for translators with the default texts is kept in the user
-- data folder.

local winfiles = require("customskirmishtrails.winfiles")
local storage = require("customskirmishtrails.storage")
local conversion = require("customskirmishtrails.conversion")
local texts = require("customskirmishtrails.texts")

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

---The missions of one trail. `missions` = { csv, folder, name, mode, files } from the trail
---settings file (files: the mission files of a route, read in json_folder mode). Returns the csv
---text to load in place of the csv file (nil: load the csv file) and a list of messages.
function sync.run(trailName, missions, aiMapping, knownHeaders, textFolder, trailSettings)
  local messages = {}
  local csv = conversion.readTable(missions.csv)
  local rows, text = csv ~= nil and csv.missions or nil, nil

  if missions.mode ~= "csv" then
    local reverse = conversion.reverseMapping(aiMapping)
    local byNumber, highest = {}, 0
    for _, file in ipairs(missionFiles(missions)) do
      byNumber[file.number] = { cells = conversion.readMission(file.path, reverse), path = file.path }
      highest = math.max(highest, file.number)
    end
    if highest == 0 then
      if missions.mode == "json_folder" then
        error(string.format("there are no mission files in %s", missions.folder))
      end
    else
      local csvTime = (missions.mode == "automatic" and csv ~= nil) and (winfiles.fileTime(missions.csv) or 0) or nil
      rows = {}
      for number = 1, csvTime and math.max(#csv.missions, highest) or highest do
        local file = byNumber[number]
        if file ~= nil and (csvTime == nil or (winfiles.fileTime(file.path) or 0) > csvTime) then
          table.insert(rows, file.cells)
        elseif csvTime ~= nil and csv.missions[number] ~= nil then
          table.insert(rows, csv.missions[number])
        end
      end
      local header = conversion.columnOrder(csv ~= nil and csv.header or nil, rows, knownHeaders)
      text = conversion.csvText(header, rows, "\r\n")
    end
  end

  if textFolder ~= nil and rows ~= nil then
    local name = string.format("texts-template-%s.json", trailSettings.fileName)
    local template = texts.format(rows, trailSettings.title, trailSettings.summary, trailSettings.lockedText,
      trailSettings.missionKeys)
    if storage.read(name) ~= template then
      local written, writeError = storage.write(name, template)
      if not written then
        table.insert(messages, "the translation template is not written: " .. tostring(writeError))
      end
    end
  end
  return text, messages
end

return sync
