-- Troop limits per trail mission and difficulty (unit_limit). The game computes the player's
-- troop limit every tick in one function: in single-player games (custom scenarios) it is 10000,
-- otherwise base / living lords - offset (base 2400 in Crusader, 9900 in Extreme, offset 40). A
-- mission's policy replaces the stored value while that mission is played:
--   native               the game's own value
--   formula BASE OFFSET  BASE / living lords - OFFSET ("formula 2400 40" = Crusader limits)
--   by_alive L=N ...     N troops at L living lords, linear between the listed counts and
--                        rounded down ("by_alive 8=250 4=500 2=1000 1=2000")
-- The result never exceeds the game's skirmish formula for the living lords, also in scenarios,
-- where the game itself has no limit (10000). The mission comes from the game's trail state
-- (skirmish missions) or the scenario the trail started (see scenario.session), the policy from
-- the difficulty option.
--
-- The function is found by AOB, the same in both 1.41 executables, with the operands decoded.
-- Single-player games go through the game's own counting part only for the scenario the trail
-- started, and only when its mission has a policy; then the stored value is set here every tick.

local patches = require("customskirmishtrails.patches")
local memory = require("customskirmishtrails.memory")

local unitlimits = {}

-- "cmp dword [syncMode], 0 / jne count / mov dword [ecx + limit], 10000 / ret / push esi ..."
local ENTRY_AOB = "83 3D I(? ? ? ?) 00 75 0B C7 81 I(? ? ? ?) I(? ? ? ?) C3 56 57 33 F6"
-- "mov eax, base / cdq / idiv esi / pop edi / pop esi / sub eax, offset / mov [ecx + limit], eax / ret"
local STORE_AOB = "B8 I(? ? ? ?) 99 F7 FE 5F 5E 83 E8 ? 89 81 I(? ? ? ?) C3 5F C7 81 ? ? ? ? ? ? ? ? 5E C3"
local STORE_OFFSET = 0x0D
local STORE_PATCH_SIZE = 6   -- mov [ecx + limit], eax
local ENTRY_PATCH_SIZE = 9   -- the compare (7 bytes) and the short jne (2 bytes)
local COUNT_OFFSET = 0x14    -- where the jne goes: the counting part
local GAME_MODE_SCENARIO = 2
local SYNC_MODE_SKIRMISH = 99
local MAX_LORDS = 8
local MAX_LIMIT = 100000 -- above every limit the game computes

local DIFFICULTIES = { story = true, normal = true, hard = true, very_hard = true }
local DEFAULT_DIFFICULTY = "normal" -- the option's default

local bindings = nil
local difficulty = DEFAULT_DIFFICULTY
local registry = nil
local session = nil
local installed = { skirmish = false, scenario = false }

