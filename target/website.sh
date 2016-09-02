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
		TO=live@trendever.com:~/public
		;;
	"soso_test ")
		WHERE=$HOME/soso_test/dist
		FROM=dist
		TO=$HOME/publicdir/soso_test
		;;
	*)
		echo "unknown config"
		exit 1
		;;
esac

cd $WHERE
git pull
npm install # do we need it?
npm run build
rsync -av $FROM/ $TO/
