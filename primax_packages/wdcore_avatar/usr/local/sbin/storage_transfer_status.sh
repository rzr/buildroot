#!/bin/bash
#
if [ `cat /tmp/sdstats | sed -n 's/.*=//p'` == "completed" ]; then
	rsyncCal=`pidof SDCard_CalTransfer.sh`
	if [ "$rsyncCal" != "" ]; then
		kill -9 "$rsyncCal" > /dev/null 2>&1
	fi
	killall -9 rsync > /dev/null 2>&1
    total=`cat /tmp/sdsize_total | sed -n '1p' | sed -n 's/.*=//p'`
    #sed -i 's/transferred_size_in_bytes=.*/transferred_size_in_bytes='${total}'/' /tmp/sdsize
    echo "transferred_size_in_bytes=${total}" > /tmp/sdsize
elif [ `cat /tmp/sdstats | sed -n 's/.*=//p'` == "failed" ]; then
	killall -9 rsync > /dev/null 2>&1
	echo "transferred_size_in_bytes=0" > /tmp/sdsize
elif [ `cat /tmp/sdstats | sed -n 's/.*=//p'` == "waiting" ]; then
	echo "transferred_size_in_bytes=0" > /tmp/sdsize
fi


cat /tmp/sdsize_total
cat /tmp/sdsize
cat /tmp/sdstats
	