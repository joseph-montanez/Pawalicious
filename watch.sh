#!/bin/bash
last=""

while true; do
	current=`tar cO --exclude=tests --exclude=*.json --exclude=*.h --exclude=server --exclude=*.c --exclude=*.png --exclude=*.jpg --mtime=0 . | sha1sum -`;
	#echo "$current, $last \n"
	if [ "$last" != "$current" ]; then
		last="$current"
		clear; reset;
		echo "compiling..."
		make
		killall -9 server
		./server &
		notify-send "Server" "Started"
		#./tests/login.sh
	fi
	sleep 2
done
