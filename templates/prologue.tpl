${define # {{"*", 'body'}} function(context)
  return ""
end}

${define silent {{"*", 'body'}} function(context)
  if context.body then
    context.deferred_off(context, "")
    context.replace(context, context.body)
    context.deferred_on(context, "")
  end
  return ""
end}

${define with {{"table", "context"}, {"*", "body"}} function(context)
  return context.replace(
    context.push(context, context.context),
    context.body
  )
end}

${define if {{"word", "lhs"}, {"word", "op"}, {"word", "rhs"}, {"*", "ifbody"}}
function(context)
  local ops =
  {
    -- NB: Add more as needed
    ["~="] = function(lhs, rhs)
      lhs = tonumber(lhs) or lhs
      rhs = tonumber(rhs) or rhs
      return lhs ~= rhs
    end;
  }

  local maybelater = function()
    return '${if '
      .. context.lhs .. ' '
      .. context.op .. ' '
      .. context.rhs .. ' '
      .. context.ifbody
      .. '}'
  end

  local op = context.replace(context, context.op)
  local lhs = context.replace(context, context.lhs)
  local rhs = context.replace(context, context.rhs)

  if
    op:find('%$%b{}') or
    lhs:find('%$%b{}') or
    rhs:find('%$%b{}')
  then
    -- We're not able to expand right now. Maybe later?
    return maybelater()
  end

  local handler = ops[context.op]
  if not handler then
    return maybelater() -- Unknown operation
  end

  if handler(lhs, rhs) then
    return context.replace(context, context.ifbody)
  end

  return ""
end}

${define when {{"word", "symbol"}, {"*", "whenbody"}} function(context)
  if context[context.symbol] then
    return context.whenbody
  end

  return ""
end}

${define unless {{"word", "symbol"}, {"*", "unlessbody"}} function(context)
  if not context[context.symbol] then
    return context.unlessbody
  end

  return ""
end}

${define set_insert {{"word", 'symbol'}, {"*", 'value'}} function(context)
  local value = context.value
  if not value then
    return
  end

  value = context.replace(context, value)

  context._ROOT._SETS = context._ROOT._SETS or { }

  local set = context._ROOT._SETS[context.symbol]
  if set == nil then
    set = { }
    context._ROOT._SETS[context.symbol] = set
  end

  if set[value] == nil then
    set[value] = value
    set[#set + 1] = value
  end

  return ""
end}

${define set_each {{"word", 'symbol'}, {"*", 'template'}} function(context)
  local result = ''

  context._ROOT._SETS = context._ROOT._SETS or { }

  local set = context._ROOT._SETS[context.symbol]
  if set == nil then
    set = { }
    context._ROOT._SETS[context.symbol] = set
  end

  for i = 1, #set do
    result = result .. context.replace(
      context.push(context, { self = set[i] }),
      context.template
    )
  end
  return result
end}

${define set_if_unset {{"word", 'symbol'}, {"word", 'value'}, {"*", 'template'}} function(context)
  local result = ''

  context._ROOT._SETS = context._ROOT._SETS or { }

  local set = context._ROOT._SETS[context.symbol]
  if set == nil then
    set = { }
    context._ROOT._SETS[context.symbol] = set
  end

  local value = context.replace(context, context.value)

  if set[value] == nil then
    return context.replace(context, context.template)
  end

  return ""
end}

${define set_size {{"word", 'symbol'}} function(context)
  local result = ''

  context._ROOT._SETS = context._ROOT._SETS or { }

  local set = context._ROOT._SETS[context.symbol]
  if set == nil then
    set = { }
    context._ROOT._SETS[context.symbol] = set
  end

  return "" .. (#set)
end}

${define include_once {{"*", "module"}} function(context)
  local module = context.replace(context, context.module)

  context._ROOT._SETS = context._ROOT._SETS or { }
  context._ROOT._SETS._INCLUDED = context._ROOT._SETS._INCLUDED or { }
  local included = context._ROOT._SETS._INCLUDED
  if not included[module] then
    included[module] = module
    included[#included + 1] = module
    return context.include(context, module)
  end

  return ""
end}

${define defer {{"word", "deferkey"}, {"*", "deferbody"}} function(context)
  if (context._ROOT._DEFERRED_DISABLED or 0) > 0 then
    return ""
  end

  context._ROOT._DEFERRED = context._ROOT._DEFERRED or { }
  local deferred = context._ROOT._DEFERRED
  deferred[context.deferkey] = deferred[context.deferkey] or { }
  deferred[context.deferkey][#deferred[context.deferkey] + 1] = context.deferbody
  return ""
end}

${define deferred {{"word", "deferkey"}} function(context)
  local deferred = context._ROOT._DEFERRED or { }
  local texts = deferred[context.deferkey] or { }
  deferred[context.deferkey] = nil

  return table.concat(texts)
end}

${define deferred_off { } function(context)
  context._ROOT._DEFERRED_DISABLED = (context._ROOT._DEFERRED_DISABLED or 0) + 1
  return ""
end}

${define deferred_on { } function(context)
  context._ROOT._DEFERRED_DISABLED = (context._ROOT._DEFERRED_DISABLED or 0) - 1
  return ""
end}

${define deferred_all { } function(context)
  local deferred = context._ROOT._DEFERRED or { }
  context._ROOT._DEFERRED = { }
  local keys = { }
  for k, v in pairs(deferred) do
    keys[#keys + 1] = k
  end
  table.sort(keys)
  local result = { }
  for i = 1, #keys do
    result[#result + 1] = table.concat(deferred[keys[i]])
  end
  return table.concat(result)
end}

${define
  -----------------------------------------------------------------------------
  {} [[]]
}

${define
  --[HR]-----------------------------------------------------------------------
  {} [[<hr>]]
}

${define expr {{"*", "EXPR_CODE"}} function(context)
  local code = context.replace(context, context.EXPR_CODE)
  if code:find('%$%b{}') then
    -- We're not able to expand right now. Maybe later?
    return '${expr ' .. code .. '}'
  end
  -- TODO: pcall and a nice error report
  return assert(loadstring('return (' .. code .. ')'))()
end}

${include ${_STYLE}}

${deferred_all}
