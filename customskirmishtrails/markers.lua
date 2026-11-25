-- Door pictures on the trail screen: trail_visuals.trail_marker_sheet and the missions'
-- marker_locked / marker_available / marker_won. A mission with a marker shows its picture in
-- place of the game's flag: locked (its click is not taken) until the trail reaches it, its date
-- has come and its map is installed; available after that; a won mission draws its won picture
-- over it. The game's chicken stays. A mission of the trail's route (route.lua) that the game's
-- furthest mission doesn't describe (a side mission, a parallel path) is reached and won by the
-- route.
--
-- All sites lie in the trail screen's draw (render) and click functions, at the same offsets in
-- Stronghold Crusader.exe and Stronghold_Crusader_Extreme.exe.

local memory = require("customskirmishtrails.memory")
local patches = require("customskirmishtrails.patches")
local scenario = require("customskirmishtrails.scenario")
local winfiles = require("customskirmishtrails.winfiles")

local markers = {}

-- skirmish_trail_icons.gm1, the sheet the trail screen draws from; ReserveGm takes only a sheet
-- with as many pictures of its type
markers.PICTURES = 130
local STATES = { "locked", "available", "won" }
local SKIPPED = -1200 -- the score of a mission a chicken skipped

-- the markers' screen offsets are in ESI / EDI and the trail in EDX: test edx, edx / mov [esp+14h], 0
local RENDER_SITE = { fn = "render", offset = 0x125, bytes = "85 D2 C7 44 24 14 00 00 00 00" }
local RENDER_SIZE = 10
-- the Warchest's next-mission marker: push sheet / mov ecx, screen / call draw (thiscall: sheet, picture, x, y)
local DRAW_SITE = { fn = "render", offset = 0x88F, bytes = "68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ?" }

-- furthest: "cmp [furthest], ebp" before the marker loop. scores: "cmp [ebp*4 + scores], -1200".
-- hit: "mov [selected], edx" when a click hits a mission; miss: "add edx, ebp", the next mission.
-- bound: "mov ebx, [furthest]", the last mission the click loop tries.
-- flags: the calls that draw the game's markers: shadow, flag (or skipped), the next mission's
-- shadow and marker. A shadow draw takes one argument more.
local SITES = {
  firstEditionTrail = {
    furthest = { fn = "render", offset = 0x137, bytes = "39 2D ? ? ? ? 0F 8E" },
    scores = { fn = "render", offset = 0x1AC, bytes = "81 3C AD ? ? ? ? 50 FB FF FF" },
    hit = { fn = "click", offset = 0x22A, bytes = "89 15 ? ? ? ?" },
    miss = { fn = "click", offset = 0x21E, bytes = "03 D5 83 FA" },
    bound = { fn = "click", offset = 0x1E6, bytes = "8B 1D ? ? ? ? 33 D2" },
    flags = { 0x1F8, 0x2D9, 0x3C8, 0x3F3 },
  },
  warchestTrail = {
    furthest = { fn = "render", offset = 0x653, bytes = "39 2D ? ? ? ? 0F 8E" },
    scores = { fn = "render", offset = 0x6A5, bytes = "81 3C AD ? ? ? ? 50 FB FF FF" },
    hit = { fn = "click", offset = 0x27B, bytes = "89 15 ? ? ? ?" },
    miss = { fn = "click", offset = 0x26F, bytes = "03 D5 83 FA" },
    bound = { fn = "click", offset = 0x239, bytes = "8B 1D ? ? ? ? 33 D2" },
    flags = { 0x6DD, 0x77A, 0x86E, 0x899 },
  },
  extremeTrail = {
    furthest = { fn = "render", offset = 0xAFA, bytes = "39 2D ? ? ? ? 0F 8E" },
    scores = { fn = "render", offset = 0xB4E, bytes = "81 3C AD ? ? ? ? 50 FB FF FF" },
    hit = { fn = "click", offset = 0x2CA, bytes = "89 15 ? ? ? ?" },
    miss = { fn = "click", offset = 0x2BE, bytes = "03 D5 83 FA" },
    bound = { fn = "click", offset = 0x288, bytes = "8B 1D ? ? ? ? 33 D2" },
    flags = { 0xB86, 0xC23, 0xD17, 0xD42 },
  },
}
local FLAG_ARGUMENT_BYTES = { 0x14, 0x10, 0x14, 0x10 }

