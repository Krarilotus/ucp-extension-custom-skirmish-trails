-- trail_route in the trail settings file: the trail's missions as nodes keyed by id. Main missions
-- keep the trail's order and the game's furthest mission; side missions open when the nodes they
-- require are won, and their wins are kept in a file of won node ids. Rows are 0-based here, as
-- in the game.

local winfiles = require("customskirmishtrails.winfiles")

local route = {}

local Route = {}
Route.__index = Route

---`value` when it is a list of node ids ({} for nil), otherwise nil.
local function idList(value)
  if value == nil then
    return {}
  end
  if type(value) ~= "table" then
    return nil
  end
  local count = 0
  for _, id in pairs(value) do
    if type(id) ~= "string" then
      return nil
    end
    count = count + 1
  end
  return count == #value and value or nil
end

---The trail's route from `value` (trail_route) for a trail of `count` missions, or nil and the
---problem. Other fields of a node are not used.
local function parse(value, count)
  if type(value) ~= "table" then
    return nil, "trail_route must be an object of node ids"
  end
  local nodes, rows, sides = {}, {}, 0
  for id, entry in pairs(value) do
    if type(id) ~= "string" or type(entry) ~= "table" then
      return nil, "every trail_route entry must be an object under a node id"
    end
    local mission = math.tointeger(entry.mission)
    if mission == nil or mission < 1 or mission > count then
      return nil, string.format("node '%s' needs a mission from 1 to %d", id, count)
    end
    if rows[mission - 1] ~= nil then
      return nil, string.format("nodes '%s' and '%s' have the same mission %d", rows[mission - 1].id, id, mission)
    end
    local kind = entry.kind or "main"
    if kind ~= "main" and kind ~= "side" then
      return nil, string.format("node '%s': kind must be main or side", id)
    end
    local requires, requiresAny = idList(entry.requires), idList(entry.requires_any)
    if requires == nil or requiresAny == nil then
      return nil, string.format("node '%s': requires and requires_any must be lists of node ids", id)
    end
    if kind == "main" and (#requires > 0 or #requiresAny > 0) then
      return nil, string.format("node '%s': a main mission opens in the trail's order and takes no requires", id)
    end
    if kind == "side" then
      sides = sides + 1
    end
    local node = { id = id, row = mission - 1, side = kind == "side", requires = requires, requiresAny = requiresAny }
    nodes[id], rows[mission - 1] = node, node
  end
  for id, node in pairs(nodes) do
    for _, list in ipairs({ node.requires, node.requiresAny }) do
      for _, required in ipairs(list) do
        if nodes[required] == nil then
          return nil, string.format("node '%s' requires '%s', which is not a node", id, required)
        end
      end
    end
  end
  if rows[count - 1] ~= nil and rows[count - 1].side then
    return nil, string.format("the trail's last mission (%d) must be a main mission", count)
  end
  return { nodes = nodes, rows = rows, sides = sides }
end

local function readWins(path)
  local wins = {}
  local file = io.open(path, "rb")
  if file == nil then
    return wins
  end
  for id in file:read("*a"):gmatch("[^\r\n]+") do
    wins[id] = true
  end
  file:close()
  return wins
end

---Reads `value` (trail_route of the settings file `settingsPath`) for a trail with `count`
---missions; side wins are kept in `winsPath`. Returns the route when it has side missions, nil
---otherwise or when it can't be used (logged).
function route.load(settingsPath, value, count, winsPath)
  local parsed, problem = parse(value, count)
  if parsed == nil then
    log(WARNING, string.format("custom-skirmish-trails: %s: %s; the trail plays its missions in their order",
      settingsPath, problem))
    return nil
  end
  if parsed.sides == 0 then
    return nil
  end
  parsed.count, parsed.path, parsed.wins = count, winsPath, readWins(winsPath)
  return setmetatable(parsed, Route)
end

function Route:isSide(row)
  local node = self.rows[row]
  return node ~= nil and node.side
end

---The first main mission at or after `row` (count when there is none).
function Route:nextMain(row)
  while row < self.count and self:isSide(row) do
    row = row + 1
  end
  return row
end

---A main mission is won once the trail has passed it (won or skipped with a chicken).
function Route:isWon(row, furthest)
  local node = self.rows[row]
  if node ~= nil and node.side then
    return self.wins[node.id] == true
  end
  return row < furthest
end

---A side mission can be played when every node of requires and one of requires_any is won.
function Route:isAvailable(row, furthest)
  local node = self.rows[row]
  local function won(id)
    return self:isWon(self.nodes[id].row, furthest)
  end
  for _, id in ipairs(node.requires) do
    if not won(id) then
      return false
    end
  end
  for _, id in ipairs(node.requiresAny) do
    if won(id) then
      return true
    end
  end
  return #node.requiresAny == 0
end

function Route:recordWin(row)
  local id = self.rows[row].id
  if self.wins[id] then
    return
  end
  self.wins[id] = true
  local ids = {}
  for won in pairs(self.wins) do
    table.insert(ids, won)
  end
  table.sort(ids)
  local ok, err = winfiles.writeFile(self.path, table.concat(ids, "\n") .. "\n")
  if not ok then
    log(WARNING, "custom-skirmish-trails: could not save side mission wins: " .. tostring(err))
  end
end

return route
