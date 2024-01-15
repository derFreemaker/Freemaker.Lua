print("\nbundling bundle...")
os.execute("lua src/bundle.lua -o bin/bundle.lua src/bundle.lua")

print("\nbundling utils...")
os.execute("lua src/bundle.lua -o bin/utils.lua -t Freemaker.Utils src/utils/init.lua")

print("\nbundling filesystem...")
os.execute("lua src/bundle.lua -o bin/filesystem.lua -t Freemaker.FileSystem src/filesystem.lua")

print("\nbundling path...")
os.execute("lua src/bundle.lua -o bin/path.lua -t Freemaker.FileSystem.Path src/path.lua")
