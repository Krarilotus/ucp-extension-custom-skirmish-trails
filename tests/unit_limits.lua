-- Run from the module root with Lua 5.4.
local missionjson = require("customskirmishtrails.missionjson")

log = function() end
utils = {
  AOBExtract = function() error("native executable unavailable in this test") end,
}

package.loaded['customskirmishtrails.memory'] = {}
local unitlimits = require("customskirmishtrails.unitlimits")

local function mission(map, limit)
  return missionjson.toRow({
    format = 1,
    map_name = map,
    mission_type = "skirmish_scenario",
    players = { {} },
    unit_limit = limit,
  }, nil, map .. ".json")
end

local crusader = mission("Door01", { formula = { base = 2400, offset = 40 } })
local byAlive = mission("Door02", { by_alive = { { lords = 8, limit = 250 }, { lords = 4, limit = 500 },
  { lords = 2, limit = 1000 }, { lords = 1, limit = 2000 } } })
local native = mission("Door03")
native.unit_limit = "native"
local empty = mission("Door04")
assert(crusader.unit_limit == "formula 2400 40" and byAlive.unit_limit == "by_alive 8=250 4=500 2=1000 1=2000")
local encoded = missionjson.fromRow({ "map_name", "num_players", "mission_type", "unit_limit" }, crusader)
assert(encoded:find('"formula": {\n      "base": 2400,\n      "offset": 40', 1, true))

local expected = { 1160, 1000, nil, nil }
local trails = { warchestTrail = { crusader, byAlive, native, empty } }

unitlimits.enable()
unitlimits.apply(trails)
for index = 1, #trails.warchestTrail do
  local entry = trails.warchestTrail[index]
  local policy = unitlimits.policy(entry)
  local actual = policy and unitlimits.value(policy, 2)
  assert(actual == expected[index], entry.map_name)
end
print("4/4 missions passed")
