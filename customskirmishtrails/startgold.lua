-- Start gold per player: as the game sets up a game, it queues each player's start gold, which
-- the keep pays into the treasury over the first seconds. In a skirmish mission of the trail that
-- is the game's value (the start gold table's value for the mission's advantage and start mode,
-- times 3 on an Extreme trail), or the mission's gold_player_1 .. gold_player_8 where it has one.
-- The trail briefing shows the same: the human player's gold and, when the mission gives an AI
-- player its own gold, one value per AI player, or the lowest and highest where those don't fit.
-- A scenario mission keeps the game's queued gold (the table's value, without the trail factor);
-- its briefing shows the gold scenario.briefingGold gives with that value, and no gold while that
-- isn't known.

local memory = require('customskirmishtrails.memory')
local patches = require('customskirmishtrails.patches')
local interface = require('customskirmishtrails.interface')
local menutext = require('customskirmishtrails.menutext')
local scenario = require('customskirmishtrails.scenario')

local startgold = {}

-- The briefing's gold lines: each reads the game's gold table and applies the trail's factor
-- ("mov eax, [edx*8 + table]", "imul eax, esi"), then draws it ("push eax", "mov ecx, text",
-- "call number"). The table entry is the one the game queues at the start: the briefing loads the
-- mission's advantage and start mode into the values that index it. The AI line's label just
-- before is drawn by the game's text routine ("call text").
local LINE_BYTES = "8B 04 D5 ? ? ? ? 0F AF C6 50 B9 ? ? ? ? E8 ? ? ? ?"
local HUMAN_SITE = { fn = "brief", offset = 0x3B2, bytes = LINE_BYTES }
local AI_SITE = { fn = "brief", offset = 0x3FC, bytes = LINE_BYTES }
local AI_LABEL_CALL_SITE = { fn = "brief", offset = 0x368, bytes = "E8 ? ? ? ?" }
local GAME_VALUE_SIZE = 10
local TABLE_OPERAND = 3
local LINE_SIZE = 21
local AI_TEXT_SIZE = 128
-- The AI line's coin is drawn 0x46 px right of its number. The text routine right-aligns a text
-- at x when its fourth argument is negative, so the AI players' gold text ends 8 px before the coin.
local AI_TEXT_RIGHT = 0x3E
-- The AI line's label (game text 0xF2, 8) starts 0xF8 px left of its number; both use font 0x11.
local AI_LABEL_TEXT = { 0xF2, 8 }
local AI_LABEL_LEFT = -0xF8
local AI_FONT = 0x11
local AI_TEXT_GAP = 8

---The mission's own start gold for a player slot (1 is the human player), or nil.
local function gold(entry, player)
  return entry ~= nil and math.tointeger(tonumber(entry[string.format("gold_player_%d", player)])) or nil
end

---The human player's gold as the briefing shows it (`grant`: the table's value the game queues),
---nil for the game's value, false for none.
local function humanGold(entry, grant)
  local value = scenario.briefingGold(entry, 1, grant)
  if value == nil then
    return gold(entry, 1)
  end
  return value
end

---The AI players' gold in player order (`gameValue`: the game's value, `grant`: the table's value
---the game queues), nil when the mission gives no AI player its own gold, or false when the
---briefing shows none.
local function aiGold(entry, gameValue, grant)
  if entry == nil then
    return nil
  end
  local players = math.min(math.tointeger(tonumber(entry.num_players)) or 8, 8)
  local values, own = {}, scenario.isScenario(entry)
  for player = 2, players do
    if interface.hasAi(entry, player) then
      local value = scenario.briefingGold(entry, player, grant)
      if value == false then
        return false
      end
      if value == nil then
        value = gold(entry, player)
      end
      own = own or value ~= nil
      table.insert(values, value or gameValue)
    end
  end
  if not own then
    return nil
  end
  return #values > 0 and values or false
end

---The AI players' gold as the briefing shows it: every value ("4000 / 3000 / 4000") when that
---fits between the label and the coin, else the lowest and highest ("3000 - 4000").
local function aiGoldText(textObject, values)
  local text = table.concat(values, " / ")
  local label = menutext.measure(textObject,
    modules.textResourceModifier:GetText(AI_LABEL_TEXT[1], AI_LABEL_TEXT[2]), AI_FONT)
  local width = menutext.measure(textObject, text, AI_FONT)
  if label == nil or width == nil or AI_LABEL_LEFT + label + AI_TEXT_GAP + width <= AI_TEXT_RIGHT then
    return text
  end
  local low, high = math.min(table.unpack(values)), math.max(table.unpack(values))
  return low == high and tostring(low) or string.format("%d - %d", low, high)
