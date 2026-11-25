-- trail_route in the trail settings file: the trail's missions as nodes keyed by id. Main missions
-- keep the trail's order and the game's furthest mission; side missions open when the nodes they
-- require are won, and their wins are kept in a file of won node ids. Every win of a node is kept
-- in a results file with the players whose lord, and who themselves, were alive at that win; a
-- side mission's unlock reads it, and a node's reward is given at its first win. Rows are 0-based
-- here, as in the game.

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

local MAX_PLAYERS = 8
local MAX_REWARD = 1000
-- unlock fields with a player, and the results each one reads
local PLAYER_FACTS = { lord_alive = "lords", player_alive = "players" }

---A node's unlock { "won": id, "lord_alive": player, "player_alive": player } as
---{ won, lords, players }, or nil and the problem.
local function readUnlock(value)
  if type(value) ~= "table" or type(value.won) ~= "string" then
    return nil, "unlock needs \"won\", a node id"
  end
  local unlock = { won = value.won }
  for key, player in pairs(value) do
    if key ~= "won" then
      local n = math.tointeger(player)
      if PLAYER_FACTS[key] == nil or n == nil or n < 1 or n > MAX_PLAYERS then
        return nil, string.format("unlock.%s is not lord_alive or player_alive with a player from 1 to %d",
          tostring(key), MAX_PLAYERS)
      end
      unlock[PLAYER_FACTS[key]] = n
    end
  end
  return unlock
end

---A node's reward { "chickens": n } as { chickens }, or nil and the problem.
local function readReward(value)
  local chickens = type(value) == "table" and math.tointeger(value.chickens)
  if not chickens or chickens < 1 or chickens > MAX_REWARD or next(value, next(value)) ~= nil then
    return nil, string.format("reward must be { \"chickens\": 1 to %d }", MAX_REWARD)
  end
  return { chickens = chickens }
end

---The trail's route from `value` (trail_route) for a trail of `count` missions, or nil and the
---problem. Other fields of a node are not used.
local function parse(value, count)
  if type(value) ~= "table" then
    return nil, "trail_route must be an object of node ids"
  end
  local nodes, rows, sides, rewards = {}, {}, 0, false
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
    local unlock, reward, problem
    if entry.unlock ~= nil then
      unlock, problem = readUnlock(entry.unlock)
      if unlock == nil or kind == "main" then
        return nil, string.format("node '%s': %s", id, problem or "a main mission takes no unlock")
      end
    end
    if entry.reward ~= nil then
      reward, problem = readReward(entry.reward)
      if reward == nil then
        return nil, string.format("node '%s': %s", id, problem)
      end
      rewards = true
    end
    if kind == "side" then
      sides = sides + 1
    end
    local node = { id = id, row = mission - 1, side = kind == "side", requires = requires, requiresAny = requiresAny,
      unlock = unlock, reward = reward }
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
    if node.unlock ~= nil and nodes[node.unlock.won] == nil then
      return nil, string.format("node '%s': unlock.won '%s' is not a node", id, node.unlock.won)
    end
  end
  if rows[count - 1] ~= nil and rows[count - 1].side then
    return nil, string.format("the trail's last mission (%d) must be a main mission", count)
  end
  return { nodes = nodes, rows = rows, sides = sides, rewards = rewards }
end

local function readLines(path)
  local lines = {}
  local file = io.open(path, "rb")
  if file == nil then
    return lines
  end
  for line in file:read("*a"):gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  file:close()
  return lines
end

---Writes `lines` sorted into `path`; `what` names them in the log when that fails.
local function writeLines(path, lines, what)
  table.sort(lines)
  local ok, err = winfiles.writeFile(path, table.concat(lines, "\n") .. "\n")
  if not ok then
    log(WARNING, string.format("custom-skirmish-trails: could not save %s: %s", what, tostring(err)))
  end
end

local function readWins(path)
  local wins = {}
  for _, id in ipairs(readLines(path)) do
    wins[id] = true
  end
  return wins
end

-- A results line: "<node id> lords=1,3 players=1"
local function readResults(path)
  local results = {}
  for _, line in ipairs(readLines(path)) do
    local id, rest = line:match("^(%S+)(.*)$")
    local result = { lords = {}, players = {} }
    for key, list in rest:gmatch("(%a+)=(%S*)") do
      for player in list:gmatch("%d+") do
        if result[key] ~= nil then
          result[key][tonumber(player)] = true
        end
      end
    end
    results[id] = result
  end
  return results
end

local function resultLine(id, result)
  local fields = { id }
  for _, key in ipairs({ "lords", "players" }) do
    local players = {}
    for player = 1, MAX_PLAYERS do
      if result[key][player] then
        table.insert(players, tostring(player))
      end
    end
    table.insert(fields, key .. "=" .. table.concat(players, ","))
  end
  return table.concat(fields, " ")
end

---Reads `value` (trail_route of the settings file `settingsPath`) for a trail with `count`
---missions; side wins are kept in `winsPath`, the results of node wins in `resultsPath`. Returns
---the route when it has side missions, nil otherwise or when it can't be used (logged).
function route.load(settingsPath, value, count, winsPath, resultsPath)
  local parsed, problem = parse(value, count)
  if parsed == nil then
    log(WARNING, string.format("custom-skirmish-trails: %s: %s; the trail plays its missions in their order",
      settingsPath, problem))
    return nil
  end
  if parsed.sides == 0 then
    if parsed.rewards then
      log(WARNING, string.format("custom-skirmish-trails: %s: rewards need a route with side missions; they are "
        .. "not given", settingsPath))
    end
    return nil
  end
  parsed.count, parsed.path, parsed.wins = count, winsPath, readWins(winsPath)
  parsed.resultsPath, parsed.results = resultsPath, readResults(resultsPath)
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

---A side mission can be played when every node of requires and one of requires_any is won, and
---its unlock's node was won while the named player's lord and the named player were alive.
function Route:isAvailable(row, furthest)
  local node = self.rows[row]
  local unlock = node.unlock
  if unlock ~= nil then
    local result = self.results[unlock.won]
    if result == nil or (unlock.lords and not result.lords[unlock.lords])
        or (unlock.players and not result.players[unlock.players]) then
      return false
    end
  end
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
  writeLines(self.path, ids, "side mission wins")
end

---Keeps the win of the node at `row` with `facts` ({ lords = { [player] = true }, players = ... },
---nil when the game's players can't be read), joined with its earlier wins. Returns the chickens
---of the node's reward at its first win, 0 otherwise.
function Route:recordResult(row, facts)
  local node = self.rows[row]
  if node == nil then
    return 0
  end
  local first = self.results[node.id] == nil
  local result = self.results[node.id] or { lords = {}, players = {} }
  for key, players in pairs(facts or {}) do
    for player in pairs(players) do
      result[key][player] = true
    end
  end
  self.results[node.id] = result
  local lines = {}
  for id, kept in pairs(self.results) do
    table.insert(lines, resultLine(id, kept))
  end
  writeLines(self.resultsPath, lines, "trail results")
  return first and node.reward ~= nil and node.reward.chickens or 0
end

---The chickens of the rewards of every node won so far.
function Route:earnedChickens()
  local total = 0
  for id in pairs(self.results) do
    local node = self.nodes[id]
    total = total + (node ~= nil and node.reward ~= nil and node.reward.chickens or 0)
  end
  return total
end

return route
