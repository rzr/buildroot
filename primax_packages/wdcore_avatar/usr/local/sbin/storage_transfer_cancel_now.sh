#!/bin/sh

if [ ! -d /media/SDcard ]; then
    echo "Unable to locate storage device"
    exit 1
fi

#Running=`sqlite3 /usr/local/nas/orion/jobs.db 'select jobstate_id from Jobs where jobstate_id=2' | wc -l`
#if [ "${Running}" -eq "0" ]; then
#   exit 2
#fi

if [ `cat /tmp/sdstats | sed -n 's/.*=//p'` != "running" ]; then
	exit 3 
fi

rsyncCal=`pidof SDCard_CalTransfer.sh`
if [ "$rsyncCal" != "" ]; then
	kill -9 "$rsyncCal" > /dev/null 2>&1
fi

killall -9 rsync > /dev/null 2>&1
killall -9 cp > /dev/null 2>&1
killall -9 mv > /dev/null 2>&1

backupid=`pidof SDCard_StorageTransfer.sh`
if [ "$backupid" != "" ]; then
	kill -9 "$backupid" > /dev/null 2>&1
fi

echo "status=canceled" > /tmp/sdstats
echo "TransferStatus=completed" > /etc/nas/config/sdcard-transfer-status.conf
sleep 1
echo "18;0;" > /tmp/MCU_Cmd
/usr/local/sbin/incUpdateCount.pm storage_transfer &
