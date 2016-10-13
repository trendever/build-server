#!/bin/bash

# public-accessible artifacts directory
PUBLIC="dev.trendever.com/artifacts"

# script working directory
export WD="$(dirname $(readlink -f "$0"))"

# artifacts (output) directory)
export ART="$WD/../artifacts"

export OUT="$ART/$1-$(date +"%Y%m%d-%H%M-%N")"
export MESSAGES="$OUT/messages"
export LANG=C

mkdir -p "$OUT"

rm -f "$ART/$1-latest"
ln -s $OUT "$ART/$1-latest"

# create temporary dir for it
tmp=$(mktemp -d)
cd "$tmp"

service="$(basename $2)"
script=services #default script

if [ -x "$WD/target/$service.sh" ]; then
	script="$service"
fi

bash -ex "$WD/target/$script.sh" "$@" &> "$OUT/log-$service.txt"
if [[ $? -eq 0 ]]
then
	echo "$1 $3_$service: #success"
	cat "$MESSAGES"
	echo "Full log: $PUBLIC/$(basename $OUT)/log-$service.txt"
else 
	echo "$1 $3_$service: #fail"
	cat "$MESSAGES"
	echo "==="
	tail -n 9 "$OUT/log-$service.txt" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" # strip color codes
	echo "==="
	echo "Full log: $PUBLIC/$(basename $OUT)/log-$service.txt"
fi 


cd $wd
rm -rf "$tmp"
true
