---@diagnostic disable

	local __fileFuncs__ = {}
	local __cache__ = {}
	local function __loadFile__(module)
	    if not __cache__[module] then
	        __cache__[module] = { __fileFuncs__[module]() }
	    end
	    return table.unpack(__cache__[module])
	end
	__fileFuncs__["src.Utils.String"] = function()
	---@class Freemaker.Utils.String
	local String = {}

	---@param str string
	---@param pattern string
	---@param plain boolean?
	---@return string?, integer
	local function findNext(str, pattern, plain)
	    local found = str:find(pattern, 0, plain or false)
	    if found == nil then
	        return nil, 0
	    end
	    return str:sub(0, found - 1), found - 1
	end

	---@param str string?
	---@param sep string?
	---@param plain boolean?
	---@return string[]
	function String.Split(str, sep, plain)
	    if str == nil then
	        return {}
	    end

	    local strLen = str:len()
	    local sepLen

	    if sep == nil then
	        sep = "%s"
	        sepLen = 2
	    else
	        sepLen = sep:len()
	    end

	    local tbl = {}
	    local i = 0
	    while true do
	        i = i + 1
	        local foundStr, foundPos = findNext(str, sep, plain)

	        if foundStr == nil then
	            tbl[i] = str
	            return tbl
	        end

	        tbl[i] = foundStr
	        str = str:sub(foundPos + sepLen + 1, strLen)
	    end
	end

	---@param str string?
	---@return boolean
	function String.IsNilOrEmpty(str)
	    if str == nil then
	        return true
	    end
	    if str == "" then
	        return true
	    end
	    return false
	end

	---@param array string[]
	---@param sep string
	---@return string
	function String.Join(array, sep)
	    local str = ""

	    str = array[1]
	    for _, value in next, array, 1 do
	        str = str .. sep .. value
	    end

	    return str
	end

	return String

end

__fileFuncs__["src.Utils.Table"] = function()
	---@class Freemaker.Utils.Table
	local Table = {}

	---@param obj table?
	---@param seen table[]
	---@return table?
	local function copyTable(obj, copy, seen)
	    if obj == nil then return nil end
	    if seen[obj] then return seen[obj] end

	    seen[obj] = copy
	    setmetatable(copy, copyTable(getmetatable(obj), {}, seen))

	    for key, value in next, obj, nil do
	        key = (type(key) == "table") and copyTable(key, {}, seen) or key
	        value = (type(value) == "table") and copyTable(value, {}, seen) or value
	        rawset(copy, key, value)
	    end

	    return copy
	end

	---@generic TTable
	---@param t TTable
	---@return TTable table
	function Table.Copy(t)
	    return copyTable(t, {}, {})
	end

	---@param from table
	---@param to table
	function Table.CopyTo(from, to)
	    copyTable(from, to, {})
	end

	---@param t table
	---@param ignoreProperties string[]?
	function Table.Clear(t, ignoreProperties)
	    if not ignoreProperties then
	        ignoreProperties = {}
	    end
	    for key, _ in next, t, nil do
	        if not Table.Contains(ignoreProperties, key) then
	            t[key] = nil
	        end
	    end
	    setmetatable(t, nil)
	end

	---@param t table
	---@param value any
	---@return boolean
	function Table.Contains(t, value)
	    for _, tValue in pairs(t) do
	        if value == tValue then
	            return true
	        end
	    end
	    return false
	end

	---@param t table
	---@param key any
	---@return boolean
	function Table.ContainsKey(t, key)
	    if t[key] ~= nil then
	        return true
	    end
	    return false
	end

	--- removes all spaces between
	---@param t any[]
	function Table.Clean(t)
	    for key, value in pairs(t) do
	        for i = key - 1, 1, -1 do
	            if key ~= 1 then
	                if t[i] == nil and (t[i - 1] ~= nil or i == 1) then
	                    t[i] = value
	                    t[key] = nil
	                    break
	                end
	            end
	        end
	    end
	end

	---@param t table
	---@return integer count
	function Table.Count(t)
	    local count = 0
	    for _, _ in next, t, nil do
	        count = count + 1
	    end
	    return count
	end

	---@param t table
	---@return table
	function Table.Invert(t)
	    local inverted = {}
	    for key, value in pairs(t) do
	        inverted[value] = key
	    end
	    return inverted
	end

	return Table

