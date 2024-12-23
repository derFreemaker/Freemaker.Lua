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

--- removes all spaces between
---@param t any[]
function _table.clean(t)
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
---@param t T
---@param func fun(key: any, value: any) : boolean
---@return T
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
---@param t T
---@param func fun(key: any, value: any) : boolean
---@return T
function _table.select_implace(t, func)
    for key, value in pairs(t) do
        if not func(key, value) then
            t[key] = nil
        end
    end
    return t
end

return _table
