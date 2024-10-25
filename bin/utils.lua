---@diagnostic disable

local __bundler__ = {
    __files__ = {},
    __binary_files__ = {},
    __cache__ = {},
}
function __bundler__.__get_os__()
    if package.config:sub(1, 1) == '\\' then
        return "windows"
    else
        return "linux"
    end
end
function __bundler__.__loadFile__(module)
    if not __bundler__.__cache__[module] then
        if __bundler__.__binary_files__[module] then
            local os_type = __bundler__.__get_os__()
            local file_path = os.tmpname()
            local file = io.open(file_path, "wb")
            if not file then
                error("unable to open file: " .. file_path)
            end
            local content
            if os_type == "windows" then
                content = __bundler__.__files__[module .. ".dll"]
            else
                content = __bundler__.__files__[module .. ".so"]
            end
            for i = 1, #content do
                local byte = tonumber(content[i], 16)
                file:write(string.char(byte))
            end
            file:close()
            __bundler__.__cache__[module] = { package.loadlib(file_path, "luaopen_" .. module)() }
        else
            __bundler__.__cache__[module] = { __bundler__.__files__[module]() }
        end
    end
    return table.unpack(__bundler__.__cache__[module])
end
__bundler__.__files__["src.utils.string"] = function()
	---@class Freemaker.utils.string
	local string = {}

	---@param str string
	---@param pattern string
	---@param plain boolean | nil
	---@return string | nil, integer
	local function find_next(str, pattern, plain)
	    local found = str:find(pattern, 0, plain or true)
	    if found == nil then
	        return nil, 0
	    end
	    return str:sub(0, found - 1), found - 1
	end

	---@param str string | nil
	---@param sep string | nil
	---@param plain boolean | nil
	---@return string[]
	function string.split(str, sep, plain)
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
	        local foundStr, foundPos = find_next(str, sep, plain)

	        if foundStr == nil then
	            tbl[i] = str
	            return tbl
	        end

	        tbl[i] = foundStr
	        str = str:sub(foundPos + sepLen + 1, strLen)
	    end
	end

	---@param str string | nil
	---@return boolean
	function string.is_nil_or_empty(str)
	    if str == nil then
	        return true
	    end
	    if str == "" then
	        return true
	    end
	    return false
	end

	return string

end

__bundler__.__files__["src.utils.table"] = function()
	---@class Freemaker.utils.table
	local table = {}

	---@param t table
	---@param copy table
	---@param seen table<table, table>
	local function copy_table_to(t, copy, seen)
	    if seen[t] then
	        return seen[t]
	    end

	    seen[t] = copy

	    for key, value in next, t do
	        if type(value) == "table" then
	            if type(copy[key]) ~= "table" then
	                copy[key] = {}
	            end
	            copy_table_to(value, copy[key], seen)
	        else
	            copy[key] = value
	        end
	    end

	    local t_meta = getmetatable(t)
	    if t_meta then
	        local copy_meta = getmetatable(copy) or {}
	        copy_table_to(t_meta, copy_meta, seen)
	        setmetatable(copy, copy_meta)
	    end
	end

	---@generic T
	---@param t T
	---@return T table
	function table.copy(t)
	    local copy = {}
	    copy_table_to(t, copy, {})
	    return copy
	end

	---@generic T
	---@param from T
	---@param to T
	function table.copy_to(from, to)
	    copy_table_to(from, to, {})
	end

	---@param t table
	---@param ignoreProperties string[] | nil
	function table.clear(t, ignoreProperties)
	    if not ignoreProperties then
	        for key, _ in next, t, nil do
	            t[key] = nil
	        end
	    else
	        for key, _ in next, t, nil do
	            if not table.contains(ignoreProperties, key) then
	                t[key] = nil
	            end
	        end
	    end

	    setmetatable(t, nil)
	end

	---@param t table
	---@param value any
	---@return boolean
	function table.contains(t, value)
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
	function table.contains_key(t, key)
	    if t[key] ~= nil then
	        return true
	    end
	    return false
	end

	--- removes all spaces between
	---@param t any[]
	function table.clean(t)
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
	function table.count(t)
	    local count = 0
	    for _, _ in next, t, nil do
	        count = count + 1
	    end
	    return count
	end

	---@param t table
	---@return table
	function table.invert(t)
	    local inverted = {}
	    for key, value in pairs(t) do
	        inverted[value] = key
	    end
	    return inverted
	end

	---@generic T
	---@generic R
	---@param t T[]
	---@param func fun(value: T) : R
	---@return R[]
	function table.map(t, func)
	    ---@type any[]
	    local result = {}
	    for index, value in ipairs(t) do
	        result[index] = func(value)
	    end
	    return result
	end

	---@generic T
	---@param t T
	---@return T
	function table.readonly(t)
	    return setmetatable({}, {
	        __newindex = function()
	            error("this table is readonly")
	        end,
	        __index = t
	    })
	end

	---@generic T
	---@param t T
	---@param func fun(key: any, value: any) : boolean
	---@return T
	function table.select(t, func)
	    local copy = table.copy(t)
	    for key, value in pairs(copy) do
	        if not func(key, value) then
	            copy[key] = nil
	        end
	    end
	    return copy
	end

	---@generic T
	---@param t T
	---@param func fun(key: any, value: any) : boolean
	---@return T
	function table.select_implace(t, func)
	    for key, value in pairs(t) do
	        if not func(key, value) then
	            t[key] = nil
	        end
	    end
	    return t
	end

	return table

end

__bundler__.__files__["src.utils.value"] = function()
	local table = __bundler__.__loadFile__("src.utils.table")

	---@class Freemaker.utils.value
	local value = {}

	---@generic T
	---@param value T
	---@return T
	function value.copy(value)
	    local typeStr = type(value)

	    if typeStr == "table" then
	        return table.Copy(value)
	    end

	    return value
	end

	return value

end

__bundler__.__files__["__main__"] = function()
	---@class Freemaker.utils
	---@field string Freemaker.utils.string
	---@field table Freemaker.utils.table
	---@field value Freemaker.utils.value
	local utils = {}

	utils.string = __bundler__.__loadFile__("src.utils.string")
	utils.table = __bundler__.__loadFile__("src.utils.table")
	utils.value = __bundler__.__loadFile__("src.utils.value")

	return utils

end

---@type { [1]: Freemaker.utils }
local main = { __bundler__.__loadFile__("__main__") }
return table.unpack(main)
