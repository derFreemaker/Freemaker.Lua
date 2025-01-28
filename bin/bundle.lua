---@diagnostic disable

local __bundler__ = {
    __files__ = {},
    __binary_files__ = {},
    __cache__ = {},
    __temp_files__ = {},
    __org_exit__ = os.exit
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
        local tempDir = os.getenv("TEMP") or os.getenv("TMP")
            if not tempDir then
                tempDir = "/tmp"
            end
            local os_type = __bundler__.__get_os__()
            local file_path = tempDir .. os.tmpname()
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
            local content_len = content:len()
            for i = 2, content_len, 2 do
                local byte = tonumber(content:sub(i - 1, i), 16)
                file:write(string.char(byte))
            end
            file:close()
            __bundler__.__cache__[module] = { package.loadlib(file_path, "luaopen_" .. module)() }
            table.insert(__bundler__.__temp_files__, file_path)
        else
            __bundler__.__cache__[module] = { __bundler__.__files__[module]() }
        end
    end
    return table.unpack(__bundler__.__cache__[module])
end
function __bundler__.__cleanup__()
    for _, file_path in ipairs(__bundler__.__temp_files__) do
        os.remove(file_path)
    end
end
---@diagnostic disable-next-line: duplicate-set-field
function os.exit(...)
    __bundler__.__cleanup__()
    __bundler__.__org_exit__(...)
end
function __bundler__.__main__()
    local loading_thread = coroutine.create(__bundler__.__loadFile__)
    local success, items = (function(success, ...) return success, {...} end)
        (coroutine.resume(loading_thread, "__main__"))
    if not success then
        print("error in bundle loading thread:\n"
            .. debug.traceback(loading_thread, items[1]))
    end
    __bundler__.__cleanup__()
    return table.unpack(items)
end
__bundler__.__files__["thrid_party.argparse"] = function()
	-- The MIT License (MIT)

	-- Copyright (c) 2013 - 2018 Peter Melnichenko

	-- Permission is hereby granted, free of charge, to any person obtaining a copy of
	-- this software and associated documentation files (the "Software"), to deal in
	-- the Software without restriction, including without limitation the rights to
	-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
	-- the Software, and to permit persons to whom the Software is furnished to do so,
	-- subject to the following conditions:

	-- The above copyright notice and this permission notice shall be included in all
	-- copies or substantial portions of the Software.

	-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
	-- FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
	-- COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
	-- IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
	-- CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

	local function deep_update(t1, t2)
	   for k, v in pairs(t2) do
	      if type(v) == "table" then
	         v = deep_update({}, v)
	      end

	      t1[k] = v
	   end

	   return t1
	end

	-- A property is a tuple {name, callback}.
	-- properties.args is number of properties that can be set as arguments
	-- when calling an object.
	local function class(prototype, properties, parent)
	   -- Class is the metatable of its instances.
	   local cl = {}
	   cl.__index = cl

	   if parent then
	      cl.__prototype = deep_update(deep_update({}, parent.__prototype), prototype)
	   else
	      cl.__prototype = prototype
	   end

	   if properties then
	      local names = {}

	      -- Create setter methods and fill set of property names.
	      for _, property in ipairs(properties) do
	         local name, callback = property[1], property[2]

	         cl[name] = function(self, value)
	            if not callback(self, value) then
	               self["_" .. name] = value
	            end

	            return self
	         end

	         names[name] = true
	      end

	      function cl.__call(self, ...)
	         -- When calling an object, if the first argument is a table,
	         -- interpret keys as property names, else delegate arguments
	         -- to corresponding setters in order.
	         if type((...)) == "table" then
	            for name, value in pairs((...)) do
	               if names[name] then
	                  self[name](self, value)
	               end
	            end
	         else
	            local nargs = select("#", ...)

	            for i, property in ipairs(properties) do
	               if i > nargs or i > properties.args then
	                  break
	               end

	               local arg = select(i, ...)

	               if arg ~= nil then
	                  self[property[1]](self, arg)
	               end
	            end
	         end

	         return self
	      end
	   end

	   -- If indexing class fails, fallback to its parent.
	   local class_metatable = {}
	   class_metatable.__index = parent

	   function class_metatable.__call(self, ...)
	      -- Calling a class returns its instance.
	      -- Arguments are delegated to the instance.
	      local object = deep_update({}, self.__prototype)
	      setmetatable(object, self)
	      return object(...)
	   end

	   return setmetatable(cl, class_metatable)
	end

	local function typecheck(name, types, value)
	   for _, type_ in ipairs(types) do
	      if type(value) == type_ then
	         return true
	      end
	   end

	   error(("bad property '%s' (%s expected, got %s)"):format(name, table.concat(types, " or "), type(value)))
	end

	local function typechecked(name, ...)
	   local types = { ... }
	   return { name, function(_, value) typecheck(name, types, value) end }
	end

	local multiname = { "name", function(self, value)
	   typecheck("name", { "string" }, value)

	   for alias in value:gmatch("%S+") do
	      self._name = self._name or alias
	      table.insert(self._aliases, alias)
	   end

	   -- Do not set _name as with other properties.
	   return true
	end }

	local function parse_boundaries(str)
	   if tonumber(str) then
	      return tonumber(str), tonumber(str)
	   end

	   if str == "*" then
	      return 0, math.huge
	   end

	   if str == "+" then
	      return 1, math.huge
	   end

	   if str == "?" then
	      return 0, 1
	   end

	   if str:match "^%d+%-%d+$" then
	      local min, max = str:match "^(%d+)%-(%d+)$"
	      return tonumber(min), tonumber(max)
	   end

	   if str:match "^%d+%+$" then
	      local min = str:match "^(%d+)%+$"
	      return tonumber(min), math.huge
	   end
	end

	local function boundaries(name)
	   return { name, function(self, value)
	      typecheck(name, { "number", "string" }, value)

	      local min, max = parse_boundaries(value)

	      if not min then
	         error(("bad property '%s'"):format(name))
	      end

	      self["_min" .. name], self["_max" .. name] = min, max
	   end }
	end

	local actions = {}

	local option_action = { "action", function(_, value)
	   typecheck("action", { "function", "string" }, value)

	   if type(value) == "string" and not actions[value] then
	      error(("unknown action '%s'"):format(value))
	   end
	end }

	local option_init = { "init", function(self)
	   self._has_init = true
	end }

	local option_default = { "default", function(self, value)
	   if type(value) ~= "string" then
	      self._init = value
	      self._has_init = true
	      return true
	   end
	end }

	local add_help = { "add_help", function(self, value)
	   typecheck("add_help", { "boolean", "string", "table" }, value)

	   if self._has_help then
	      table.remove(self._options)
	      self._has_help = false
	   end

	   if value then
	      local help = self:flag()
	          :description "Show this help message and exit."
	          :action(function()
	             print(self:get_help())
	             os.exit(0)
	          end)

	      if value ~= true then
	         help = help(value)
	      end

	      if not help._name then
	         help "-h" "--help"
	      end

	      self._has_help = true
	   end
	end }

	local Parser = class({
	   _arguments = {},
	   _options = {},
	   _commands = {},
	   _mutexes = {},
	   _groups = {},
	   _require_command = true,
	   _handle_options = true
	}, {
	   args = 3,
	   typechecked("name", "string"),
	   typechecked("description", "string"),
	   typechecked("epilog", "string"),
	   typechecked("usage", "string"),
	   typechecked("help", "string"),
	   typechecked("require_command", "boolean"),
	   typechecked("handle_options", "boolean"),
	   typechecked("action", "function"),
	   typechecked("command_target", "string"),
	   typechecked("help_vertical_space", "number"),
	   typechecked("usage_margin", "number"),
	   typechecked("usage_max_width", "number"),
	   typechecked("help_usage_margin", "number"),
	   typechecked("help_description_margin", "number"),
	   typechecked("help_max_width", "number"),
	   add_help
	})

	local Command = class({
	   _aliases = {}
	}, {
	   args = 3,
	   multiname,
	   typechecked("description", "string"),
	   typechecked("epilog", "string"),
	   typechecked("target", "string"),
	   typechecked("usage", "string"),
	   typechecked("help", "string"),
	   typechecked("require_command", "boolean"),
	   typechecked("handle_options", "boolean"),
	   typechecked("action", "function"),
	   typechecked("command_target", "string"),
	   typechecked("help_vertical_space", "number"),
	   typechecked("usage_margin", "number"),
	   typechecked("usage_max_width", "number"),
	   typechecked("help_usage_margin", "number"),
	   typechecked("help_description_margin", "number"),
	   typechecked("help_max_width", "number"),
	   typechecked("hidden", "boolean"),
	   add_help
	}, Parser)

	local Argument = class({
	   _minargs = 1,
	   _maxargs = 1,
	   _mincount = 1,
	   _maxcount = 1,
	   _defmode = "unused",
	   _show_default = true
	}, {
	   args = 5,
	   typechecked("name", "string"),
	   typechecked("description", "string"),
	   option_default,
	   typechecked("convert", "function", "table"),
	   boundaries("args"),
	   typechecked("target", "string"),
	   typechecked("defmode", "string"),
	   typechecked("show_default", "boolean"),
	   typechecked("argname", "string", "table"),
	   typechecked("hidden", "boolean"),
	   option_action,
	   option_init
	})

	local Option = class({
	   _aliases = {},
	   _mincount = 0,
	   _overwrite = true
	}, {
	   args = 6,
	   multiname,
	   typechecked("description", "string"),
	   option_default,
	   typechecked("convert", "function", "table"),
	   boundaries("args"),
	   boundaries("count"),
	   typechecked("target", "string"),
	   typechecked("defmode", "string"),
	   typechecked("show_default", "boolean"),
	   typechecked("overwrite", "boolean"),
	   typechecked("argname", "string", "table"),
	   typechecked("hidden", "boolean"),
	   option_action,
	   option_init
	}, Argument)

	function Parser:_inherit_property(name, default)
	   local element = self

	   while true do
	      local value = element["_" .. name]

	      if value ~= nil then
	         return value
	      end

	      if not element._parent then
	         return default
	      end

	      element = element._parent
	   end
	end

	function Argument:_get_argument_list()
	   local buf = {}
	   local i = 1

	   while i <= math.min(self._minargs, 3) do
	      local argname = self:_get_argname(i)

	      if self._default and self._defmode:find "a" then
	         argname = "[" .. argname .. "]"
	      end

	      table.insert(buf, argname)
	      i = i + 1
	   end

	   while i <= math.min(self._maxargs, 3) do
	      table.insert(buf, "[" .. self:_get_argname(i) .. "]")
	      i = i + 1

	      if self._maxargs == math.huge then
	         break
	      end
	   end

	   if i < self._maxargs then
	      table.insert(buf, "...")
	   end

	   return buf
	end

	function Argument:_get_usage()
	   local usage = table.concat(self:_get_argument_list(), " ")

	   if self._default and self._defmode:find "u" then
	      if self._maxargs > 1 or (self._minargs == 1 and not self._defmode:find "a") then
	         usage = "[" .. usage .. "]"
	      end
	   end

	   return usage
	end

	function actions.store_true(result, target)
	   result[target] = true
	end

	function actions.store_false(result, target)
	   result[target] = false
	end

	function actions.store(result, target, argument)
	   result[target] = argument
	end

	function actions.count(result, target, _, overwrite)
	   if not overwrite then
	      result[target] = result[target] + 1
	   end
	end

	function actions.append(result, target, argument, overwrite)
	   result[target] = result[target] or {}
	   table.insert(result[target], argument)

	   if overwrite then
	      table.remove(result[target], 1)
	   end
	end

	function actions.concat(result, target, arguments, overwrite)
	   if overwrite then
	      error("'concat' action can't handle too many invocations")
	   end

	   result[target] = result[target] or {}

	   for _, argument in ipairs(arguments) do
	      table.insert(result[target], argument)
	   end
	end

	function Argument:_get_action()
	   local action, init

	   if self._maxcount == 1 then
	      if self._maxargs == 0 then
	         action, init = "store_true", nil
	      else
	         action, init = "store", nil
	      end
	   else
	      if self._maxargs == 0 then
	         action, init = "count", 0
	      else
	         action, init = "append", {}
	      end
	   end

	   if self._action then
	      action = self._action
	   end

	   if self._has_init then
	      init = self._init
	   end

	   if type(action) == "string" then
	      action = actions[action]
	   end

	   return action, init
	end

	-- Returns placeholder for `narg`-th argument.
	function Argument:_get_argname(narg)
	   local argname = self._argname or self:_get_default_argname()

	   if type(argname) == "table" then
	      return argname[narg]
	   else
	      return argname
	   end
	end

	function Argument:_get_default_argname()
	   return "<" .. self._name .. ">"
	end

	function Option:_get_default_argname()
	   return "<" .. self:_get_default_target() .. ">"
	end

	-- Returns labels to be shown in the help message.
	function Argument:_get_label_lines()
	   return { self._name }
	end

	function Option:_get_label_lines()
	   local argument_list = self:_get_argument_list()

	   if #argument_list == 0 then
	      -- Don't put aliases for simple flags like `-h` on different lines.
	      return { table.concat(self._aliases, ", ") }
	   end

	   local longest_alias_length = -1

	   for _, alias in ipairs(self._aliases) do
	      longest_alias_length = math.max(longest_alias_length, #alias)
	   end

	   local argument_list_repr = table.concat(argument_list, " ")
	   local lines = {}

	   for i, alias in ipairs(self._aliases) do
	      local line = (" "):rep(longest_alias_length - #alias) .. alias .. " " .. argument_list_repr

	      if i ~= #self._aliases then
	         line = line .. ","
	      end

	      table.insert(lines, line)
	   end

	   return lines
	end

	function Command:_get_label_lines()
	   return { table.concat(self._aliases, ", ") }
	end

	function Argument:_get_description()
	   if self._default and self._show_default then
	      if self._description then
	         return ("%s (default: %s)"):format(self._description, self._default)
	      else
	         return ("default: %s"):format(self._default)
	      end
	   else
	      return self._description or ""
	   end
	end

	function Command:_get_description()
	   return self._description or ""
	end

	function Option:_get_usage()
	   local usage = self:_get_argument_list()
	   table.insert(usage, 1, self._name)
	   usage = table.concat(usage, " ")

	   if self._mincount == 0 or self._default then
	      usage = "[" .. usage .. "]"
	   end

	   return usage
	end

	function Argument:_get_default_target()
	   return self._name
	end

	function Option:_get_default_target()
	   local res

	   for _, alias in ipairs(self._aliases) do
	      if alias:sub(1, 1) == alias:sub(2, 2) then
	         res = alias:sub(3)
	         break
	      end
	   end

	   res = res or self._name:sub(2)
	   return (res:gsub("-", "_"))
	end

	function Option:_is_vararg()
	   return self._maxargs ~= self._minargs
	end

	function Parser:_get_fullname()
	   local parent = self._parent
	   local buf = { self._name }

	   while parent do
	      table.insert(buf, 1, parent._name)
	      parent = parent._parent
	   end

	   return table.concat(buf, " ")
	end

	function Parser:_update_charset(charset)
	   charset = charset or {}

	   for _, command in ipairs(self._commands) do
	      command:_update_charset(charset)
	   end

	   for _, option in ipairs(self._options) do
	      for _, alias in ipairs(option._aliases) do
	         charset[alias:sub(1, 1)] = true
	      end
	   end

	   return charset
	end

	function Parser:argument(...)
	   local argument = Argument(...)
	   table.insert(self._arguments, argument)
	   return argument
	end

	function Parser:option(...)
	   local option = Option(...)

	   if self._has_help then
	      table.insert(self._options, #self._options, option)
	   else
	      table.insert(self._options, option)
	   end

	   return option
	end

	function Parser:flag(...)
	   return self:option():args(0)(...)
	end

	function Parser:command(...)
	   local command = Command():add_help(true)(...)
	   command._parent = self
	   table.insert(self._commands, command)
	   return command
	end

	function Parser:mutex(...)
	   local elements = { ... }

	   for i, element in ipairs(elements) do
	      local mt = getmetatable(element)
	      assert(mt == Option or mt == Argument, ("bad argument #%d to 'mutex' (Option or Argument expected)"):format(i))
	   end

	   table.insert(self._mutexes, elements)
	   return self
	end

	function Parser:group(name, ...)
	   assert(type(name) == "string", ("bad argument #1 to 'group' (string expected, got %s)"):format(type(name)))

	   local group = { name = name, ... }

	   for i, element in ipairs(group) do
	      local mt = getmetatable(element)
	      assert(mt == Option or mt == Argument or mt == Command,
	         ("bad argument #%d to 'group' (Option or Argument or Command expected)"):format(i + 1))
	   end

	   table.insert(self._groups, group)
	   return self
	end

	local usage_welcome = "Usage: "

	function Parser:get_usage()
	   if self._usage then
	      return self._usage
	   end

	   local usage_margin = self:_inherit_property("usage_margin", #usage_welcome)
	   local max_usage_width = self:_inherit_property("usage_max_width", 70)
	   local lines = { usage_welcome .. self:_get_fullname() }

	   local function add(s)
	      if #lines[#lines] + 1 + #s <= max_usage_width then
	         lines[#lines] = lines[#lines] .. " " .. s
	      else
	         lines[#lines + 1] = (" "):rep(usage_margin) .. s
	      end
	   end

	   -- Normally options are before positional arguments in usage messages.
	   -- However, vararg options should be after, because they can't be reliable used
	   -- before a positional argument.
	   -- Mutexes come into play, too, and are shown as soon as possible.
	   -- Overall, output usages in the following order:
	   -- 1. Mutexes that don't have positional arguments or vararg options.
	   -- 2. Options that are not in any mutexes and are not vararg.
	   -- 3. Positional arguments - on their own or as a part of a mutex.
	   -- 4. Remaining mutexes.
	   -- 5. Remaining options.

	   local elements_in_mutexes = {}
	   local added_elements = {}
	   local added_mutexes = {}
	   local argument_to_mutexes = {}

	   local function add_mutex(mutex, main_argument)
	      if added_mutexes[mutex] then
	         return
	      end

	      added_mutexes[mutex] = true
	      local buf = {}

	      for _, element in ipairs(mutex) do
	         if not element._hidden and not added_elements[element] then
	            if getmetatable(element) == Option or element == main_argument then
	               table.insert(buf, element:_get_usage())
	               added_elements[element] = true
	            end
	         end
	      end

	      if #buf == 1 then
	         add(buf[1])
	      elseif #buf > 1 then
	         add("(" .. table.concat(buf, " | ") .. ")")
	      end
	   end

	   local function add_element(element)
	      if not element._hidden and not added_elements[element] then
	         add(element:_get_usage())
	         added_elements[element] = true
	      end
	   end

	   for _, mutex in ipairs(self._mutexes) do
	      local is_vararg = false
	      local has_argument = false

	      for _, element in ipairs(mutex) do
	         if getmetatable(element) == Option then
	            if element:_is_vararg() then
	               is_vararg = true
	            end
	         else
	            has_argument = true
	            argument_to_mutexes[element] = argument_to_mutexes[element] or {}
	            table.insert(argument_to_mutexes[element], mutex)
	         end

	         elements_in_mutexes[element] = true
	      end

	      if not is_vararg and not has_argument then
	         add_mutex(mutex)
	      end
	   end

	   for _, option in ipairs(self._options) do
	      if not elements_in_mutexes[option] and not option:_is_vararg() then
	         add_element(option)
	      end
	   end

	   -- Add usages for positional arguments, together with one mutex containing them, if they are in a mutex.
	   for _, argument in ipairs(self._arguments) do
	      -- Pick a mutex as a part of which to show this argument, take the first one that's still available.
	      local mutex

	      if elements_in_mutexes[argument] then
	         for _, argument_mutex in ipairs(argument_to_mutexes[argument]) do
	            if not added_mutexes[argument_mutex] then
	               mutex = argument_mutex
	            end
	         end
	      end

	      if mutex then
	         add_mutex(mutex, argument)
	      else
	         add_element(argument)
	      end
	   end

	   for _, mutex in ipairs(self._mutexes) do
	      add_mutex(mutex)
	   end

	   for _, option in ipairs(self._options) do
	      add_element(option)
	   end

	   if #self._commands > 0 then
	      if self._require_command then
	         add("<command>")
	      else
	         add("[<command>]")
	      end

	      add("...")
	   end

	   return table.concat(lines, "\n")
	end

	local function split_lines(s)
	   if s == "" then
	      return {}
	   end

	   local lines = {}

	   if s:sub(-1) ~= "\n" then
	      s = s .. "\n"
	   end

	   for line in s:gmatch("([^\n]*)\n") do
	      table.insert(lines, line)
	   end

	   return lines
	end

	local function autowrap_line(line, max_length)
	   -- Algorithm for splitting lines is simple and greedy.
	   local result_lines = {}

	   -- Preserve original indentation of the line, put this at the beginning of each result line.
	   -- If the first word looks like a list marker ('*', '+', or '-'), add spaces so that starts
	   -- of the second and the following lines vertically align with the start of the second word.
	   local indentation = line:match("^ *")

	   if line:find("^ *[%*%+%-]") then
	      indentation = indentation .. " " .. line:match("^ *[%*%+%-]( *)")
	   end

	   -- Parts of the last line being assembled.
	   local line_parts = {}

	   -- Length of the current line.
	   local line_length = 0

	   -- Index of the next character to consider.
	   local index = 1

	   while true do
	      local word_start, word_finish, word = line:find("([^ ]+)", index)

	      if not word_start then
	         -- Ignore trailing spaces, if any.
	         break
	      end

	      local preceding_spaces = line:sub(index, word_start - 1)
	      index = word_finish + 1

	      if (#line_parts == 0) or (line_length + #preceding_spaces + #word <= max_length) then
	         -- Either this is the very first word or it fits as an addition to the current line, add it.
	         table.insert(line_parts, preceding_spaces) -- For the very first word this adds the indentation.
	         table.insert(line_parts, word)
	         line_length = line_length + #preceding_spaces + #word
	      else
	         -- Does not fit, finish current line and put the word into a new one.
	         table.insert(result_lines, table.concat(line_parts))
	         line_parts = { indentation, word }
	         line_length = #indentation + #word
	      end
	   end

	   if #line_parts > 0 then
	      table.insert(result_lines, table.concat(line_parts))
	   end

	   if #result_lines == 0 then
	      -- Preserve empty lines.
	      result_lines[1] = ""
	   end

	   return result_lines
	end

	-- Automatically wraps lines within given array,
	-- attempting to limit line length to `max_length`.
	-- Existing line splits are preserved.
	local function autowrap(lines, max_length)
	   local result_lines = {}

	   for _, line in ipairs(lines) do
	      local autowrapped_lines = autowrap_line(line, max_length)

	      for _, autowrapped_line in ipairs(autowrapped_lines) do
	         table.insert(result_lines, autowrapped_line)
	      end
	   end

	   return result_lines
	end

	function Parser:_get_element_help(element)
	   local label_lines = element:_get_label_lines()
	   local description_lines = split_lines(element:_get_description())

	   local result_lines = {}

	   -- All label lines should have the same length (except the last one, it has no comma).
	   -- If too long, start description after all the label lines.
	   -- Otherwise, combine label and description lines.

	   local usage_margin_len = self:_inherit_property("help_usage_margin", 3)
	   local usage_margin = (" "):rep(usage_margin_len)
	   local description_margin_len = self:_inherit_property("help_description_margin", 25)
	   local description_margin = (" "):rep(description_margin_len)

	   local help_max_width = self:_inherit_property("help_max_width")

	   if help_max_width then
	      local description_max_width = math.max(help_max_width - description_margin_len, 10)
	      description_lines = autowrap(description_lines, description_max_width)
	   end

	   if #label_lines[1] >= (description_margin_len - usage_margin_len) then
	      for _, label_line in ipairs(label_lines) do
	         table.insert(result_lines, usage_margin .. label_line)
	      end

	      for _, description_line in ipairs(description_lines) do
	         table.insert(result_lines, description_margin .. description_line)
	      end
	   else
	      for i = 1, math.max(#label_lines, #description_lines) do
	         local label_line = label_lines[i]
	         local description_line = description_lines[i]

	         local line = ""

	         if label_line then
	            line = usage_margin .. label_line
	         end

	         if description_line and description_line ~= "" then
	            line = line .. (" "):rep(description_margin_len - #line) .. description_line
	         end

	         table.insert(result_lines, line)
	      end
	   end

	   return table.concat(result_lines, "\n")
	end

	local function get_group_types(group)
	   local types = {}

	   for _, element in ipairs(group) do
	      types[getmetatable(element)] = true
	   end

	   return types
	end

	function Parser:_add_group_help(blocks, added_elements, label, elements)
	   local buf = { label }

	   for _, element in ipairs(elements) do
	      if not element._hidden and not added_elements[element] then
	         added_elements[element] = true
	         table.insert(buf, self:_get_element_help(element))
	      end
	   end

	   if #buf > 1 then
	      table.insert(blocks, table.concat(buf, ("\n"):rep(self:_inherit_property("help_vertical_space", 0) + 1)))
	   end
	end

	function Parser:get_help()
	   if self._help then
	      return self._help
	   end

	   local blocks = { self:get_usage() }

	   local help_max_width = self:_inherit_property("help_max_width")

	   if self._description then
	      local description = self._description

	      if help_max_width then
	         description = table.concat(autowrap(split_lines(description), help_max_width), "\n")
	      end

	      table.insert(blocks, description)
	   end

	   -- 1. Put groups containing arguments first, then other arguments.
	   -- 2. Put remaining groups containing options, then other options.
	   -- 3. Put remaining groups containing commands, then other commands.
	   -- Assume that an element can't be in several groups.
	   local groups_by_type = {
	      [Argument] = {},
	      [Option] = {},
	      [Command] = {}
	   }

	   for _, group in ipairs(self._groups) do
	      local group_types = get_group_types(group)

	      for _, mt in ipairs({ Argument, Option, Command }) do
	         if group_types[mt] then
	            table.insert(groups_by_type[mt], group)
	            break
	         end
	      end
	   end

	   local default_groups = {
	      { name = "Arguments", type = Argument, elements = self._arguments },
	      { name = "Options",   type = Option,   elements = self._options },
	      { name = "Commands",  type = Command,  elements = self._commands }
	   }

	   local added_elements = {}

	   for _, default_group in ipairs(default_groups) do
	      local type_groups = groups_by_type[default_group.type]

	      for _, group in ipairs(type_groups) do
	         self:_add_group_help(blocks, added_elements, group.name .. ":", group)
	      end

	      local default_label = default_group.name .. ":"

	      if #type_groups > 0 then
	         default_label = "Other " .. default_label:gsub("^.", string.lower)
	      end

	      self:_add_group_help(blocks, added_elements, default_label, default_group.elements)
	   end

	   if self._epilog then
	      local epilog = self._epilog

	      if help_max_width then
	         epilog = table.concat(autowrap(split_lines(epilog), help_max_width), "\n")
	      end

	      table.insert(blocks, epilog)
	   end

	   return table.concat(blocks, "\n\n")
	end

	local function get_tip(context, wrong_name)
	   local context_pool = {}
	   local possible_name
	   local possible_names = {}

	   for name in pairs(context) do
	      if type(name) == "string" then
	         for i = 1, #name do
	            possible_name = name:sub(1, i - 1) .. name:sub(i + 1)

	            if not context_pool[possible_name] then
	               context_pool[possible_name] = {}
	            end

	            table.insert(context_pool[possible_name], name)
	         end
	      end
	   end

	   for i = 1, #wrong_name + 1 do
	      possible_name = wrong_name:sub(1, i - 1) .. wrong_name:sub(i + 1)

	      if context[possible_name] then
	         possible_names[possible_name] = true
	      elseif context_pool[possible_name] then
	         for _, name in ipairs(context_pool[possible_name]) do
	            possible_names[name] = true
	         end
	      end
	   end

	   local first = next(possible_names)

	   if first then
	      if next(possible_names, first) then
	         local possible_names_arr = {}

	         for name in pairs(possible_names) do
	            table.insert(possible_names_arr, "'" .. name .. "'")
	         end

	         table.sort(possible_names_arr)
	         return "\nDid you mean one of these: " .. table.concat(possible_names_arr, " ") .. "?"
	      else
	         return "\nDid you mean '" .. first .. "'?"
	      end
	   else
	      return ""
	   end
	end

	local ElementState = class({
	   invocations = 0
	})

	function ElementState:__call(state, element)
	   self.state = state
	   self.result = state.result
	   self.element = element
	   self.target = element._target or element:_get_default_target()
	   self.action, self.result[self.target] = element:_get_action()
	   return self
	end

	function ElementState:error(fmt, ...)
	   self.state:error(fmt, ...)
	end

	function ElementState:convert(argument, index)
	   local converter = self.element._convert

	   if converter then
	      local ok, err

	      if type(converter) == "function" then
	         ok, err = converter(argument)
	      elseif type(converter[index]) == "function" then
	         ok, err = converter[index](argument)
	      else
	         ok = converter[argument]
	      end

	      if ok == nil then
	         self:error(err and "%s" or "malformed argument '%s'", err or argument)
	      end

	      argument = ok
	   end

	   return argument
	end

	function ElementState:default(mode)
	   return self.element._defmode:find(mode) and self.element._default
	end

	local function bound(noun, min, max, is_max)
	   local res = ""

	   if min ~= max then
	      res = "at " .. (is_max and "most" or "least") .. " "
	   end

	   local number = is_max and max or min
	   return res .. tostring(number) .. " " .. noun .. (number == 1 and "" or "s")
	end

	function ElementState:set_name(alias)
	   self.name = ("%s '%s'"):format(alias and "option" or "argument", alias or self.element._name)
	end

	function ElementState:invoke()
	   self.open = true
	   self.overwrite = false

	   if self.invocations >= self.element._maxcount then
	      if self.element._overwrite then
	         self.overwrite = true
	      else
	         local num_times_repr = bound("time", self.element._mincount, self.element._maxcount, true)
	         self:error("%s must be used %s", self.name, num_times_repr)
	      end
	   else
	      self.invocations = self.invocations + 1
	   end

	   self.args = {}

	   if self.element._maxargs <= 0 then
	      self:close()
	   end

	   return self.open
	end

	function ElementState:pass(argument)
	   argument = self:convert(argument, #self.args + 1)
	   table.insert(self.args, argument)

	   if #self.args >= self.element._maxargs then
	      self:close()
	   end

	   return self.open
	end

	function ElementState:complete_invocation()
	   while #self.args < self.element._minargs do
	      self:pass(self.element._default)
	   end
	end

	function ElementState:close()
	   if self.open then
	      self.open = false

	      if #self.args < self.element._minargs then
	         if self:default("a") then
	            self:complete_invocation()
	         else
	            if #self.args == 0 then
	               if getmetatable(self.element) == Argument then
	                  self:error("missing %s", self.name)
	               elseif self.element._maxargs == 1 then
	                  self:error("%s requires an argument", self.name)
	               end
	            end

	            self:error("%s requires %s", self.name, bound("argument", self.element._minargs, self.element._maxargs))
	         end
	      end

	      local args

	      if self.element._maxargs == 0 then
	         args = self.args[1]
	      elseif self.element._maxargs == 1 then
	         if self.element._minargs == 0 and self.element._mincount ~= self.element._maxcount then
	            args = self.args
	         else
	            args = self.args[1]
	         end
	      else
	         args = self.args
	      end

	      self.action(self.result, self.target, args, self.overwrite)
	   end
	end

	local ParseState = class({
	   result = {},
	   options = {},
	   arguments = {},
	   argument_i = 1,
	   element_to_mutexes = {},
	   mutex_to_element_state = {},
	   command_actions = {}
	})

	function ParseState:__call(parser, error_handler)
	   self.parser = parser
	   self.error_handler = error_handler
	   self.charset = parser:_update_charset()
	   self:switch(parser)
	   return self
	end

	function ParseState:error(fmt, ...)
	   self.error_handler(self.parser, fmt:format(...))
	end

	function ParseState:switch(parser)
	   self.parser = parser

	   if parser._action then
	      table.insert(self.command_actions, { action = parser._action, name = parser._name })
	   end

	   for _, option in ipairs(parser._options) do
	      option = ElementState(self, option)
	      table.insert(self.options, option)

	      for _, alias in ipairs(option.element._aliases) do
	         self.options[alias] = option
	      end
	   end

	   for _, mutex in ipairs(parser._mutexes) do
	      for _, element in ipairs(mutex) do
	         if not self.element_to_mutexes[element] then
	            self.element_to_mutexes[element] = {}
	         end

	         table.insert(self.element_to_mutexes[element], mutex)
	      end
	   end

	   for _, argument in ipairs(parser._arguments) do
	      argument = ElementState(self, argument)
	      table.insert(self.arguments, argument)
	      argument:set_name()
	      argument:invoke()
	   end

	   self.handle_options = parser._handle_options
	   self.argument = self.arguments[self.argument_i]
	   self.commands = parser._commands

	   for _, command in ipairs(self.commands) do
	      for _, alias in ipairs(command._aliases) do
	         self.commands[alias] = command
	      end
	   end
	end

	function ParseState:get_option(name)
	   local option = self.options[name]

	   if not option then
	      self:error("unknown option '%s'%s", name, get_tip(self.options, name))
	   else
	      return option
	   end
	end

	function ParseState:get_command(name)
	   local command = self.commands[name]

	   if not command then
	      if #self.commands > 0 then
	         self:error("unknown command '%s'%s", name, get_tip(self.commands, name))
	      else
	         self:error("too many arguments")
	      end
	   else
	      return command
	   end
	end

	function ParseState:check_mutexes(element_state)
	   if self.element_to_mutexes[element_state.element] then
	      for _, mutex in ipairs(self.element_to_mutexes[element_state.element]) do
	         local used_element_state = self.mutex_to_element_state[mutex]

	         if used_element_state and used_element_state ~= element_state then
	            self:error("%s can not be used together with %s", element_state.name, used_element_state.name)
	         else
	            self.mutex_to_element_state[mutex] = element_state
	         end
	      end
	   end
	end

	function ParseState:invoke(option, name)
	   self:close()
	   option:set_name(name)
	   self:check_mutexes(option)

	   if option:invoke() then
	      self.option = option
	   end
	end

	function ParseState:pass(arg)
	   if self.option then
	      if not self.option:pass(arg) then
	         self.option = nil
	      end
	   elseif self.argument then
	      self:check_mutexes(self.argument)

	      if not self.argument:pass(arg) then
	         self.argument_i = self.argument_i + 1
	         self.argument = self.arguments[self.argument_i]
	      end
	   else
	      local command = self:get_command(arg)
	      self.result[command._target or command._name] = true

	      if self.parser._command_target then
	         self.result[self.parser._command_target] = command._name
	      end

	      self:switch(command)
	   end
	end

	function ParseState:close()
	   if self.option then
	      self.option:close()
	      self.option = nil
	   end
	end

	function ParseState:finalize()
	   self:close()

	   for i = self.argument_i, #self.arguments do
	      local argument = self.arguments[i]
	      if #argument.args == 0 and argument:default("u") then
	         argument:complete_invocation()
	      else
	         argument:close()
	      end
	   end

	   if self.parser._require_command and #self.commands > 0 then
	      self:error("a command is required")
	   end

	   for _, option in ipairs(self.options) do
	      option.name = option.name or ("option '%s'"):format(option.element._name)

	      if option.invocations == 0 then
	         if option:default("u") then
	            option:invoke()
	            option:complete_invocation()
	            option:close()
	         end
	      end

	      local mincount = option.element._mincount

	      if option.invocations < mincount then
	         if option:default("a") then
	            while option.invocations < mincount do
	               option:invoke()
	               option:close()
	            end
	         elseif option.invocations == 0 then
	            self:error("missing %s", option.name)
	         else
	            self:error("%s must be used %s", option.name, bound("time", mincount, option.element._maxcount))
	         end
	      end
	   end

	   for i = #self.command_actions, 1, -1 do
	      self.command_actions[i].action(self.result, self.command_actions[i].name)
	   end
	end

	function ParseState:parse(args)
	   for _, arg in ipairs(args) do
	      local plain = true

	      if self.handle_options then
	         local first = arg:sub(1, 1)

	         if self.charset[first] then
	            if #arg > 1 then
	               plain = false

	               if arg:sub(2, 2) == first then
	                  if #arg == 2 then
	                     if self.options[arg] then
	                        local option = self:get_option(arg)
	                        self:invoke(option, arg)
	                     else
	                        self:close()
	                     end

	                     self.handle_options = false
	                  else
	                     local equals = arg:find "="
	                     if equals then
	                        local name = arg:sub(1, equals - 1)
	                        local option = self:get_option(name)

	                        if option.element._maxargs <= 0 then
	                           self:error("option '%s' does not take arguments", name)
	                        end

	                        self:invoke(option, name)
	                        self:pass(arg:sub(equals + 1))
	                     else
	                        local option = self:get_option(arg)
	                        self:invoke(option, arg)
	                     end
	                  end
	               else
	                  for i = 2, #arg do
	                     local name = first .. arg:sub(i, i)
	                     local option = self:get_option(name)
	                     self:invoke(option, name)

	                     if i ~= #arg and option.element._maxargs > 0 then
	                        self:pass(arg:sub(i + 1))
	                        break
	                     end
	                  end
	               end
	            end
	         end
	      end

	      if plain then
	         self:pass(arg)
	      end
	   end

	   self:finalize()
	   return self.result
	end

	function Parser:error(msg)
	   io.stderr:write(("%s\n\nError: %s\n"):format(self:get_usage(), msg))
	   os.exit(1)
	end

	-- Compatibility with strict.lua and other checkers:
	local default_cmdline = rawget(_G, "arg") or {}

	function Parser:_parse(args, error_handler)
	   return ParseState(self, error_handler):parse(args or default_cmdline)
	end

	function Parser:parse(args)
	   return self:_parse(args, self.error)
	end

	local function xpcall_error_handler(err)
	   return tostring(err) .. "\noriginal " .. debug.traceback("", 2):sub(2)
	end

	function Parser:pparse(args)
	   local parse_error

	   local ok, result = xpcall(function()
	      return self:_parse(args, function(_, err)
	         parse_error = err
	         error(err, 0)
	      end)
	   end, xpcall_error_handler)

	   if ok then
	      return true, result
	   elseif not parse_error then
	      error(result, 0)
	   else
	      return false, parse_error
	   end
	end

	local argparse = {}

	argparse.version = "0.6.0"

	setmetatable(argparse, {
	   __call = function(_, ...)
	      return Parser(default_cmdline[0]):add_help(true)(...)
	   end
	})

	return argparse

end

__bundler__.__files__["src.utils.number"] = function()
	---@class Freemaker.utils.number
	local _number = {}

	---@type table<integer, integer>
	local round_cache = {}

	---@param value number
	---@param decimal integer | nil
	---@return integer
	function _number.round(value, decimal)
	    decimal = decimal or 0
	    if decimal > 308 then
	        error("cannot round more decimals than 308")
	    end

	    local mult = round_cache[decimal]
	    if not mult then
	        mult = 10 ^ decimal
	        round_cache[decimal] = mult
	    end

	    return ((value * mult + 0.5) // 1) / mult
	end

	---@param value number
	---@param min number
	---@param max number
	---@return number
	function _number.clamp(value, min, max)
	    if value < min then
	        return min
	    end

	    if value > max then
	        return max
	    end

	    return value
	end

	return _number

end

__bundler__.__files__["src.utils.string.builder"] = function()
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

end

__bundler__.__files__["src.utils.string.init"] = function()
	---@class Freemaker.utils.string
	---@field builder Freemaker.utils.string.builder
	local _string = {
	    builder = __bundler__.__loadFile__("src.utils.string.builder")
	}

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

	---@param str string
	---@param length integer
	---@param char string | nil
	function _string.left_pad(str, length, char)
	    local str_length = str:len()
	    return string.rep(char or " ", length - str_length) .. str
	end

	---@param str string
	---@param length integer
	---@param char string | nil
	function _string.right_pad(str, length, char)
	    local str_length = str:len()
	    return str .. string.rep(char or " ", length - str_length)
	end

	return _string

end

__bundler__.__files__["src.utils.table"] = function()
	---@class Freemaker.utils.table
	local _table = {}

	---@param t table
	---@param copy table
	---@param seen table<table, table>
	---@return table
	local function copy_table_to(t, copy, seen)
	    if seen[t] then
	        return seen[t]
	    end

	    seen[t] = copy

	    for key, value in next, t do
	        if type(value) == "table" then
	            copy[key] = copy_table_to(value, copy[key] or {}, seen)
	        else
	            copy[key] = value
	        end
	    end

	    local t_meta = getmetatable(t)
	    if t_meta then
	        local copy_meta = getmetatable(copy) or {}
	        copy_table_to(t_meta, copy_meta, seen)
	        setmetatable(copy, copy_meta)
	    end

	    return copy
	end

	---@generic T
	---@param t T
	---@return T table
	function _table.copy(t)
	    return copy_table_to(t, {}, {})
	end

	---@generic T
	---@param from T
	---@param to T
	function _table.copy_to(from, to)
	    copy_table_to(from, to, {})
	end

	---@param t table
	---@param ignoreProperties string[] | nil
	function _table.clear(t, ignoreProperties)
	    if not ignoreProperties then
	        for key, _ in next, t, nil do
	            t[key] = nil
	        end
	    else
	        for key, _ in next, t, nil do
	            if not _table.contains(ignoreProperties, key) then
	                t[key] = nil
	            end
	        end
	    end

	    setmetatable(t, nil)
	end

	---@param t table
	---@param value any
	---@return boolean
	function _table.contains(t, value)
	    for _, tValue in pairs(t) do
	        if value == tValue then
	            return true
	        end
	    end

	    return false
	end

	---@param t table
	---@param key any
	---@return boolean
	function _table.contains_key(t, key)
	    if t[key] ~= nil then
	        return true
	    end

	    return false
	end

	---@param t table
	---@return integer count
	function _table.count(t)
	    local count = 0

	    for _, _ in next, t, nil do
	        count = count + 1
	    end

	    return count
	end

	---@param t table
	---@return table
	function _table.invert(t)
	    local inverted = {}

	    for key, value in pairs(t) do
	        inverted[value] = key
	    end

	    return inverted
	end

	---@generic T
	---@generic R
	---@param t T[]
	---@param func fun(value: T) : R
	---@return R[]
	function _table.map(t, func)
	    ---@type any[]
	    local result = {}

	    for index, value in ipairs(t) do
	        result[index] = func(value)
	    end

	    return result
	end

	-- Only makes this table readonly
	-- **NOT** the child tables
	---@generic T
	---@param t T
	---@return T
	function _table.readonly(t)
	    return setmetatable({}, {
	        __newindex = function()
	            error("this table is readonly")
	        end,
	        __index = t
	    })
	end

	---@generic T
	---@generic R
	---@param t T
	---@param func fun(key: any, value: any) : R
	---@return R[]
	function _table.select(t, func)
	    local copy = _table.copy(t)

	    for key, value in pairs(copy) do
	        if not func(key, value) then
	            copy[key] = nil
	        end
	    end

	    return copy
	end

	---@generic T
	---@generic R
	---@param t T
	---@param func fun(key: any, value: any) : R
	---@return R[]
	function _table.select_implace(t, func)
	    for key, value in pairs(t) do
	        if not func(key, value) then
	            t[key] = nil
	        end
	    end

	    return t
	end

	return _table

end

__bundler__.__files__["src.utils.array"] = function()
	local table_insert = table.insert

	---@generic T
	---@param t T[]
	---@param value T
	local function insert_first_nil(t, value)
	    local i = 0
	    while true do
	        i = i + 1
	        if t[i] == nil then
	            t[i] = value
	            return
	        end
	    end
	end

	---@class Freemaker.utils.array
	local _array = {}

	---@generic T
	---@param t T[]
	---@param amount integer
	---@return T[]
	function _array.take_front(t, amount)
	    local length = #t
	    if amount > length then
	        amount = length
	    end

	    local copy = {}
	    for i = 1, amount, 1 do
	        table_insert(copy, t[i])
	    end
	    return copy
	end

	---@generic T
	---@param t T[]
	---@param amount integer
	---@return T[]
	function _array.take_back(t, amount)
	    local length = #t
	    local start = #t - amount + 1
	    if start < 1 then
	        start = 1
	    end

	    local copy = {}
	    for i = start, length, 1 do
	        table_insert(copy, t[i])
	    end
	    return copy
	end

	---@generic T
	---@param t T[]
	---@param amount integer
	---@return T[]
	function _array.drop_front_implace(t, amount)
	    for i, value in ipairs(t) do
	        if i <= amount then
	            t[i] = nil
	        else
	            insert_first_nil(t, value)
	            t[i] = nil
	        end
	    end
	    return t
	end

	---@generic T
	---@param t T[]
	---@param amount integer
	---@return T[]
	function _array.drop_back_implace(t, amount)
	    local length = #t
	    local start = length - amount + 1

	    for i = start, length, 1 do
	        t[i] = nil
	    end
	    return t
	end

	---@generic T
	---@generic R
	---@param t T[]
	---@param func fun(index: integer, value: T) : R
	---@return R[]
	function _array.select(t, func)
	    local copy = {}
	    for index, value in pairs(t) do
	        table_insert(copy, func(index, value))
	    end
	    return copy
	end

	---@generic T
	---@generic R
	---@param t T[]
	---@param func fun(index: integer, value: T) : R
	---@return R[]
	function _array.select_implace(t, func)
	    for index, value in pairs(t) do
	        local new_value = func(index, value)
	        t[index] = nil
	        if new_value then
	            insert_first_nil(t, new_value)
	        end
	    end
	    return t
	end

	--- removes all spaces between
	---@param t any[]
	function _array.clean(t)
	    for key, value in pairs(t) do
	        for i = key - 1, 1, -1 do
	            if key == 1 then
	                goto continue
	            end

	            if t[i] == nil and (t[i - 1] ~= nil or i == 1) then
	                t[i] = value
	                t[key] = nil
	                break
	            end

	            ::continue::
	        end
	    end
	end

	return _array

end

__bundler__.__files__["src.utils.value"] = function()
	local table = __bundler__.__loadFile__("src.utils.table")

	---@class Freemaker.utils.value
	local _value = {}

	---@generic T
	---@param x T
	---@return T
	function _value.copy(x)
	    local typeStr = type(x)
	    if typeStr == "table" then
	        return table.copy(x)
	    end

	    return x
	end

	---@generic T
	---@param value T | nil
	---@param default_value T
	---@return T
	function _value.default(value, default_value)
	    if value == nil then
	        return default_value
	    end

	    return value
	end

	return _value

end

__bundler__.__files__["src.utils.stopwatch"] = function()
	---@class Freemaker.utils.stopwatch
	---@field start_time number | nil
	---@field last_lap_time number | nil
	local _stopwatch = {}

	function _stopwatch.new()
	    return setmetatable({
	    }, { __index = _stopwatch })
	end

	function _stopwatch.start_new()
	    local instance = _stopwatch.new()
	    instance:start()
	    return instance
	end

	function _stopwatch:start()
	    if self.start_time then
	        return
	    end

	    self.start_time = os.clock()
	end

	---@return number elapesd_milliseconds
	function _stopwatch:stop()
	    if not self.start_time then
	        return 0
	    end

	    local elapesd_time = os.clock() - self.start_time
	    self.start_time = nil

	    return elapesd_time * 1000
	end

	---@return number elapesd_milliseconds
	function _stopwatch:lap()
	    if not self.start_time then
	        return 0
	    end

	    local lap_time = os.clock()
	    self.last_lap_time = lap_time

	    local previous_lap = self.last_lap_time or self.start_time
	    local elapesd_time = lap_time - previous_lap

	    return elapesd_time * 1000
	end

	return _stopwatch

end

__bundler__.__files__["src.utils.init"] = function()
	---@class Freemaker.utils
	---@field number Freemaker.utils.number
	---@field string Freemaker.utils.string
	---@field table Freemaker.utils.table
	---@field array Freemaker.utils.array
	---@field value Freemaker.utils.value
	---
	---@field stopwatch Freemaker.utils.stopwatch
	local utils = {}

	utils.number = __bundler__.__loadFile__("src.utils.number")
	utils.string = __bundler__.__loadFile__("src.utils.string.init")
	utils.table = __bundler__.__loadFile__("src.utils.table")
	utils.array = __bundler__.__loadFile__("src.utils.array")
	utils.value = __bundler__.__loadFile__("src.utils.value")

	utils.stopwatch = __bundler__.__loadFile__("src.utils.stopwatch")

	return utils

end

__bundler__.__files__["bin.lfs"] = function()
	---@type lfs
	local lfs = require("lfs")

	function lfs.exists(path)
	    return lfs.attributes(path, "mode") ~= nil
	end

	return lfs

end

__bundler__.__files__["src.path"] = function()
	local utils = __bundler__.__loadFile__("src.utils.init")

	---@type lfs
	local file_system = __bundler__.__loadFile__("bin.lfs")

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
	    if self.m_nodes[#self.m_nodes] == "" then
	        return false
	    end

	    return file_system.attributes(self:to_string(), "mode") == "file"
	end

	---@return boolean
	function _path:is_dir()
	    local path = self:to_string()
	    if self.m_nodes[#self.m_nodes] == "" then
	        path = path:sub(0, -2)
	    end

	    return file_system.attributes(path, "mode") == "directory"
	end

	function _path:exists()
	    local path = self:to_string()
	    if self.m_nodes[#self.m_nodes] == "" then
	        path = path:sub(0, -2)
	    end

	    return file_system.exists(path)
	end

	---@param all boolean | nil
	---@return boolean
	function _path:create(all)
	    if self:exists() then
	        return true
	    end

	    if all and #self.m_nodes > 1 then
	        if not self:get_parent_folder_path():create(all) then
	            return false
	        end
	    end

	    if self:is_dir() then
	        return ({ file_system.mkdir(self:to_string()) })[1] or false
	    elseif self:is_file() then
	        return ({ file_system.touch(self:to_string()) })[1] or false
	    end

	    return false
	end

	---@param all boolean | nil
	---@return boolean
	function _path:remove(all)
	    if not self:exists() then
	        return true
	    end

	    if self:is_file() then
	        local success = os.remove(self:to_string())
	        return success
	    end

	    if self:is_dir() then
	        for child in file_system.dir(self:to_string()) do
	            if child == "."
	                or child == ".." then
	                goto continue
	            end

	            if not all then
	                return false
	            end

	            local child_path = self:extend(child)
	            if file_system.attributes(child_path:to_string()).mode == "directory" then
	                child_path:append("/")
	            end

	            if not child_path:remove(all) then
	                return false
	            end
	            ::continue::
	        end

	        local success = file_system.rmdir(self:to_string())
	        return success or false
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
	            copy.m_nodes[length] = ""
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
	    local path_str = table.concat({ ... }, "/")
	    if self.m_nodes[#self.m_nodes] == "" then
	        self.m_nodes[#self.m_nodes] = nil
	    end

	    path_str = format_str(path_str)
	    local newNodes = utils.string.split(path_str, "/")

	    for _, value in ipairs(newNodes) do
	        self.m_nodes[#self.m_nodes + 1] = value
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

end

__bundler__.__files__["__main__"] = function()
	local function get_os()
	    if package.config:sub(1, 1) == '\\' then
	        return "windows"
	    else
	        return "linux"
	    end
	end

	package.path = "./?.lua;" .. package.path

	local argparse = __bundler__.__loadFile__("thrid_party.argparse")
	local utils = __bundler__.__loadFile__("src.utils.init")
	local path = __bundler__.__loadFile__("src.path")

	local current_dir = path.new(".")

	local parser = argparse("bundle", "Used to bundle a file together by importing the files it uses with require")
	parser:argument("input", "Input file.")
	parser:option("-o --output", "Output file.", "out.lua")
	parser:option("-t --type", "Output type/s."):count("*")
	parser:option("-c --comments", "remove comments (does not remove all comments)", false)
	parser:option("-l --lines", "remove empty lines", false)
	parser:option("-I --include-path", "added search path's for 'require(...)'"):count("*")

	---@type { input: string, output: string, type: string[] | nil, comments: boolean, lines: boolean, include_path: string[] }
	local args = parser:parse() -- { "-o", "bin/bundle.lua", "-I./bin", "src/bundle.lua" })

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

	package.path = ""
	package.cpath = ""
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
	        package.path = package.path .. ";" .. include .. "/?.lua"
	        if get_os() == "windows" then
	            package.cpath = package.cpath .. ";" .. include .. "/?.dll"
	        else
	            package.cpath = package.cpath .. ";" .. include .. "/?.so"
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
	                end
	            end

	            ---@type Freemaker.bundle.require
	            local require_data = {
	                module = match,
	                file_path = file_path,
	                startPos = start_pos,
	                endPos = end_pos,
	                replace = replace,
	                binary = binary
	            }
	            table.insert(requires, require_data)
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
	            local file = io.open(file_path_str, "rb")
	            if file then
	                local content = file:read("a")
	                file:close()

	                local bytes = {}
	                for i = 1, #content do
	                    bytes[#bytes + 1] = string.format("%02X", string.byte(content, i))
	                end
	                content = table.concat(bytes)

	                cache[module .. ".so"] = true
	                out_file:write("__bundler__.__files__[\"", module, ".so\"] = [[", content, "]]\n")
	            end
	            did = true
	        end

	        if not cache[module .. ".dll"] then
	            local file_path_str = file_path:to_string()
	            file_path_str = file_path_str:sub(0, file_path_str:len() - 1) .. ".dll"
	            local file = io.open(file_path_str, "rb")
	            if file then
	                local content = file:read("a")
	                file:close()

	                local bytes = {}
	                for i = 1, #content do
	                    bytes[#bytes + 1] = string.format("%02X", string.byte(content, i))
	                end
	                content = table.concat(bytes)

	                cache[module .. ".dll"] = true
	                out_file:write("__bundler__.__files__[\"", module, ".dll\"] = [[", content, "]]\n")
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
	    __temp_files__ = {},
	    __org_exit__ = os.exit
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
	        local tempDir = os.getenv("TEMP") or os.getenv("TMP")
	            if not tempDir then
	                tempDir = "/tmp"
	            end
	            local os_type = __bundler__.__get_os__()
	            local file_path = tempDir .. os.tmpname()
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
	            local content_len = content:len()
	            for i = 2, content_len, 2 do
	                local byte = tonumber(content:sub(i - 1, i), 16)
	                file:write(string.char(byte))
	            end
	            file:close()
	            __bundler__.__cache__[module] = { package.loadlib(file_path, "luaopen_" .. module)() }
	            table.insert(__bundler__.__temp_files__, file_path)
	        else
	            __bundler__.__cache__[module] = { __bundler__.__files__[module]() }
	        end
	    end
	    return table.unpack(__bundler__.__cache__[module])
	end
	function __bundler__.__cleanup__()
	    for _, file_path in ipairs(__bundler__.__temp_files__) do
	        os.remove(file_path)
	    end
	end
	---@diagnostic disable-next-line: duplicate-set-field
	function os.exit(...)
	    __bundler__.__cleanup__()
	    __bundler__.__org_exit__(...)
	end
	function __bundler__.__main__()
	    local loading_thread = coroutine.create(__bundler__.__loadFile__)
	    local success, items = (function(success, ...) return success, {...} end)
	        (coroutine.resume(loading_thread, "__main__"))
	    if not success then
	        print("error in bundle loading thread:\n"
	            .. debug.traceback(loading_thread, items[1]))
	    end
	    __bundler__.__cleanup__()
	    return table.unpack(items)
	end
	]])

	bundler.process_file(input_file_path, "__main__")

	if args.type then
	    out_file:write("---@type {")
	    for index, type_name in ipairs(args.type) do
	        out_file:write(" [", index, "]: ", type_name, " ")
	    end
	    out_file:write("}\n")
	    out_file:write("local main = { __bundler__.__main__() }\n")
	    out_file:write("return table.unpack(main)\n")
	else
	    out_file:write("return __bundler__.__main__()\n")
	end

	out_file:close()
	print("done!")

end

---@type {}
local main = { __bundler__.__main__() }
return table.unpack(main)
