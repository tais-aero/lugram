#!/usr/bin/env bash

set -e

# TODO: DRY with make.sh

filter=${1}
filter=${filter:=.*}

echo "#!/bin/bash" > out/entrypoint.sh
echo "set -e" >> out/entrypoint.sh

echo Generating screens 2>&1
screens=$(lua generate.lua fosdem17/list screens | grep -v "^$" | grep "${filter}")
echo "Will generate screens: ${screens}" 2>&1
for screen in ${screens}; do
  prefix="print.${screen//\//.}"
  echo Generating ${prefix} 2>&1
  lua generate.lua "${screen}" print >"out/${prefix}.mermaid"
  echo "mermaid -w 2048 -o /src /src/${prefix}.mermaid" >> out/entrypoint.sh
done

chmod +x out/entrypoint.sh
docker run -v $(pwd)/out:/src mermaid /src/entrypoint.sh
