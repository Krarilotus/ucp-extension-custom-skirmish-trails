local memory = require("customskirmishtrails.memory")
local interface = require("customskirmishtrails.interface")
local cst_io = require("customskirmishtrails.io")
local description = require("customskirmishtrails.description")
local tradeability = require("customskirmishtrails.tradeability")
local producibility = require("customskirmishtrails.producibility")
local recruitability = require("customskirmishtrails.recruitability")
local startgold = require("customskirmishtrails.startgold")
local start_goods = require("customskirmishtrails.start_goods")
local patches = require("customskirmishtrails.patches")
local settingsModule = require("customskirmishtrails.settings")
local visuals = require("customskirmishtrails.visuals")
local menutext = require("customskirmishtrails.menutext")
local textsModule = require("customskirmishtrails.texts")
local sync = require("customskirmishtrails.sync")
local progress = require("customskirmishtrails.progress")
local scenario = require("customskirmishtrails.scenario")
local unitlimits = require("customskirmishtrails.unitlimits")
local markers = require("customskirmishtrails.markers")
local route = require("customskirmishtrails.route")

local TRAIL_PROGRESS_ADDRESSES = memory.TRAIL_PROGRESS_ADDRESSES
local REGISTRY = memory.REGISTRY
local fetchCurrentTrail = memory.fetchCurrentTrail

-- The three trails: their name in this module, their key in the GUI config and their
-- trail_type in trail settings files.
local TRAILS = {
  { name = "firstEditionTrail", key = "firstedition", type = "First" },
  { name = "warchestTrail", key = "warchest", type = "Warchest" },
  { name = "extremeTrail", key = "extremetrail", type = "Extreme" },
}

-- per trail: mission number -> map name given by a plugin (setMissionMap)
local MAP_OVERRIDES = {}
-- per trail: the briefing text of a scenario mission that is not open yet
local LOCKED_TEXTS = {}

local currentEntry = memory.currentEntry

local function insertPostSkirmishSetupDetour()
  log(2, "insertPostSkirmishSetupDetour: setting up detour")
  -- local detourLocation, detourSize = core.AOBScan("A1 ? ? ? ? 8D 0C 80 03 C9 89 ? ? ? ? ?"), 5
  local detourLocation, detourSize = core.AOBScan("8B 8C 24 ? ? 00 00 5f 5e 89 ? ? ? ? ? 89 ? ? ? ? ? 89 ? ? ? ? ? 89 ? ? ? ? ? 5B 33 CC"), 7
  core.detourCode(function(registers)
    local isTrail, trail, trailName, mission = fetchCurrentTrail()
    if not isTrail then
      log(2, "not in skirmish trail")
      return registers
    end

    if trailName == nil then error(string.format("invalid trail: %s", trail)) end

    log(2, string.format("trail: %s", trailName))
    
    local missions = REGISTRY[trailName]
    if missions == nil then
      log(2, string.format("No custom missions registered for trail name: %s", trailName))
      return registers
    end

    log(2, string.format("Committing extra parameters for %s mission: %s", trailName, mission))
    
    local entry = missions[mission]
    if entry == nil then
      log(-1, string.format("skirmish trail (%s) entry is unexpectedly nil: %s", trailName, mission))
      return registers
    end
    interface.commitEntryExtra(entry)

    return registers

  end, detourLocation, detourSize)

  core.detourCode(function(registers)
    if core.readInteger(memory.IS_SKIRMISH_TRAIL) ~= 1 then return registers end

    local isTrail, trail, trailName, mission = memory.fetchCurrentTrail()
    if not isTrail then return registers end
    local missions = REGISTRY[trailName]
    if missions == nil then
      log(2, string.format("No custom missions registered for trail name: %s", trailName))
      return registers
    end

    log(2, string.format("Committing start goods parameters for %s mission: %s", trailName, mission))
    
    local entry = missions[mission]
    if entry == nil then
      log(-1, string.format("skirmish trail (%s) entry is unexpectedly nil: %s", trailName, mission))
      return registers
    end
    -- the human player's starting troops are computed right after this from the lord type
    patches.applyLord(entry)
    interface.setStartGoods(entry)
  end, core.AOBScan("A3 ? ? ? ? A3 ? ? ? ? A3 ? ? ? ? A3 ? ? ? ? A3 ? ? ? ? A3 ? ? ? ? A3 ? ? ? ? A3 ? ? ? ? A3 ? ? ? ? A3 ? ? ? ? A3 ? ? ? ? A3 ? ? ? ? A3 ? ? ? ? A3 ? ? ? ? 89 44 24 10 "), 5)
