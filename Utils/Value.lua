local Table = require("Utils.Table")

---@class Utils.Value
local Value = {}

---@generic T
---@param value T
---@return T
function Value.Copy(value)
    local typeStr = type(value)

    if typeStr == "table" then
        return Table.Copy(value)
    end

    return value
end

return Value
