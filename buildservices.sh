#!/bin/bash

REGISTRY="dev.trendever.com:5000"
SERVICE="$2"
BRANCH="$3"
COMMAND="$1"

# docker registry
SERVICES="$WD/branches.conf"
RES="${BRANCH}_${SERVICE}"

echo "Starting $COMMAND $BRANCH_$SERVICE"

# build it
if [ "$COMMAND" != "deploy" ]; then

	# build itself
	# @TODO: gb test
	docker run --rm -v "$PWD/services":/project -u $(id -u) desertbit/golang-gb:alpine /bin/sh -c "cd src/$SERVICE && gb build"

	rm -rf 'container'
	mkdir 'container'

	cp "services/bin/$SERVICE" 'container/service'

	if [ -f "services/scripts/start-$SERVICE.sh" ]; then
		cp services/scripts/start-$SERVICE.sh container/start.sh
	fi

	if [ -f "services/scripts/deploy/$SERVICE.sh" ]; then
		(cd services; sh ./scripts/deploy/$SERVICE.sh ./../container)
	fi

	# build && push output container
	cp "$WD/Dockerfile" .
	docker build -t "$RES" .
	docker tag "$RES" "$REGISTRY/$RES"
	docker push "$REGISTRY/$RES"
fi

# deploy it
cat "$SERVICES" | grep -P "^$RES[ \t]" | while read machine_info; do

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
	docker pull "$REGISTRY/$RES"

	docker-compose up -d --force-recreate "$SERVICE"
done
