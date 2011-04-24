#!/bin/bash
last=""

while true; do
	current=`tar cO --exclude=tests --mtime=0 . | sha1sum -`;
	#echo "$current, $last \n"
	if [ "$last" != "$current" ]; then
		last="$current"
		clear; reset;
		echo "compiling..."
		killall -9 server
		make
		./server &
		#notify-send "Server" "Started"
		./tests/login.sh
	fi
	sleep 2
done
