local FileSystem, err = package.loadlib("C:\\Coding\\Lua\\Utils\\fileSystem\\cmake-build-release\\libfilesystem.dll", "luaopen_libfilesystem")
print(FileSystem, err)
print(FileSystem.GetCurrentDirectory())
