local table = require("src.utils.table")

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

---@param value number
---@param min number
---@return number
function _value.min(value, min)
    if value < min then
        return min
    end
    return value
end

---@param value number
---@param max number
---@return number
function _value.max(value, max)
    if value > max then
        return max
    end
    return value
end

return _value
