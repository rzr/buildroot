#!/bin/sh
#
# (c) 2013 Western Digital Technologies, Inc. All rights reserved.
#
# getTemperatureStatus.sh
#
#
PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
source /etc/nas/config/wifinetwork-param.conf
if [ -f "/tmp/WiFiClientApDebugModeEnabledLog" ]; then
	Debugmode=1
else
	Debugmode=0
fi
if [ "$Debugmode" == "1" ]; then
	timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
	echo $timestamp ": wifi_client_ap_connection_status.sh" $@ >> /tmp/wificlientap.log
fi
RemoveWPS() {
	if [ -f "/tmp/clientStatus" ]; then
		rm /tmp/clientStatus
	fi
	if [ -f "/tmp/WPSpinMethod" ]; then
		rm /tmp/WPSpinMethod
	fi
	echo "22;00;" > /tmp/MCU_Cmd
}


if [ -f "/tmp/WPSpinMethod" ]; then
	WPStauts=`cat /tmp/WPSpinMethod`
	if [ "$Debugmode" == "1" ]; then
		timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
		echo $timestamp ": wifi_client_ap_connection_status.sh" "$WPStauts" >> /tmp/wificlientap.log
	fi
	if [ "$WPStauts" == "WpsNotSupported" ]; then
		RemoveWPS
		echo "15" \""$WPStauts"\"
		exit 0
	elif [ "$WPStauts" == "IncorrectPin" ]; then
		RemoveWPS
		echo "10" \""$WPStauts"\"
		exit 0
	elif [ "$WPStauts" == "TIMEDOUT" ]; then
		RemoveWPS
		echo "25" \""$WPStauts"\"
		exit 0
	else
		connectStatus=`wpa_cli -i wlan0 status | grep -rsi wpa_state | awk -F= '{print $NF}'`
		if [ "$connectStatus" == "COMPLETED" ]; then
			RemoveWPS
			echo "5" \""success"\" 
			exit 0
		#else
		#	echo "20" \""$WPStauts"\"
		#	exit 0
		fi
	fi
elif [ -f "/tmp/ClientConnStatus" ]; then
	ApCliStauts=`cat /tmp/ClientConnStatus`
	if [ "$Debugmode" == "1" ]; then
		timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
		echo $timestamp ": wifi_client_ap_connection_status.sh" "$ApCliStauts" >> /tmp/wificlientap.log
	fi
	rm /tmp/ClientConnStatus
	if [ "$ApCliStauts" == "IncorrectKey" ]; then
		echo "10" \""$ApCliStauts"\"
	fi
else 
	exit 1
fi 