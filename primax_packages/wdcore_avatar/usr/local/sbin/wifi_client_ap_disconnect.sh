#!/bin/sh
#
# (c) 2013 Western Digital Technologies, Inc. All rights reserved.
#
# wifi_client_ap_disconnect.sh
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
	echo $timestamp ": wifi_client_ap_disconnect.sh" $@ >> /tmp/wificlientap.log
fi
ErrorCode(){
	echo "/usr/local/sbin/wifi_client_ap_disconnect.sh --mac <mac_address>"
	if [ "$Debugmode" == "1" ]; then
		timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
		echo $timestamp ": wifi_client_ap_configuration_set.sh input parameter error" "$1"  >> /tmp/wificlientap.log
	fi
	exit 1
}

CheckAPExist(){
	interface=`pidof hostapd`
	if [ "$interface" == "" ]; then
		/usr/local/sbin/wifi_ap_set_config.sh --enabled EnabledHomeNetwork 
	fi
}

if [ $# == 0 ]; then
	ErrorCode "--All"
fi


while [ "$1" != "" ]; do
	case "$1" in
		
		--mac	)	shift
					string_mac="$1"
					option_connect=disconnect
					;;
					
		*)			ErrorCode "--Unknown"
					;;
	esac
	
	shift
done

if [ "$option_connect" == "disconnect" ]; then
	connectMAC=`iwconfig wlan0 | grep "Access Point" | awk '{print $NF}'`
	if [ "$Debugmode" == "1" ]; then
		timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
		echo $timestamp ": wifi_client_ap_disconnect.sh connected MAC addr:" "$connectMAC" >> /tmp/wificlientap.log
	fi
	if [ "$connectMAC" == "$string_mac" ]; then
		/sbin/wifi-restart UPDATE_STA_CONF
		/sbin/wifi-restart STA 
		if [ "$Debugmode" == "1" ]; then
			timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
			echo $timestamp ": wifi_client_ap_disconnect.sh Disconnecting Target Router"  >> /tmp/wificlientap.log
		fi
	
		sed -i 's/connected="true"./connected="false" /' /etc/nas/config/wifinetwork-remembered.conf
		sed -i 's/remembered="true"./remembered="false" /' /tmp/wifinetwork-remembered.conf
		sed '/'\""${string_mac}"\"'/d' /etc/nas/config/wifinetwork-remembered.conf > /tmp/wifinetwork-remembered_tmp.conf
		cat /tmp/wifinetwork-remembered_tmp.conf > /etc/nas/config/wifinetwork-remembered.conf
		cat /etc/nas/config/wifinetwork-remembered.conf > /tmp/wifinetwork-remembered.conf
		rm /tmp/wifinetwork-remembered_tmp.conf
		if [ "$Debugmode" == "1" ]; then
			timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
			profileleft=`cat /etc/nas/config/wifinetwork-remembered.conf`
			echo $timestamp ": wifi_client_ap_disconnect.sh Delete target Profile, latest profile list" >> /tmp/wificlientap.log
			echo $timestamp ": wifi_client_ap_disconnect.sh " $profileleft >> /tmp/wificlientap.log
		fi
		#num_remember=`cat /etc/nas/config/wifinetwork-remembered.conf | wc -l`
		sed -i 's/STA_SSID_NAME=.*/STA_SSID_NAME=/' /etc/nas/config/wifinetwork-param.conf
		sed -i 's/STA_MAC_MAPPING=.*/STA_MAC_MAPPING=/' /etc/nas/config/wifinetwork-param.conf
		sed -i 's/STA_MAC_ADDRESS=.*/STA_MAC_ADDRESS=/' /etc/nas/config/wifinetwork-param.conf
		sed -i 's/STA_SECURITY_MODE=.*/STA_SECURITY_MODE=/' /etc/nas/config/wifinetwork-param.conf
		sed -i 's/STA_CIPHER_TYPE=.*/STA_CIPHER_TYPE=/' /etc/nas/config/wifinetwork-param.conf
		sed -i 's/STA_PSK_KEY=.*/STA_PSK_KEY=/' /etc/nas/config/wifinetwork-param.conf
		sed -i 's/STA_WEP_KEY=.*/STA_WEP_KEY=/' /etc/nas/config/wifinetwork-param.conf		
		#if [ "${num_remember}" == 0 ]; then
		#	sed -i 's/STA_CLIENT=.*/STA_CLIENT=false/' /etc/nas/config/wifinetwork-param.conf
		#fi
		
		/usr/local/sbin/wifi_client_trust_mode.sh "down" &
		CheckAPExist
		echo "24;00;" > /tmp/MCU_Cmd
		wifi_client_ap_scan.sh --remembered signalCHECK > /dev/null	
		exit 0
	else
		if [ "$Debugmode" == "1" ]; then
			timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
			echo $timestamp ": wifi_client_ap_disconnect.sh Dismatch Target, Only remove profile" >> /tmp/wificlientap.log
		fi
		sed -i '/'\""${string_mac}"\"'/ s/remembered="true"./remembered="false" /' /tmp/wifinetwork-remembered.conf
		sed '/'\""${string_mac}"\"'/d' /etc/nas/config/wifinetwork-remembered.conf > /tmp/wifinetwork-remembered_tmp.conf
		cat /tmp/wifinetwork-remembered_tmp.conf > /etc/nas/config/wifinetwork-remembered.conf
		cat /etc/nas/config/wifinetwork-remembered.conf > /tmp/wifinetwork-remembered.conf
		rm /tmp/wifinetwork-remembered_tmp.conf
	fi	
fi

