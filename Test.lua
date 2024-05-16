local FileSystem, err = package.loadlib("C:\\Coding\\Lua\\Utils\\fileSystem\\cmake-build-release\\libfilesystem.dll", "luaopen_libfilesystem", "returnerror")
print(FileSystem.GetCurrentDirectory())