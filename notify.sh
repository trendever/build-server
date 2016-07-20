#!/bin/bash

# public-accessible artifacts directory
PUBLIC="dev.trendever.com/artifacts"

# path to service repository
REPO="git@github.com:trendever/services.git" 

# script working directory
export WD="$(dirname $(readlink -f "$0"))"

# artifacts (output) directory)
export ART="$WD/../artifacts"

export OUT="$ART/$1-$(date +"%Y%m%d-%H%M")"
export LANG=C

mkdir -p "$OUT"

rm -f "$ART/$1-latest"
ln -s $OUT "$ART/$1-latest"

# create temporary dir for it
tmp=$(mktemp -d)
cd "$tmp"

if ! git clone -b "$2" "$REPO" 'services'; then
	echo "Fetch git repo failed"
	exit 1
fi

if [ "$1" != "services" ]; then
	need_rebuild="$1"
else
	need_rebuild=$(bash "$WD/services.sh")
fi

echo "Services that need rebuild: "
if [ -n "${need_rebuild}" ]; then
	echo "$need_rebuild"
else
	echo 'none'
fi

for service in $need_rebuild; do
	bash -ex "$WD/img.sh" "$service" "$2" &> "$OUT/log-$service.txt"

	if [[ $? -eq 0 ]]
	then
		echo "Build $2_$service: #success"
		echo "Full log: $PUBLIC/$(basename $OUT)/log-$service.txt"
	else 
		echo "Build $2_$service: #fail"
		echo "==="
		tail -n 8 "$OUT/log-$service.txt"
		echo "==="
		echo "Full log: $PUBLIC/$(basename $OUT)/log-$service.txt"
	fi 
done


cd $wd
rm -rf "$tmp"
true