end

__fileFuncs__["src.Utils.Value"] = function()
	local Table = __loadFile__("src.Utils.Table")

	---@class Freemaker.Utils.Value
	local Value = {}

	---@generic T
	---@param value T
	---@return T
	function Value.Copy(value)
	    local typeStr = type(value)

	    if typeStr == "table" then
	        return Table.Copy(value)
	    end

	    return value
	end

	return Value

end

__fileFuncs__["src.Utils"] = function()
	---@class Freemaker.Utils
	---@field String Freemaker.Utils.String
	---@field Table Freemaker.Utils.Table
	---@field Value Freemaker.Utils.Value
	local Utils = {}

	Utils.String = __loadFile__("src.Utils.String")
	Utils.Table = __loadFile__("src.Utils.Table")
	Utils.Value = __loadFile__("src.Utils.Value")

	return Utils

end

__fileFuncs__["src.FileSystem"] = function()
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
			table.insert(children, line)
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
			table.insert(children, line)
		end
		return children
	end

	---@param path string
	---@return boolean
	function FileSystem.CreateFolder(path)
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
		return ok
	end

	return FileSystem

end

__fileFuncs__["__main__"] = function()
	local Utils = __loadFile__("src.Utils")
	local FileSystem = __loadFile__("src.FileSystem")

	---@param str string
	---@return string str
	local function formatStr(str)
	    str = str:gsub("\\", "/")
	    return str
	end

	---@class Freemaker.FileSystem.Path
	---@field private m_nodes string[]
	local Path = {}

	---@param str string
	---@return boolean isNode
	function Path.IsNode(str)
	    if str:find("/") then
	        return false
	    end

	    return true
	end

	---@package
	---@param pathOrNodes string | string[] | nil
	---@return Freemaker.FileSystem.Path
	function Path.new(pathOrNodes)
	    local instance = {}
	    if not pathOrNodes then
	        instance.m_nodes = {}
	        return setmetatable(instance, { __index = Path })
	    end

	    if type(pathOrNodes) == "string" then
	        pathOrNodes = formatStr(pathOrNodes)
	        pathOrNodes = Utils.String.Split(pathOrNodes, "/")
	    end

	    local length = #pathOrNodes
	    local node = pathOrNodes[length]
	    if node and node ~= "" and not node:find("^.+%..+$") then
	        pathOrNodes[length + 1] = ""
	    end

	    instance.m_nodes = pathOrNodes
	    instance = setmetatable(instance, { __index = Path })

	    return instance
	end

	---@return string path
	function Path:ToString()
	    self:Normalize()
	    return Utils.String.Join(self.m_nodes, "/")
	end

	---@return boolean
	function Path:IsEmpty()
	    return #self.m_nodes == 0 or (#self.m_nodes == 2 and self.m_nodes[1] == "" and self.m_nodes[2] == "")
	end

	---@return boolean
	function Path:IsFile()
	    return self.m_nodes[#self.m_nodes] ~= ""
	end

	---@return boolean
	function Path:IsDir()
	    return self.m_nodes[#self.m_nodes] == ""
	end

	function Path:Exists()
	    return FileSystem.Exists(self:ToString())
	end

	---@return boolean
	function Path:Create()
	    if self:Exists() then
	        return true
	    end

	    if self:IsDir() then
	        return FileSystem.CreateFolder(self:ToString())
	    elseif self:IsFile() then
	        return FileSystem.CreateFile(self:ToString())
	    end

	    return false
	end

	---@return boolean
	function Path:IsAbsolute()
	    if #self.m_nodes == 0 then
	        return false
	    end

	    if self.m_nodes[1] == "" then
	        return true
	    end

	    if self.m_nodes[1]:find(":", nil, true) then
	        return true
	    end

	    return false
	end

	---@return Freemaker.FileSystem.Path
	function Path:Absolute()
	    local copy = Utils.Table.Copy(self.m_nodes)

	    for i = 1, #copy, 1 do
	        copy[i] = copy[i + 1]
	    end

	    return Path.new(copy)
	end

	---@return boolean
	function Path:IsRelative()
	    if #self.m_nodes == 0 then
	        return false
	    end

	    return self.m_nodes[1] ~= "" and not (self.m_nodes[1]:find(":", nil, true))
	end

	---@return Freemaker.FileSystem.Path
	function Path:Relative()
	    local copy = {}

	    if self.m_nodes[1] ~= "" then
	        copy[1] = ""
	        for i = 1, #self.m_nodes, 1 do
	            copy[i + 1] = self.m_nodes[i]
	        end
	    end

	    return Path.new(copy)
	end

	---@return string
	function Path:GetParentFolder()
	    local copy = Utils.Table.Copy(self.m_nodes)
	    local length = #copy

	    if length > 0 then
	        if length > 1 and copy[length] == "" then
	            copy[length] = nil
	            copy[length - 1] = ""
	        else
	            copy[length] = nil
	        end
	    end

	    return Utils.String.Join(copy, "/")
	end

	---@return Freemaker.FileSystem.Path
	function Path:GetParentFolderPath()
	    local copy = self:Copy()
	    local length = #copy.m_nodes

	    if length > 0 then
	        if length > 1 and copy.m_nodes[length] == "" then
	            copy.m_nodes[length] = nil
	            copy.m_nodes[length - 1] = ""
	        else
	            copy.m_nodes[length] = nil
	        end
	    end

	    return copy
	end

	---@return string fileName
	function Path:GetFileName()
	    if not self:IsFile() then
	        error("path is not a file: " .. self:ToString())
	    end

	    return self.m_nodes[#self.m_nodes]
	end

	---@return string fileExtension
	function Path:GetFileExtension()
	    if not self:IsFile() then
	        error("path is not a file: " .. self:ToString())
	    end

	    local fileName = self.m_nodes[#self.m_nodes]

	    local _, _, extension = fileName:find("^.+(%..+)$")
	    return extension
	end

	---@return string fileStem
	function Path:GetFileStem()
	    if not self:IsFile() then
	        error("path is not a file: " .. self:ToString())
	    end

	    local fileName = self.m_nodes[#self.m_nodes]

	    local _, _, stem = fileName:find("^(.+)%..+$")
	    return stem
	end

	---@return string folderName
	function Path:GetDirectoryName()
	    if not self:IsDir() then
	        error("path is not a directory: " .. self:ToString())
	    end

	    if #self.m_nodes < 2 then
	        error("path is empty")
	    end

	    return self.m_nodes[#self.m_nodes - 1]
	end

	---@return Freemaker.FileSystem.Path
	function Path:Normalize()
	    ---@type string[]
	    local newNodes = {}

	    for index, value in ipairs(self.m_nodes) do
	        if value == "." then
	        elseif value == "" then
	            if index == 1 or index == #self.m_nodes then
	                newNodes[#newNodes + 1] = ""
	            end
	        elseif value == ".." then
	            if index ~= 1 then
	                newNodes[#newNodes] = nil
	            end
	        else
	            newNodes[#newNodes + 1] = value
	        end
	    end

	    if newNodes[1] then
	        newNodes[1] = newNodes[1]:gsub("@", "")
	    end

	    self.m_nodes = newNodes
	    return self
	end

	---@param path string
	---@return Freemaker.FileSystem.Path
	function Path:Append(path)
	    if self.m_nodes[#self.m_nodes] == "" then
	        self.m_nodes[#self.m_nodes] = nil
	    end

	    path = formatStr(path)
	    local newNodes = Utils.String.Split(path, "/")

	    for _, value in ipairs(newNodes) do
	        self.m_nodes[#self.m_nodes + 1] = value
	    end

	    if self.m_nodes[#self.m_nodes] ~= "" and not self.m_nodes[#self.m_nodes]:find("^.+%..+$") then
	        self.m_nodes[#self.m_nodes + 1] = ""
	    end

	    self:Normalize()

	    return self
	end

	---@param path string
	---@return Freemaker.FileSystem.Path
	function Path:Extend(path)
	    local copy = self:Copy()
	    return copy:Append(path)
	end

	---@return Freemaker.FileSystem.Path
	function Path:Copy()
	    local copyNodes = Utils.Table.Copy(self.m_nodes)
	    return Path.new(copyNodes)
	end

	return Path

end

---@type Freemaker.FileSystem.Path
local main = __fileFuncs__["__main__"]()
return main
