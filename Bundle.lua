local CliParser = require("CLIParser")
local FileSystem = require("FileSystem")
local Utils = require("Utils")
local Path = require("Path")

local CurrentDirectory = Path.new(FileSystem.GetCurrentDirectory())
local RootDirectory = CurrentDirectory:Extend(".."):Normalize()
local CurrentWorkingDirectory = Path.new(FileSystem.GetCurrentWorkingDirectory())

local parser = CliParser("bundle", "Used to bundle a file together by importing the files it uses with require")
parser:argument("input", "Input file.")
parser:option("-o --output", "Output file.", "out.lua")
parser:option("-t --type", "Output type.")

---@type { input: string, output: string, type: string }
local args = parser:parse() -- { "-o", "bin/bundle.lua", "Bundle.lua" })

local InputFilePath = Path.new(args.input)
if InputFilePath:IsRelative() then
    InputFilePath = CurrentWorkingDirectory:Extend(InputFilePath:ToString())
end

local OutputFilePath = Path.new(args.output)
if OutputFilePath:IsRelative() then
    OutputFilePath = CurrentWorkingDirectory:Extend(OutputFilePath:ToString())
end

local outFile = io.open(OutputFilePath:ToString(), "w+")
if not outFile then
    error("unable to open output: " .. args.output)
end

---@class Freemaker.Bundle.require
---@field module string
---@field startPos integer
---@field endPos integer
---@field replace boolean

local bundler = {}

---@param text string
---@return Freemaker.Bundle.require[]
function bundler.findAllRequires(text)
    ---@type { module: string, startPos: integer, endPos: integer }[]
    local requires = {}
    local currentPos = 0
    while true do
        local startPos, endPos, match = text:find('require%("([^"]+)"%)', currentPos)
        if startPos == nil then
            startPos, endPos, match = text:find('require% "([^"]+)"', currentPos)
        end

        if startPos == nil then
            break
        end

        table.insert(requires, { startPos = startPos, endPos = endPos, module = match })
        ---@diagnostic disable-next-line: cast-local-type
        currentPos = endPos
    end
    return requires
end

---@param requires Freemaker.Bundle.require[]
---@param text string
---@return string text
function bundler.replaceRequires(requires, text)
    local diff = 0
    for _, require in pairs(requires) do
        local front = text:sub(0, require.startPos + diff - 1)
        local back = text:sub(require.endPos + diff + 1)
        text = front .. "__loadFile__(\"" .. require.module .. "\")" .. back
        diff = diff + 5
    end

    return text
end

local cache = {}

---@param requires Freemaker.Bundle.require[]
function bundler.processRequires(requires)
    for _, require in pairs(requires) do
        ---@type string[]
        local records = {}
        local requirePath = RootDirectory:Extend(require.module:gsub("%.", "\\") .. ".lua")
        if not requirePath:Exists() then
            table.insert(records, requirePath:ToString())
            requirePath = RootDirectory:Extend(require.module:gsub("%.", "\\") .. "\\init.lua")
            if not requirePath:Exists() then
                table.insert(records, requirePath:ToString())
                print("WARNING: unable to find: " .. require.module
                    .. " with paths: \"" .. Utils.String.Join(records, "\";\"") .. "\"")
                require.replace = false
                goto continue
            end
        end

        bundler.processFile(requirePath, require.module)
        ::continue::
    end
end

---@param path Freemaker.FileSystem.Path
---@param module string
function bundler.processFile(path, module)
    if cache[module] then
        return cache[module]
    end

    local file = io.open(path:ToString())
    if not file then
        error("unable to open: " .. path:ToString())
    end
    local text = file:read("a")
    file:close()

    local requires = bundler.findAllRequires(text)
    bundler.processRequires(requires)

    text = bundler.replaceRequires(requires, text)
    cache[module] = text

    outFile:write("__fileFuncs__[\"" .. module .. "\"] = function()\n")
    local lines = Utils.String.Split(text, "\n", false)
    for _, line in pairs(lines) do
        if line:find("--", nil, true) == 1 then
            goto continue
        end

        if not line:find("%S") then
            goto continue
        end

        outFile:write("    " .. line .. "\n")
        ::continue::
    end
    outFile:write("end\n\n")
end

print("writing...")

outFile:write([[local __fileFuncs__ = {}
local __cache__ = {}
local function __loadFile__(module)
    if not __cache__[module] then
        __cache__[module] = { __fileFuncs__[module]() }
    end
    return table.unpack(__cache__[module])
end
]])

bundler.processFile(InputFilePath, "__main__")

outFile:write("return __loadFile__(\"" .. "__main__" .. "\")")
if args.type then
    outFile:write(" --[[@as " .. args.type .. "]]")
end
outFile:write("\n")

outFile:close()
print("done!")
