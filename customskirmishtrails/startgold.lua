-- Start gold per player: the game's own start gold (its skirmish value for the mission's
-- advantage and start mode), or the mission's gold_player_1 .. gold_player_8 where it has one.
-- The trail briefing shows the same: the human player's gold and, when the mission gives an AI
-- player its own gold, one value per AI player.

local memory = require('customskirmishtrails.memory')
local patches = require('customskirmishtrails.patches')

local startgold = {}

-- The briefing's gold lines: each reads the game's gold table and applies the trail's factor
-- ("mov eax, [edx*8 + table]", "imul eax, esi"); the AI line then draws it ("push eax",
-- "mov ecx, text", "call number"). The AI line's label just before is drawn by the game's
-- text routine ("call text").
local HUMAN_SITE = { fn = "brief", offset = 0x3B2, bytes = "8B 04 D5 ? ? ? ? 0F AF C6" }
local AI_SITE = { fn = "brief", offset = 0x3FC, bytes = "8B 04 D5 ? ? ? ? 0F AF C6 50 B9 ? ? ? ? E8 ? ? ? ?" }
local AI_LABEL_CALL_SITE = { fn = "brief", offset = 0x368, bytes = "E8 ? ? ? ?" }
local GAME_VALUE_SIZE = 10
local AI_SITE_SIZE = 21
local AI_TEXT_SIZE = 128

---The mission's own start gold for a player slot (1 is the human player), or nil.
local function gold(entry, player)
  return entry ~= nil and math.tointeger(tonumber(entry[string.format("gold_player_%d", player)])) or nil
end

local function hasAi(entry, player)
  local value = entry["player" .. player]
  return value ~= nil and value ~= "" and tonumber(value) ~= 0
end

---The AI players' gold as the briefing shows it ("4000 / 3000 / 4000"), or nil when the mission
---gives no AI player its own gold.
local function aiGoldText(entry, gameValue)
  if entry == nil then
    return nil
  end
  local players = math.min(math.tointeger(tonumber(entry.num_players)) or 8, 8)
  local values, own = {}, false
  for player = 2, players do
    if hasAi(entry, player) then
      local value = gold(entry, player)
      own = own or value ~= nil
      table.insert(values, tostring(value or gameValue))
    end
  end
  return own and table.concat(values, " / ") or nil
end

local function showInBriefing()
  local human = patches.siteAddress(HUMAN_SITE, "the human player's gold in the briefing")
  local ai = patches.siteAddress(AI_SITE, "the AI players' gold in the briefing")
  local label = patches.siteAddress(AI_LABEL_CALL_SITE, "the AI players' gold in the briefing")
  if human == nil or ai == nil or label == nil then
    return
  end
  local textObject = core.readInteger(ai + 11)
  local drawNumber = ai + AI_SITE_SIZE + core.readInteger(ai + 17)
  local drawText = label + 5 + core.readInteger(label + 1)
  local gameValue = {}
  for index, byte in ipairs(core.readBytes(ai, GAME_VALUE_SIZE)) do
    gameValue[index] = byte & 0xFF
  end
  local aiText = core.allocate(AI_TEXT_SIZE, true)
  local shownText = nil

  -- EAX: the game's value; it becomes the mission's own value
  local humanStub = patches.luaStub(function(registers)
    local value = gold(memory.currentEntry(), 1)
    if value ~= nil then
      registers.EAX = value
    end
    return registers
  end)
  -- EAX: the game's value; EDX becomes the text to draw instead, or 0
  local aiStub = patches.luaStub(function(registers)
    local text = aiGoldText(memory.currentEntry(), registers.EAX)
    if text ~= nil and text ~= shownText then
      core.writeString(aiText, text:sub(1, AI_TEXT_SIZE - 1))
      shownText = text
    end
    registers.EDX = text ~= nil and aiText or 0
    return registers
  end)

  patches.guarded({ { address = human, size = GAME_VALUE_SIZE }, { address = ai, size = AI_SITE_SIZE } }, function()
    core.insertCode(human, GAME_VALUE_SIZE, { core.callTo(humanStub) }, nil, "before")
    core.insertCode(ai, AI_SITE_SIZE, {
      gameValue,
      core.callTo(aiStub),
      0x50,                                -- push eax
      0x85, 0xD2,                          -- test edx, edx
      0x74, core.byteRelTo("number", -1),  -- jz number
      0x89, 0x14, 0x24,                    -- mov [esp], edx
      0xB9, core.itob(textObject),         -- mov ecx, text
      core.callTo(drawText),
      0xEB, core.byteRelTo("done", -1),    -- jmp done
      "number",
      0xB9, core.itob(textObject),         -- mov ecx, text
      core.callTo(drawNumber),
      "done",
    })
  end)
end

function startgold.enable()
  -- every player's start gold as the game sets up a skirmish (EBX: the player's slot)
  local detourAddress, detourSize = core.AOBScan("89 86 00 E4 FF FF"), 6
  core.detourCode(function(registers)
    local entry, isTrail = memory.currentEntry()
    local value = isTrail and gold(entry, registers.EBX) or nil
    if value ~= nil then
      log(VERBOSE, string.format("startgold: player %d gets %d gold", registers.EBX, value))
      registers.EAX = value
    end
    return registers
  end, detourAddress, detourSize)

  local ok, err = pcall(showInBriefing)
  if not ok then
    log(WARNING, "custom-skirmish-trails: the briefing shows the game's gold: " .. tostring(err))
  end
end

return startgold
