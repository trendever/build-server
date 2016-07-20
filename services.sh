#!/bin/bash

changed=$(cd services; git show --name-only --oneline | tail -n +2 | sed -e 's|^src/||;s|^vendor/src/||'| sed -e 's|/[^/]\+\.[^/]\+$|/|' | sed -e 's|/$||' | sort | uniq)


list=$(docker run --rm -v "$PWD/services":/usr/src/services -w "/usr/src/services/" -u $(id -u) desertbit/golang-gb:alpine sh -c "gb list -f '{{.ImportPath}} {{.Package.Imports}}'")


for file in $changed; do 
	echo -e "$list" | grep -- $file | tr '/' ' ' | cut -d' ' -f1
done | sort | uniq | grep -f "$WD/services.conf"
