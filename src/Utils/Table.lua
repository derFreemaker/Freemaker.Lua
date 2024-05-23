---@class Freemaker.Utils.Table
local Table = {}

---@param obj table | nil
---@param seen table[]
---@return table | nil
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
---@param ignoreProperties string[] | nil
function Table.Clear(t, ignoreProperties)
    if not ignoreProperties then
        for key, _ in next, t, nil do
            t[key] = nil
        end
    else
        for key, _ in next, t, nil do
            if not Table.Contains(ignoreProperties, key) then
                t[key] = nil
            end
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
