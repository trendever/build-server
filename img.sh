#!/bin/bash -ex

# build && deploy docker service image
# warning: this file is launched in -ex mode
#  this means every top-level command that generates and error will stop execution
#  if you don't want to die, use `if ...`, `|| true` or anything else

SERVICE="$1"
BRANCH="$2"

echo "Starting build $BRANCH_$SERVICE"

# docker registry
REGISTRY="dev.trendever.com:5000"
SERVICES="$WD/branches.conf"
# docker compose dir

docker run --rm -v "$PWD/services":/project -u $(id -u) desertbit/golang-gb:alpine /bin/sh -c "cd src/$SERVICE && gb build"

rm -rf 'container'
mkdir 'container'

cp "services/bin/$SERVICE" 'container/service'
if [ -f "services/scripts/start-$SERVICE.sh" ]; then
	cp services/scripts/start-$SERVICE.sh container/start.sh
fi

# build && push output container
cp "$WD/Dockerfile" .
RES="${BRANCH}_${SERVICE}"
docker build -t "$RES" .
docker tag "$RES" "$REGISTRY/$RES"
docker push "$REGISTRY/$RES"

# deploy it
cat "$SERVICES" | grep -P "^$RES[ \t]" | while read machine_info; do
	machine=$(echo "$machine_info" | awk '{print $2}')
	compose=$(echo "$machine_info" | awk '{print $3}')

	eval $(docker-machine env "$machine")
	# check if configuration applied
	if [[ "$(docker-machine active)" != "$machine" ]]; then
		# @TODO: partial deploy is possible; this may break lots of stuff
		echo "Could not connect to $machine"
		exit 1
	fi
	cd "$WD"
	cd "$compose"
	docker pull "$REGISTRY/$RES"
	docker-compose up -d "$SERVICE"
done
