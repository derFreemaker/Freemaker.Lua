local CliParser = require("src.cliParser")
local FileSystem = require("src.fileSystem")
local Utils = require("src.utils")
local Path = require("src.path")

local CurrentWorkingDirectory = Path.new(FileSystem.GetCurrentWorkingDirectory())

local parser = CliParser("bundle", "Used to bundle a file together by importing the files it uses with require")
parser:argument("input", "Input file.")
parser:option("-o --output", "Output file.", "out.lua")
parser:option("-t --type", "Output type.")
parser:option("-c --comments", "remove comments (does not remove all comments)", false)
parser:option("-l --lines", "remove empty lines", true)

---@type { input: string, output: string, type: string?, comments: boolean, lines: boolean }
local args = parser:parse() -- { "-o", "bin/bundle.lua", "src/Bundle.lua" })

local InputFilePath = Path.new(args.input)
if InputFilePath:IsRelative() then
    InputFilePath = CurrentWorkingDirectory:Extend(InputFilePath:ToString())
end

local OutputFilePath = Path.new(args.output)
if OutputFilePath:IsRelative() then
    OutputFilePath = CurrentWorkingDirectory:Extend(OutputFilePath:ToString())
end

local outFile = io.open(OutputFilePath:ToString(), "w")
if not outFile then
    error("unable to open output: " .. OutputFilePath:ToString())
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

        local textPart = text:sub(0, startPos):reverse()
        local newLinePos = textPart:find("\n")
        local comment = textPart:find("--", nil, true)
        if not (newLinePos and comment and comment < newLinePos) then
            ---@type Freemaker.Bundle.require
            ---@diagnostic disable-next-line: assign-type-mismatch
            local data = { startPos = startPos, endPos = endPos, module = match, replace = true }
            table.insert(requires, data)
        end

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
        if not require.replace then
            goto continue
        end

        local front = text:sub(0, require.startPos + diff - 1)
        local back = text:sub(require.endPos + diff + 1)
        text = front .. "__loadFile__(\"" .. require.module .. "\")" .. back
        diff = diff + 5

        ::continue::
    end

    return text
end

local cache = {}

---@param requires Freemaker.Bundle.require[]
function bundler.processRequires(requires)
    for _, require in pairs(requires) do
        ---@type string[]
        local records = {}

        local requirePath = CurrentWorkingDirectory:Extend(require.module:gsub("%.", "\\") .. ".lua")
        if requirePath:Exists() then
            bundler.processFile(requirePath, require.module)
            goto continue
        end

        table.insert(records, requirePath:ToString())
        requirePath = CurrentWorkingDirectory:Extend(require.module:gsub("%.", "\\") .. "\\init.lua")
        if requirePath:Exists() then
            bundler.processFile(requirePath, require.module)
            goto continue
        end

        table.insert(records, requirePath:ToString())
        print("WARNING: unable to find: " .. require.module
            .. " with paths: \"" .. Utils.String.Join(records, "\";\"") .. "\"")
        require.replace = false

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
        if args.comments then
            if line:find("%s*%-%-") == 1 then
                goto continue
            end
        end

        if not line:find("%S") then
            if args.lines then
                goto continue
            else
                outFile:write("\n")
            end

            goto continue
        end

        outFile:write("\t" .. line .. "\n")
        ::continue::
    end
    outFile:write("end\n\n")
end

print("writing...")

if not args.comments then
    outFile:write("---@diagnostic disable\r\n\r\n")
end

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

if args.type then
    outFile:write("---@type " .. args.type .. "\n")
    outFile:write("local main = __fileFuncs__[\"" .. "__main__" .. "\"]()\n")
    outFile:write("return main\n")
else
    outFile:write("return __fileFuncs__[\"" .. "__main__" .. "\"]()\n")
end

outFile:close()
print("done!")
