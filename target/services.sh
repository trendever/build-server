#!/bin/bash -ex

# clone && build && deploy docker service image
# warning: this file is launched in -ex mode
#  this means every top-level command that generates and error will stop execution
#  if you don't want to die, use `if ...`, `|| true` or anything else

# path to service repository

REPO="git@github.com:trendever/services.git" 

COMMAND="$1"
SERVICE="$2"
BRANCH="$3"

if ! git clone --recursive -b "$BRANCH" "$REPO" 'services'; then
	echo "Fetch git repo failed"
	exit 1
fi

if [ "$SERVICE" != "services" ]; then
	need_rebuild="$SERVICE"
else
	if [ "$COMMAND" == 'deploy' ]; then
		need_rebuild=$(cat $WD/services.conf | tr -d '^')
	else
		need_rebuild="$(bash "$WD/services.sh")"
	fi
fi

echo -n "Services that need rebuild: " >> "$MESSAGES"
if [ -n "${need_rebuild}" ]; then
	echo "$need_rebuild" >> "$MESSAGES"
else
	echo 'none' >> "$MESSAGES"
fi

for SERVICE in $need_rebuild; do
	bash -ex $WD/buildservices.sh "$1" "$SERVICE" "$3"
done

# when done, save commit
cd 'services'
head=$(git rev-parse HEAD)
branch=$(basename $(git rev-parse --abbrev-ref HEAD))
echo "$head" > "$WD/lasts/${branch}"
