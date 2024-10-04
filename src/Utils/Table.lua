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

return table
