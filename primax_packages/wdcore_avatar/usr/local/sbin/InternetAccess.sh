#!/bin/bash
#
# � 2014 Primax Technologies, Inc. All rights reserved.
#
# InternetAccess.sh 
#
#  
#   
#

#---------------------

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

#---------------------
# Begin Script
#---------------------
ping -c 5 8.8.8.8 > /tmp/pingInternet
cat /tmp/pingInternet | grep "100% packet loss" > /dev/null 2> /dev/null
if [ $? == 0 ]; then
	curl -4 --connect-timeout 5 "http://www.wdc.com/en/" > /dev/null 2> /dev/null
	if [ $? != 0 ]; then
		curl -4 --connect-timeout 5 "http://www.google.com" > /dev/null 2> /dev/null
		if [ $? != 0 ]; then
			echo "InternetConnectionFailed"
			exit 0;
		fi
	else
		/usr/local/sbin/getNewFirmwareUpgrade.sh immediate send_alert > /dev/null 2> /dev/null &
		/usr/local/sbin/checkAutoUpdate.sh > /dev/null 2> /dev/null &
	fi
else
	/usr/local/sbin/getNewFirmwareUpgrade.sh immediate send_alert > /dev/null 2> /dev/null &
	/usr/local/sbin/checkAutoUpdate.sh > /dev/null 2> /dev/null &
fi

#---------------------
# End Script
#---------------------
