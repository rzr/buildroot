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
	echo $timestamp ": wifi_client_ap_ButtonPress.sh" $@ >> /tmp/wificlientap.log
fi

APmode=`ifconfig | grep ^wlan1`
if [ "$APmode" == "" ]; then
	trustMode=`cat /tmp/ifplugd_trust`
	if [ "$trustMode" == "untrusted" ] || [ "$trustMode" == "trusted" ]; then
		if [ "$Debugmode" == "1" ]; then
			timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
			echo $timestamp ": wifi_client_ap_ButtonPress.sh Turn ON AP mode to Downlink Client"  >> /tmp/wificlientap.log
		fi
		echo "ForceShareMode" > /tmp/ConnectionMode
		SdStatus=`cat /etc/nas/config/sdcard-transfer-status.conf | awk -F= '{print $NF}'`
		if [ "$SdStatus" != "process" ]; then
			echo "22;01;" > /tmp/MCU_Cmd
		fi
		/usr/local/sbin/wifi_ap_set_config.sh --enabled EnabledHomeNetwork > /dev/null 2>&1 &
	fi
else
	WifiMode=`cat /tmp/ConnectionMode`
	if [ "$WifiMode" == "ApMode" ]; then
		uplinkNum=`cat /etc/nas/config/wifinetwork-remembered.conf | wc -l`
		if [ "$uplinkNum" -gt "0" ]; then
			if [ "$Debugmode" == "1" ]; then
				timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
				echo $timestamp ": wifi_client_ap_ButtonPress.sh Change to Client mode"  >> /tmp/wificlientap.log
			fi
			/usr/local/sbin/wifi_ap_set_config.sh --enabled LeaveHomeNetwork > /dev/null 2>&1 &
		fi
	fi
fi

exit 0