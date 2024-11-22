---@class Freemaker.utils.string
local _string = {}

---@param str string
---@param pattern string
---@param plain boolean | nil
---@return string | nil, integer
local function find_next(str, pattern, plain)
    local found = str:find(pattern, 0, plain or true)
    if found == nil then
        return nil, 0
    end
    return str:sub(0, found - 1), found - 1
end

---@param str string | nil
---@param sep string | nil
---@param plain boolean | nil
---@return string[]
function _string.split(str, sep, plain)
    if str == nil then
        return {}
    end

    local strLen = str:len()
    local sepLen

    if sep == nil then
        sep = "%s"
        sepLen = 2
    else
        sepLen = sep:len()
    end

    local tbl = {}
    local i = 0
    while true do
        i = i + 1
        local foundStr, foundPos = find_next(str, sep, plain)

        if foundStr == nil then
            tbl[i] = str
            return tbl
        end

        tbl[i] = foundStr
        str = str:sub(foundPos + sepLen + 1, strLen)
    end
end

---@param str string | nil
---@return boolean
function _string.is_nil_or_empty(str)
    if str == nil then
        return true
    end
    if str == "" then
        return true
    end
    return false
end

return _string
