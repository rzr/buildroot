#!/bin/sh
#
# (c) 2013 Western Digital Technologies, Inc. All rights reserved.
#
# wifi_client_ap_configuration_set.sh
#
#
PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

source /etc/nas/config/wifinetwork-param.conf
STA_Status=$STA_CLIENT

if [ -f "/tmp/WiFiClientApDebugModeEnabledLog" ]; then
	Debugmode=1
else
	Debugmode=0
fi
if [ "$Debugmode" == "1" ]; then
	timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
	echo $timestamp ": wifi_client_ap_configuration_set.sh" $@ >> /tmp/wificlientap.log
fi

CheckAPExist(){
	interface=`pidof hostapd`
	if [ "$interface" == "" ]; then
		/usr/local/sbin/wifi_ap_set_config.sh --enabled EnabledHomeNetwork 
	fi
}

ErrorCode(){
	echo "/usr/local/sbin/wifi_client_ap_configuration_set.sh --enabled true|false"
	if [ "$Debugmode" == "1" ]; then
		timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
		echo $timestamp ": wifi_client_ap_configuration_set.sh input parameter error" "$1"  >> /tmp/wificlientap.log
	fi
	exit 1
}

ParamSet(){
	if [ -f "/tmp/ifplugd_trust" ]; then
		rm /tmp/ifplugd_trust
	fi
	echo "ApMode" > /tmp/ConnectionMode
	echo "192.168.60.1" > /tmp/resolv.conf
}

if [ $# == 0 ]; then
	ErrorCode "--All"
fi

while [ "$1" != "" ]; do
	case "$1" in
		
		--enabled)	shift
					if [ "$1" != "true" ] && [ "$1" != "false" ]; then
		           		ErrorCode "--enabled"
		           	else 
		           		clientHunt="$1"
		           	fi
					;;
					
		*)			ErrorCode "--Unknown"
					;;
	esac
	
	shift
done

if [ "$clientHunt" == "false" ]; then #disable
	if [ "$STA_Status" != "$clientHunt" ]; then
		sed -i 's/STA_CLIENT=.*/STA_CLIENT='${clientHunt}'/' /etc/nas/config/wifinetwork-param.conf
		/etc/init.d/S90multi-role stop 
		CheckAPExist
		ParamSet
		if [ "$Debugmode" == "1" ]; then
			timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
			echo $timestamp ": wifi_client_ap_configuration_set.sh  disable ok" >> /tmp/wificlientap.log
		fi
		exit 0
	fi
else
	if [ "$STA_Status" != "$clientHunt" ]; then
		sed -i 's/STA_CLIENT=.*/STA_CLIENT='${clientHunt}'/' /etc/nas/config/wifinetwork-param.conf
		FileNum=`cat /etc/nas/config/wifinetwork-remembered.conf | wc -l`
		if [ "$FileNum" != 0 ]; then
			sed -i 's/STA_CONF_JOIN=.*/STA_CONF_JOIN=1/' /etc/nas/config/wifinetwork-param.conf
		fi
		/sbin/wifi-restart STA > /dev/null 2>&1 &
		if [ "$Debugmode" == "1" ]; then
			timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
			echo $timestamp ": wifi_client_ap_configuration_set.sh  enable ok" >> /tmp/wificlientap.log
		fi
		sleep 1
		exit 0
	fi
fi

exit 0