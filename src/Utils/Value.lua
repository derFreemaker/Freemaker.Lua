local table = require("src.utils.table")

---@class Freemaker.utils.value
local value = {}

---@generic T
---@param value T
---@return T
function value.copy(value)
    local typeStr = type(value)

    if typeStr == "table" then
        return table.Copy(value)
    end

    return value
end

return value
