
local _, pColorArray = utils.AOBExtract("8B ? ? I(? ? ? ?) 6A 13 6A 00 51")
local _, pTextManagerObj = utils.AOBExtract("8B ? I(? ? ? ?) A1 ? ? ? ? 52 8D 54 01 0A")

local renderFunc = core.AOBScan("8B 44 24 20 8B 54 24 18 53")

local placeholderAddress = core.allocate(100)
core.writeString(placeholderAddress, "[placeholder]")

local LINE_CAPACITY = 1000
local textLines = {
  core.allocate(LINE_CAPACITY, true),
  core.allocate(LINE_CAPACITY, true),
  core.allocate(LINE_CAPACITY, true),
  core.allocate(LINE_CAPACITY, true),
  core.allocate(LINE_CAPACITY, true),
  core.allocate(LINE_CAPACITY, true),
  core.allocate(LINE_CAPACITY, true),
  core.allocate(LINE_CAPACITY, true),
}

---Writes `text` in the game's text encoding (textResourceModifier) into the `capacity` bytes at
---`address`, cut to fit.
local function writeGameText(address, capacity, text)
  local transformed = modules.textResourceModifier:TransformText(text)
  local bounded = transformed:match("^[^%z]*"):sub(1, capacity - 1)
  core.writeString(address, bounded)
  core.writeByte(address + #bounded, 0)
end

local function genRenderText(address, xOffset, yOffset)
  return core.AssemblyLambda([[
    pushad
    
    push 0
    push 0
    push 0x12
    push 0
    mov edx, dword [pColorArray]
    push edx
    push 0
    add eax, yOffset
    push eax
    add ecx, xOffset
    push ecx
    
    mov ecx, stringAddress
    push ecx
    mov ecx, pTextManagerObj
    call func
    
    popad
  ]], {
    func = renderFunc,
    stringAddress = address or placeholderAddress,
    pColorArray = pColorArray,
    pTextManagerObj = pTextManagerObj,
    yOffset = 0x04 + (yOffset or 0),
    xOffset = 0x100 + (xOffset or 0),
  })
end



return {
  enable = function()
    local codes = {}
    for line, addr in pairs(textLines) do
      table.insert(codes, genRenderText(addr, 0, 0x16 * (line - 1)))
    end
    core.insertCode(core.AOBScan("8D A4 24 00 00 00 00 83 FD 01"), 7, codes, nil, 'after')
  end,
  setText = function(line, text)
    local address = textLines[line]
    if address == nil or type(text) ~= "string" then return end
    writeGameText(address, LINE_CAPACITY, text)
  end,
  writeGameText = writeGameText,
  getText = function(line)
    local address = textLines[line]
    return address and core.readString(address) or nil
  end,
}
