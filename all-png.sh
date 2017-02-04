#!/usr/bin/env bash

set -e

echo Generating all 2>&1
lua generate.lua fosdem17/list all >out/all.mermaid
docker run -v $(pwd)/out:/src mermaid mermaid -w 8192 -o /src /src/all.mermaid
