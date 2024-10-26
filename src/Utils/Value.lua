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

return value
