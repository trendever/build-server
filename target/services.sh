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
	if [ "$COMMAND" == 'deploy' ] || [ "$4" == 'all' ]; then
		need_rebuild=$(cat $WD/services.conf)
	else
		need_rebuild="$(bash "$WD/services.sh" $4)"
	fi
fi

echo "Services that need rebuild: " >> "$MESSAGES"
if [ -n "${need_rebuild}" ]; then
	echo "$need_rebuild" >> "$MESSAGES"
else
	echo 'none' >> "$MESSAGES"
fi

for SERVICE in $need_rebuild; do
	bash -ex $WD/buildservices.sh "$COMMAND" "$SERVICE" "$BRANCH"
done

# when done, save commit
cd 'services'
head=$(git rev-parse HEAD)
branch=$(basename $(git rev-parse --abbrev-ref HEAD))
echo "$head" > "$WD/lasts/${branch}"
