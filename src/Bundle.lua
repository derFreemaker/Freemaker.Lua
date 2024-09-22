local function get_os()
    if package.config:sub(1, 1) == '\\' then
        return "windows"
    else
        return "linux"
    end
end

---@type lfs
local file_system
if __bundler__ then
    file_system = require("lfs")
else
    local os_ext = ""
    if get_os() == "windows" then
        os_ext = ";./bin/?.dll"
    else
        os_ext = ";./bin/?.so"
    end
    package.cpath = package.cpath .. os_ext
    file_system = require("lfs")
    package.cpath = package.cpath:sub(0, package.cpath:find(os_ext, nil, true) - 1)
end

local argparse = require("thrid_party.argparse")
local utils = require("src.utils.init")
local path = require("src.path")

local current_dir = path.new(file_system.currentdir())

local parser = argparse("bundle", "Used to bundle a file together by importing the files it uses with require")
parser:argument("input", "Input file.")
parser:option("-o --output", "Output file.", "out.lua")
parser:option("-t --type", "Output type/s."):count("*")
parser:option("-c --comments", "remove comments (does not remove all comments)", false)
parser:option("-l --lines", "remove empty lines", false)
parser:option("-I --include-path", "added search path's for 'require(...)'"):count("*")

---@type { input: string, output: string, type: string[] | nil, comments: boolean, lines: boolean, include_path: string[] }
local args = parser:parse() -- { "-o", "bin/bundle.lua", "-Ibin", "src/bundle.lua" })

local input_file_path = path.new(args.input)
if input_file_path:is_relative() then
    input_file_path = current_dir:extend(input_file_path:to_string())
end

local output_file_path = path.new(args.output)
if output_file_path:is_relative() then
    output_file_path = current_dir:extend(output_file_path:to_string())
end

local out_file = io.open(output_file_path:to_string(), "w")
if not out_file then
    error("unable to open output: " .. output_file_path:to_string())
end

for _, include in ipairs(args.include_path) do
    local include_path = path.new(include)

    if include_path:is_absolute() then
        package.path = package.path .. ";" .. include .. "/?.lua"
        if get_os() == "windows" then
            package.cpath = package.cpath .. ";" .. include .. "/?.dll"
        else
            package.cpath = package.cpath .. ";" .. include .. "/?.so"
        end
    else
        package.path = package.path .. ";./" .. include .. "/?.lua"
        if get_os() == "windows" then
            package.cpath = package.cpath .. ";./" .. include .. "/?.dll"
        else
            package.cpath = package.cpath .. ";./" .. include .. "/?.so"
        end
    end
end

---@class Freemaker.bundle.require
---@field module string
---@field file_path string | nil
---@field startPos integer
---@field endPos integer
---@field replace boolean
---@field binary boolean

local bundler = {}

---@param text string
---@return Freemaker.bundle.require[]
function bundler.find_all_requires(text)
    ---@type Freemaker.bundle.require[]
    local requires = {}
    local current_pos = 0
    while true do
        local start_pos, end_pos, match = text:find('require%("([^"]+)"%)', current_pos)
        if start_pos == nil then
            start_pos, end_pos, match = text:find('require% "([^"]+)"', current_pos)
        end

        if start_pos == nil then
            break
        end

        local text_part = text:sub(0, start_pos):reverse()
        local new_line_pos = text_part:find("\n")
        local comment = text_part:find("--", nil, true)
        if not (new_line_pos and comment and comment < new_line_pos) then
            ---@cast end_pos integer

            local replace = false
            local binary = false
            local file_path = package.searchpath(match, package.path)
            if file_path then
                replace = true

                file_path = file_path:sub(0, file_path:len() - 4)
            else
                file_path = package.searchpath(match, package.cpath)
                if file_path then
                    replace = true
                    binary = true

                    if get_os() == "windows" then
                        file_path = file_path:sub(0, file_path:len() - 4)
                    else
                        file_path = file_path:sub(0, file_path:len() - 3)
                    end
                    file_path = current_dir:to_string() .. file_path
                end
            end

            ---@type Freemaker.bundle.require
            local data = {
                module = match,
                file_path = file_path,
                startPos = start_pos,
                endPos = end_pos,
                replace = replace,
                binary = binary
            }
            table.insert(requires, data)
        end

        ---@diagnostic disable-next-line: cast-local-type
        current_pos = end_pos
    end
    return requires
end

---@param requires Freemaker.bundle.require[]
---@param text string
---@return string text
function bundler.replace_requires(requires, text)
    local diff = 0
    for _, require in pairs(requires) do
        if not require.replace then
            goto continue
        end

        local front = text:sub(0, require.startPos + diff - 1)
        local back = text:sub(require.endPos + diff + 1)
        local replacement = "__bundler__.__loadFile__(\"" .. require.module .. "\")"
        text = front .. replacement .. back
        diff = diff - require.module:len() - 11 + replacement:len()

        ::continue::
    end

    return text
end

local cache = {}

