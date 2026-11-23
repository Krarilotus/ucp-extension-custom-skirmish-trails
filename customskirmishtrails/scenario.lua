-- Scenario missions: a trail mission with mission_kind "scenario" plays a custom scenario map
-- (map type 0, for example an Invasion map made in the editor or saved from a game). It starts
-- the way Custom Scenarios -> Play a Map starts a map, so the map's events, goals, invasions,
-- placed units and AI lords run as the map has them; an Invasion map opens the game's own
-- briefing. A win of the trail's selected mission is handed to the game's own trail code on the
-- mission finished screen, which advances the trail and returns to the trail map.
--
-- Every game site is found by an AOB that matches once in Stronghold Crusader.exe and
-- Stronghold_Crusader_Extreme.exe 1.41, with the same layout in both. If one is missing, found
-- twice or has unexpected bytes, scenario missions are switched off and start nothing.

local patches = require("customskirmishtrails.patches")
local memory = require("customskirmishtrails.memory")

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
local MAX_PLAYERS = 8
-- The game resolves "maps\<name>.map" and "<Documents>\Stronghold Crusader\Maps\<name>.map"
-- into 1001-byte path buffers, so names stay well below that.
local MAX_MAP_NAME = 200
local NAME_BUFFER = MAX_MAP_NAME + 1

local bindings = nil
local trailOf = nil -- function(trailName) -> missions of that trail, set by enable

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
  local ok, available, from = pcall(function() return files:getMapAvailability(entry.map_name, "crusader") end)
  if not ok or type(available) ~= "boolean" then
    log(WARNING, string.format("custom-skirmish-trails: map availability of %s: %s", tostring(entry.map_name),
      tostring(ok and "no answer" or available)))
    return false, nil
  end
  return available, from
end

local function readOperand(site, offset)
  return core.readInteger(site + offset)
end

local IMAGE_ALIGNMENT = 0x10000 -- Windows maps images on 64 KB boundaries
local MAX_IMAGE_STEPS = 0x200   -- 32 MB, far more than the game's image

---The bounds of the executable section that `address` lies in, read from the PE headers of its
---image (found by walking back to the "MZ" header), or nil.
local function sectionOf(address)
  local base = address - address % IMAGE_ALIGNMENT
  for _ = 1, MAX_IMAGE_STEPS do
    if core.readSmallInteger(base) & 0xFFFF == 0x5A4D then
      local nt = base + core.readInteger(base + 0x3C)
      if core.readInteger(nt) ~= 0x4550 then
        return nil
      end
      local count = core.readSmallInteger(nt + 6) & 0xFFFF
      local first = nt + 24 + (core.readSmallInteger(nt + 20) & 0xFFFF)
      for index = 0, count - 1 do
        local header = first + 40 * index
        local start = base + core.readInteger(header + 12)
        local finish = start + core.readInteger(header + 8)
        if address >= start and address < finish then
          return start, finish
        end
      end
      return nil
    end
    base = base - IMAGE_ALIGNMENT
  end
  return nil
end

---The address of `aob` (found at `found`), or nil when the game's code has it a second time.
local function unique(name, aob, found)
  local _, finish = sectionOf(found)
  if finish == nil then
    log(WARNING, string.format("custom-skirmish-trails: %s is not in the game's code; scenario missions are switched off", name))
    return nil
  end
  local plain = aob:gsub("I%(", ""):gsub("%)", "")
  local again = found + 1 < finish and core.scanForAOB(plain, found + 1, finish) or 0
  if again ~= nil and again ~= 0 then
    log(WARNING, string.format("custom-skirmish-trails: %s found twice; scenario missions are switched off", name))
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
  if readOperand(syncModeSite, 1) ~= list[1] or readOperand(winnersSite, 1) ~= list[3] then
    log(WARNING, "custom-skirmish-trails: the game's mode and player slot don't match; scenario missions are switched off")
    return nil
  end
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
    gameMode = readOperand(branch, 1),
    winnersBranch = branch,
    winners = readOperand(winnersSite, 9),
    armyCutJe = jeSite,
    armyCutSkip = jeSite + 6 + core.readInteger(jeSite + 2),
  }
end

