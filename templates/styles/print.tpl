${include styles/common}

${define link {{"word", 'target'}, {"*", 'body'}} function(context)
  return context.replace(context, context.body)
end}

${define title {{"*", 'title'}} function(context)
  return context.replace(context, context.title)
end}

graph TD

printable["${include_once ${_TEMPLATE}}"]
