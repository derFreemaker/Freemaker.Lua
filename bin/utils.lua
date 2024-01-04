local __fileFuncs__ = {}
    local __cache__ = {}
    local function __loadFile__(module)
        if not __cache__[module] then
            __cache__[module] = { __fileFuncs__[module]() }
        end
        return table.unpack(__cache__[module])
    end
    __fileFuncs__["src.Utils.String"] = function()
    local String = {}
    local function findNext(str, pattern, plain)
        local found = str:find(pattern, 0, plain or false)
        if found == nil then
            return nil, 0
        end
        return str:sub(0, found - 1), found - 1
    end
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
    function String.IsNilOrEmpty(str)
        if str == nil then
            return true
        end
        if str == "" then
            return true
        end
        return false
    end
    function String.Join(array, sep)
        local str = ""
        str = array[1]
        for _, value in next, array, 1 do
            str = str .. sep .. value
        end
        return str
    end
    return String
end

__fileFuncs__["src.Utils.Table"] = function()
    local Table = {}
    local function copyTable(obj, copy, seen)
        if obj == nil then return nil end
        if seen[obj] then return seen[obj] end
        seen[obj] = copy
        setmetatable(copy, copyTable(getmetatable(obj), {}, seen))
        for key, value in next, obj, nil do
            key = (type(key) == "table") and copyTable(key, {}, seen) or key
            value = (type(value) == "table") and copyTable(value, {}, seen) or value
            rawset(copy, key, value)
        end
        return copy
    end
    function Table.Copy(t)
        return copyTable(t, {}, {})
    end
    function Table.CopyTo(from, to)
        copyTable(from, to, {})
    end
    function Table.Clear(t, ignoreProperties)
        if not ignoreProperties then
            ignoreProperties = {}
        end
        for key, _ in next, t, nil do
            if not Table.Contains(ignoreProperties, key) then
                t[key] = nil
            end
        end
        setmetatable(t, nil)
    end
    function Table.Contains(t, value)
        for _, tValue in pairs(t) do
            if value == tValue then
                return true
            end
        end
        return false
    end
    function Table.ContainsKey(t, key)
        if t[key] ~= nil then
            return true
        end
        return false
    end
    function Table.Clean(t)
        for key, value in pairs(t) do
            for i = key - 1, 1, -1 do
                if key ~= 1 then
                    if t[i] == nil and (t[i - 1] ~= nil or i == 1) then
                        t[i] = value
                        t[key] = nil
                        break
                    end
                end
            end
        end
    end
    function Table.Count(t)
        local count = 0
        for _, _ in next, t, nil do
            count = count + 1
        end
        return count
    end
    function Table.Invert(t)
        local inverted = {}
        for key, value in pairs(t) do
            inverted[value] = key
        end
        return inverted
    end
    return Table
end

__fileFuncs__["src.Utils.Value"] = function()
    local Table = __loadFile__("src.Utils.Table")
    local Value = {}
    function Value.Copy(value)
        local typeStr = type(value)
        if typeStr == "table" then
            return Table.Copy(value)
        end
        return value
    end
    return Value
end

__fileFuncs__["__main__"] = function()
    local Utils = {}
    Utils.String = __loadFile__("src.Utils.String")
    Utils.Table = __loadFile__("src.Utils.Table")
    Utils.Value = __loadFile__("src.Utils.Value")
    return Utils
end

---@type Freemaker.Utils
local main = __fileFuncs__["__main__"]()
return main
