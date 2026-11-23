-- Scenario missions: a trail mission with mission_kind "scenario" plays a custom scenario map
-- (map type 0, for example an Invasion map made in the editor or saved from a game). It starts
-- the way Custom Scenarios -> Play a Map starts a map, so the map's events, goals, invasions,
-- placed units and AI lords run as the map has them, and the game shows its own briefing.
-- A win of the trail's selected mission is handed to the game's own trail code on the mission
-- finished screen, which advances the trail and returns to the trail map.
--
-- Every game site is found by an AOB that is unique in Stronghold Crusader.exe and
-- Stronghold_Crusader_Extreme.exe 1.41, with the same layout in both. If one cannot be found or
-- its bytes are not the expected ones, scenario missions are switched off and start nothing.

local patches = require("customskirmishtrails.patches")
local memory = require("customskirmishtrails.memory")

local scenario = {}

local AOBS = {
  -- the Play a Map launcher (cdecl, one int): any value but 0 loads the map named in the chosen
  -- map name, and every value but 1 opens the briefing afterwards for an Invasion map
  launcher = "81 EC E8 07 00 00 A1 ? ? ? ? 33 C4 89 84 24 E4 07 00 00 53 55 56 8B 35 ? ? ? ? 57 BF 01 00 00 00 6A 04 B9",
  -- the Custom Scenarios menu's click handler (cdecl, one int); 4 is Play a Map
  customScenarios = "8B 44 24 04 83 C0 FF 83 F8 04 0F 87 ? ? ? ? FF 24 85 ? ? ? ? 6A 09 B9",
  -- inside its Play a Map case: "mov byte [chosenMap], 0" and "mov [difficulty], eax"
  playAMap = "C7 05 ? ? ? ? 03 00 00 00 89 35 ? ? ? ? C6 05 I(? ? ? ?) 00 A3 I(? ? ? ?)",
  -- the Play a Map list's Prepare, opened from the menu: single-player game mode, host, the
  -- human player's slot and the lobby's map fields
  listPrepare = "53 33 DB 83 C8 FF 39 1D ? ? ? ? 89 1D ? ? ? ? 89 1D ? ? ? ? A3 ? ? ? ? 89 1D I(? ? ? ?)"
    .. " C7 05 ? ? ? ? 02 00 00 00 74 61 68 80 38 01 00 53 68 ? ? ? ? 89 1D ? ? ? ?"
    .. " C7 05 I(? ? ? ?) 01 00 00 00 C7 05 I(? ? ? ?) 01 00 00 00 89 1D I(? ? ? ?) A3 I(? ? ? ?)"
    .. " A3 ? ? ? ? 88 1D I(? ? ? ?)",
  -- Play a Map's starting-army cut: "cmp eax, 3 / jne / cmp [difficulty], ebx / je skip / call
  -- mapHasCertainEvent". Unless the difficulty is the lowest or the map has an invasion event,
  -- it deletes every 4th (Normal) of the human player's military units until about a quarter of
  -- their troop value is gone.
  armyCut = "83 F8 03 0F 85 ? ? ? ? 39 1D ? ? ? ? 0F 84 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 85 C0 0F 85",
}

local ARMY_CUT_JE_OFFSET = 0x0F

-- In the mission finished screen ("win" in patches.lua): the branch that picks the follow-up by
-- game mode, and the values the game's trail branch reads.
local WIN_BRANCH_SITE = { fn = "win", offset = 0xEF, bytes = "A1 ? ? ? ? 3B C7 0F 85" }   -- mov eax, [gameMode]
local WIN_SYNC_MODE_SITE = { fn = "win", offset = 0xFC, bytes = "A1 ? ? ? ? 83 F8 63 0F 85" } -- mov eax, [syncMode]; cmp eax, 99
local WIN_WINNERS_SITE = { fn = "win", offset = 0x1B0, bytes = "A1 ? ? ? ? 66 39 2C 45 ? ? ? ?" } -- mov eax, [humanSlot]; cmp word [eax*2 + winners], bp

local GAME_MODE_SCENARIO = 2 -- custom scenario (Play a Map)
local GAME_MODE_SKIRMISH = 3
local SYNC_MODE_SINGLE_PLAYER = 0
local SYNC_MODE_SKIRMISH = 99
local PLAY_A_MAP = 4
local LAUNCH_WITH_BRIEFING = 2
local DIFFICULTY_NORMAL = 1
local MAP_NAME_SIZE = 1000 -- the chosen map name's buffer holds 1001 bytes

local bindings = nil
local trailOf = nil -- function(trailName) -> missions of that trail, set by enable

---The map name as the game spells it: UTF-8 names (from csv or JSON files) in the game's code
---page, through textResourceModifier. Names already in the code page stay as they are.
local function gameSpelling(name)
  if type(name) ~= "string" or not name:find("[\128-\255]") or (utf8 ~= nil and utf8.len(name) == nil) then
    return name
  end
  local texts = modules.textResourceModifier
  if texts ~= nil and texts.TransformText ~= nil then
    local ok, transformed = pcall(function() return texts:TransformText(name) end)
    if ok and type(transformed) == "string" then
      return transformed
    end
  end
  return name
