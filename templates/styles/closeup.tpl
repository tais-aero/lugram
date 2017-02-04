${include styles/common}

${define link {{"word", 'target'}, {"*", 'body'}} function(context)
  local target = context.replace(context, context.target)
  local body = context.replace(context, context.body)

  if target:find('%$%b{}') then
    -- We're not able to expand right now. Maybe later?
    return '${link ' .. target .. ' ' .. body .. '}'
  end

  local modules = context._ROOT._SETS.modules
  if not modules then
    modules = { }
    context._ROOT._SETS.modules = modules
  end

  local visited = context._ROOT._SETS.visited
  if not visited then
    visited = { }
    context._ROOT._SETS.visited = visited
  end

  local links = context._ROOT._SETS.links
  if not links then
    links = { }
    context._ROOT._SETS.links = links
  end

  local link_counts = context._ROOT._LINK_COUNTS
  if not link_counts then
    link_counts = { }
    context._ROOT._LINK_COUNTS = link_counts
  end

  local link_bodies = context._ROOT._LINK_BODIES
  if not link_bodies then
    link_bodies = { }
    context._ROOT._LINK_BODIES = link_bodies
  end

  if not modules[target] then
    modules[target] = target
    modules[#modules + 1] = target
  end

  if
    context._MODULE ~= context._CLOSEUP and
    context.target ~= context._CLOSEUP
  then
    return context.body
  end

  local link = context._MODULE .. '--"' .. body .. '"-->' .. target
  if context._MODULE ~= context._CLOSEUP then
    if
      context._MODULE == target or
      context.body == '<button>X</button>' -- Hack!
    then
      return context.body
    end

    link = context._MODULE .. '-->' .. target
  end

  if links[link] then
    return body
  end
  links[link] = link
  links[#links + 1] = link

  local lb = link_bodies[context._MODULE]
  if not lb then
    lb = { }
    link_bodies[context._MODULE] = lb
  end

  if context._MODULE ~= context._CLOSEUP then
    lb[target] = true
  else
    local t = lb[target]
    if not t then
      t = { }
      lb[target] = t
    end

    if not t[body] then
      t[body] = body
      t[#t + 1] = body
    end
  end

  link_counts[target] = (link_counts[target] or 0) + 1
  link_counts[context._MODULE] = (link_counts[context._MODULE] or 0) + 1

  return body
end}

${define title {{"*", 'title'}} function(context)
  context.title = context.replace(context, context.title)
  context._ROOT._TITLES = context._ROOT._TITLES or { }
  context._ROOT._TITLES[context._MODULE] = context.title

  return context.title
end}

${define gettitle {{"*", 'module'}} function(context)
  context._ROOT._TITLES = context._ROOT._TITLES or { }
  return context._ROOT._TITLES[context.module] or context.module
end}

${define recurse_modules {{"*", 'body'}} function(context) -- TODO: Hack
  local modules = context._ROOT._SETS.modules
  if not modules then
    modules = { }
    context._ROOT._SETS.modules = modules
  end

  local visited = context._ROOT._SETS.visited
  if not visited then
    visited = { }
    context._ROOT._SETS.visited = visited
  end

  local link_counts = context._ROOT._LINK_COUNTS
  if not link_counts then
    link_counts = { }
    context._ROOT._LINK_COUNTS = link_counts
  end

  local small_modules = { }

  local result = ""
  while #modules > #visited do
    for i = 1, #modules do
      local module = modules[i]
      if not visited[module] then
        visited[module] = module
        visited[#visited + 1] = module

        if module ~= context._CLOSEUP then
          small_modules[#small_modules + 1] =
          {
            module;
            context.silent_screen(context, module);
          }
        else
          result = result .. context.screen(context, module)
        end
      end
    end
  end

  for i = 1, #small_modules do
    local module, screen = small_modules[i][1], small_modules[i][2]
    if link_counts[module] and link_counts[module] > 0 then
      result = result .. screen
    end
  end

  return result
end}

${define recurse_links {{"*", 'body'}} function(context) -- TODO: Hack
  local result = ''

  local link_bodies = context._ROOT._LINK_BODIES or { }
  for source, targets in pairs(link_bodies) do
    for target, bodies in pairs(targets) do
      if bodies == true then
        result = result .. source .. '-->' .. target .. '\n'
      else
        result = result .. source .. '--"<center>' .. bodies[1]
        for i = 2, #bodies do
          result = result .. '<hr/>' .. bodies[i]
        end
        result = result .. '</center>"-->' .. target .. '\n'
      end
    end
  end

  return result
end}

${define screen {{"*", "module"}} [[
${set_insert modules ${module}}${module}["${include ${module}}"]
]]}

${define silent_screen {{"*", "module"}} function(context)
  context._ROOT._TITLES = context._ROOT._TITLES or { }

  context.set_insert(context, context.replace(context, "modules ${module}"))
  context.deferred_off(context, "")
  context.include(context, context.module)
  context.deferred_on(context, "")
  return context.module .. '["' .. (context._ROOT._TITLES[context.module] or context.module) .. '"]\n'
end}

graph TD

${set_insert modules ${_TEMPLATE}}

${recurse_modules}

${recurse_links}
