#!/usr/bin/env bash

set -e

# TODO: DRY with make.sh

(
  echo Generating outline 2>&1
  lua generate.lua fosdem17/list outline >/dev/null

  echo Generating screens 2>&1
  screens=$(lua generate.lua fosdem17/list screens | grep -v "^$")
  for screen in ${screens}; do
    prefix="print.${screen//\//.}"
    echo Generating ${prefix} 2>&1
    lua generate.lua "${screen}" print >/dev/null

    prefix="closeup.${screen//\//.}"
    echo Generating ${prefix} 2>&1
    lua generate.lua fosdem17/list closeup "{_CLOSEUP='${screen}'}" >/dev/null
  done

  echo Generating all 2>&1
  lua generate.lua fosdem17/list all >/dev/null
) |& egrep '^(Generating|Error|Warning)' \
  | GREP_COLOR='0' egrep --color='always' '^Generating.*|$' \
  | GREP_COLOR='01;31' egrep --color='always' '^Error.*|$' \
  | GREP_COLOR='01;93' egrep --color='always' '^Warning.*|$'