end

local function applyTrail(trailName, result, missions, languageTexts, startInstalled, keys)
  -- the game language's texts over the default texts of the csv
  textsModule.apply(languageTexts, result, keys)
  local rowOf = {}
  for row, key in ipairs(keys or {}) do
    rowOf[key] = row
  end
  for mission, mapName in pairs(MAP_OVERRIDES[trailName] or {}) do
    local index = rowOf[mission] or mission
    if result[index] ~= nil then
      result[index].map_name = mapName
    else
      log(WARNING, string.format("setMissionMap: the trail has no mission %s; %s is not used",
        tostring(mission), mapName))
    end
  end
  MAP_OVERRIDES[trailName] = nil
  for index, entry in ipairs(result) do
    interface.applyColors(entry, string.format("%s mission %d", trailName, index))
    if scenario.difficultyScaling(entry) == nil then
      log(WARNING, string.format("%s mission %d: unknown difficulty_scaling '%s'; vanilla is used",
        trailName, index, tostring(entry.difficulty_scaling)))
    end
    if scenario.missionType(entry) == nil then
      log(WARNING, string.format("%s mission %d: unknown mission_type '%s'",
        trailName, index, tostring(entry.mission_type)))
    elseif scenario.isScenario(entry) and not startInstalled then
      result[index] = nil
    elseif scenario.isScenario(entry) then
      local fileName, reason = scenario.mapFileName(entry.map_name)
      if fileName == nil then
        log(WARNING, string.format("%s mission %d: scenario map '%s': %s",
          trailName, index, tostring(entry.map_name), reason))
      else
        entry.map_name = fileName
        scenario.applyMapLords(entry, fileName)
      end
    end
  end

  REGISTRY[trailName] = result
  
  for index, entry in pairs(REGISTRY[trailName]) do
    interface.commitEntry(missions, index, entry, trailName)
  end
end

local function detourSwitchToMenu()
  core.detourCode(function(registers)
    log(2, string.format("detour: SetupSkirmishMode: %s", ""))

    -- we aren't in a trail setting yet (we are preparting for it), so we ignore the isTrail part of the return values
    local _, trail, trailName, mission = fetchCurrentTrail()
    if trail ~= nil then
      local missions = REGISTRY[trailName]
      if missions == nil then
        log(VERBOSE, string.format("No custom missions registered for trail name: %s", trailName))
        patches.applyLord(nil)
        return registers
      end

      local entry = missions[mission]
      if entry == nil then
        log(-1, string.format("skirmish trail (%s) entry is unexpectedly nil: %s", trailName, mission))
        patches.applyLord(nil)
        return registers
      end
      
      interface.commitTextDescription(scenario.briefingEntry(entry, LOCKED_TEXTS[trailName]))
      patches.applyLord(entry)
      
    else
      log(2, "detourSwitchMenu: no text description to set")
    end
  end, core.AOBScan("C7 ? ? ? ? ? ? ? ? ? ? E8 ? ? ? ? 5D C3"), 11)
end

---Player names and the human player's lord: every time the game names its players (for a
---trail mission's briefing and when a map starts), a trail mission puts its own in.
local function hookPlayerNaming()
  patches.hookPlayerNaming(function(isTrailBriefing)
    local entry, isTrail = currentEntry()
    if isTrailBriefing or isTrail then
      patches.applyPlayerNames(entry)
      patches.applyLord(entry)
    else
      patches.applyLord(nil)
    end
  end)
end

---The user data file that keeps the trail's `kind` of state (progress, sides or results).
local function stateFile(kind, settings)
  return string.format("%s-%s.txt", kind, settings.fileName)
end