local native = nil -- { render, sheet, screen, draw, hide, detoured } once found
local doors = {}   -- trailName -> { token, gm, count, locks, positions, furthest, scores, day, list }

local function siteOf(site)
  return patches.siteAddress(site, "door pictures")
end

local function resolveNative()
  if native == nil then
    local render, drawSite = siteOf(RENDER_SITE), siteOf(DRAW_SITE)
    native = render ~= nil and drawSite ~= nil and {
      render = render,
      sheet = core.readInteger(drawSite + 1),
      screen = core.readInteger(drawSite + 6),
      draw = core.exposeCode((drawSite + 15 + core.readInteger(drawSite + 11)) & 0xFFFFFFFF, 5, 1),
      hide = core.allocate(1, true),
    } or false
  end
  return native or nil
end

---The marker sheet's pictures of `entry` ({ locked, available, won }), or nil.
local function picturesOf(trailName, index, entry)
  local pictures = {}
  for number, state in ipairs(STATES) do
    local value = entry["marker_" .. state]
    pictures[number] = math.tointeger(value)
    -- an empty locked picture draws nothing until the mission is open
    local empty = state == "locked" and (value == nil or value == "")
    if not empty and (pictures[number] == nil or pictures[number] < 0 or pictures[number] >= markers.PICTURES) then
      if entry.marker_locked ~= nil or entry.marker_available ~= nil or entry.marker_won ~= nil then
        log(WARNING, string.format("custom-skirmish-trails: %s mission %d: marker_locked, marker_available and "
          .. "marker_won must be pictures 0 to %d of the marker sheet", trailName, index, markers.PICTURES - 1))
      end
      return nil
    end
  end
  return pictures
end

---Which doors have pictures and which are open (date and map), again when the day changes.
local function refresh(trailName, door)
  local day = os.date("%Y-%m-%d")
  if door.day == day then
    return
  end
  door.day, door.list = day, {}
  local missions = memory.REGISTRY[trailName] or {}
  for index = 1, door.count do
    local entry = missions[index]
    local pictures = entry and picturesOf(trailName, index, entry)
    local open = pictures ~= nil and scenario.isOpen(entry)
    door.list[index] = pictures and { pictures = pictures, open = open }
    if pictures == nil and door.route ~= nil and door.route:needsPictures(index - 1) then
      log(WARNING, string.format("custom-skirmish-trails: %s mission %d is off the trail's order and has no marker; "
        .. "it can't be played",
        trailName, index))
    end
  end
end

local function onRender(registers)
  local trailName = memory.TRAIL_TYPES[registers.EDX]
  local door = trailName and doors[trailName]
  if door ~= nil and door.gm == nil then
    door.gm = modules.gmResourceModifier:GetReservedGm(door.token)
    if door.gm < 0 then
      log(WARNING, "custom-skirmish-trails: gmResourceModifier did not load the marker sheet; the game's markers stay")
    end
  end
  local shown = door ~= nil and door.gm >= 0
  core.writeByte(native.hide, shown and 1 or 0)
  if not shown then
    if door ~= nil and door.reach ~= nil then
      core.writeInteger(door.reach, core.readInteger(door.furthest))
    end
    return registers
  end
  refresh(trailName, door)
  local furthest = core.readInteger(door.furthest)
  local r, reach = door.route, furthest
  for index = 1, door.count do
    local slot, item = index - 1, door.list[index]
    local open = slot <= furthest
    local skipped = core.readInteger(door.scores + slot * 4) == SKIPPED
    local won = slot < furthest and not skipped
    if r ~= nil and r:needsPictures(slot) then
      open, won = item ~= nil and r:isOpen(slot), r:isPassed(slot) and not skipped
    end
    open = open and (item == nil or item.open)
    core.writeByte(door.locks + slot, open and 0 or 1)
    if open and slot > reach then
      reach = slot
    end
    if item ~= nil then
      local x = core.readInteger(door.positions + slot * 8) + registers.ESI
      local y = core.readInteger(door.positions + slot * 8 + 4) + registers.EDI
      -- the game's draw counts pictures from 1
      local picture = open and item.pictures[2] or item.pictures[1]
      if picture ~= nil then
        native.draw(native.screen, door.gm, picture + 1, x, y)
      end
      if won then
        native.draw(native.screen, door.gm, item.pictures[3] + 1, x, y)
      end
    end
  end
  if door.reach ~= nil then
    core.writeInteger(door.reach, reach)
  end
  return registers
