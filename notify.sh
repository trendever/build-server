#!/bin/bash

# public-accessible artifacts directory
PUBLIC="dev.trendever.com/artifacts"

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

bash -ex "$WD/img.sh" "$1" "$2" &> "$OUT/log.txt"

if [[ $? -eq 0 ]]
then
	echo "Build $2_$1: #success"
else 
	echo "Build $2_$1: #fail"
	tail -n 8 "$OUT/log.txt"
	echo "Full log: $PUBLIC/$(basename $OUT)/log.txt"
fi 

cd $wd
rm -rf "$tmp"
true