end

---The code that replaces the gold line at `address`: `stub` gets the game's value in EAX and the
---table index in EDX, and sets EAX to the number to draw and EDX to a text to draw instead, or 0.
local function lineCode(address, stub, drawText)
  local gameValue = {}
  for index, byte in ipairs(core.readBytes(address, GAME_VALUE_SIZE)) do
    gameValue[index] = byte & 0xFF
  end
  local textObject = core.readInteger(address + 12)
  local drawNumber = address + LINE_SIZE + core.readInteger(address + 17)
  return {
    gameValue,
    core.callTo(stub),
    0x50,                                -- push eax
    0x85, 0xD2,                          -- test edx, edx
    0x74, core.byteRelTo("number", -1),  -- jz number
    0x89, 0x14, 0x24,                    -- mov [esp], edx
    0x83, 0x44, 0x24, 0x04, AI_TEXT_RIGHT, -- add dword [esp + 4], AI_TEXT_RIGHT (x)
    0xC7, 0x44, 0x24, 0x0C, core.itob(-1), -- mov dword [esp + 12], -1 (right-aligned)
    0xB9, core.itob(textObject),         -- mov ecx, text
    core.callTo(drawText),
    0xEB, core.byteRelTo("done", -1),    -- jmp done
    "number",
    0xB9, core.itob(textObject),         -- mov ecx, text
    core.callTo(drawNumber),
    "done",
  }
end

---True when the briefing's gold lines are replaced.
local function showInBriefing()
  local human = patches.siteAddress(HUMAN_SITE, "the human player's gold in the briefing")
  local ai = patches.siteAddress(AI_SITE, "the AI players' gold in the briefing")
  local label = patches.siteAddress(AI_LABEL_CALL_SITE, "the AI players' gold in the briefing")
  if human == nil or ai == nil or label == nil then
    return false
  end
  local textObject = core.readInteger(ai + 12)
  local drawText = label + 5 + core.readInteger(label + 1)
  local aiText = core.allocate(AI_TEXT_SIZE, true)
  local noText = core.allocate(1, true)
  assert(aiText ~= nil and aiText ~= 0 and noText ~= nil and noText ~= 0, "out of memory")
  local shownValues = nil
  local humanTable, aiTable = core.readInteger(human + TABLE_OPERAND), core.readInteger(ai + TABLE_OPERAND)

  local humanStub = patches.luaStub(function(registers)
    local value = humanGold(memory.currentEntry(), core.readInteger(humanTable + 8 * registers.EDX))
    if value then
      registers.EAX = value
    end
    registers.EDX = value == false and noText or 0
    return registers
  end)
  local aiStub = patches.luaStub(function(registers)
    local values = aiGold(memory.currentEntry(), registers.EAX, core.readInteger(aiTable + 8 * registers.EDX))
    if values then
      local key = table.concat(values, " / ")
      if key ~= shownValues then
        core.writeString(aiText, aiGoldText(textObject, values):sub(1, AI_TEXT_SIZE - 1) .. "\0")
        shownValues = key
      end
    end
    registers.EDX = values and aiText or values == false and noText or 0
    return registers
  end)

  patches.guarded({ { address = human, size = LINE_SIZE }, { address = ai, size = LINE_SIZE } }, function()
    core.insertCode(human, LINE_SIZE, lineCode(human, humanStub, drawText))
    core.insertCode(ai, LINE_SIZE, lineCode(ai, aiStub, drawText))
  end)
  return true
end

---Installs the start gold and the briefing's gold lines. True when the briefing's gold lines are
---installed.
function startgold.enable()
  -- the store of each player's queued start gold as the game sets up a game (EBX: the player's
  -- slot); a scenario mission keeps the game's value
  local detourAddress = patches.find("89 86 00 E4 FF FF", "the start gold store")
  if detourAddress == nil then
    return false
  end
  core.detourCode(function(registers)
    local entry, isTrail = memory.currentEntry()
    local value = isTrail and not scenario.isScenario(entry) and gold(entry, registers.EBX) or nil
    if value ~= nil then
      registers.EAX = value
    end
    return registers
  end, detourAddress, 6)

  local ok, shown = pcall(showInBriefing)
  if not ok then
    log(WARNING, "the briefing shows the game's gold: " .. tostring(shown))
  end
  return ok and shown
end

return startgold
