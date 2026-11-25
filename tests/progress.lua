package.path = (MODULE_DIR or ".") .. "/?.lua;" .. package.path

local files, memoryWrites = {}, {}
local onWin, afterInit
local trail = "warchestTrail"
local path = "progress-warchestTrail-normal.txt"

package.loaded["customskirmishtrails.memory"] = { TRAIL_PROGRESS_ADDRESSES = { [trail] = 200 } }
package.loaded["customskirmishtrails.patches"] = {
  siteAddress = function(site)
    assert(site.fn == "win" and site.offset == 0x2F7)
    return 100
  end,
  luaStub = function(callback)
    onWin = callback
    return 400
  end,
}
package.loaded["customskirmishtrails.storage"] = {
  write = function(name, contents)
    files[name] = contents
    return true
  end,
  read = function(name) return files[name] end,
}
core = {
  readInteger = function(address)
    assert(address == 104)
    return 300
  end,
  writeInteger = function(address, value) memoryWrites[address] = value end,
  callTo = function(address) return address end,
  insertCode = function(address, size, code, returnTo, original)
    assert(address == 103 and size == 5 and code[2] == 400 and original == "after")
  end,
}
hooks = { registerHookCallback = function(name, callback)
  assert(name == "afterInit")
  afterInit = callback
end }

local progress = require("customskirmishtrails.progress")
progress.install(trail, path, 3)
afterInit()
assert(memoryWrites[300] == 0 and memoryWrites[200] == 0)
local registers = { EAX = 3 }
assert(onWin(registers) == registers)
assert(files[path] == "3\n")
afterInit()
assert(memoryWrites[300] == 3 and memoryWrites[200] == 2)
progress.install(trail, "progress-warchestTrail-hard.txt", 3)
afterInit()
assert(memoryWrites[300] == 0 and memoryWrites[200] == 0)
onWin({ EAX = 4 })
assert(files["progress-warchestTrail-hard.txt"] == nil)
assert(files[path] == "3\n")
print("progress: passed")
