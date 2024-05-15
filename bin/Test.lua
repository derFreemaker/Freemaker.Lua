local filesystem = package.loadlib("C:/Coding/Lua/Utils/bin/fileSystem.dll", "luaopen_filesystem")

for key, value in pairs(filesystem) do
    print(key, value)
end