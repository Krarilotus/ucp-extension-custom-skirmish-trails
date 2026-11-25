-- trail_route in the trail settings file: the trail's missions as nodes keyed by id. Main missions
-- keep the trail's order and the game's furthest mission; side missions open when the nodes they
-- require are won, and their wins are kept in a file of won node ids. Every win of a node is kept
-- in a results file with its difficulty and the players whose lord, and who themselves, were alive
-- at that win; a side mission's unlock needs one such win, and a node's reward is given at its
-- first win. Rows are 0-based here, as in the game.

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
local DIFFICULTIES = { story = true, normal = true, hard = true, very_hard = true }
-- unlock fields with players, and the facts of a win each one reads
local PLAYER_FACTS = { lord_alive = "lords", player_alive = "players" }

---Players 1-8 from one player or a list of them, or nil.
local function playerList(value)
  local list = type(value) == "table" and value or { value }
  local players = {}
  for _, player in pairs(list) do
    local n = math.tointeger(player)
    if n == nil or n < 1 or n > MAX_PLAYERS then
      return nil
    end
    table.insert(players, n)
  end
  return #players > 0 and #players == #list and players or nil
end

---A node's unlock { "won": id, "difficulty": name, "lord_alive": players, "player_alive": players }
---as { won, difficulty, lords, players }, or nil and the problem.
local function readUnlock(value)
  if type(value) ~= "table" or type(value.won) ~= "string" then
    return nil, "unlock needs \"won\", a node id"
  end
  if value.difficulty ~= nil and not DIFFICULTIES[value.difficulty] then
    return nil, "unlock.difficulty must be story, normal, hard or very_hard"
  end
  local unlock = { won = value.won, difficulty = value.difficulty }
  for key, players in pairs(value) do
    if PLAYER_FACTS[key] ~= nil then
      unlock[PLAYER_FACTS[key]] = playerList(players)
      if unlock[PLAYER_FACTS[key]] == nil then
        return nil, string.format("unlock.%s must be a player from 1 to %d or a list of them", key, MAX_PLAYERS)
      end
    elseif key ~= "won" and key ~= "difficulty" then
      return nil, string.format("unlock.%s is not won, difficulty, lord_alive or player_alive", tostring(key))
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

-- A results line, one per different win: "<node id> <difficulty> lords=1,3 players=1"
local function resultLine(id, difficulty, facts)
  local fields = { id, difficulty }
  for _, key in ipairs({ "lords", "players" }) do
    local players = {}
    for player = 1, MAX_PLAYERS do
      if facts[key][player] then
        table.insert(players, tostring(player))
      end
    end
    table.insert(fields, key .. "=" .. table.concat(players, ","))
  end
  return table.concat(fields, " ")
end

---Adds the win of results line `line` to the route; false when it is kept already or not a line.
local function addResult(r, line)
  local id, difficulty, rest = line:match("^(%S+)%s+(%S+)(.*)$")
  if id == nil or r.lines[line] then
    return false
  end
  local result = { difficulty = difficulty, lords = {}, players = {} }
  for key, list in rest:gmatch("(%a+)=(%S*)") do
    if key == "lords" or key == "players" then
      for player in list:gmatch("%d+") do
        result[key][tonumber(player)] = true
      end
    end
  end
  r.lines[line] = true
  r.results[id] = r.results[id] or {}
  table.insert(r.results[id], result)
  return true
end

---Reads `value` (trail_route of the settings file `settingsPath`) for a trail with `count`
---missions, played at `difficulty`; side wins are kept in `winsPath`, the results of node wins in
---`resultsPath`. Returns the route when it has side missions, nil otherwise or when it can't be
---used (logged).
function route.load(settingsPath, value, count, winsPath, resultsPath, difficulty)
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
  parsed.resultsPath, parsed.difficulty, parsed.results, parsed.lines = resultsPath, difficulty, {}, {}
  for _, line in ipairs(readLines(resultsPath)) do
    addResult(parsed, line)
  end
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

---True when one win of the unlock's node was at its difficulty with all its players alive.
function Route:isUnlocked(unlock)
  for _, result in ipairs(self.results[unlock.won] or {}) do
    local met = unlock.difficulty == nil or result.difficulty == unlock.difficulty
    for _, key in ipairs({ "lords", "players" }) do
      for _, player in ipairs(unlock[key] or {}) do
        met = met and result[key][player] == true
      end
    end
    if met then
      return true
    end
  end
  return false
end

---A side mission can be played when every node of requires and one of requires_any is won, and
---its unlock is met.
function Route:isAvailable(row, furthest)
  local node = self.rows[row]
  if node.unlock ~= nil and not self:isUnlocked(node.unlock) then
    return false
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

---Keeps the win of the node at `row` with the difficulty and `facts` ({ lords = { [player] = true },
---players = ... }, nil when the game's players can't be read). Returns the chickens of the node's
---reward at its first win, 0 otherwise.
function Route:recordResult(row, facts)
  local node = self.rows[row]
  if node == nil then
    return 0
  end
  local first = self.results[node.id] == nil
  if addResult(self, resultLine(node.id, self.difficulty, facts or { lords = {}, players = {} })) then
    local lines = {}
    for line in pairs(self.lines) do
      table.insert(lines, line)
    end
    writeLines(self.resultsPath, lines, "trail results")
  end
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