end

---Reserves `sheetPath` (a .gm1 file laid out as skirmish_trail_icons.gm1) for `trailName`, which
---has `count` missions, and takes over its markers and clicks. With `r` (route.lua), side missions
---are drawn and clicked by their own state. Call while extensions are enabled.
function markers.install(trailName, sheetPath, count, r)
  local sites = SITES[trailName]
  local furthest, scores = siteOf(sites.furthest), siteOf(sites.scores)
  local hit, miss = siteOf(sites.hit), siteOf(sites.miss)
  local bound = r ~= nil and siteOf(sites.bound)
  if bound == nil then return end
  local positions = patches.positionTable(trailName)
  local flags = {}
  for index, offset in ipairs(sites.flags) do
    flags[index] = siteOf({ fn = "render", offset = offset, bytes = "E8 ? ? ? ?" })
    if flags[index] == nil then return end
  end
  if furthest == nil or scores == nil or hit == nil or miss == nil or positions == nil or resolveNative() == nil then
    return
  end
  if bound and core.readInteger(bound + 2) ~= core.readInteger(furthest + 2) then
    log(WARNING, "custom-skirmish-trails: unexpected game code for side missions; door pictures are switched off")
    return
  end
  local resolved, reason = winfiles.scopedPath(sheetPath)
  if resolved == nil then
    log(WARNING, "custom-skirmish-trails: " .. tostring(reason))
    return
  end
  local modifier = modules.gmResourceModifier
  local resource = modifier:LoadGm1Resource(resolved)
  local token = resource >= 0 and modifier:ReserveGm(native.sheet, resource) or -1
  if token < 0 then
    if resource >= 0 then modifier:FreeGm1Resource(resource) end
    log(WARNING, string.format("custom-skirmish-trails: %s is not a sheet like skirmish_trail_icons.gm1 "
      .. "(%d pictures); the game's markers stay", sheetPath, markers.PICTURES))
    return
  end

  local locks = core.allocate(patches.CAPACITY[trailName], true)
  local reach = bound and core.allocate(4, true)
  local patched = { { address = hit, size = 6 } }
  if bound then
    table.insert(patched, { address = bound, size = 6 })
  end
  for _, flag in ipairs(flags) do
    table.insert(patched, { address = flag, size = 5 })
  end
  if not native.detoured then
    table.insert(patched, { address = native.render, size = RENDER_SIZE })
  end
  local ok, err = pcall(patches.guarded, patched, function()
    if not native.detoured then
      core.detourCode(onRender, native.render, RENDER_SIZE)
    end
    for index, flag in ipairs(flags) do
      -- cmp byte [hide], 0 / je draw / ret: the game's marker is drawn only without door pictures
      local target = (flag + 5 + core.readInteger(flag + 1)) & 0xFFFFFFFF
      local stub = core.allocateCode(16)
      core.writeCode(stub, { 0x80, 0x3D, core.itob(native.hide), 0x00, 0x0F, 0x84, core.relTo(target, -4),
        0xC2, FLAG_ARGUMENT_BYTES[index], 0x00 })
      core.writeCodeInteger(flag + 1, core.getRelativeAddress(flag, stub, -5))
    end
    -- cmp byte [edx + locks], 0 / jne miss / mov [selected], edx
    core.insertCode(hit, 6, { 0x80, 0xBA, core.itob(locks), 0x00, 0x0F, 0x85, core.relTo(miss, -4),
      0x89, 0x15, core.itob(core.readInteger(hit + 2)) })
    if bound then
      -- mov ebx, [reach]: the last mission that can be clicked, side missions included
      core.writeInteger(reach, core.readInteger(core.readInteger(furthest + 2)))
      core.writeCodeInteger(bound + 2, reach)
    end
  end)
  if not ok then
    log(WARNING, "custom-skirmish-trails: door pictures are switched off: " .. tostring(err))
    return
  end
  native.detoured = true
  doors[trailName] = {
    token = token, count = count, locks = locks, positions = positions, route = r, reach = reach or nil,
    furthest = core.readInteger(furthest + 2), scores = core.readInteger(scores + 3),
  }
  log(INFO, string.format("custom-skirmish-trails: %s door pictures from %s", trailName, sheetPath))
end

return markers