---The trail_route of a trail settings file; nil when it can't be played (logged).
local function installRoute(trail, settings, count)
  if settings.route == nil then
    return nil
  end
  local r = route.load(settings.routeFiles or route.read(settings.path, settings.route, count), count,
    stateFile("sides", settings), stateFile("results", settings))
  if r == nil then
    log(ERROR, trail.type .. " trail progression could not be applied.")
    return nil
  end
  if not progress.installRoute(trail.name, r) then
    log(ERROR, trail.type .. " trail progression could not be applied.")
    log(WARNING, string.format("%s: the trail route is switched off; the trail plays its "
      .. "missions in their order", settings.path))
    return nil
  end
  return r
end

---A route of mission files is the trail's mission data: it gives the order of the missions (the
---rows of the csv the game loads), their positions and their keys in language files.
local function readRouteFiles(trail, settings)
  local parsed = route.read(settings.path, settings.route, nil)
  local problem = parsed == nil and ""
    or settings.missions == nil and "a route of mission files needs trail_missions.base_name"
    or parsed.count > patches.CAPACITY[trail.name]
      and string.format("the route has %d missions; this trail can have at most %d", parsed.count,
        patches.CAPACITY[trail.name])
  if problem then
    if problem ~= "" then
      log(WARNING, string.format("%s: %s; the trail's missions are not loaded",
        settings.path, problem))
    end
    return false
  end
  if settings.positions ~= nil then
    log(WARNING, string.format("%s: a route of mission files has the positions; "
      .. "trail_mission_positions is not used", settings.path))
  end
  local directory = settingsModule.directoryOf(settings.path)
  local files = {}
  for row, file in ipairs(parsed.files) do
    files[row] = settingsModule.resolveRelative(directory, file)
  end
  settings.missions.files, settings.missions.mode = files, "json_folder"
  settings.positions, settings.missionKeys, settings.routeFiles = parsed.positions, parsed.keys, parsed
  return true
end

-- Trail sources ---------------------------------------------------------------------------

local function configuredPath(value)
  return type(value) == "table" and value.path or nil
end

local function knownHeaders()
  local headers = {}
  for _, header in ipairs(cst_io.HEADERS) do table.insert(headers, header) end
  for _, header in ipairs(cst_io.HEADERS_EXTRA) do table.insert(headers, header) end
  return headers
end

local sourceFailures = {}

local function sourceFailure(trail, path, reason)
  if not sourceFailures[trail.name] then
    sourceFailures[trail.name] = true
    log(ERROR, trail.type .. " custom trail missions could not be loaded.")
  end
  if reason ~= nil then
    log(WARNING, string.format("%s trail source %s: %s; the game's own missions are used",
      trail.type, tostring(path), tostring(reason)))
  end
end

local function readTrailSource(config, trail)
  local options = type(config[trail.key]) == "table" and config[trail.key] or {}
  local path = configuredPath(options.source)
  local legacy = path == nil or path == ""
  local settingsPath, csvPath
  if legacy then
    -- Accept old profile keys for one release.
    settingsPath, csvPath = configuredPath(options.settings), configuredPath(options.csv)
  elseif type(path) == "string" and path:lower():match("%.csv$") then
    csvPath = path
  elseif type(path) == "string" and path:lower():match("%.json$") then
    settingsPath = path
  else
    sourceFailure(trail, path, "expected a .csv or .json file")
    return
  end

  local settings, csvText, jsonRows
  if type(settingsPath) == "string" and settingsPath ~= "" then
    settings = settingsModule.load(settingsPath, trail.name, not legacy)
    if settings == nil and not legacy then
      sourceFailure(trail)
      return
    end
  end
  if settings ~= nil then
    if route.hasFiles(settings.route) and not readRouteFiles(trail, settings) then
      if not legacy then
        sourceFailure(trail)
        return
      end
      settings.route, settings.missions = nil, nil
    end
    local missions = settings.missions
    if missions ~= nil then
      csvPath = missions.csv
      if missions.mode ~= "csv" then
        local ok, result, rows = pcall(sync.run, missions, settings.hasAiMapping and settings.aiMapping or nil,
          knownHeaders(), legacy)
        if ok then
          csvText = result
          if not legacy then jsonRows = rows end
        else
          if not legacy or missions.mode == "json_folder" then
            sourceFailure(trail, settingsPath, result)
            if legacy then return settings end
            return
          end
          log(WARNING, string.format("%s trail source %s: %s",
            trail.type, tostring(settingsPath), tostring(result)))
        end
      end
    end
  end

  local sourcePath = legacy and (csvText and settingsPath or csvPath) or path
  if type(sourcePath) ~= "string" or sourcePath == "" then return settings end
  local plannedCount = settings and settings.positions and #settings.positions or patches.VANILLA_COUNT[trail.name]
  local ok, entries, reason = pcall(cst_io.readCSV, sourcePath, plannedCount + 1, csvText, not legacy, jsonRows)
  if not ok or entries == nil then
    sourceFailure(trail, sourcePath, ok and reason or entries)
    if legacy then return settings end
    return
  end
  return settings, entries, sourcePath
