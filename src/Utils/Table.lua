---@class Freemaker.utils.table
local table = {}

---@param obj table | nil
---@param seen table[]
---@return table | nil
local function copy_table(obj, copy, seen)
    if obj == nil then return nil end
    if seen[obj] then return seen[obj] end

    seen[obj] = copy
    setmetatable(copy, copy_table(getmetatable(obj), {}, seen))

    for key, value in next, obj, nil do
        key = (type(key) == "table") and copy_table(key, {}, seen) or key
        value = (type(value) == "table") and copy_table(value, {}, seen) or value
        rawset(copy, key, value)
    end

    return copy
end

---@generic TTable
---@param t TTable
---@return TTable table
function table.copy(t)
    return copy_table(t, {}, {})
end

---@param from table
---@param to table
function table.copy_to(from, to)
    copy_table(from, to, {})
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

return table
