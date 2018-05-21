#!/bin/bash

case "$2 $3" in
	"website dev")
		WHERE=trendever_website
		FROM=dist
		TO=$HOME/publicdir/website
		;;
	"website master")
		WHERE=trendever_master
		FROM=dist
		TO=trendever@beta.trendever.com:/home/trendever/www/trendever
		;;
	"website directbot")
		WHERE=dev_directbot
		FROM=dist
		TO=$HOME/publicdir/directbot
		;;
	"website directbotprod")
		WHERE=directbot_master
		FROM=dist
		TO=trendever@beta.trendever.com:/home/trendever/www/directbot
		;;
	"website trusty")
		WHERE=trusty_dev
		FROM=build/dist
		TO=$HOME/publicdir/trusty_dev
		;;
	"soso_test master")
		WHERE=soso_test
		FROM=dist
		TO=$HOME/publicdir/soso_test
		;;
	*)
		echo "Warning! Unknown branch -- ignoring" >> "$MESSAGES"
		exit 0
		;;
esac

cd $HOME/websrc/$WHERE
git pull
npm install # do we need it?
npm run build
rsync -av --delete-delay $FROM/ $TO/
