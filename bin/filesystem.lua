local __fileFuncs__ = {}
    local __cache__ = {}
    local function __loadFile__(module)
        if not __cache__[module] then
            __cache__[module] = { __fileFuncs__[module]() }
        end
        return table.unpack(__cache__[module])
    end
    __fileFuncs__["__main__"] = function()
    local FileSystem = {}
    function FileSystem.OpenFile(path, mode)
    	return io.open(path, mode)
    end
    function FileSystem.GetCurrentDirectory()
    	local source = debug.getinfo(2, 'S').source:gsub('\\', '/'):gsub('@', '')
    	local slashPos = source:reverse():find('/')
    	if not slashPos then
    		return ""
    	end
    	local length = source:len()
    	local currentPath = source:sub(0, length - slashPos)
    	return currentPath
    end
    function FileSystem.GetCurrentWorkingDirectory()
    	local cmd = io.popen("cd")
    	if not cmd then
    		error("unable to get current directory")
    	end
    	local path = ""
    	for line in cmd:lines() do
    		if line ~= "" then
    			path = path .. line
    		end
    	end
    	cmd:close()
    	return path
    end
    function FileSystem.GetDirectories(path)
    	local command = 'dir "' .. path .. '" /ad /b'
    	local result = io.popen(command)
    	if not result then
    		error('unable to run command: ' .. command)
    	end
    	---@type string[]
    	local children = {}
    	for line in result:lines() do
    		table.insert(children, line)
    	end
    	return children
    end
    function FileSystem.GetFiles(path)
    	local command = 'dir "' .. path .. '" /a-d /b'
    	local result = io.popen(command)
    	if not result then
    		error('unable to run command: ' .. command)
    	end
    	---@type string[]
    	local children = {}
    	for line in result:lines() do
    		table.insert(children, line)
    	end
    	return children
    end
    function FileSystem.CreateFolder(path)
    	local success = os.execute("mkdir \"" .. path .. "\"")
    	return success or false
    end
    function FileSystem.CreateFile(path)
    	local file = FileSystem.OpenFile(path, "w")
    	if not file then
    		return false
    	end
    	file:write("")
    	file:close()
    	return true
    end
    function FileSystem.Exists(path)
    	return os.rename(path, path)
    end
    return FileSystem
end

return __fileFuncs__["__main__"]() --[[@as Freemaker.FileSystem]]
