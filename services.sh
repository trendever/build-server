#!/bin/bash

cd services

head=$(git rev-parse HEAD)
branch=$(basename $(git rev-parse --abbrev-ref HEAD))

from=HEAD~1
if [ -f "$WD/lasts/${branch}" ]; then
	from=$(cat "$WD/lasts/${branch}")
fi

changed=$(git diff --name-only HEAD $from | grep -e ^src -e ^vendor | sed -e 's|^src/||;s|^vendor/src/||'| sed -e 's|/[^/]\+\.[^/]\+$|/|' | sed -e 's|/$||' | sort | uniq)

list=$(docker run --rm -v "$PWD":/usr/src/services -w "/usr/src/services/" -u $(id -u) desertbit/golang-gb:alpine sh -c "gb list -f '{{.ImportPath}} {{.Package.Imports}}'")

for file in $changed; do 
	echo -e "$list" | grep -- $file | tr '/' ' ' | cut -d' ' -f1
done | sort | uniq | grep -f "$WD/services.conf"
true
