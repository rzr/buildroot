#!/bin/bash
# Return value define : [500GB] = 0; [1 TB] = 1; [2 TB] = 2; 
	
if [ -f /tmp/HDDCapacity ]; then
    cat /tmp/HDDCapacity
    exit 0
fi

DEV=$(cat /tmp/HDDDevNode);
STR=$(smartctl -a -d sat $DEV | grep 'User Capacity' | cut -d '[' -f2 | cut -d ' ' -f1 | cut -d '.' -f1);
	
if [ "$STR" == "500" ]; then
    echo 0;
    echo 0 > /tmp/HDDCapacity
elif [ "$STR" == "1" ]; then
    echo 1;
    echo 1 > /tmp/HDDCapacity
elif [ "$STR" == "2" ]; then
    echo 2;
    echo 2 > /tmp/HDDCapacity
elif [ "$STR" == "3" ]; then
    echo 2;
    echo 3 > /tmp/HDDCapacity    
else
    echo error:Cannot find capacity!;
    echo "error:Cannot find capacity!" > /tmp/HDDCapacity
fi
