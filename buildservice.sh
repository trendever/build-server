#!/bin/bash

PROJECT="$1"
COMMAND="$2"
SERVICE="$3"
BRANCH="$4"

# docker registry
REGISTRY="dev.trendever.com:5000"
# deploy config
DEPLOY="$WD/projects/$PROJECT/deploy"
# docker image name
RES="${BRANCH}_${SERVICE}"

echo "Starting $COMMAND $RES"

# build it
if [ "$COMMAND" != "deploy" ]; then
	# build itself
	# @TODO: gb test
	docker run --rm -v "$PWD/$PROJECT":/project -u $(id -u) desertbit/golang-gb:alpine /bin/sh -c "cd src/$SERVICE && gb build"

	rm -rf 'container'
	mkdir 'container'

	cp "$PROJECT/bin/$SERVICE" 'container/service'

	if [ -f "$PROJECT/scripts/start-$SERVICE.sh" ]; then
		cp "$PROJECT/scripts/start-$SERVICE.sh" "container/start.sh"
	fi

	if [ -f "$PROJECT/scripts/deploy/$SERVICE.sh" ]; then
		(cd "$PROJECT"; sh "./scripts/deploy/$SERVICE.sh" "../container")
	fi

	# build && push output container
	cp "$WD/Dockerfile" .
	docker build -t "$RES" .
	docker tag "$RES" "$REGISTRY/$PROJECT/$RES"
	docker push "$REGISTRY/$PROJECT/$RES"
fi

# deploy it
cat "$DEPLOY" | grep -P "^$RES[ \t]" | while read machine_info; do

	# read conf string
	read _ machine compose deploy <<< ${machine_info}
	echo "$machine $compose $deploy" > /dev/null

	# skip for build-only targets
	if [[ "$deploy" == 'false' ]] && [[ "$COMMAND" != 'deploy' ]]; then
		continue
	fi

	# connect to remote host
	eval $(docker-machine env --shell=bash "$machine")

	# check if connection established
	if [[ "$(docker-machine active)" != "$machine" ]]; then
		# @TODO: partial deploy is possible; this may break lots of stuff
		echo "Could not connect to $machine"
		exit 1
	fi

	cd "$WD"
	cd "$compose"
	docker pull "$REGISTRY/$PROJECT/$RES"

	docker-compose up -d --force-recreate "$SERVICE"
done
