-- Troop limits per trail mission and difficulty (unit_limit). The game computes the player's
-- troop limit every tick in one function: in single-player games (custom scenarios) it is 10000,
-- otherwise base / living lords - offset (base 2400 in Crusader, 9900 in Extreme, offset 40). A
-- mission's policy replaces the stored value while that mission is played:
--   native               the game's own value
--   formula BASE OFFSET  BASE / living lords - OFFSET ("formula 2400 40" = Crusader limits)
-- The result never exceeds the game's own formula value, so the unit pool can't fill up. The value
-- follows from the game state each tick (the mission being played, the living lords) and the
-- difficulty option, so saving, loading and replays give the same limit, and it goes back to the
-- game's own value when the mission ends.
--
-- The function is found by AOB, the same in both 1.41 executables, with the operands decoded.
-- Single-player games go through the game's own counting part only while trail data has a
-- policy; then the stored value is set here every tick.

local patches = require("customskirmishtrails.patches")

local unitlimits = {}

-- "cmp dword [syncMode], 0 / jne count / mov dword [ecx + limit], 10000 / ret / push esi ..."
local ENTRY_AOB = "83 3D I(? ? ? ?) 00 75 0B C7 81 I(? ? ? ?) I(? ? ? ?) C3 56 57 33 F6"
-- "mov eax, base / cdq / idiv esi / pop edi / pop esi / sub eax, offset / mov [ecx + limit], eax / ret"
local STORE_AOB = "B8 I(? ? ? ?) 99 F7 FE 5F 5E 83 E8 ? 89 81 I(? ? ? ?) C3 5F C7 81 ? ? ? ? ? ? ? ? 5E C3"
local STORE_OFFSET = 0x0D
local ENTRY_PATCH_SIZE = 9   -- the compare (7 bytes) and the short jne (2 bytes)
local COUNT_OFFSET = 0x14    -- where the jne goes: the counting part
local MAX_LORDS = 8

local DIFFICULTIES = { story = true, normal = true, hard = true, very_hard = true }

local bindings = nil
local currentMission = nil
local difficulty = nil

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
  return nil, string.format("'%s' is not 'native' or 'formula BASE OFFSET'", text)
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

---The policy of a mission for the difficulty that is set, or nil for the game's own value.
local function policyOf(entry)
  local policies = entry and entry.unit_limit_policies or nil
  if policies == nil then
    return nil
  end
  local policy = (difficulty and policies[difficulty]) or policies.default
  if policy == nil or policy.kind == "native" then
    return nil
  end
  return policy
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
    syncMode = syncMode,
    singlePlayerValue = singlePlayerValue,
    base = base,
    offset = core.readByte(store + STORE_OFFSET - 1),
    storeSite = store + STORE_OFFSET,
  }
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

local function install(b)
  b.route = core.allocate(1, true)
  core.insertCode(b.entry, ENTRY_PATCH_SIZE, {
    0x80, 0x3D, core.itob(b.route), 0x00,               -- cmp byte [route], 0
    0x0F, 0x85, core.relTo(b.entry + COUNT_OFFSET, -4), -- jne count
    0x83, 0x3D, core.itob(b.syncMode), 0x00,            -- cmp dword [syncMode], 0
    0x0F, 0x85, core.relTo(b.entry + COUNT_OFFSET, -4), -- jne count
  })
  core.detourCode(function(registers)
    local singlePlayer = core.readInteger(b.syncMode) == 0
    local native = singlePlayer and b.singlePlayerValue or registers.EAX
    local value = native
    local ok, _, _, mission = pcall(currentMission)
    local policy = ok and policyOf(mission) or nil
    local lords = policy and livingLords(registers.EAX) or nil
    if policy ~= nil and lords ~= nil then
      local formula = registers.EAX -- the game's own formula for these lords
      value = math.max(0, math.min(policy.base // lords - policy.offset, formula))
    end
    registers.EAX = value
    return registers
  end, b.storeSite, 6)
  core.writeByte(b.route, 1)
end

---Binds the troop limit. `missionNow()` gives the trail mission being played (see
---scenario.currentMission); `level` is the difficulty option (story, normal, hard, very_hard).
function unitlimits.enable(missionNow, level)
  currentMission = missionNow
  difficulty = type(level) == "string" and level:lower() or nil
  if difficulty ~= nil and not DIFFICULTIES[difficulty] then
    log(WARNING, string.format("custom-skirmish-trails: difficulty '%s' is not story, normal, hard or very_hard", level))
    difficulty = nil
  end
  local ok, result = pcall(resolve)
  if ok then
    bindings = result
  else
    log(WARNING, "custom-skirmish-trails: unit_limit is switched off: " .. tostring(result))
  end
end

---Reads the unit_limit of every mission and installs the troop limit when one of them has a
---policy other than native. Call it after the trails' missions are loaded.
function unitlimits.apply(trails)
  local any = false
  for trailName, missions in pairs(trails) do
    for index, entry in ipairs(missions) do
      local policies, reason = unitlimits.parse(entry.unit_limit)
      if policies == nil then
        log(WARNING, string.format("custom-skirmish-trails: %s mission %d: unit_limit %s", trailName, index, reason))
        policies = {}
      end
      entry.unit_limit_policies = policies
      for _, policy in pairs(policies) do
        if policy.kind ~= "native" then any = true end
      end
    end
  end
  if not any or bindings == nil or bindings.route ~= nil then
    return
  end
  local ok, err = pcall(install, bindings)
  if not ok then
    log(WARNING, "custom-skirmish-trails: unit_limit is switched off: " .. tostring(err))
  end
end

return unitlimits
