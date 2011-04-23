#!/bin/bash
last=""

while true; do
	current=`tar cO --mtime=0 . | sha1sum -`;
	#echo "$current, $last \n"
	if [ "$last" != "$current" ]; then
		last="$current"
		echo "compiling..."
		killall -9 server
		make all
		./server &
	fi
	sleep 0.25
done
