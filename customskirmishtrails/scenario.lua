-- Scenario missions: a trail mission with mission_kind "scenario" plays a custom scenario map
-- (map type 0, for example an Invasion map made in the editor or saved from a game). It starts
-- the way Custom Scenarios -> Play a Map starts a map, so the map's events, goals, invasions,
-- placed units and AI lords run as they do from Play a Map; an Invasion map opens the game's own
-- briefing. keep_start_army skips Play a Map's starting-army cut for one mission. A win of the
-- scenario the trail started is handed to the game's own trail code on the mission finished
-- screen, which advances the trail and returns to the trail map.
--
-- The trail's Start records which mission it started (the session): its trail, number and map.
-- The session holds while that map is played in this run of the game, through Restart and loaded
-- saves of it; the next trail Start, opening the Play a Map list or loading a save of another map
-- ends it. A save of another game on the same map, loaded while the session holds, counts as the
-- session's mission.
--
-- Every game site is found by an AOB that matches once in Stronghold Crusader.exe and
-- Stronghold_Crusader_Extreme.exe 1.41, with the same layout in both. If one is missing, found
-- twice or has unexpected bytes, scenario missions are switched off and start nothing.

local patches = require("customskirmishtrails.patches")
local memory = require("customskirmishtrails.memory")
local unitlimits = require("customskirmishtrails.unitlimits")

local scenario = {}

-- addresses only
local SCANS = {
  -- the Play a Map launcher (cdecl, one int): any value but 0 loads the map named in the chosen
  -- map name, and every value but 1 opens the briefing afterwards for an Invasion map
  launcher = "81 EC E8 07 00 00 A1 ? ? ? ? 33 C4 89 84 24 E4 07 00 00 53 55 56 8B 35 ? ? ? ? 57 BF 01 00 00 00 6A 04 B9",
  -- the Custom Scenarios menu's click handler (cdecl, one int); 4 is Play a Map
  customScenarios = "8B 44 24 04 83 C0 FF 83 F8 04 0F 87 ? ? ? ? FF 24 85 ? ? ? ? 6A 09 B9",
  -- Play a Map's starting-army cut: "cmp eax, 3 / jne / cmp [difficulty], ebx / je skip / call
  -- mapHasCertainEvent". Unless the difficulty is the lowest or the map has an invasion event,
  -- it deletes every 4th (Normal) of the human player's military units until about a quarter of
  -- their troop value is gone.
  armyCut = "83 F8 03 0F 85 ? ? ? ? 39 1D ? ? ? ? 0F 84 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 85 C0 0F 85",
  -- the Load Game button's read of the save: "push / mov ecx / mov [callback], / call read"; after
  -- it (SAVE_LOADED_OFFSET) the chosen map holds the save's map name
  saveRead = "68 ? ? ? ? B9 ? ? ? ? C7 05 ? ? ? ? ? ? ? ? E8 ? ? ? ? B9 ? ? ? ? 89 2D ? ? ? ? 89 1D ? ? ? ? 89 1D",
}
-- with operands
local EXTRACTS = {
  -- inside Custom Scenarios' Play a Map case: "mov byte [chosenMap], 0" and "mov [difficulty], eax"
  playAMap = "C7 05 ? ? ? ? 03 00 00 00 89 35 ? ? ? ? C6 05 I(? ? ? ?) 00 A3 I(? ? ? ?)",
  -- the Play a Map list's Prepare, opened from the menu: single-player game mode, host, the
  -- human player's slot and the lobby's map fields
  listPrepare = "53 33 DB 83 C8 FF 39 1D ? ? ? ? 89 1D ? ? ? ? 89 1D ? ? ? ? A3 ? ? ? ? 89 1D I(? ? ? ?)"
    .. " C7 05 ? ? ? ? 02 00 00 00 74 61 68 80 38 01 00 53 68 ? ? ? ? 89 1D ? ? ? ?"
    .. " C7 05 I(? ? ? ?) 01 00 00 00 C7 05 I(? ? ? ?) 01 00 00 00 89 1D I(? ? ? ?) A3 I(? ? ? ?)"
    .. " A3 ? ? ? ? 88 1D I(? ? ? ?)",
  -- the Play a Map list's render, once it has faded out after the launcher: "mov [menuSwitchDelay], 0"
  listFaded = "C7 05 ? ? ? ? 20 00 00 00 89 1D I(? ? ? ?) 39 1D ? ? ? ? 0F 84",
}

