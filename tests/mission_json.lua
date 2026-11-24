-- Run from the module root with Lua 5.4.
local missionjson = require("customskirmishtrails.missionjson")
local warnings = {}
WARNING = 1
log = function(level, message)
  assert(level == WARNING)
  warnings[#warnings + 1] = message
end

local data = { format = 1, map_name = "Door01", players = { {} } }
local row = missionjson.toRow(data, nil, "door.json")
local headers = { "map_name", "num_players", "fairness", "start_levels", "keep_start_army" }
local exported = missionjson.fromRow(headers, row)
assert(not exported:find('"advantage"', 1, true))
assert(not exported:find('"start_mode"', 1, true))

data.advantage = "neutral"
data.start_mode = "normal"
data.extra = { fairness = "4", start_levels = "1" }
row = missionjson.toRow(data, nil, "door.json")
assert(row.fairness == "4" and row.start_levels == "1")
assert(#warnings == 1 and warnings[1]:find("door.json: extra.fairness", 1, true))
exported = missionjson.fromRow(headers, row)
assert(exported:find('"advantage": "ai_small"', 1, true))
assert(exported:find('"start_mode": "normal"', 1, true))

data.extra.keep_start_army = " 1 "
row = missionjson.toRow(data, nil, "door.json")
assert(#warnings == 2 and row.keep_start_army == " 1 ")

-- The CSV reader accepts an equivalent numeric flag while export preserves its spelling.
row.keep_start_army = " 1 "
assert(missionjson.startArmyFlag(row.keep_start_army) == 1)
exported = missionjson.fromRow(headers, row)
assert(exported:find('"keep_start_army": " 1 "', 1, true))