---Starting-army cut: a Play a Map start skips it when the map it loads is the scenario the trail
---started last (Restart of it too). The trail's start writes that name; opening the Play a Map
---list clears it, so starts from the list and loads of other maps stay as they are.
local function installArmyCutSkip(b)
  b.trailMap = core.allocate(NAME_BUFFER, true)
  local skip = b.armyCutSkip
  core.insertCode(b.armyCutJe, 6, {
    core.jeTo(skip),
    0x56,                                    -- push esi
    0x57,                                    -- push edi
    0xBE, core.itob(b.trailMap),             -- mov esi, trailMap
    0xBF, core.itob(b.chosenMap),            -- mov edi, chosenMap
    0x80, 0x3E, 0x00,                        -- cmp byte [esi], 0
    0x0F, 0x84, core.relTo("cut", -4),       -- je cut (no trail scenario)
    "compare",
    0x8A, 0x06,                              -- mov al, [esi]
    0x3A, 0x07,                              -- cmp al, [edi]
    0x0F, 0x85, core.relTo("cut", -4),       -- jne cut
    0x46,                                    -- inc esi
    0x47,                                    -- inc edi
    0x84, 0xC0,                              -- test al, al
    0x0F, 0x85, core.relTo("compare", -4),   -- jnz compare
    0x5F,                                    -- pop edi
    0x5E,                                    -- pop esi
    core.jmpTo(skip),
    "cut",
    0x5F,                                    -- pop edi
    0x5E,                                    -- pop esi
  })
  core.insertCode(b.listPrepare, 6, {
    0xC6, 0x05, core.itob(b.trailMap), 0x00, -- mov byte [trailMap], 0
  }, nil, "after")
end

local function writeName(address, name)
  core.writeString(address, name)
  core.writeByte(address + #name, 0)
end

---Starts a scenario mission as Play a Map does: the Custom Scenarios handler's Play a Map case,
---what the list sets when it opens, the chosen map, Normal difficulty, the launcher.
local function start(fileName)
  local b = bindings
  b.customScenarios(PLAY_A_MAP)
  core.writeInteger(b.syncMode, SYNC_MODE_SINGLE_PLAYER)
  core.writeInteger(b.isHost, 1)
  core.writeInteger(b.humanSlot, 1)
  core.writeInteger(b.inGame, 0)
  core.writeInteger(b.lobbyMission, -1)
  core.writeByte(b.lobbyMapName, 0)
  core.writeInteger(memory.IS_SKIRMISH_TRAIL, 0)
  writeName(b.chosenMap, fileName)
  writeName(b.trailMap, fileName)
  core.writeInteger(b.difficulty, DIFFICULTY_NORMAL)
  b.launcher(LAUNCH_WITH_BRIEFING)
end

---The trail and mission of a won scenario: the trail mission that is selected in its trail and
---plays the map the game keeps for Restart. That name is also in saved games, so a door saved and
---loaded later counts as well, and so does a win of the same map started from Play a Map. The
---current trail is asked first.
local function wonMission()
  local chosen = asciiLower(core.readString(bindings.chosenMap) or "")
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
      local fileName = scenario.isScenario(entry) and scenario.mapFileName(entry.map_name) or nil
      if fileName ~= nil and asciiLower(fileName) == chosen then
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

---On the mission finished screen of a scenario (it opens only for a victory): a won trail mission
---takes the game's own trail branch, which advances the trail and opens the trail map. That
---branch counts a win only when the human player's winner flag is set, which skirmish games set
---and scenarios don't, so it is set here.
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
    core.writeInteger(memory.IS_SKIRMISH_TRAIL, 1)
    core.writeInteger(b.syncMode, SYNC_MODE_SKIRMISH)
    core.writeSmallInteger(b.winners + 2 * slot, 1)
    core.writeInteger(b.gameMode, GAME_MODE_SKIRMISH)
    return registers
  end, b.winnersBranch, 5)
end

---Starts `entry` when it is a scenario mission. Returns true when the trail's own skirmish
---setup must not run: the scenario started, or it can't start (switched off, invalid map name,
---not open yet).
function scenario.startIfScenario(entry)
  local kind = scenario.kind(entry)
  if kind == "skirmish" then
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
  start(fileName)
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
  local installed, err = pcall(function()
    installArmyCutSkip(result)
    installWinHandover(result)
  end)
  if not installed then
    log(WARNING, "custom-skirmish-trails: scenario missions are switched off: " .. tostring(err))
    return false
  end
  bindings = result
  return true
end

return scenario
