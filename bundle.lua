print("\nbundling bundle...")
os.execute("lua src/bundle.lua -o bin/bundle.lua -Ibin src/bundle.lua")

print("\nbundling utils...")
os.execute("lua src/bundle.lua -o bin/utils.lua -t Freemaker.utils -Ibin src/utils/init.lua")

print("\nbundling path...")
os.execute("lua src/bundle.lua -o bin/path.lua -t Freemaker.file-system.path -Ibin src/path.lua")
