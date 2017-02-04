${include styles/common}

${define link {{"word", 'target'}, {"*", 'body'}} function(context)
  local target = context.replace(context, context.target)
  local body = context.replace(context, context.body)

  if target:find('%$%b{}') then
    -- We're not able to expand right now. Maybe later?
    return '${link ' .. target .. ' ' .. body .. '}'
  end

  if context._MODULE ~= target then
    context._ROOT._SETS = context._ROOT._SETS or { }
    context._ROOT._SETS.links = context._ROOT._SETS.links or { }
    local links = context._ROOT._SETS.links
    links[target] = target
    links[#links + 1]= target
  end

  context.include_once(context, target) -- Ignoring generated text

  return ""
end}

${define title {{"*", 'title'}} [[
  ${set_insert screens ${_MODULE}}
]]}

${silent ${include_once ${_TEMPLATE}}}

${set_each screens ${self}
}
