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

return _number
