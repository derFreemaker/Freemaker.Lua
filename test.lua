local filesystem = require("bin.filesystem")

print(filesystem.Exists("C:/Coding/Lua/Utils/test.lua"))
print(filesystem.GetCurrentWorkingDirectory())

print("# Directories")
local dirs = filesystem.GetDirectories("C:/Coding/Lua/Utils")
for dir in pairs(dirs) do
    print(dir)
end

print("# Files")
local files = filesystem.GetFiles("C:/Coding/Lua/Utils")
for file in pairs(files) do
    print(file)
end