#!/bin/bash
#
#
# wifi_ap_get_config.sh
#
#


PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
. /etc/nas/config/share-param.conf
. /etc/nas/config/wifinetwork-param.conf 2>/dev/null

if [ "$AP_HOTSPOT" == "true" ]; then
    echo "enabled=true"
else
    echo "enabled=false"
fi

echo "ssid=${AP_SSID_NAME}"

#if [ "$AP_ENCRYPTION_TYPE" == "NONE" ]; then
#    echo -n "security_key=\"\" "
#else
#    echo -n "security_key=\"${AP_ENCRYPTION_KEY}\" "
#fi

if [ "$AP_BROADCAST" == "true" ]; then
    echo "broadcast=true"
else
    echo "broadcast=false"
fi

if [ "$AP_ENCRYPTION_TYPE" == "NONE" ]; then
    echo "secured=false"
else
    echo "secured=true"
fi

echo "mac_address=`iw dev wlan1 info | grep "addr" | awk '{print $2}' | tr [:lower:] [:upper:]`"
if [ "${AP_ENCRYPTION_TYPE}" == "WPAPSK" ] || [ "${AP_ENCRYPTION_TYPE}" == "WPA2PSK" ] || [ "${AP_ENCRYPTION_TYPE}" == "WPAPSK1WPAPSK2" ]; then
	echo "security_mode=${AP_ENCRYPTION_TYPE}/${AP_CIPHER_TYPE}"
else
	echo "security_mode=${AP_ENCRYPTION_TYPE}"
fi
	
#echo -n "channel=\"${AP_CHANNEL}\""
if [ "${AP_CHANNEL}" == "0" ]; then
	echo "channel_mode=auto"
	if [ -f "/tmp/CurrentChannel" ];then
		chl=`cat /tmp/CurrentChannel`
		if [ $? == 0 ]; then
			echo "channel=$chl"
		else
			echo "channel=${AP_CHANNEL}"
		fi
	else 
		echo "channel=${AP_CHANNEL}"
	fi
else
	echo "channel_mode=manual"
	echo "channel=${AP_CHANNEL}"
fi

echo "ip=${AP_IP}"
echo "netmask=${AP_MASK}"

echo "network_mode=${AP_NETWORK_MODE}"

if [ "$AP_DHCPD_ENABLE" == "true" ]; then
    echo "enable_dhcp=true"
else
    echo "enable_dhcp=false"
fi

max_channels=`iwlist wlan0 channel | grep wlan0 | awk -F " " '{print $2}'`
filter='^[0-9]+$'

if ! [[ $max_channels =~ $filter ]] ; then
     max_channels=11
fi

echo "max_available_channel=$max_channels"

