---@class Freemaker.Utils.String
local String = {}

---@param str string
---@param pattern string
---@param plain boolean | nil
---@return string | nil, integer
local function findNext(str, pattern, plain)
    local found = str:find(pattern, 0, plain or false)
    if found == nil then
        return nil, 0
    end
    return str:sub(0, found - 1), found - 1
end

---@param str string | nil
---@param sep string | nil
---@param plain boolean | nil
---@return string[]
function String.Split(str, sep, plain)
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
        local foundStr, foundPos = findNext(str, sep, plain)

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
function String.IsNilOrEmpty(str)
    if str == nil then
        return true
    end
    if str == "" then
        return true
    end
    return false
end

---@param array string[]
---@param sep string
---@return string
function String.Join(array, sep)
    local str = ""

    str = array[1]
    for _, value in next, array, 1 do
        str = str .. sep .. value
    end

    return str
end

return String
