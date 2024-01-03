local Utils = require("Utils")

---@class Freemaker.FileSystem
local FileSystem = {}

---@param path string
---@param mode openmode
---@return file*?
function FileSystem.OpenFile(path, mode)
	return io.open(path, mode)
end

---@return string
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

---@return string
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

---@param path string
---@return string[]
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

---@param path string
---@return string[]
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

---@param path string
---@return boolean
function FileSystem.CreateFolder(path)
	local success = os.execute("mkdir \"" .. path .. "\"")
	return success or false
end

---@param path string
---@return boolean
function FileSystem.CreateFile(path)
	local file = FileSystem.OpenFile(path, "w")
	if not file then
		return false
	end

	file:write("")
	file:close()

	return true
end

---@param path string
---@return boolean
function FileSystem.Exists(path)
	return os.rename(path, path)
end

return FileSystem
