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
