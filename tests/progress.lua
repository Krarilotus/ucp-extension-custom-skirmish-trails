package.path = (MODULE_DIR or ".") .. "/?.lua;" .. package.path

local files, memoryWrites = {}, {}
local onWin, afterInit
local trail = "warchestTrail"
local path = "ucp/custom-skirmish-trails-progress-warchestTrail-normal.txt"

package.loaded["customskirmishtrails.memory"] = { TRAIL_PROGRESS_ADDRESSES = { [trail] = 200 } }
package.loaded["customskirmishtrails.patches"] = { siteAddress = function(site)
  assert(site.fn == "win" and site.offset == 0x2F7)
  return 100
end }
package.loaded["customskirmishtrails.winfiles"] = { writeFile = function(name, contents)
  files[name] = contents
  return true
end }
core = {
  readInteger = function(address)
    assert(address == 104)
    return 300
  end,
  writeInteger = function(address, value) memoryWrites[address] = value end,
  detourCode = function(callback, address, size)
    assert(address == 103 and size == 5)
    onWin = callback
  end,
}
hooks = { registerHookCallback = function(name, callback)
  assert(name == "afterInit")
  afterInit = callback
end }
io.open = function(name)
  if files[name] then
    return { read = function() return files[name] end, close = function() end }
  end
end

local progress = require("customskirmishtrails.progress")
progress.install(trail, "normal", 3)
afterInit()
assert(memoryWrites[300] == 0 and memoryWrites[200] == 0)
local registers = { EAX = 3 }
assert(onWin(registers) == registers)
assert(files[path] == "3\n")
afterInit()
assert(memoryWrites[300] == 3 and memoryWrites[200] == 2)
progress.install(trail, "hard", 3)
afterInit()
assert(memoryWrites[300] == 0 and memoryWrites[200] == 0)
onWin({ EAX = 4 })
assert(files["ucp/custom-skirmish-trails-progress-warchestTrail-hard.txt"] == nil)
assert(files[path] == "3\n")
print("progress: passed")
