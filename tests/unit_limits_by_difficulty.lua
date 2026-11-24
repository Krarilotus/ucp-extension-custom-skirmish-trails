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
    mission_kind = "scenario",
    players = { {} },
    unit_limit = limit,
  }, nil, map .. ".json")
end

local first = mission("Door01",
  "story: native; normal: formula 2400 40; hard: formula 1600 40; very_hard: formula 800 40")
local second = mission("Door02", "hard: formula 1200 40; default: formula 3000 40")
local native = mission("Door03")
local encoded = missionjson.fromRow({ "map_name", "num_players", "mission_kind", "unit_limit" }, first)
assert(encoded:find(first.unit_limit, 1, true))

local expected = {
  story = { nil, 1460 },
  normal = { 1160, 1460 },
  hard = { 760, 560 },
  very_hard = { 360, 1460 },
}
local trails = { warchestTrail = { first, second, native } }

for difficulty, limits in pairs(expected) do
  unitlimits.enable(difficulty)
  unitlimits.apply(trails)
  for index, entry in ipairs(trails.warchestTrail) do
    local policy = unitlimits.policy(entry)
    local actual = policy and unitlimits.value(policy, 2)
    assert(actual == limits[index], difficulty .. " / " .. entry.map_name)
  end
end
print("12/12 difficulty and mission combinations passed")
