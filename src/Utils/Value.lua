local table = require("src.utils.table")

---@class Freemaker.utils.value
local value = {}

---@generic T
---@param x T
---@return T
function value.copy(x)
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
function value.default(value, default_value)
    if value == nil then
        return default_value
    end
    return value
end

return value
