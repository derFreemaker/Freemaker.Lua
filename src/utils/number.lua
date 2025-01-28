---@class Freemaker.utils.number
local _number = {}

---@type table<integer, integer>
local round_cache = {}

---@param value number
---@param decimal integer | nil
---@return integer
function _number.round(value, decimal)
    decimal = decimal or 0
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