end

return {
  enable = function(self, config)
    config = config or {}
    local strict = type(config.csv) == "table" and config.csv.strict_format == true
    if strict then
      cst_io.setStrictness("error")
    else
      cst_io.setStrictness("warning")
    end
    settingsModule.setStrict(strict)
    textsModule.setStrict(strict)

    local _, skirmishTrailMissions, extremeTrailMissions, warchestTrailMissions = utils.AOBExtract("8D ? I(? ? ? ?) 75 08 8D ? I(? ? ? ?) EB 0B 83 F9 01 75 06 8D ? I(? ? ? ?) 53")
    local missionTables = {
      firstEditionTrail = skirmishTrailMissions,
      warchestTrail = warchestTrailMissions,
      extremeTrail = extremeTrailMissions,
    }

    -- trail settings files: mission count and positions, start years, texts, visuals, progress
    local trailSettings = {}
    local trailEntries, sourcePaths = {}, {}
    local routes = {}
    local missionCounts = {}
    local startYears = {}
    for _, trail in ipairs(TRAILS) do
      local okSource, settings, entries, sourcePath = pcall(readTrailSource, config, trail)
      if not okSource then
        local options = config[trail.key]
        local path = type(options) == "table" and (configuredPath(options.source)
          or configuredPath(options.settings) or configuredPath(options.csv))
        sourceFailure(trail, path, settings)
        settings = nil
      end
      trailSettings[trail.name], trailEntries[trail.name], sourcePaths[trail.name] = settings, entries, sourcePath
      missionCounts[trail.name] = patches.VANILLA_COUNT[trail.name]

      if settings ~= nil then
        if settings.positions ~= nil then
          local count = #settings.positions
          if trail.name == "extremeTrail" and count > patches.VANILLA_COUNT.extremeTrail then
            local grown = patches.growExtremeTable(missionTables.extremeTrail, patches.CAPACITY.extremeTrail)
            if grown == missionTables.extremeTrail then
              count = patches.VANILLA_COUNT.extremeTrail -- the table could not move
            end
            missionTables.extremeTrail = grown
          end
          if count == patches.VANILLA_COUNT[trail.name] or patches.setMissionCount(trail.name, count) then
            missionCounts[trail.name] = count
          else
            log(ERROR, trail.type .. " trail mission count could not be changed.")
          end
          -- Extreme missions past the game's 20 have no name in the game's texts; a csv
          -- line's mission_name replaces this one
          for index = patches.VANILLA_COUNT[trail.name] + 1, missionCounts[trail.name] do
            modules.textResourceModifier:SetText(0xF5, 0x51 + (index - 1), string.format("Mission %d", index))
          end
          local positions = {}
          for index = 1, math.min(missionCounts[trail.name], #settings.positions) do
            positions[index] = settings.positions[index]
          end
          if not patches.setPositions(trail.name, positions) then
            log(ERROR, trail.type .. " trail mission positions could not be changed.")
          end
        end
        startYears[trail.name] = settings.startingYear
        local okVisuals, visualsError = pcall(visuals.applyVisuals, trail.name, settings.visuals)
        if not okVisuals then
          log(ERROR, trail.type .. " trail artwork could not be applied.")
          log(WARNING, string.format("%s trail visuals: %s", trail.type, tostring(visualsError)))
        end
        if settings.id ~= nil then
          progress.install(trail.name, stateFile("progress", settings), missionCounts[trail.name])
        end
        local okRoute, sides = pcall(installRoute, trail, settings, missionCounts[trail.name])
        if not okRoute then
          log(ERROR, trail.type .. " trail progression could not be applied.")
          log(WARNING, string.format("%s trail route: %s", trail.type, tostring(sides)))
          sides = nil
        end
        routes[trail.name] = sides
        local pictures = false
        if settings.visuals.iconSheet ~= nil then
          local okMarkers, installed = pcall(markers.install, trail.name, settings.visuals.iconSheet,
            missionCounts[trail.name], sides)
          if not okMarkers then
            log(WARNING, tostring(installed))
          end
          if not (okMarkers and installed) then
            log(ERROR, trail.type .. " trail door pictures are off.")
          end
          pictures = okMarkers and installed
        end
        if not pictures then
          progress.withoutPictures(trail.name, sides)
        end
        if settings.hasAiMapping then
          interface.setAiAliases(trail.name, settings.aiMapping)
        end
      end
    end
    patches.setStartYears(startYears)

    local startInstalled
    -- after the routes have read their files from the user data folder (their afterInit callbacks)
    hooks.registerHookCallback("afterInit", function()
      local chickenBudgets = {}
      for index, trailName in pairs(memory.TRAIL_TYPES) do
        local settings = trailSettings[trailName]
        local budget = settings and settings.chickens
        -- the chickens of the route's rewards won so far
        local r = routes[trailName]
        if r ~= nil and r.rewards and budget ~= "unlimited" then
          budget = math.min((budget or patches.NATIVE_CHICKENS) + r:earnedChickens(), 2147483647)
        end
        -- One more than the number of rows keeps a chicken available after every possible skip.
        chickenBudgets[index] = budget == "unlimited" and patches.CAPACITY[trailName] + 1 or budget
      end
      patches.setChickenBudgets(chickenBudgets)

      local language = data.version.getGameLanguage() or ""

      for _, trail in ipairs(TRAILS) do
        local trailSettingsForTexts = trailSettings[trail.name]
        -- the game language's text file, if the trail settings file names one
        local languageTexts = nil
        if trailSettingsForTexts ~= nil then
          local textFile = textsModule.fileFor(trailSettingsForTexts.textFiles, language)
          if textFile ~= nil then
            languageTexts = textsModule.load(textFile)
            if languageTexts ~= nil then
              log(INFO, string.format("%s trail texts (%s): %s", trail.type, language, textFile))
            end
          elseif trailSettingsForTexts.textFiles ~= nil then
            log(INFO, string.format("no %s text file for the %s trail; the default texts are shown",
              language, trail.type))
          end
          LOCKED_TEXTS[trail.name] = (languageTexts and languageTexts.lockedText) or trailSettingsForTexts.lockedText
          local okTexts, textError = pcall(menutext.apply, trail.name,
            (languageTexts and languageTexts.title) or trailSettingsForTexts.title,
            (languageTexts and languageTexts.summary) or trailSettingsForTexts.summary)
          if not okTexts then
            log(ERROR, trail.type .. " trail title and summary could not be applied.")
            log(WARNING, "trail title and summary: " .. tostring(textError))
          end
        end
        local entries, path = trailEntries[trail.name], sourcePaths[trail.name]
        if entries ~= nil then
          log(INFO, string.format("%s trail (%s): %s", trail.type, language, path))
          for index = #entries, missionCounts[trail.name] + 1, -1 do
            entries[index] = nil
          end
          local okTrail, trailError = pcall(applyTrail, trail.name, entries, missionTables[trail.name],
            languageTexts, startInstalled, trailSettingsForTexts and trailSettingsForTexts.missionKeys)
          if not okTrail then sourceFailure(trail, path, trailError) end
        end
      end

      for trailName, overrides in pairs(MAP_OVERRIDES) do
        if next(overrides) ~= nil then
          log(WARNING, string.format("setMissionMap: %s has no mission data of its own; "
            .. "its maps are not changed", trailName))
        end
      end

      unitlimits.apply(REGISTRY, scenario.session(), scenario.isPlayedMission)

      self.REGISTRY = REGISTRY -- debug line
    end)

    insertPostSkirmishSetupDetour()


    -- -- detour to get the map text displayed right...
    -- core.detourCode(function(registers)
    --   if core.readInteger(memory.IS_SKIRMISH_TRAIL) ~= 1 then
    --     return registers
    --   end

    --   if core.readInteger(memory.CURRENT_TRAIL_TYPE) ~= 2 then
    --     return registers
    --   end

    --   local mission = core.readInteger(memory.EXTREME_TRAIL_PROGRESS) + 1
    --   local entry = REGISTRY.extremeTrail[mission]
    --   -- todo
    -- end, core.AOBScan("83 C2 51 52", 9))
    
    log(2, "enable description hijack")
    description.enable()
    tradeability.enable()
    producibility.enable()
    startgold.enable()
    local okIcons, iconsError = pcall(patches.showStartModeIcons)
    if not okIcons or iconsError == false then
      log(ERROR, "Custom starting mode pictures are off.")
      if not okIcons then log(WARNING, "start mode pictures: " .. tostring(iconsError)) end
    end
    local okTeams, teamsError = pcall(patches.separateBriefingTeams)
    if not okTeams or teamsError == false then
      log(ERROR, "The team separator in trail briefings is off.")
      if not okTeams then log(WARNING, "the briefing's team separator: " .. tostring(teamsError)) end
    end

    detourSwitchToMenu()
    hookPlayerNaming()
    local _, installed = scenario.enable(function(trailName) return REGISTRY[trailName] end)
    startInstalled = installed
    unitlimits.enable()
  end,
  disable = function(self, config) end,
  getTrailProgress = function(self, trail)
    local progressAddr = TRAIL_PROGRESS_ADDRESSES[trail]

    if progressAddr == nil then
      error(string.format("no such trail: %s", trail))
    end
    
    return core.readInteger(progressAddr)
  end,
  setTrailProgress = function(self, trail, progress)
    local progressAddr = TRAIL_PROGRESS_ADDRESSES[trail]

    if progressAddr == nil then
      error(string.format("no such trail: %s", trail))
    end
    
    core.writeInteger(progressAddr, progress)
  end,
  ---A plugin gives mission `mission` (1, 2, ..., or a node id of a route of mission files) of a
  ---trail ("First", "Warchest" or "Extreme") another map file, for example the map in the language
  ---a player chose. Call it while extensions are enabled; it applies when the trail's missions are
  ---loaded.
  setMissionMap = function(self, trailType, mission, mapName)
    local trailName = settingsModule.TRAIL_TYPES[trailType]
    if trailName == nil then
      error(string.format("no such trail: %s", tostring(trailType)))
    end
    local index = type(mission) == "string" and mission ~= "" and mission or math.tointeger(mission)
    if index == nil or (type(index) == "number" and index < 1) or type(mapName) ~= "string" or mapName == "" then
      error("setMissionMap: a mission number or node id and a map name are needed")
    end
    MAP_OVERRIDES[trailName] = MAP_OVERRIDES[trailName] or {}
    MAP_OVERRIDES[trailName][index] = mapName
  end,
  setText = function(self, line, text)
    description.setText(line, text)
  end,
  getStartGood = function(self, good)
    return start_goods.getStartGood(good)
  end,
  setStartGood = function(self, good, value)
    start_goods.setStartGood(good, value)
  end,
  getTradeable = function(self, resource)
    return tradeability.getTradeable(resource)
  end,
  setTradeable = function(self, resource, tradeable)
    tradeability.setTradeable(resource, tradeable)
  end,
  setProducible = function(self, weapon, producible)
    producibility.setWeaponProducible(weapon, producible)
  end,
  getRecruitable = function(self, unit)
    return recruitability.getUnitRecruitable(unit)
  end,
  setRecruitable = function(self, unit, value)
    recruitability.setUnitRecruitable(unit, value)
  end,
  getTextDescription = function(self, index)
    return description.getText(index)
  end,
  setTextDescription = function(self, index, value)
    return description.setText(index, value)
  end,
},
{
  public = {
    "setTrailProgress",
    "setMissionMap",
    "setText",
    "setTradeable",
    "setProducible",
  }
}