local ARMY_CUT_JE_OFFSET = 0x0F
local SAVE_LOADED_OFFSET = 0x19

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
local MAX_PLAYERS = 8
-- The game resolves "maps\<name>.map" and "<Documents>\Stronghold Crusader\Maps\<name>.map"
-- into 1001-byte path buffers, so names stay well below that.
local MAX_MAP_NAME = 200
local NAME_BUFFER = MAX_MAP_NAME + 1

local bindings = nil
local trailOf = nil -- function(trailName) -> missions of that trail, set by enable
local active = nil  -- the session: { trailName, index, entry, fileName }

local function asciiLower(text)
  return (text:gsub("[A-Z]", string.lower))
end

---The file name of a scenario map as the game's file functions spell it, or nil and a reason.
---Map files in the game's folders have Windows code page names; a UTF-8 name from a csv,
---mission or plugin file is written in its Latin-1 form, the same rule the files module uses for
---availability.json. A trailing ".map" is dropped, because the launcher adds it.
function scenario.mapFileName(name)
  if type(name) ~= "string" then
    return nil, "no map name"
  end
  if name:lower():sub(-4) == ".map" then
    name = name:sub(1, -5)
  end
  if name == "" or name:find("[%c/\\:*?\"<>|]") then
    return nil, "not a map file name"
  end
  if name:find("[\128-\255]") and utf8 ~= nil and utf8.len(name) ~= nil then
    local bytes = {}
    for _, codepoint in utf8.codes(name) do
      if codepoint > 255 then
        return nil, "letters outside Latin-1"
      end
      bytes[#bytes + 1] = string.char(codepoint)
    end
    name = table.concat(bytes)
  end
  if #name > MAX_MAP_NAME then
    return nil, string.format("longer than %d bytes", MAX_MAP_NAME)
  end
  return name
end

---The mission kind ("skirmish" when empty), or nil for a kind this version doesn't know.
function scenario.kind(entry)
  local kind = type(entry) == "table" and entry.mission_kind or nil
  if kind == nil or kind == "" then
    return "skirmish"
  end
  kind = type(kind) == "string" and asciiLower(kind:match("^%s*(.-)%s*$")) or nil
  if kind == "skirmish" or kind == "scenario" then
    return kind
  end
  return nil
end

---True when `entry` is a scenario mission.
function scenario.isScenario(entry)
  return scenario.kind(entry) == "scenario"
end

---Whether a scenario mission's map can be played today, and the date it opens when it is dated
---in an availability.json of the files module. Dates come with files 1.5.0
---(getMapAvailability); without that function no map is dated. A failing lookup counts as not
---open yet.
function scenario.availability(entry)
  local files = modules.files
  if files == nil or files.getMapAvailability == nil then
    return true, nil
  end
  local ok, result = pcall(function() return files:getMapAvailability(entry.map_name, "crusader") end)
  if not ok or type(result) ~= "table" or type(result.available) ~= "boolean" then
    log(WARNING, string.format("custom-skirmish-trails: map availability of %s: %s", tostring(entry.map_name),
      tostring(ok and "no answer" or result)))
    return false, nil
  end
  return result.available, result.from
end

---The address of `aob` (found at `found`), or nil when it is not unique in the game's code.
local function unique(name, aob, found)
  local ok, reason = patches.isUnique(aob, found)
  if not ok then
    log(WARNING, string.format("custom-skirmish-trails: %s %s; scenario missions are switched off", name, reason))
    return nil
  end
  return found
end

local function resolve()
  local found = {}
  for name, aob in pairs(SCANS) do
    local ok, address = pcall(core.AOBScan, aob)
    if not ok or address == nil or unique(name, aob, address) == nil then
      log(WARNING, string.format("custom-skirmish-trails: could not bind %s; scenario missions are switched off", name))
      return nil
    end
    found[name] = { address = address }
  end
  for name, aob in pairs(EXTRACTS) do
    local ok, address, a, b, c, d, e, f = pcall(utils.AOBExtract, aob)
    if not ok or address == nil or unique(name, aob, address) == nil then
      log(WARNING, string.format("custom-skirmish-trails: could not bind %s; scenario missions are switched off", name))
      return nil
    end
    found[name] = { address = address, a, b, c, d, e, f }
  end
  local branch = patches.siteAddress(WIN_BRANCH_SITE, "the mission finished screen")
  local syncModeSite = patches.siteAddress(WIN_SYNC_MODE_SITE, "the mission finished screen")
  local winnersSite = patches.siteAddress(WIN_WINNERS_SITE, "the mission finished screen")
  local jeSite = found.armyCut.address + ARMY_CUT_JE_OFFSET
  if branch == nil or syncModeSite == nil or winnersSite == nil or not patches.matches(jeSite, "0F 84 ? ? ? ?") then
    log(WARNING, "custom-skirmish-trails: unexpected game code; scenario missions are switched off")
    return nil
  end
  local list = found.listPrepare
  -- the list and the mission finished screen must name the same game mode and human slot
  if core.readInteger(syncModeSite + 1) ~= list[1] or core.readInteger(winnersSite + 1) ~= list[3] then
    log(WARNING, "custom-skirmish-trails: the game's mode and player slot don't match; scenario missions are switched off")
    return nil
  end
  return {
    launcher = core.exposeCode(found.launcher.address, 1, 0),
    customScenarios = core.exposeCode(found.customScenarios.address, 1, 0),
    listPrepare = list.address,
    saveLoaded = found.saveRead.address + SAVE_LOADED_OFFSET,
    chosenMap = found.playAMap[1],
    difficulty = found.playAMap[2],
    syncMode = list[1],
    isHost = list[2],
    humanSlot = list[3],
    inGame = list[4],
    lobbyMission = list[5],
    lobbyMapName = list[6],
    menuSwitchDelay = found.listFaded[1],
    gameMode = core.readInteger(branch + 1),
    winnersBranch = branch,
    winners = core.readInteger(winnersSite + 9),
    armyCutJe = jeSite,
    armyCutSkip = jeSite + 6 + core.readInteger(jeSite + 2),
  }
end

---A routine (call, no arguments) that sets ZF when the chosen map is the session's map; it keeps
---every register.
local function installSameMap(b)
  local code = {
    0x50,                                    -- push eax
    0x56,                                    -- push esi
    0x57,                                    -- push edi
    0xBE, core.itob(b.trailMap),             -- mov esi, trailMap
    0xBF, core.itob(b.chosenMap),            -- mov edi, chosenMap
    "compare",
    0x8A, 0x06,                              -- mov al, [esi]
    0x3A, 0x07,                              -- cmp al, [edi]
    0x0F, 0x85, core.relTo("done", -4),      -- jne done (ZF clear)
    0x46,                                    -- inc esi
    0x47,                                    -- inc edi
    0x84, 0xC0,                              -- test al, al
    0x0F, 0x85, core.relTo("compare", -4),   -- jnz compare (at the end ZF is set)
    "done",
    0x5F,                                    -- pop edi
    0x5E,                                    -- pop esi
    0x58,                                    -- pop eax
    0xC3,                                    -- ret
  }
  b.sameMap = core.allocateCode(core.calculateCodeSize(code))
  core.writeCode(b.sameMap, code)
end

---Starting-army cut: a Play a Map start skips it when it loads the session's map and the
---session's mission has keep_start_army (Restart of it too).
local function installArmyCutSkip(b)
  local skip = b.armyCutSkip
  core.insertCode(b.armyCutJe, 6, {
    core.jeTo(skip),
    0x80, 0x3D, core.itob(b.keepArmy), 0x00, -- cmp byte [keepArmy], 0
    0x0F, 0x84, core.relTo("cut", -4),       -- je cut
    core.callTo(b.sameMap),
    0x0F, 0x85, core.relTo("cut", -4),       -- jne cut
    core.jmpTo(skip),
    "cut",
  })
end

local function writeName(address, name)
  core.writeString(address, name)
  core.writeByte(address + #name, 0)
end

---True when the mission keeps the player's whole starting army (keep_start_army 1).
local function keepsStartArmy(entry)
  local value = entry.keep_start_army
  return value == 1 or value == true or value == "1"
end

---The session, or nil when there is none or the Play a Map list ended it.
local function session()
  if active ~= nil and core.readByte(bindings.trailMap) ~= 0 then
    return active
  end
  return nil
end

---Makes `trailName` mission `index` (a scenario mission playing `fileName`) the session, or ends
---the session (no arguments).
local function setSession(trailName, index, entry, fileName)
  local b = bindings
  active = trailName and { trailName = trailName, index = index, entry = entry, fileName = fileName } or nil
  writeName(b.trailMap, active and fileName or "")
  core.writeByte(b.keepArmy, active and keepsStartArmy(entry) and 1 or 0)
  core.writeByte(b.cap, active and unitlimits.policy(entry) ~= nil and 1 or 0)
end

---Starts `trailName` mission `index` (a scenario mission playing `fileName`) as Play a Map does:
---the Custom Scenarios handler's Play a Map case (it asks for the Play a Map list, which the
---launcher's next screen replaces), what the list sets when it opens, the session, the chosen
---map, Normal difficulty, the launcher, and what the list does once it has faded out: the
---launcher's next screen opens now.
local function start(trailName, index, entry, fileName)
  local b = bindings
  b.customScenarios(PLAY_A_MAP)
  setSession(trailName, index, entry, fileName)
  core.writeInteger(b.syncMode, SYNC_MODE_SINGLE_PLAYER)
  core.writeInteger(b.isHost, 1)
  core.writeInteger(b.humanSlot, 1)
  core.writeInteger(b.inGame, 0)
  core.writeInteger(b.lobbyMission, -1)
  core.writeByte(b.lobbyMapName, 0)
  core.writeInteger(memory.IS_SKIRMISH_TRAIL, 0)
  writeName(b.chosenMap, fileName)
  core.writeInteger(b.difficulty, DIFFICULTY_NORMAL)
  b.launcher(LAUNCH_WITH_BRIEFING)
  core.writeInteger(b.menuSwitchDelay, 0)
end

---The trail and mission of a won scenario: the session's. The game empties the chosen map
---before the mission finished screen; a name still there must be the session's map.
local function wonMission()
  local current = session()
  if current == nil then
    return nil
  end
  local chosen = core.readString(bindings.chosenMap) or ""
  if chosen ~= "" and chosen ~= current.fileName then
    return nil
  end
  return current.trailName, current.index
end

local TRAIL_INDEX = {}
for index, name in pairs(memory.TRAIL_TYPES) do
  TRAIL_INDEX[name] = index
end

---On the mission finished screen of a scenario (it opens only for a victory): a won trail mission
---takes the game's own trail branch, which credits the trail's selected mission, advances the
---trail and opens the trail map. That branch counts a win only when the human player's winner
---flag is set, which skirmish games set and scenarios don't, so it is set here, and the won
---mission is selected.
local function installWinHandover(b)
  core.detourCode(function(registers)
    if bindings == nil or core.readInteger(b.gameMode) ~= GAME_MODE_SCENARIO then
      return registers
    end
    local slot = core.readInteger(b.humanSlot)
    if slot < 1 or slot > MAX_PLAYERS then
      return registers
    end
    local trailName, mission = wonMission()
    if trailName == nil then
      return registers
    end
    log(INFO, string.format("custom-skirmish-trails: %s mission %d won", trailName, mission))
    core.writeInteger(memory.CURRENT_TRAIL_TYPE, TRAIL_INDEX[trailName])
    core.writeInteger(memory.TRAIL_PROGRESS_ADDRESSES[trailName], mission - 1)
    core.writeInteger(memory.IS_SKIRMISH_TRAIL, 1)
    core.writeInteger(b.syncMode, SYNC_MODE_SKIRMISH)
    core.writeSmallInteger(b.winners + 2 * slot, 1)
    core.writeInteger(b.gameMode, GAME_MODE_SKIRMISH)
    return registers
  end, b.winnersBranch, 5)
end

---Opening the Play a Map list ends the session, and so does loading a save of another map.
local function installSessionEnd(b)
  local function clear()
    return {
      0xC6, 0x05, core.itob(b.trailMap), 0x00, -- mov byte [trailMap], 0
      0xC6, 0x05, core.itob(b.keepArmy), 0x00, -- mov byte [keepArmy], 0
      0xC6, 0x05, core.itob(b.cap), 0x00,      -- mov byte [cap], 0
    }
  end
  core.insertCode(b.listPrepare, 6, clear(), nil, "after")
  core.insertCode(b.saveLoaded, 5, {
    core.callTo(b.sameMap),
    0x0F, 0x84, core.relTo("keep", -4),      -- je keep
    clear(),
    "keep",
  }, nil, "after")
end

---Starts `entry` (`trailName` mission `index`) when it is a scenario mission. Returns true when
---the trail's own skirmish setup must not run: the scenario started, or it can't start (switched
---off, invalid map name, not open yet, troop limit unavailable).
function scenario.startIfScenario(trailName, index, entry)
  local kind = scenario.kind(entry)
  if kind == "skirmish" then
    if not unitlimits.available(entry, false) then
      log(WARNING, string.format("custom-skirmish-trails: %s has a unit_limit, and the troop limit is switched off; "
        .. "the mission doesn't start", tostring(entry.map_name)))
      return true
    end
    return false
  end
  if kind == nil then
    log(WARNING, string.format("custom-skirmish-trails: %s: unknown mission_kind '%s'; the mission doesn't start",
      tostring(entry.map_name), tostring(entry.mission_kind)))
    return true
  end
  if bindings == nil then
    log(WARNING, string.format("custom-skirmish-trails: %s is a scenario mission, and scenario missions are switched off",
      tostring(entry.map_name)))
    return true
  end
  local fileName, reason = scenario.mapFileName(entry.map_name)
  if fileName == nil then
    log(WARNING, string.format("custom-skirmish-trails: scenario map '%s': %s; the mission doesn't start",
      tostring(entry.map_name), reason))
    return true
  end
  local available, from = scenario.availability(entry)
  if not available then
    log(INFO, string.format("custom-skirmish-trails: %s opens on %s", fileName, tostring(from)))
    return true
  end
  if not unitlimits.available(entry, true) then
    log(WARNING, string.format("custom-skirmish-trails: %s has a unit_limit, and the troop limit of scenario missions "
      .. "is switched off; the mission doesn't start", fileName))
    return true
  end
  start(trailName, index, entry, fileName)
  return true
end

---The mission as its briefing shows it: a scenario mission that isn't open yet shows
---`lockedText` ({date} becomes the date it opens) instead of its description. Asking files also
---gives a dated map that is due its file redirect, which the trail's Start needs to find the map.
function scenario.briefingEntry(entry, lockedText)
  if not scenario.isScenario(entry) then
    return entry
  end
  local available, from = scenario.availability(entry)
  if available or type(lockedText) ~= "string" then
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
    if active ~= nil then
      setSession()
    end
    local ok, handled = pcall(scenario.startIfScenario, trailName, index + 1, entry)
    if not ok then
      log(WARNING, "custom-skirmish-trails: starting a scenario mission failed: " .. tostring(handled))
      if bindings ~= nil then setSession() end
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
---Returns true when they can be played.
function scenario.enable(missionsOf)
  trailOf = missionsOf
  -- without the Start hook a scenario mission would run the skirmish setup on its map
  if not installStartHook() then
    log(WARNING, "custom-skirmish-trails: unexpected game code at the trail's Start; scenario missions run as skirmishes")
    return false
  end
  local ok, result = pcall(resolve)
  if not ok or result == nil then
    if not ok then
      log(WARNING, "custom-skirmish-trails: scenario missions are switched off: " .. tostring(result))
    end
    return false
  end
  result.trailMap = core.allocate(NAME_BUFFER, true)
  result.keepArmy = core.allocate(1, true)
  result.cap = core.allocate(1, true)
  local sites = {
    { address = result.armyCutJe, size = 6 },
    { address = result.listPrepare, size = 6 },
    { address = result.saveLoaded, size = 5 },
    { address = result.winnersBranch, size = 5 },
  }
  local installed, err = pcall(patches.guarded, sites, function()
    installSameMap(result)
    installArmyCutSkip(result)
    installSessionEnd(result)
    installWinHandover(result)
  end)
  if not installed then
    log(WARNING, "custom-skirmish-trails: scenario missions are switched off: " .. tostring(err))
    return false
  end
  bindings = result
  return true
end

---The session for the troop limit, or nil when scenario missions are switched off: the addresses
---of the routine "the chosen map is the session's" (sameMap), the game mode and the flag "the
---session's mission has a troop limit", and entry() for the session's mission.
function scenario.session()
  if bindings == nil then
    return nil
  end
  return {
    sameMap = bindings.sameMap,
    gameMode = bindings.gameMode,
    cap = bindings.cap,
    entry = function()
      local current = session()
      return current and current.entry or nil
    end,
  }
end

return scenario
