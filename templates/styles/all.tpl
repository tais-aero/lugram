${include styles/common}

${set_insert visited ${_TEMPLATE}}

${define link {{"word", 'target'}, {"*", 'body'}} function(context)
  local target = context.replace(context, context.target)
  local body = context.replace(context, context.body)

  if target:find('%$%b{}') then
    -- We're not able to expand right now. Maybe later?
    return '${link ' .. target .. ' ' .. body .. '}'
  end

  local modules = context._ROOT._SETS.modules or { }
  local visited = context._ROOT._SETS.visited or { }
  local links = context._ROOT._SETS.links or { }

  local link_bodies = context._ROOT._LINK_BODIES
  if not link_bodies then
    link_bodies = { }
    context._ROOT._LINK_BODIES = link_bodies
  end

  local link = context._MODULE .. '--"' .. body .. '"-->' .. target
  if links[link] then
    return body
  end
  links[link] = link
  links[#links + 1] = link

  if not modules[target] then
    modules[target] = target
    modules[#modules + 1] = target
  end

  local lb = link_bodies[context._MODULE]
  if not lb then
    lb = { }
    link_bodies[context._MODULE] = lb
  end

  local t = lb[target]
  if not t then
    t = { }
    lb[target] = t
  end

  if not t[body] then
    t[body] = body
    t[#t + 1] = body
  end

  return body
end}

${define title {{"*", 'title'}} [[${title}]]}

${define recurse_modules {{"*", 'body'}} function(context) -- TODO: Hack
  local modules = context._ROOT._SETS.modules or { }
  local visited = context._ROOT._SETS.visited or { }

  local result = ""
  while #modules > #visited do
    for i = 1, #modules do
      local module = modules[i]
      if not visited[module] then
        visited[module] = module
        visited[#visited + 1] = module

        result = result .. context.screen(context, modules[i])
      end
    end
  end

  return result
end}

${define recurse_links {{"*", 'body'}} function(context) -- TODO: Hack
  local result = ''

  local link_bodies = context._ROOT._LINK_BODIES or { }
  for source, targets in pairs(link_bodies) do
    for target, bodies in pairs(targets) do
      result = result .. source .. '--"<center>' .. bodies[1]
      for i = 2, #bodies do
        result = result .. '<hr/>' .. bodies[i]
      end
      result = result .. '</center>"-->' .. target .. '\n'
    end
  end

  return result
end}

${define screen {{"*", "module"}} [[
${set_insert modules ${module}}${module}["${include ${module}}"]
]]}

graph TD

${screen ${_TEMPLATE}}

${recurse_modules}

${recurse_links}
