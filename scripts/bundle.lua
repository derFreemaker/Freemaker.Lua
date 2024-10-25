local workspace_dir = ({...})[1]
local bin_dir = workspace_dir .. "/bin"

print("\nbundling bundle...")
os.execute("cd " .. workspace_dir .. " && lua src/bundle.lua -o bin/bundle.lua src/bundle.lua -I" .. workspace_dir .. " -I" .. bin_dir)

print("\nbundling utils...")
os.execute("cd " .. workspace_dir .. " && lua src/bundle.lua -o bin/utils.lua -t Freemaker.utils src/utils/init.lua -I" .. workspace_dir .. " -I" .. bin_dir)

print("\nbundling path...")
os.execute("cd " .. workspace_dir .. " && lua src/bundle.lua -o bin/path.lua -t Freemaker.file-system.path src/path.lua -I" .. workspace_dir .. " -I" .. bin_dir)
