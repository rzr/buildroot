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
			rm -f /tmp/InternetConnection
			exit 0;
		fi
	else
		if [ ! -f /tmp/InternetConnection ]; then
			/usr/local/sbin/getNewFirmwareUpgrade.sh immediate send_alert > /dev/null 2> /dev/null &
			/usr/local/sbin/checkAutoUpdate.sh > /dev/null 2> /dev/null &
			date +%s > /tmp/InternetConnection
		else
			now_time=`date "+%s"`
			start_time=`cat /tmp/InternetConnection`
			time_diff=`expr $now_time - $start_time`
			if [ "$time_diff" -gt "3600" ]; then
				/usr/local/sbin/getNewFirmwareUpgrade.sh immediate send_alert > /dev/null 2> /dev/null &
				/usr/local/sbin/checkAutoUpdate.sh > /dev/null 2> /dev/null &
				date +%s > /tmp/InternetConnection
			fi
		fi
	fi
else
	if [ ! -f /tmp/InternetConnection ]; then
		/usr/local/sbin/getNewFirmwareUpgrade.sh immediate send_alert > /dev/null 2> /dev/null &
		/usr/local/sbin/checkAutoUpdate.sh > /dev/null 2> /dev/null &
		date +%s > /tmp/InternetConnection
	else
		now_time=`date "+%s"`
		start_time=`cat /tmp/InternetConnection`
		time_diff=`expr $now_time - $start_time`
		if [ "$time_diff" -gt "3600" ]; then
			/usr/local/sbin/getNewFirmwareUpgrade.sh immediate send_alert > /dev/null 2> /dev/null &
			/usr/local/sbin/checkAutoUpdate.sh > /dev/null 2> /dev/null &
			date +%s > /tmp/InternetConnection
		fi
	fi
fi

#---------------------
# End Script
#---------------------
