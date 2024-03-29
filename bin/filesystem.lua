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
	local command = 'dir "' .. path .. '" /ad /b /on'
	local result = io.popen(command)
	if not result then
		error('unable to run command: ' .. command)
	end
	---@type string[]
	local children = {}
	for line in result:lines() do
		children[line] = 0
	end
	return children
end

---@param path string
---@return string[]
function FileSystem.GetFiles(path)
	local command = 'dir "' .. path .. '" /a-d /b /on'
	local result = io.popen(command)
	if not result then
		error('unable to run command: ' .. command)
	end
	---@type string[]
	local children = {}
	for line in result:lines() do
		children[line] = 0
	end
	return children
end

---@param path string
---@return boolean
function FileSystem.CreateDirectory(path)
	if FileSystem.Exists(path) then
		return true
	end

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
	local ok, err, code = os.rename(path, path)
	if not ok then
		if code == 13 then
			-- Permission denied, but it exists
			return true
		end
	end
	return ok or false
end

local filesystem = package.loadlib(FileSystem.GetCurrentDirectory() .. "/../filesystem/bin/freemaker_filesystem.dll",
	"luaopen_filesystem")
if filesystem then
	for key, value in pairs(filesystem()) do
		FileSystem[key] = value
	end
end

return FileSystem