end

scenario.gameSpelling = gameSpelling

local function asciiLower(text)
  return (text:gsub("[A-Z]", string.lower))
end

local function mapKey(name)
  local key = asciiLower(gameSpelling(name) or "")
  if key:sub(-4) == ".map" then key = key:sub(1, -5) end
  return key
end

---True when `entry` is a scenario mission.
function scenario.isScenario(entry)
  return type(entry) == "table" and type(entry.mission_kind) == "string"
    and entry.mission_kind:lower() == "scenario"
end

---Whether a scenario mission's map can be played today, and the date it opens when it is dated
---in an availability.json of the files module. Without that files function every map counts as
---available.
function scenario.availability(entry)
  local files = modules.files
  if files == nil or files.getMapAvailability == nil or type(entry.map_name) ~= "string" then
    return true, nil
  end
  local ok, available, from = pcall(function() return files:getMapAvailability(entry.map_name, "crusader") end)
  if not ok then
    log(WARNING, "custom-skirmish-trails: map availability: " .. tostring(available))
    return true, nil
  end
  return available ~= false, from
end

local function readOperand(site, extra)
  return core.readInteger(site + (extra or 1))
end

local function resolve()
  local found = {}
  for name, aob in pairs(AOBS) do
    local ok, address, a, b, c, d, e, f, g = pcall(utils.AOBExtract, aob)
    if not ok or address == nil then
      log(WARNING, string.format("custom-skirmish-trails: could not find %s; scenario missions are switched off", name))
      return nil
    end
    found[name] = { address = address, a, b, c, d, e, f, g }
  end
  local branch = patches.siteAddress(WIN_BRANCH_SITE, "the mission finished screen")
  local syncMode = patches.siteAddress(WIN_SYNC_MODE_SITE, "the mission finished screen")
  local winners = patches.siteAddress(WIN_WINNERS_SITE, "the mission finished screen")
  if branch == nil or syncMode == nil or winners == nil then
    log(WARNING, "custom-skirmish-trails: scenario missions are switched off")
    return nil
  end
  local jeSite = found.armyCut.address + ARMY_CUT_JE_OFFSET
  if not patches.matches(jeSite, "0F 84 ? ? ? ?") then
    log(WARNING, "custom-skirmish-trails: unexpected game code at the starting-army cut; scenario missions are switched off")
    return nil
  end
  local list = found.listPrepare
  return {
    launcher = core.exposeCode(found.launcher.address, 1, 0),
    customScenarios = core.exposeCode(found.customScenarios.address, 1, 0),
    listPrepare = list.address,
    chosenMap = found.playAMap[1],
    difficulty = found.playAMap[2],
    syncMode = list[1],
    isHost = list[2],
    humanSlot = list[3],
    inGame = list[4],
    lobbyMission = list[5],
    lobbyMapName = list[6],
    gameMode = readOperand(branch),
    winnersBranch = branch,
    winners = readOperand(winners, 9),
    armyCutJe = jeSite,
    armyCutSkip = jeSite + 6 + core.readInteger(jeSite + 2),
  }
end

---Starting-army cut: Play a Map starts skip it while the flag is set. A start from the trail
---sets it; opening the Play a Map list clears it, so starts from the list stay as they are.
local function installArmyCutSkip(b)
  b.keepArmy = core.allocate(1, true)
  local skip = b.armyCutSkip
  core.insertCode(b.armyCutJe, 6, {
    core.jeTo(skip),
    0x80, 0x3D, core.itob(b.keepArmy), 0x00, -- cmp byte [keepArmy], 0
    0x0F, 0x85, core.relTo(skip, -4),        -- jne skip
  })
  core.insertCode(b.listPrepare, 6, {
    0xC6, 0x05, core.itob(b.keepArmy), 0x00, -- mov byte [keepArmy], 0
  }, nil, "after")
end

