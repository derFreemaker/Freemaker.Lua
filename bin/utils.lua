---@diagnostic disable

local __bundler__ = {
    __files__ = {},
    __binary_files__ = {},
    __cache__ = {},
    __temp_files__ = {},
    __org_exit__ = os.exit
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
        local tempDir = os.getenv("TEMP") or os.getenv("TMP")
            if not tempDir then
                tempDir = "/tmp"
            end
            local os_type = __bundler__.__get_os__()
            local file_path = tempDir .. os.tmpname()
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
            local content_len = content:len()
            for i = 2, content_len, 2 do
                local byte = tonumber(content:sub(i - 1, i), 16)
                file:write(string.char(byte))
            end
            file:close()
            __bundler__.__cache__[module] = { package.loadlib(file_path, "luaopen_" .. module)() }
            table.insert(__bundler__.__temp_files__, file_path)
        else
            __bundler__.__cache__[module] = { __bundler__.__files__[module]() }
        end
    end
    return table.unpack(__bundler__.__cache__[module])
end
function __bundler__.__cleanup__()
    for _, file_path in ipairs(__bundler__.__temp_files__) do
        os.remove(file_path)
    end
end
---@diagnostic disable-next-line: duplicate-set-field
function os.exit(...)
    __bundler__.__cleanup__()
    __bundler__.__org_exit__(...)
end
function __bundler__.__main__()
    local loading_thread = coroutine.create(__bundler__.__loadFile__)
    local success, items = (function(success, ...) return success, {...} end)
        (coroutine.resume(loading_thread, "__main__"))
    if not success then
        print("error in bundle loading thread:\n"
            .. debug.traceback(loading_thread, items[1]))
    end
    __bundler__.__cleanup__()
    return table.unpack(items)
end
__bundler__.__files__["src.utils.number"] = function()
	---@class Freemaker.utils.number
	local _number = {}

	---@type table<integer, integer>
	local round_cache = {}

	---@param value number
	---@param decimal integer
	---@return integer
	function _number.round(value, decimal)
	    if decimal > 308 then
	        error("cannot round more decimals than 308")
	    end

	    local mult = round_cache[decimal]
	    if not mult then
	        mult = 10 ^ decimal
	        round_cache[decimal] = mult
	    end

	    return ((value * mult + 0.5) // 1) / mult
	end

	---@param value number
	---@param min number
	---@param max number
	---@return number
	function _number.clamp(value, min, max)
	    if value < min then
	        return min
	    end

	    if value > max then
	        return max
	    end

	    return value
	end

	return _number

end

__bundler__.__files__["src.utils.string.builder"] = function()
	local table_insert = table.insert
	local table_concat = table.concat

	---@class Freemaker.utils.string.builder
	---@field private m_cache string[]
	local _string_builder = {}

	function _string_builder.new()
	    local instance = setmetatable({
	        m_cache = {}
	    }, { __index = _string_builder })
	    return instance
	end

	function _string_builder:append(...)
	    for _, value in ipairs({...}) do
	        table_insert(self.m_cache, tostring(value))
	    end
	end

	function _string_builder:append_line(...)
	    self:append(...)
	    self:append("\n")
	end

	function _string_builder:build()
	    return table_concat(self.m_cache)
	end

	return _string_builder

end

__bundler__.__files__["src.utils.string.init"] = function()
	---@class Freemaker.utils.string
	---@field builder Freemaker.utils.string.builder
	local _string = {
	    builder = __bundler__.__loadFile__("src.utils.string.builder")
	}

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
	function _string.split(str, sep, plain)
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
	function _string.is_nil_or_empty(str)
	    if str == nil then
	        return true
	    end

	    if str == "" then
	        return true
	    end

	    return false
	end

	---@param str string
	---@param length integer
	---@param char string | nil
	function _string.left_pad(str, length, char)
	    local str_length = str:len()
	    return string.rep(char or " ", length - str_length) .. str
	end

	---@param str string
	---@param length integer
	---@param char string | nil
	function _string.right_pad(str, length, char)
	    local str_length = str:len()
	    return str .. string.rep(char or " ", length - str_length)
	end

	return _string

end

__bundler__.__files__["src.utils.table"] = function()
	---@class Freemaker.utils.table
	local _table = {}

	---@param t table
	---@param copy table
	---@param seen table<table, table>
	---@return table
	local function copy_table_to(t, copy, seen)
	    if seen[t] then
	        return seen[t]
	    end

	    seen[t] = copy

	    for key, value in next, t do
	        if type(value) == "table" then
	            copy[key] = copy_table_to(value, copy[key] or {}, seen)
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

	    return copy
	end

	---@generic T
	---@param t T
	---@return T table
	function _table.copy(t)
	    return copy_table_to(t, {}, {})
	end

	---@generic T
	---@param from T
	---@param to T
	function _table.copy_to(from, to)
	    copy_table_to(from, to, {})
	end

	---@param t table
	---@param ignoreProperties string[] | nil
	function _table.clear(t, ignoreProperties)
	    if not ignoreProperties then
	        for key, _ in next, t, nil do
	            t[key] = nil
	        end
	    else
	        for key, _ in next, t, nil do
	            if not _table.contains(ignoreProperties, key) then
	                t[key] = nil
	            end
	        end
	    end

	    setmetatable(t, nil)
	end

	---@param t table
	---@param value any
	---@return boolean
	function _table.contains(t, value)
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
	function _table.contains_key(t, key)
	    if t[key] ~= nil then
	        return true
	    end

	    return false
	end

	---@param t table
	---@return integer count
	function _table.count(t)
	    local count = 0

	    for _, _ in next, t, nil do
	        count = count + 1
	    end

	    return count
	end

	---@param t table
	---@return table
	function _table.invert(t)
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
	function _table.map(t, func)
	    ---@type any[]
	    local result = {}

	    for index, value in ipairs(t) do
	        result[index] = func(value)
	    end

	    return result
	end

	-- Only makes this table readonly
	-- **NOT** the child tables
	---@generic T
	---@param t T
	---@return T
	function _table.readonly(t)
	    return setmetatable({}, {
	        __newindex = function()
	            error("this table is readonly")
	        end,
	        __index = t
	    })
	end

	---@generic T
	---@generic R
	---@param t T
	---@param func fun(key: any, value: any) : R
	---@return R[]
	function _table.select(t, func)
	    local copy = _table.copy(t)

	    for key, value in pairs(copy) do
	        if not func(key, value) then
	            copy[key] = nil
	        end
	    end

	    return copy
	end

	---@generic T
	---@generic R
	---@param t T
	---@param func fun(key: any, value: any) : R
	---@return R[]
	function _table.select_implace(t, func)
	    for key, value in pairs(t) do
	        if not func(key, value) then
	            t[key] = nil
	        end
	    end

	    return t
	end

	return _table

end

__bundler__.__files__["src.utils.array"] = function()
	local table_insert = table.insert

	---@generic T
	---@param t T[]
	---@param value T
	local function insert_first_nil(t, value)
	    local i = 0
	    while true do
	        i = i + 1
	        if t[i] == nil then
	            t[i] = value
	            return
	        end
	    end
	end

	---@class Freemaker.utils.array
	local _array = {}

	---@generic T
	---@param t T[]
	---@param amount integer
	---@return T[]
	function _array.take_front(t, amount)
	    local length = #t
	    if amount > length then
	        amount = length
	    end

	    local copy = {}
	    for i = 1, amount, 1 do
	        table_insert(copy, t[i])
	    end
	    return copy
	end

	---@generic T
	---@param t T[]
	---@param amount integer
	---@return T[]
	function _array.take_back(t, amount)
	    local length = #t
	    local start = #t - amount + 1
	    if start < 1 then
	        start = 1
	    end

	    local copy = {}
	    for i = start, length, 1 do
	        table_insert(copy, t[i])
	    end
	    return copy
	end

	---@generic T
	---@param t T[]
	---@param amount integer
	---@return T[]
	function _array.drop_front_implace(t, amount)
	    for i, value in ipairs(t) do
	        if i <= amount then
	            t[i] = nil
	        else
	            insert_first_nil(t, value)
	            t[i] = nil
	        end
	    end
	    return t
	end

	---@generic T
	---@param t T[]
	---@param amount integer
	---@return T[]
	function _array.drop_back_implace(t, amount)
	    local length = #t
	    local start = length - amount + 1

	    for i = start, length, 1 do
	        t[i] = nil
	    end
	    return t
	end

	---@generic T
	---@generic R
	---@param t T[]
	---@param func fun(index: integer, value: T) : R
	---@return R[]
	function _array.select(t, func)
	    local copy = {}
	    for index, value in pairs(t) do
	        table_insert(copy, func(index, value))
	    end
	    return copy
	end

	---@generic T
	---@generic R
	---@param t T[]
	---@param func fun(index: integer, value: T) : R
	---@return R[]
	function _array.select_implace(t, func)
	    for index, value in pairs(t) do
	        local new_value = func(index, value)
	        t[index] = nil
	        if new_value then
	            insert_first_nil(t, new_value)
	        end
	    end
	    return t
	end

	--- removes all spaces between
	---@param t any[]
	function _array.clean(t)
	    for key, value in pairs(t) do
	        for i = key - 1, 1, -1 do
	            if key == 1 then
	                goto continue
	            end

	            if t[i] == nil and (t[i - 1] ~= nil or i == 1) then
	                t[i] = value
	                t[key] = nil
	                break
	            end

	            ::continue::
	        end
	    end
	end

	return _array

end

__bundler__.__files__["src.utils.value"] = function()
	local table = __bundler__.__loadFile__("src.utils.table")

	---@class Freemaker.utils.value
	local _value = {}

	---@generic T
	---@param x T
	---@return T
	function _value.copy(x)
	    local typeStr = type(x)
	    if typeStr == "table" then
	        return table.copy(x)
	    end

	    return x
	end

	---@generic T
	---@param value T | nil
	---@param default_value T
	---@return T
	function _value.default(value, default_value)
	    if value == nil then
	        return default_value
	    end

	    return value
	end

	return _value

end

__bundler__.__files__["__main__"] = function()
	---@class Freemaker.utils
	---@field number Freemaker.utils.number
	---@field string Freemaker.utils.string
	---@field table Freemaker.utils.table
	---@field array Freemaker.utils.array
	---@field value Freemaker.utils.value
	local utils = {}

	utils.number = __bundler__.__loadFile__("src.utils.number")
	utils.string = __bundler__.__loadFile__("src.utils.string.init")
	utils.table = __bundler__.__loadFile__("src.utils.table")
	utils.array = __bundler__.__loadFile__("src.utils.array")
	utils.value = __bundler__.__loadFile__("src.utils.value")

	return utils

end

---@type { [1]: Freemaker.utils }
local main = { __bundler__.__main__() }
return table.unpack(main)
