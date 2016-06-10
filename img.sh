#!/bin/bash -ex

# build && deploy docker service image
# warning: this file is launched in -ex mode
#  this means every top-level command that generates and error will stop execution
#  if you don't want to die, use `if ...`, `|| true` or anything else

SERVICE="$1"
BRANCH="$2"

# path to service repository
REPO="git@github.com:trendever/${SERVICE}.git"

# docker registry
REGISTRY="dev.trendever.com:5000"
SERVICES="$WD/services.conf"
# docker compose dir
COMPOSE="$WD/live-services"

# clone everything to service/
git clone -b "${BRANCH}" "${REPO}" 'service'

# temporary disable tests
# docker run --rm -v "$PWD/service":/usr/src/service -w /usr/src/service -u $(id -u) desertbit/golang-gb:alpine sh -c 'gb build all && gb test -v'
docker run --rm -v "$PWD/service":/usr/src/service -w /usr/src/service -u $(id -u) desertbit/golang-gb:alpine sh -c 'gb build all'

# delete some really unneeded stuff
rm -rf ./service/.git
# delete code files, static libraries, dot-hidden files
find ./service -type f -and -\( -name '*.go' -or -name '*.a' -or -name '.*' -\) -delete
# delete empty dirs
find ./service -type d -empty -delete

# build && push output container
cp "$WD/Dockerfile" .
RES="${BRANCH}_${SERVICE}"
docker build -t "$RES" .
docker tag "$RES" "$REGISTRY/$RES"
docker push "$REGISTRY/$RES"

# deploy it
for machine in $(cat "$SERVICES" | grep "^$RES " | cut -d' ' -f2-); do
	eval $(docker-machine env "$machine")
	# check if configuration applied
	if [[ "$(docker-machine active)" != "$machine" ]]; then
		# @TODO: partial deploy is possible; this may break lots of stuff
		echo "Could not connect to $machine"
		exit 1
	fi
	cd ~/live-services
	docker pull "$REGISTRY/$RES"
	docker-compose up -d "$SERVICE"
done
