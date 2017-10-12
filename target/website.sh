#!/bin/bash

case "$2 $3" in
	"website dev")
		WHERE=$HOME/trendever_website
		FROM=dist
		TO=$HOME/publicdir/website
		;;
	"website master")
		WHERE=$HOME/trendever_master
		FROM=dist
		TO=live@trendever.com:/home/live/public
		;;
	"website directbot")
		WHERE=$HOME/dev_directbot
		FROM=dist
		TO=$HOME/publicdir/directbot
		;;
	"website directbotprod")
		WHERE=$HOME/directbot_master
		FROM=dist
		TO=live@trendever.com:/home/live/directbot_public
		;;
	"website trusty")
		WHERE=$HOME/trusty_dev
		FROM=build/dist
		TO=$HOME/publicdir/trusty_dev
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
