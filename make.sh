#!/usr/bin/env bash

set -e

# TODO: Do this automatically if docker image is not detected
# docker build -t mermaid .

# TODO: Do not leave intermediate files (*.sh, *.mermaid) behind

# TODO: Move Lua execution to the Docker as well to avoid installing Lua stack
#       Meanwhile, something like this should work:
#       sudo apt-get install lua5.1 luarocks
#       sudo luarocks install lua-nucleo

echo Generating screens 2>&1
screens=${1}
screens=${screens:=$(lua generate.lua fosdem17/list screens | grep -v "^$")}

echo "#!/bin/bash" > out/entrypoint.sh
echo "set -e" >> out/entrypoint.sh

echo Generating outline 2>&1
lua generate.lua fosdem17/list outline >out/outline.mermaid
echo "mermaid -w 4096 -o /src /src/outline.mermaid" >> out/entrypoint.sh

# Commented out for performance reasons
# lua generate.lua fosdem17/list all >out/all.mermaid
# echo "mermaid -w 8192 -o /src /src/all.mermaid" >> out/entrypoint.sh

# The closeup target has more complex logic

for screen in ${screens}; do
  prefix="closeup.${screen//\//.}"
  echo Generating ${prefix} 2>&1
  lua generate.lua fosdem17/list closeup "{_CLOSEUP='${screen}'}" >"out/${prefix}.mermaid"
  echo "mermaid -w 2048 -o /src /src/${prefix}.mermaid" >> out/entrypoint.sh
done

chmod +x out/entrypoint.sh
docker run -v $(pwd)/out:/src mermaid /src/entrypoint.sh

# Commented out for performance reasons
# graphicsmagick
# gm convert out/*.png out/all.pdf
