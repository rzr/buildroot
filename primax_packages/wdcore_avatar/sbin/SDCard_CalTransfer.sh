#!/bin/bash
#

while [ `cat /tmp/sdstats | sed -n 's/.*=//p'` == "running" ]; do
	if [ -f "/tmp/runningSDBackup" ]; then
		backupFolder=`cat /tmp/runningSDBackup`
	elif [ -d "/media/sdb1/SD Card Imports" ]; then
		backupFolder="/media/sdb1/SD Card Imports/"
	fi
	if [ "$backupFolder" != "" ]; then
		rsyncCt=`ps aux | grep rsync | grep rv | wc -l`
		if [ "$rsyncCt" -le 1 ]; then
			DoneSize=`rsync -rv "${backupFolder}"/ | grep "total size is" | awk '{print $4}' | sed -n 's/,//gp'`
			if [ "$DoneSize" == "" ]; then
				DoneSize=0
			fi
			OrigSize=`cat /tmp/sdbackedupsize`
			if [ "$OrigSize" == "" ]; then
				OrigSize=0
			fi
		
			if [ "$OrigSize" -gt "$DoneSize" ]; then
				transferredSize=`expr $OrigSize - $DoneSize`
			else
				transferredSize=`expr $DoneSize - $OrigSize`
			fi
			echo "transferred_size_in_bytes=""$transferredSize" > /tmp/sdsize
		fi
	else
		echo "transferred_size_in_bytes=1024" > /tmp/sdsize
	fi
	sleep 30
done