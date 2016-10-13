#!/bin/bash

case "$2 $3" in
	"website dev")
		WHERE=$HOME/trendever_website
		FROM=build
		TO=$HOME/publicdir/website
		;;
	"website master")
		WHERE=$HOME/trendever_website_release
		FROM=build
		TO=live@trendever.com:/home/live/public
		;;
	"soso_test master")
		WHERE=$HOME/soso_test
		FROM=dist
		TO=$HOME/publicdir/soso_test
		;;
	*)
		echo "Warning! Unknown branch -- ignoring" >> "$MESSAGES"
		exit 0
		;;
esac

cd $WHERE
git pull
npm install # do we need it?
npm run build
rsync -av --delete-delay $FROM/ $TO/
