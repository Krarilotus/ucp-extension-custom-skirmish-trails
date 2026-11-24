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

function progress.install(trail, difficulty, count)
  local site = patches.siteAddress(WIN_STORES[trail], "difficulty-specific trail progress")
  if site == nil then
    return
  end
  local store = site + 3
  local furthest = core.readInteger(store + 1)
  local selected = memory.TRAIL_PROGRESS_ADDRESSES[trail]
  local path = string.format("ucp/custom-skirmish-trails-progress-%s-%s.txt", trail, difficulty)

  core.detourCode(function(registers)
    local value = registers.EAX
    if value >= 1 and value <= count then
      local ok, err = winfiles.writeFile(path, tostring(value) .. "\n")
      if not ok then
        log(WARNING, "custom-skirmish-trails: could not save trail progress: " .. tostring(err))
      end
    end
    return registers
  end, store, 5)

  hooks.registerHookCallback("afterInit", function()
    local value = readProgress(path, count)
    core.writeInteger(furthest, value)
    core.writeInteger(selected, math.min(value, count - 1))
  end)
end

return progress
