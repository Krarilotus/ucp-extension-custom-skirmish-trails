-- Run from the module root with Lua 5.4.
local patches = require("customskirmishtrails.patches")
local counterSetup = 0x1000 + 0x93
local buffer = 0x2000
local budgets = {}
local installed = false
core = {
  AOBScan = function() return 0x1000 end,
  allocate = function(size)
    assert(size == 12)
    return buffer
  end,
  readBytes = function(address, size)
    assert(address == counterSetup)
    local bytes = { 0xBA, 3, 0, 0, 0, 0x89, 0x15, 0, 0, 0, 0,
      0x75, 0x2A, 0x8B, 0x0D, 0, 0, 0, 0, 0x33, 0xC0 }
    assert(size <= #bytes)
    return bytes
  end,
  writeInteger = function(address, value) budgets[address] = value end,
  itob = function(value) assert(value == buffer); return { 0, 0x20, 0, 0 } end,
  relTo = function(label) assert(label == "done"); return { 0, 0, 0, 0 } end,
  insertCode = function(address, size, code)
    assert(address == counterSetup and size == 5)
    assert(code[1] == 0x9C and code[#code] == 0x9D)
    installed = true
  end,
}
patches.setChickenBudgets({})
assert(not installed)
patches.setChickenBudgets({ [0] = 0, [2] = 7 })
assert(installed)
assert(budgets[buffer] == 0 and budgets[buffer + 4] == 3 and budgets[buffer + 8] == 7)
