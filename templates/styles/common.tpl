${define links {{"table", 'targets'}, {"*", 'body'}} function(context)
  for i = 1, #context.targets do
    context.replace(
      context,
      "${link " .. context.targets[i] .. " ".. context.body .. "}"
    )
  end
  return context.replace(context, context.body)
end}
