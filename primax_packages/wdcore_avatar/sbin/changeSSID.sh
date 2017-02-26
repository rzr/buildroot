#!/bin/sh
LIMIT_SSID_LEN=32
ssid=$1
if [ "$ssid" != "" ]; then
	if [ ${#ssid} -gt ${LIMIT_SSID_LEN} ]; then 
        exit 1
    fi
							
	echo ${ssid} | grep -q '+\|]\|\[\|\"\|\\\|\?\|\$'
	if [ $? == 0 ]; then
		exit 1
	fi   
							
	echo ${ssid} | grep -q '^\\!\|^#\|^;'
    if [ $? == 0 ]; then
       	exit 1
    fi   
    
	sed -i 's/ssid=.*/ssid='$ssid'/' /etc/hostapd/hostapd.conf
	sed -i 's/AP_SSID_NAME=.*/AP_SSID_NAME='${ssid}'/' /etc/nas/config/wifinetwork-param.conf
	killall dhcpd
	killall hostapd
	/etc/init.d/S60hostapd start
	/usr/sbin/dhcpd -q wlan1
fi