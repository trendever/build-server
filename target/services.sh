#!/bin/bash -ex

# clone && build && deploy docker service image
# warning: this file is launched in -ex mode
#  this means every top-level command that generates and error will stop execution
#  if you don't want to die, use `if ...`, `|| true` or anything else

COMMAND="$1"
TARGET="$2"
BRANCH="$3"
DIFF_FROM="$4"

IFS='/' read -r PROJECT TARGET <<< "$2"

if [ -z "$TARGET" ]; then
	TARGET=$PROJECT
	if [ ! -f "$WD/projects/$PROJECT" ]; then
		PROJECT=$(basename $0)
	fi
fi

REPO=$(cat "$WD/projects/$PROJECT/repo")

if ! git clone --recursive -b "$BRANCH" "$REPO" "$PROJECT"; then
	echo "Fetch git repo '$REPO' failed"
	exit 1
fi

if [ "$TARGET" != "$PROJECT" ]; then
	need_rebuild="$TARGET"
else
	if [ "$COMMAND" == 'deploy' ] || [ "$DIFF_FROM" == 'all' ]; then
		need_rebuild=$(cat "$WD/projects/$PROJECT/targets")
	else
		need_rebuild="$(bash "$WD/changed.sh" $PROJECT $DIFF_FROM)"
	fi
fi

echo "Services that need rebuild: " >> "$MESSAGES"
if [ -n "${need_rebuild}" ]; then
	echo "$need_rebuild" >> "$MESSAGES"
else
	echo 'none' >> "$MESSAGES"
fi

for SERVICE in $need_rebuild; do
	bash -ex $WD/buildservice.sh "$PROJECT" "$COMMAND" "$SERVICE" "$BRANCH"
done

# when done, save commit
cd "$PROJECT"
head=$(git rev-parse HEAD)
branch=$(basename $(git rev-parse --abbrev-ref HEAD))
echo "$head" > "$WD/lasts/"$PROJECT"/${branch}"
