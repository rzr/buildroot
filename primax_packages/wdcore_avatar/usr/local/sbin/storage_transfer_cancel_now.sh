#!/bin/sh
killall -15 rsync &
touch /tmp/SDCard_Process_Canceled
exit 0