---@param requires Freemaker.bundle.require[]
function bundler.process_requires(requires)
    for _, require in pairs(requires) do
        if not require.replace then
            goto continue
        end
        local module_require_path = require.file_path:gsub("\\", "/")

        if require.binary then
            local found = false

            local dll_require_path = path.new(module_require_path .. ".dll")
            if not dll_require_path:exists() then
                print("WARNING: no '.dll' found for module: '" ..
                    require.module .. "' path: " .. dll_require_path:to_string())
            else
                found = true
            end

            local so_require_path = path.new(module_require_path .. ".so")
            if not so_require_path:exists() then
                print("WARNING: no '.so' found for module: '" ..
                    require.module .. "' path: " .. so_require_path:to_string())
            else
                found = true
            end

            if found then
                bundler.process_file(path.new(module_require_path), require.module, true)
            end

            goto continue
        end

        ---@type string[]
        local records = {}

        local require_path = path.new(module_require_path .. ".lua")
        if require_path:exists() then
            bundler.process_file(require_path, require.module)
            goto continue
        end

        table.insert(records, require_path:to_string())
        require_path = current_dir:extend(require.module:gsub("%.", "\\") .. "\\init.lua")
        if require_path:exists() then
            bundler.process_file(require_path, require.module)
            goto continue
        end

        table.insert(records, require_path:to_string())
        print("WARNING: unable to find: " .. require.module
            .. " with paths: \"" .. table.concat(records, "\";\"") .. "\"")
        require.replace = false

        ::continue::
    end
end

---@param file_path Freemaker.file-system.path
---@param module string
---@param binary boolean | nil
function bundler.process_file(file_path, module, binary)
    binary = binary or false

    if binary then
        if not cache[module .. ".so"] and not cache[module .. ".dll"] then
            out_file:write("__bundler__.__binary_files__[\"", module, "\"] = true\n")
        end

        local did = false

        if not cache[module .. ".so"] then
            local file_path_str = file_path:to_string()
            file_path_str = file_path_str:sub(0, file_path_str:len() - 1) .. ".so"
            if file_system.exists(file_path_str) then
                local file = io.open(file_path_str, "rb")
                if not file then
                    error("unable to open: " .. file_path:to_string())
                end
                local content = file:read("a")
                file:close()

                local bytes = {}
                for i = 1, #content do
                    bytes[#bytes + 1] = string.format("\"%02X\"", string.byte(content, i))
                end
                content = table.concat(bytes, ",")

                cache[module .. ".so"] = true
                out_file:write("__bundler__.__files__[\"", module, ".so\"] = {", content, "}\n")
            end
            did = true
        end

        if not cache[module .. ".dll"] then
            local file_path_str = file_path:to_string()
            file_path_str = file_path_str:sub(0, file_path_str:len() - 1) .. ".dll"
            if file_system.exists(file_path_str) then
                local file = io.open(file_path_str, "rb")
                if not file then
                    error("unable to open: " .. file_path:to_string())
                end
                local content = file:read("a")
                file:close()

                local bytes = {}
                for i = 1, #content do
                    bytes[#bytes + 1] = string.format("\"%02X\"", string.byte(content, i))
                end
                content = table.concat(bytes, ",")

                cache[module .. ".dll"] = true
                out_file:write("__bundler__.__files__[\"", module, ".dll\"] = {", content, "}\n")
            end
            did = true
        end

        if did then
            out_file:write("\n")
        end

        return
    end

    if cache[module] then
        return
    end

    local file = io.open(file_path:to_string())
    if not file then
        error("unable to open: " .. file_path:to_string())
    end
    local content = file:read("a")
    file:close()

    local requires = bundler.find_all_requires(content)
    bundler.process_requires(requires)
    content = bundler.replace_requires(requires, content)

    cache[module] = true
    out_file:write("__bundler__.__files__[\"", module, "\"] = function()\n")
    local lines = utils.string.split(content, "\n", false)
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
                out_file:write("\n")
            end

            goto continue
        end

        out_file:write("\t" .. line .. "\n")
        ::continue::
    end
    out_file:write("end\n\n")
end

print("writing...")

if not args.comments then
    out_file:write("---@diagnostic disable\n\n")
end

out_file:write([[
local __bundler__ = {
    __files__ = {},
    __binary_files__ = {},
    __cache__ = {},
}
function __bundler__.__get_os__()
    if package.config:sub(1, 1) == '\\' then
        return "windows"
    else
        return "linux"
    end
end
function __bundler__.__loadFile__(module)
    if not __bundler__.__cache__[module] then
        if __bundler__.__binary_files__[module] then
            local os_type = __bundler__.__get_os__()
            local file_path = os.tmpname()
            local file = io.open(file_path, "wb")
            if not file then
                error("unable to open file: " .. file_path)
            end
            local content
            if os_type == "windows" then
                content = __bundler__.__files__[module .. ".dll"]
            else
                content = __bundler__.__files__[module .. ".so"]
            end
            for i = 1, #content do
                local byte = tonumber(content[i], 16)
                file:write(string.char(byte))
            end
            file:close()
            __bundler__.__cache__[module] = { package.loadlib(file_path, "luaopen_" .. module)() }
        else
            __bundler__.__cache__[module] = { __bundler__.__files__[module]() }
        end
    end
    return table.unpack(__bundler__.__cache__[module])
end
]])

bundler.process_file(input_file_path, "__main__")

if args.type then
    out_file:write("---@type {")
    for index, type_name in ipairs(args.type) do
        out_file:write(" [", index, "]: ", type_name, " ")
    end
    out_file:write("}\n")
    out_file:write("local main = { __bundler__.__loadFile__(\"__main__\") }\n")
    out_file:write("return table.unpack(main)\n")
else
    out_file:write("return __bundler__.__loadFile__(\"__main__\")\n")
end

out_file:close()
print("done!")