---Reads one policy ("native", "formula 2400 40"), or nil and a reason.
local function parsePolicy(text)
  local words = {}
  for word in text:gmatch("%S+") do words[#words + 1] = word:lower() end
  if #words == 1 and words[1] == "native" then
    return { kind = "native" }
  end
  if #words == 3 and words[1] == "formula" then
    local base, offset = math.tointeger(tonumber(words[2])), math.tointeger(tonumber(words[3]))
    if base ~= nil and offset ~= nil and base > 0 and offset >= 0 then
      return { kind = "formula", base = base, offset = offset }
    end
  end
  if #words >= 2 and words[1] == "by_alive" then
    local points, seen = {}, {}
    for index = 2, #words do
      local lords, limit = words[index]:match("^(%d+)=(%d+)$")
      lords, limit = math.tointeger(tonumber(lords)), math.tointeger(tonumber(limit))
      if lords == nil or lords < 1 or lords > MAX_LORDS or seen[lords] or limit == nil or limit > MAX_LIMIT then
        points = nil
        break
      end
      seen[lords] = true
      points[#points + 1] = { lords = lords, limit = limit }
    end
    if points ~= nil then
      table.sort(points, function(a, b) return a.lords < b.lords end)
      return { kind = "by_alive", points = points }
    end
  end
  return nil, string.format("'%s' is not 'native', 'formula BASE OFFSET' or 'by_alive LORDS=LIMIT ...' "
    .. "(each LORDS 1-8 once, LIMIT at most %d)", text, MAX_LIMIT)
end

---Reads a unit_limit cell: one policy for every difficulty, or "story: ...; hard: ..." with an
---optional "default: ...". Returns a table (difficulty -> policy) or nil and a reason.
function unitlimits.parse(text)
  if text == nil or text == "" then
    return {}
  end
  if type(text) ~= "string" then
    return nil, "unit_limit must be a text"
  end
  local result = {}
  if not text:find(":") then
    local policy, reason = parsePolicy(text)
    if policy == nil then return nil, reason end
    result.default = policy
    return result
  end
  for part in text:gmatch("[^;]+") do
    local key, value = part:match("^%s*([%w_]+)%s*:%s*(.-)%s*$")
    key = key and key:lower() or nil
    if key == nil or (key ~= "default" and not DIFFICULTIES[key]) then
      return nil, string.format("'%s' is not 'difficulty: policy' (story, normal, hard, very_hard, default)", part)
    end
    local policy, reason = parsePolicy(value)
    if policy == nil then return nil, reason end
    result[key] = policy
  end
  return result
end

---A policy's limit for `lords` living lords. by_alive interpolates linearly between the listed
---counts and keeps the nearest listed limit outside them.
function unitlimits.value(policy, lords)
  if policy.kind == "formula" then
    return policy.base // lords - policy.offset
  end
  local points = policy.points
  if lords <= points[1].lords then
    return points[1].limit
  end
  for index = 2, #points do
    local low, high = points[index - 1], points[index]
    if lords <= high.lords then
      return low.limit + (high.limit - low.limit) * (lords - low.lords) // (high.lords - low.lords)
    end
  end
  return points[#points].limit
end

---The policy a mission plays with at the difficulty that is set, or nil for the game's own value.
function unitlimits.policy(entry)
  return type(entry) == "table" and entry.unit_limit_policy or nil
end

---False when the mission has a policy that can't be applied (the game code was not found), so
---that it doesn't start without its limit. `isScenario`: the mission starts as a scenario.
function unitlimits.available(entry, isScenario)
  if unitlimits.policy(entry) == nil then
    return true
  end
  return installed.skirmish and (not isScenario or installed.scenario)
end

local function resolve()
  local okEntry, entry, syncMode, limitField, singlePlayerValue = pcall(utils.AOBExtract, ENTRY_AOB)
  local okStore, store, base, storeField = pcall(utils.AOBExtract, STORE_AOB)
  if not okEntry or not okStore or entry == nil or store == nil then
    log(WARNING, "custom-skirmish-trails: could not find the troop limit; unit_limit is switched off")
    return nil
  end
  for _, check in ipairs({ { ENTRY_AOB, entry }, { STORE_AOB, store } }) do
    local unique, reason = patches.isUnique(check[1], check[2])
    if not unique then
      log(WARNING, string.format("custom-skirmish-trails: the troop limit code %s; unit_limit is switched off", reason))
      return nil
    end
  end
  if limitField ~= storeField or store <= entry or store - entry > 0x100 then
    log(WARNING, "custom-skirmish-trails: unexpected troop limit code; unit_limit is switched off")
    return nil
  end
  return {
    entry = entry,
    store = store,
    syncMode = syncMode,
    field = limitField,
    singlePlayerValue = singlePlayerValue,
    base = base,
    offset = core.readByte(store + STORE_OFFSET - 1),
    storeSite = store + STORE_OFFSET,
  }
end

---True when both sites still hold the code and operands found by resolve (another patch may
---have changed them since).
local function unchanged(b)
  return patches.matches(b.entry, patches.plain(ENTRY_AOB)) and patches.matches(b.store, patches.plain(STORE_AOB))
    and core.readInteger(b.entry + 2) == b.syncMode and core.readInteger(b.entry + 11) == b.field
    and core.readInteger(b.entry + 15) == b.singlePlayerValue and core.readInteger(b.store + 1) == b.base
    and core.readInteger(b.store + 15) == b.field and core.readByte(b.store + STORE_OFFSET - 1) == b.offset
end

---The number of living lords the game's formula used, from its result.
local function livingLords(value)
  for lords = 1, MAX_LORDS do
    if bindings.base // lords - bindings.offset == value then
      return lords
    end
  end
  return nil
end

---The trail mission being played: in single-player mode only the trail's scenario reaches the
---store (the entry patch checks it); in single-player skirmish the game's trail state names it.
local function playedEntry(syncMode)
  if syncMode == 0 then
    return session ~= nil and session.entry() or nil
  end
  if syncMode ~= SYNC_MODE_SKIRMISH then
    return nil
  end
  local ok, isTrail, _, trailName, index = pcall(memory.fetchCurrentTrail)
  if not ok or not isTrail then
    return nil
  end
  local missions = registry[trailName]
  return missions and missions[index] or nil
end

local function installStore(b)
  patches.guarded({ { address = b.storeSite, size = STORE_PATCH_SIZE } }, function()
    core.detourCode(function(registers)
      local syncMode = core.readInteger(b.syncMode)
      local singlePlayer = syncMode == 0
      local policy = unitlimits.policy(playedEntry(syncMode))
      local lords = policy and livingLords(registers.EAX) or nil
      if policy ~= nil and lords ~= nil then
        registers.EAX = math.max(0, math.min(unitlimits.value(policy, lords), registers.EAX))
      elseif singlePlayer then
        registers.EAX = b.singlePlayerValue
      end
      return registers
    end, b.storeSite, STORE_PATCH_SIZE)
  end)
end

---Single-player games count only for the trail's scenario: the scenario mode is on, its mission
---has a policy (session.cap) and the chosen map is the session's (session.sameMap). Otherwise the
---game's own compare is repeated, so its single-player store runs with the flags it had.
local function installEntry(b, s)
  patches.guarded({ { address = b.entry, size = ENTRY_PATCH_SIZE } }, function()
    core.insertCode(b.entry, ENTRY_PATCH_SIZE, {
      0x83, 0x3D, core.itob(b.syncMode), 0x00,               -- cmp dword [syncMode], 0
      0x0F, 0x85, core.relTo(b.entry + COUNT_OFFSET, -4),    -- jne count
      0x80, 0x3D, core.itob(s.cap), 0x00,                    -- cmp byte [cap], 0
      0x0F, 0x84, core.relTo("native", -4),                  -- je native
      0x83, 0x3D, core.itob(s.gameMode), GAME_MODE_SCENARIO, -- cmp dword [gameMode], 2
      0x0F, 0x85, core.relTo("native", -4),                  -- jne native
      0xE8, core.relTo(s.sameMap, -4),                       -- call sameMap
      0x0F, 0x85, core.relTo("native", -4),                  -- jne native
      core.jmpTo(b.entry + COUNT_OFFSET),
      "native",
      0x83, 0x3D, core.itob(b.syncMode), 0x00,               -- cmp dword [syncMode], 0
    })
  end)
end

---Binds the troop limit. `level` is the difficulty option (story, normal, hard, very_hard); none
---means normal, the option's default.
function unitlimits.enable(level)
  difficulty = DEFAULT_DIFFICULTY
  if type(level) == "string" and DIFFICULTIES[level:lower()] then
    difficulty = level:lower()
  elseif level ~= nil then
    log(WARNING, string.format("custom-skirmish-trails: difficulty '%s' is not story, normal, hard or very_hard; "
      .. "unit_limit uses normal", tostring(level)))
  end
  local ok, result = pcall(resolve)
  if ok then
    bindings = result
  else
    log(WARNING, "custom-skirmish-trails: unit_limit is switched off: " .. tostring(result))
  end
end

---Reads the unit_limit of every mission and installs the troop limit when a mission has a policy
---other than native at the difficulty that is set. Call it after the trails' missions are loaded.
---`scenarioSession` (scenario.session(), or nil) is needed for scenario missions.
function unitlimits.apply(trails, scenarioSession)
  registry = trails
  local any = false
  for trailName, missions in pairs(trails) do
    for index, entry in ipairs(missions) do
      local policies, reason = unitlimits.parse(entry.unit_limit)
      if policies == nil then
        log(WARNING, string.format("custom-skirmish-trails: %s mission %d: unit_limit %s", trailName, index, reason))
        policies = {}
      end
      local policy = policies[difficulty] or policies.default
      entry.unit_limit_policy = (policy ~= nil and policy.kind ~= "native") and policy or nil
      any = any or entry.unit_limit_policy ~= nil
    end
  end
  if not any or bindings == nil or installed.skirmish then
    return
  end
  if not unchanged(bindings) then
    log(WARNING, "custom-skirmish-trails: the troop limit code was changed by another patch; unit_limit is switched off")
    return
  end
  local ok, err = pcall(installStore, bindings)
  if not ok then
    log(WARNING, "custom-skirmish-trails: unit_limit is switched off: " .. tostring(err))
    return
  end
  installed.skirmish = true
  if scenarioSession == nil then
    log(WARNING, "custom-skirmish-trails: scenario missions are switched off, so are their troop limits")
    return
  end
  session = scenarioSession
  ok, err = pcall(installEntry, bindings, scenarioSession)
  if not ok then
    log(WARNING, "custom-skirmish-trails: the troop limits of scenario missions are switched off: " .. tostring(err))
    return
  end
  installed.scenario = true
end

return unitlimits
