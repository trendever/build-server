#!/bin/bash

cd services

head=$(git rev-parse HEAD)
branch=$(basename $(git rev-parse --abbrev-ref HEAD))

if [ -n "$1" ]; then
	from=$1
elif [ -f "$WD/lasts/${branch}" ]; then
	from=$(cat "$WD/lasts/${branch}")
else
	from=HEAD~1
fi

changed=$(git diff --name-only $from -- | grep -e ^src -e ^vendor | grep '.go$' | sed -e 's|^src/||;s|^vendor/src/||' | xargs dirname 2>/dev/null | sort -u)

gitroot=$PWD
for sub in $(git submodule | awk '{print $2}' | grep -e ^src -e ^vendor); do
	prefix=$(echo -n $sub | sed -e 's|^src/||;s|^vendor/src/||')
	subfrom=$(git diff  $from $sub | fgrep "Subproject" | head -n1 | awk '{print $3}')
	cd $sub
	changed+=$'\n'
	changed+=$(git diff --name-only $subfrom -- | grep '.go$' | sed -e "s/^/$prefix\//" | xargs dirname 2>/dev/null | sort -u)
	cd $gitroot
done

if [ -z "$changed" ]; then
	exit 0
fi

services=$(cat "$WD/services.conf")

readarray -t deps < <(docker run --rm -v "$PWD":/usr/src/services -w "/usr/src/services/" -u $(id -u) desertbit/golang-gb:alpine sh -c "GOPATH=\$GOPATH:\$PWD:\$PWD/vendor go list -f $'{{.ImportPath}}{{range .Deps}} {{.}}{{end}}' `echo $services`")
for list in "${deps[@]}"; do
	read service _ <<< $list
	req=$(comm -12 <(printf -- '%s\n' $list | sort -u) <(printf -- '%s\n' $changed | sort -u))
	if [ -n "$req" ]; then
		echo $service
	fi
done | sort
true
