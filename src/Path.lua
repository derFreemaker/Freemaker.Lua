local utils = require("src.utils.init")

---@param str string
---@return string str
local function format_str(str)
    str = str:gsub("\\", "/")
    return str
end

---@class Freemaker.file-system.path
---@field private m_nodes string[]
local _path = {}

---@param str string
---@return boolean isNode
function _path.is_node(str)
    if str:find("/") then
        return false
    end

    return true
end

---@param pathOrNodes string | string[] | nil
---@return Freemaker.file-system.path
function _path.new(pathOrNodes)
    local instance = {}
    if not pathOrNodes then
        instance.m_nodes = {}
        return setmetatable(instance, { __index = _path })
    end

    if type(pathOrNodes) == "string" then
        pathOrNodes = format_str(pathOrNodes)
        pathOrNodes = utils.string.split(pathOrNodes, "/")
    end

    local length = #pathOrNodes
    local node = pathOrNodes[length]
    if node and node ~= "" and not node:find("^.+%..+$") then
        pathOrNodes[length + 1] = ""
    end

    instance.m_nodes = pathOrNodes
    instance = setmetatable(instance, { __index = _path })

    return instance
end

---@return string path
function _path:to_string()
    self:normalize()
    return table.concat(self.m_nodes, "/")
end

---@return boolean
function _path:empty()
    return #self.m_nodes == 0 or (#self.m_nodes == 2 and self.m_nodes[1] == "" and self.m_nodes[2] == "")
end

---@return boolean
function _path:is_file()
    return self.m_nodes[#self.m_nodes] ~= ""
end

---@return boolean
function _path:is_dir()
    return self.m_nodes[#self.m_nodes] == ""
end

function _path:exists()
    local path = self:to_string()
    return os.rename(path, path)
end

---@return boolean
function _path:create()
    if self:exists() then
        return true
    end

    if self:is_dir() then
        local success = os.execute(("mkdir \"%s\""):format(self:to_string()))
        return success or false
    elseif self:is_file() then
        local file = io.open(self:to_string(), "w")
        if not file then
            return false
        end

        file:close()
        return true
    end

    return false
end

---@return boolean
function _path:is_absolute()
    if #self.m_nodes == 0 then
        return false
    end

    if self.m_nodes[1] == "" then
        return true
    end

    if self.m_nodes[1]:find(":", nil, true) == 2 then
        return true
    end

    return false
end

---@return Freemaker.file-system.path
function _path:absolute()
    local copy = utils.table.copy(self.m_nodes)

    for i = 1, #copy, 1 do
        copy[i] = copy[i + 1]
    end

    return _path.new(copy)
end

---@return boolean
function _path:is_relative()
    if #self.m_nodes == 0 then
        return false
    end

    return self.m_nodes[1] ~= "" and not (self.m_nodes[1]:find(":", nil, true))
end

---@return Freemaker.file-system.path
function _path:relative()
    local copy = {}

    if self.m_nodes[1] ~= "" then
        copy[1] = ""
        for i = 1, #self.m_nodes, 1 do
            copy[i + 1] = self.m_nodes[i]
        end
    end

    return _path.new(copy)
end

---@return string
function _path:get_parent_folder()
    local copy = utils.table.copy(self.m_nodes)
    local length = #copy

    if length > 0 then
        if length > 1 and copy[length] == "" then
            copy[length] = nil
            copy[length - 1] = ""
        else
            copy[length] = nil
        end
    end

    return table.concat(copy, "/")
end

---@return Freemaker.file-system.path
function _path:get_parent_folder_path()
    local copy = self:copy()
    local length = #copy.m_nodes

    if length > 0 then
        if length > 1 and copy.m_nodes[length] == "" then
            copy.m_nodes[length] = nil
            copy.m_nodes[length - 1] = ""
        else
            copy.m_nodes[length] = nil
        end
    end

    return copy
end

---@return string fileName
function _path:get_file_name()
    if not self:is_file() then
        error("path is not a file: " .. self:to_string())
    end

    return self.m_nodes[#self.m_nodes]
end

---@return string fileExtension
function _path:get_file_extension()
    if not self:is_file() then
        error("path is not a file: " .. self:to_string())
    end

    local fileName = self.m_nodes[#self.m_nodes]

    local _, _, extension = fileName:find("^.+(%..+)$")
    return extension
end

---@return string fileStem
function _path:get_file_stem()
    if not self:is_file() then
        error("path is not a file: " .. self:to_string())
    end

    local fileName = self.m_nodes[#self.m_nodes]

    local _, _, stem = fileName:find("^(.+)%..+$")
    return stem
end

---@return string folderName
function _path:get_dir_name()
    if not self:is_dir() then
        error("path is not a directory: " .. self:to_string())
    end

    if #self.m_nodes < 2 then
        error("path is empty")
    end

    return self.m_nodes[#self.m_nodes - 1]
end

---@return Freemaker.file-system.path
function _path:normalize()
    ---@type string[]
    local newNodes = {}

    for index, value in ipairs(self.m_nodes) do
        if value == "." then
        elseif value == "" then
            if index == 1 or index == #self.m_nodes then
                newNodes[#newNodes + 1] = ""
            end
        elseif value == ".." then
            if index ~= 1 then
                newNodes[#newNodes] = nil
            end
        else
            newNodes[#newNodes + 1] = value
        end
    end

    if newNodes[1] then
        newNodes[1] = newNodes[1]:gsub("@", "")
    end

    self.m_nodes = newNodes
    return self
end

---@param ... string
---@return Freemaker.file-system.path
function _path:append(...)
    local path_str = table.concat({...}, "/")
    if self.m_nodes[#self.m_nodes] == "" then
        self.m_nodes[#self.m_nodes] = nil
    end

    path_str = format_str(path_str)
    local newNodes = utils.string.split(path_str, "/")

    for _, value in ipairs(newNodes) do
        self.m_nodes[#self.m_nodes + 1] = value
    end

    if self.m_nodes[#self.m_nodes] ~= "" and not self.m_nodes[#self.m_nodes]:find("^.+%..+$") then
        self.m_nodes[#self.m_nodes + 1] = ""
    end

    self:normalize()

    return self
end

---@param ... string
---@return Freemaker.file-system.path
function _path:extend(...)
    local copy = self:copy()
    return copy:append(...)
end

---@return Freemaker.file-system.path
function _path:copy()
    local copyNodes = utils.table.copy(self.m_nodes)
    return _path.new(copyNodes)
end

return _path