local function writeMapName(address, name)
  if #name > MAP_NAME_SIZE then
    error("map name too long: " .. name)
  end
  core.writeString(address, name)
  core.writeByte(address + #name, 0)
end

---Starts a scenario mission as Play a Map does: the Custom Scenarios handler's Play a Map case,
---what the list sets when it opens, the chosen map, Normal difficulty, the launcher.
local function start(entry)
  local b = bindings
  b.customScenarios(PLAY_A_MAP)
  core.writeInteger(b.syncMode, SYNC_MODE_SINGLE_PLAYER)
  core.writeInteger(b.isHost, 1)
  core.writeInteger(b.humanSlot, 1)
  core.writeInteger(b.inGame, 0)
  core.writeInteger(b.lobbyMission, -1)
  core.writeByte(b.lobbyMapName, 0)
  core.writeInteger(memory.IS_SKIRMISH_TRAIL, 0)
  writeMapName(b.chosenMap, gameSpelling(entry.map_name))
  core.writeInteger(b.difficulty, DIFFICULTY_NORMAL)
  core.writeByte(b.keepArmy, 1)
  b.launcher(LAUNCH_WITH_BRIEFING)
end

---The trail and mission whose selected mission is the scenario that was just won, found by the
---map name the game keeps for Restart (it survives saving and loading).
local function wonMission()
  local chosen = mapKey(core.readString(bindings.chosenMap))
  if chosen == "" then
    return nil
  end
  local current = memory.TRAIL_TYPES[core.readInteger(memory.CURRENT_TRAIL_TYPE)]
  local order = { current }
  for _, name in pairs(memory.TRAIL_TYPES) do
    if name ~= current then table.insert(order, name) end
  end
  for _, trailName in ipairs(order) do
    local missions = trailOf(trailName)
    if missions ~= nil then
      local progress = core.readInteger(memory.TRAIL_PROGRESS_ADDRESSES[trailName])
      local entry = missions[progress + 1]
      if scenario.isScenario(entry) and mapKey(entry.map_name) == chosen then
        return trailName, progress + 1
      end
    end
  end
  return nil
end

local TRAIL_INDEX = {}
for index, name in pairs(memory.TRAIL_TYPES) do
  TRAIL_INDEX[name] = index
end

---On the mission finished screen of a scenario: a won trail mission takes the game's own trail
---branch, which advances the trail and opens the trail map.
local function installWinHandover(b)
  core.detourCode(function(registers)
    if core.readInteger(b.gameMode) ~= GAME_MODE_SCENARIO then
      return registers
    end
    local trailName, mission = wonMission()
    if trailName == nil then
      return registers
    end
    log(INFO, string.format("custom-skirmish-trails: %s mission %d won", trailName, mission))
    core.writeInteger(memory.CURRENT_TRAIL_TYPE, TRAIL_INDEX[trailName])
    core.writeInteger(memory.IS_SKIRMISH_TRAIL, 1)
    core.writeInteger(b.syncMode, SYNC_MODE_SKIRMISH)
    local slot = core.readInteger(b.humanSlot)
    core.writeSmallInteger(b.winners + 2 * slot, 1)
    core.writeInteger(b.gameMode, GAME_MODE_SKIRMISH)
    return registers
  end, b.winnersBranch, 5)
end

---Starts `entry` when it is a scenario mission. Returns true when the trail's own skirmish
---setup must not run: the scenario started, or it can't start (switched off, not open yet).
function scenario.startIfScenario(entry)
  if not scenario.isScenario(entry) then
    return false
  end
  if bindings == nil then
    log(WARNING, string.format("custom-skirmish-trails: %s is a scenario mission, and scenario missions are switched off",
      tostring(entry.map_name)))
    return true
  end
  local available, from = scenario.availability(entry)
  if not available then
    log(INFO, string.format("custom-skirmish-trails: %s opens on %s", tostring(entry.map_name), tostring(from)))
    return true
  end
  start(entry)
  return true
end

---The mission as its briefing shows it: a scenario mission that isn't open yet shows
---`lockedText` ({date} becomes the date it opens) instead of its description.
function scenario.briefingEntry(entry, lockedText)
  if not scenario.isScenario(entry) or type(lockedText) ~= "string" then
    return entry
  end
  local available, from = scenario.availability(entry)
  if available then
    return entry
  end
  local shown = {}
  for key, value in pairs(entry) do
    shown[key] = value
  end
  local text = lockedText:gsub("{date}", function() return tostring(from or "") end)
  for line = 1, 8 do
    shown[string.format("text_description_line_%02d", line)] = line == 1 and text or ""
  end
  return shown
end

---The trail's Start (SetupSkirmishMode, cdecl, the selected mission's index): scenario missions
---start as above, every other mission runs the game's skirmish setup.
local function installStartHook()
  local setup = patches.functionAddress("setup")
  if setup == nil or not patches.matches(setup, "8B 44 24 04 8B 0D ? ? ? ?") then
    return false
  end
  local original
  original = core.hookCode(function(index)
    local trailName = memory.TRAIL_TYPES[core.readInteger(memory.CURRENT_TRAIL_TYPE)]
    local missions = trailName and trailOf(trailName) or nil
    local entry = missions and missions[index + 1] or nil
    local ok, handled = pcall(scenario.startIfScenario, entry)
    if not ok then
      log(WARNING, "custom-skirmish-trails: starting a scenario mission failed: " .. tostring(handled))
      return 0
    end
    if handled then
      return 0
    end
    return original(index)
  end, setup, 1, 0, 10)
  return true
end

---Installs scenario missions. `missionsOf(trailName)` gives a trail's missions (1-based).
---Returns true when they are available.
function scenario.enable(missionsOf)
  trailOf = missionsOf
  -- without the Start hook a scenario mission would run the skirmish setup on its map
  if not installStartHook() then
    log(WARNING, "custom-skirmish-trails: unexpected game code at the trail's Start; scenario missions are switched off")
    return false
  end
  local ok, result = pcall(resolve)
  if not ok or result == nil then
    if not ok then
      log(WARNING, "custom-skirmish-trails: scenario missions are switched off: " .. tostring(result))
    end
    return false
  end
  bindings = result
  installArmyCutSkip(bindings)
  installWinHandover(bindings)
  return true
end

return scenario
