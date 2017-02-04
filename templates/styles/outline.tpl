${include styles/common}

${define link {{"word", 'target'}, {"*", 'body'}} function(context)
  local target = context.replace(context, context.target)
  local body = context.replace(context, context.body)

  if target:find('%$%b{}') then
    -- We're not able to expand right now. Maybe later?
    return '${link ' .. target .. ' ' .. body .. '}'
  end

  if context._SCREEN ~= target and body ~= '<button>X</button>' then
    context._ROOT._SETS.links = context._ROOT._SETS.links or { }
    local links = context._ROOT._SETS.links

    local link = context._SCREEN .. '-->' .. target

    if not links[link] then
      links[link] = link
      links[#links + 1] = link
    end

    context.include_once(context, target) -- Ignoring generated text
  end

  return body
end}

${define title {{"*", 'title'}} function(context)
  context._ROOT._SETS.screens = context._ROOT._SETS.screens or { }
  local screens = context._ROOT._SETS.screens

  local title = context._MODULE ..
    '["' .. context.replace(context, context.title) .. '"]'

  if not screens[context._MODULE] then
    screens[context._MODULE] = title -- Not quite a set :(
    screens[#screens + 1] = title
  end

  context._PARENT._SCREEN = context._MODULE -- Hack. Brittle.

  return context.title
end}

graph TD

${silent ${include_once ${_TEMPLATE}}}

${set_each screens ${self}
}

${set_each links ${self}
}
