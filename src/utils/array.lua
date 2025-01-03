-- caching globals for more performance
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
local array = {}

---@generic T
---@param t T[]
---@param amount integer
---@return T[]
function array.take_front(t, amount)
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
function array.take_back(t, amount)
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
function array.drop_front_implace(t, amount)
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
function array.drop_back_implace(t, amount)
    local length = #t
    local start = length - amount + 1

    for i = start, length, 1 do
        t[i] = nil
    end
    return t
end

---@generic T
---@param t T[]
---@param func fun(key: any, value: T) : boolean
---@return T[]
function array.select(t, func)
    local copy = {}
    for key, value in pairs(t) do
        if func(key, value) then
            table_insert(copy, value)
        end
    end
    return copy
end

---@generic T
---@param t T[]
---@param func fun(key: any, value: T) : boolean
---@return T[]
function array.select_implace(t, func)
    for key, value in pairs(t) do
        if func(key, value) then
            t[key] = nil
            insert_first_nil(t, value)
        else
            t[key] = nil
        end
    end
    return t
end

return array
