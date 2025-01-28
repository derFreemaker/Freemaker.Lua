local table_insert = table.insert
local table_concat = table.concat

---@class Freemaker.utils.string.builder
---@field private m_cache string[]
local _string_builder = {}

function _string_builder.new()
    local instance = setmetatable({
        m_cache = {}
    }, { __index = _string_builder })
    return instance
end

function _string_builder:append(...)
    for _, value in ipairs({...}) do
        table_insert(self.m_cache, tostring(value))
    end
end

function _string_builder:append_line(...)
    self:append(...)
    self:append("\n")
end

function _string_builder:build()
    return table_concat(self.m_cache)
end

return _string_builder
