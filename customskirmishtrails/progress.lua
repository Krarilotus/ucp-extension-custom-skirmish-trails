local memory = require("customskirmishtrails.memory")
local patches = require("customskirmishtrails.patches")
local winfiles = require("customskirmishtrails.winfiles")

local progress = {}

-- Each native victory branch computes the new furthest row in EAX, then stores it.
-- These sites are downstream of the winner check and the scenario win handover.
local WIN_STORES = {
  firstEditionTrail = { fn = "win", offset = 0x359, bytes = "8D 41 01 A3 ? ? ? ? 7D" },
  warchestTrail = { fn = "win", offset = 0x2F7, bytes = "8D 47 01 A3 ? ? ? ? 7D" },
  extremeTrail = { fn = "win", offset = 0x286, bytes = "8D 42 01 A3 ? ? ? ? 7D" },
}
-- After a win both branches store the next selected row from a register: "mov [selected], reg".
local SELECT_STORES = {
  firstEditionTrail = { fn = "win", offset = 0x374, bytes = "89 0D ? ? ? ? 66 85 D2", register = "ECX" },
  warchestTrail = { fn = "win", offset = 0x312, bytes = "89 3D ? ? ? ? 66 85 C9", register = "EDI" },
  extremeTrail = { fn = "win", offset = 0x2A1, bytes = "89 15 ? ? ? ? 66 85 C9", register = "EDX" },
}
-- A chicken has advanced the selected and the furthest row of every trail when the click handler
-- reaches "mov ecx, trails / call" (the trail's number is pushed).
local CHICKEN_SITE = { fn = "click", offset = 0x71, bytes = "B9 ? ? ? ? E8 ? ? ? ? 29 2D" }

local stores = {} -- trailName -> { furthest, selected, path, count, route } once the win store is detoured
local chickenHooked = false

local function readProgress(path, count)
  local file = io.open(path, "rb")
  if file == nil then
    return 0
  end
  local contents = file:read("*a")
  file:close()
  local value = tonumber(contents:match("^%s*(%d+)%s*$"))
  return value and math.min(value, count) or 0
end

---The win store of `trail`, detoured once: a side mission's win keeps the furthest row, a main
---mission's skips the side missions after it, and the furthest row is saved when a path is set.
local function winStore(trail, purpose)
  if stores[trail] ~= nil then
    return stores[trail]
  end
  local site = patches.siteAddress(WIN_STORES[trail], purpose)
  if site == nil then
    return nil
  end
  local store = site + 3
  local state = { furthest = core.readInteger(store + 1), selected = memory.TRAIL_PROGRESS_ADDRESSES[trail] }
  core.detourCode(function(registers)
    local r = state.route
    if r ~= nil then
      registers.EAX = r:isSide(core.readInteger(state.selected)) and core.readInteger(state.furthest)
        or r:nextMain(registers.EAX)
    end
    local value = registers.EAX
    if state.path ~= nil and value >= 1 and value <= state.count then
      local ok, err = winfiles.writeFile(state.path, tostring(value) .. "\n")
      if not ok then
        log(WARNING, "custom-skirmish-trails: could not save trail progress: " .. tostring(err))
      end
    end
    return registers
  end, store, 5)
  stores[trail] = state
  return state
end

function progress.install(trail, difficulty, count)
  local state = winStore(trail, "difficulty-specific trail progress")
  if state == nil then
    return
  end
  state.count = count
  state.path = string.format("ucp/custom-skirmish-trails-progress-%s-%s.txt", trail, difficulty)

  hooks.registerHookCallback("afterInit", function()
    local value = readProgress(state.path, count)
    core.writeInteger(state.furthest, value)
    core.writeInteger(state.selected, math.min(value, count - 1))
  end)
end

local function onChicken()
  local trail = memory.TRAIL_TYPES[core.readInteger(memory.CURRENT_TRAIL_TYPE)]
  local state = trail and stores[trail]
  local r = state and state.route
  local furthest = state and core.readInteger(state.furthest)
  if r ~= nil and r:isSide(furthest) then
    core.writeInteger(state.furthest, r:nextMain(furthest))
    core.writeInteger(state.selected, r:nextMain(furthest))
  end
end

---Plays the side missions of `r` (route.lua) on `trail` without moving its furthest row: their wins
---are recorded in the route, the next main mission is selected after them, and wins and chickens
---skip the side missions. False when a game site is not found.
function progress.installRoute(trail, r)
  local state = winStore(trail, "side missions")
  local selectSite = SELECT_STORES[trail]
  local select = state and patches.siteAddress(selectSite, "side missions")
  local chicken = chickenHooked or patches.siteAddress(CHICKEN_SITE, "side missions")
  if select == nil or not chicken or core.readInteger(select + 2) ~= state.selected then
    return false
  end
  core.detourCode(function(registers)
    local won = core.readInteger(state.selected)
    if r:isSide(won) then
      r:recordWin(won)
      registers[selectSite.register] = core.readInteger(state.furthest)
    else
      registers[selectSite.register] = r:nextMain(registers[selectSite.register])
    end
    return registers
  end, select, 6)
  if not chickenHooked then
    core.detourCode(function(registers)
      onChicken()
      return registers
    end, chicken, 5)
    chickenHooked = true
  end
  state.route = r
  -- progress kept from before the trail had its route
  hooks.registerHookCallback("afterInit", function()
    local furthest = r:nextMain(core.readInteger(state.furthest))
    core.writeInteger(state.furthest, furthest)
    if r:isSide(core.readInteger(state.selected)) then
      core.writeInteger(state.selected, math.min(furthest, r.count - 1))
    end
  end)
  return true
end

return progress
