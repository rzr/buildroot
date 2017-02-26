	#!/bin/bash
	# Return value define : [500GB] = 0; [1 TB] = 1; [2 TB] = 2; 
	
	DEV=$(cat /tmp/HDDDevNode);
	STR=$(smartctl -a -d sat $DEV | grep 'User Capacity' | cut -d '[' -f2 | cut -d ' ' -f1 | cut -d '.' -f1);
	
	if [ "$STR" == "500" ]; then
		echo 0;
	elif [ "$STR" == "1" ]; then
		echo 1;
	elif [ "$STR" == "2" ]; then
		echo 2;
	else
		echo error:Cannot find capacity!;
	fi
