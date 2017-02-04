-- luacheck: globals import
require 'lua-nucleo'

--------------------------------------------------------------------------------

local trim = import 'lua-nucleo/string.lua' { 'trim' }
local tstr = import 'lua-nucleo/tstr.lua' { 'tstr' }

--------------------------------------------------------------------------------

local eat_verb = function(str)
  if type(str) == 'table' then
    local head = table.remove(str, 1) -- No cloning
    if not head then
      if #str == 0 then
        error("failed to get verb from " .. tstr(str))
      end
      return "", str
    end
    return head, str
  end
  assert(type(str) == 'string')
  local head, tail = str:match('^(%S+)%s+(.*)$')
  if not head then
    head = str:match('^(%S+)$')
    tail = ""
  end
  if not head then
    error("failed to eat verb from `" .. str .. "'")
  end
  return head, tail
end

local eat_table = function(str)
  if type(str) == 'table' then
    local head = table.remove(str, 1) -- No cloning
    if not head then
      error("failed to get table from " .. tstr(str))
    end
    return head, str
  end
  assert(type(str) == 'string')
  local head, tail = str:match('^(%b{})%s+(.*)$')
  if not head then
    head = str:match('^(%b{})$')
    tail = ""
  end
  if not head then
    error("failed to eat table from `" .. str .. "'")
  end
  return head, tail
end

--------------------------------------------------------------------------------

local replace
do
  local impl = function(context, template)
    local replaced = false

    local result = (template:gsub("(%$%b{})", function(braced)
      return (braced:gsub("^(%${(.+)})$", function(placeholder, command)
        local args

        local handler = context[command]
        if not handler then
          command, args = eat_verb(command)
          handler = context[command]
        end

        args = args or ''

        local handler_type = type(handler)
        if handler_type == 'string' and args == '' then
          replaced = replaced or (placeholder ~= handler)
          return handler
        elseif handler_type == 'function' then
          local result = handler(context, args)
          if result then
            replaced = replaced or (placeholder ~= result)
            return result
          end
          return placeholder
        end

        io.stderr:write(
          "Warning: Unknown command ", tstr(placeholder),
          " in ", tstr(context.command or '(root chunk)'), "\n"
        )

        return placeholder
      end))
    end))

    return result, replaced
  end

  replace = function(context, template)
    if type(template) ~= "string" then
      io.stderr:write("context ", tstr(context), "\n")
      io.stderr:write("_MODULE ", tstr(context._MODULE), "\n")
      io.stderr:write("command ", tstr(context.command), "\n")
      error("bad template " .. type(template) .. " " .. tstr(template))
    end

    local depth = 100
    local result, replaced = impl(context, template)
    while replaced and depth > 0 do
      result, replaced = impl(context, result)
      depth = depth - 1
    end

    if depth == 0 then
      io.stderr:write('Warning: context replacement depth exhausted for:\n')
      io.stderr:write("template: ", tstr(template), '\n')
      io.stderr:write("command: ", tstr(context.command), "\n")
    end

    return result
  end
end

--------------------------------------------------------------------------------

local lua_value_loader = function(str)
  str = 'return ' .. str
  local res, err = loadstring(str)
  if not res then
    io.stderr:write(str, "\n")
    error(err)
  end
  return res
end

local context_from_string = function(str, context)
  return lua_value_loader(str)(context)
end

local push_context = function(root, context)
  context._PARENT = root
  return setmetatable(
    context,
    {
      __metatable = 'context.child';
      __index = root;
    }
  )
end

--------------------------------------------------------------------------------

local include = function(context, template_name)
  template_name = trim(replace(context, template_name))
  context = push_context(context, { _MODULE = template_name })

  local filename = "templates/" .. template_name .. ".tpl"

  io.stderr:write("Info: include: loading `", filename, "'\n")
  local file, err = io.open(filename)
  if not file then
    io.stderr:write(
      "Error: include: loading `", filename, "':, ", err, "\n"
    )
    return nil
  end

  local result = replace(context, file:read("*a"))

  io.stderr:write("Info: include: loaded `", filename, "'\n")

  return result
end

--------------------------------------------------------------------------------

local parse_to_context
do
  local handlers =
  {
    word = eat_verb;

    table = function(str)
      local head, tail = eat_table(str)
      head = lua_value_loader(head)()
      return head, tail
    end;

    ["*"] = function(str)
      return str, ""
    end;
  }

  parse_to_context = function(str, parsing_param, symbol)
    local str_orig = str

    assert(type(str) == "string" or type(str) == "table")
    assert(type(parsing_param) == "table")

    --[[
    io.stderr:write(
      "Debug: parse_to_context ",
      tstr(symbol), " ",
      tstr(str), " ",
      tstr(parsing_param),
      "\n"
    )
    --]]

    local context = { command = symbol }
    for i = 1, #parsing_param do
      local k, v = parsing_param[i][1], parsing_param[i][2]
      local handler = assert(handlers[k], 'unknown value type')

      --[[
      io.stderr:write(
        'Debug: eating ', tstr(k), ' to ', tstr(v), ' from ', tstr(str), '\n'
      )
      --]]

      context[v], str = assert(handler(str))

      -- io.stderr:write('Debug: remains ', tstr(str), '\n')
    end

    -- io.stderr:write('Debug: remained ', tstr(str), '\n')

    if str and #str > 0 then
      error(
        'extra arguments in command '
        .. tstr(symbol) .. ' args ' .. tstr(str_orig) .. ': '
        .. tstr(str)
      )
    end

    return context, str
  end
end

--------------------------------------------------------------------------------

local define = function(parent_context, args)
  local symbol, parsing_param, template_str

  symbol, args = eat_verb(args)
  parsing_param, args = eat_table(args)
  template_str = args

  assert(symbol)
  assert(parsing_param)
  assert(template_str)

  parsing_param = lua_value_loader(parsing_param)()
  template_str = lua_value_loader(template_str)

  io.stderr:write("Info: defined `", symbol, "'\n")

  parent_context._ROOT[symbol] = function(context, command)
    --[[
    io.stderr:write('Debug: parsing ', tstr(symbol), ' ', tstr(command), '\n')
    --]]

    context = push_context(
      context,
      parse_to_context(command, parsing_param, symbol)
    )

    local template = template_str(context)
    local template_type = type(template)

    local handler
    if template_type == 'string' then
      handler = function(current_context)
        return replace(current_context, template)
      end
    elseif template_type == 'function' then
      -- Should do its own replacements as needed
      handler = template
    else
      error("invalid definition")
    end

    return handler(context)
  end

  return ""
end

--------------------------------------------------------------------------------

-- Usage: luajit generate.lua foo/main all '{"Optional context as a Lua table"}'
local template_name = select(1, ...)
local style_name = 'styles/' .. assert(select(2, ...))

local root_context =
{
  _PROLOGUE = 'prologue';
  _TEMPLATE = template_name;
  _STYLE = style_name;

  log = function(...)
    io.stderr:write(tstr((select(1, ...))))
    for i = 2, select("#", ...) do
      io.stderr:write(" ", tstr((select(i, ...))))
    end
    io.stderr:write("\n")
    return ""
  end;

  push = push_context;
  replace = replace;

  include = include;
  define = define;
}

root_context._ROOT = root_context;
root_context._PARENT = root_context;

local context = push_context(
  root_context,
  context_from_string(select(3, ...) or "{}", root_context)
)

--------------------------------------------------------------------------------

local result = include(context, context._PROLOGUE)
io.write(result)

local remains = result:match('(%$%b{})')
if remains then
  io.stderr:write(
    'Warning: found a non-resolved placeholder: `', remains, '`\n'
  )
end

io.stderr:write("Info: DONE\n")
