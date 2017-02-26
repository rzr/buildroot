#!/bin/bash
#
# (c) 2013 Western Digital Technologies, Inc. All rights reserved.
#
# getTemperatureStatus.sh
#
#
PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

source /etc/nas/config/wifinetwork-param.conf
DHCPD_CONF_PATH="/etc/dhcpd.conf"

if [ -f "/tmp/WiFiClientApDebugModeEnabledLog" ]; then
	Debugmode=1
else
	Debugmode=0
fi
if [ "$Debugmode" == "1" ]; then
	timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
	echo $timestamp ": autoip_generation.sh" $@ >> /tmp/wificlientap.log
fi
interface=$1

ReGenerateProfile(){
	wifi_client_remembered.sh > /dev/null 2>&1 &
}
RestartService(){
	sleep 20
	#/etc/init.d/S50lighttpd restart
	#/etc/init.d/S80dhcp-server restart
	#/etc/init.d/S92twonkyserver restart
	/etc/init.d/S91upnp restart
	sleep 5
	/etc/init.d/S50avahi-daemon restart
}

function RefreshDHCPconf(){
	newip="$1"
	
	AP_SUBNET="${newip%.*}.0"
    AP_DHCP_UPPER_BOUND="${newip%.*}.100"
    AP_DHCP_LOWER_BOUND="${newip%.*}.200"
	
    sed -i '111,$d' $DHCPD_CONF_PATH

    echo "option routers $newip;"                                   >> $DHCPD_CONF_PATH
    echo "option domain-name-servers $newip;"                       >> $DHCPD_CONF_PATH
    echo " "                                                        >> $DHCPD_CONF_PATH
    echo "subnet $AP_SUBNET netmask $AP_MASK {"                     >> $DHCPD_CONF_PATH
    echo "    pool {"                                               >> $DHCPD_CONF_PATH
    echo "        max-lease-time 86400;"                            >> $DHCPD_CONF_PATH
    echo "        range $AP_DHCP_UPPER_BOUND $AP_DHCP_LOWER_BOUND;" >> $DHCPD_CONF_PATH
    echo "        option routers $newip;"                           >> $DHCPD_CONF_PATH
    echo "        option domain-name-servers $newip, $AP_DNS;"      >> $DHCPD_CONF_PATH
    echo "        allow unknown-clients;"                           >> $DHCPD_CONF_PATH
    echo "    }"                                                    >> $DHCPD_CONF_PATH
    echo "}"                                                        >> $DHCPD_CONF_PATH
}

if [ ! -f "/tmp/AutoIP_Generation" ]; then
	wlan0_if=`ifconfig | grep ^wlan0`
	if [ "$wlan0_if" != "" ]; then
		echo "go auto ip" > /tmp/AutoIP_Generation
		sleep 50
		
		connectedCipher=`wpa_cli -i wlan0 status | grep -rsw "pairwise_cipher" | awk -F= '{print $NF}'`
		if [ "$connectedCipher" == "WEP-40" ] || [ "$connectedCipher" == "WEP-104" ]; then
			networkConfig=`/usr/local/sbin/getNetworkConfig.sh`
			if [ "$networkConfig" == "disconnected" ]; then
				rm /tmp/AutoIP_Generation
				exit 0
			fi
		fi
		
		connectedmac=`wpa_cli -i wlan0 status | grep -rsw "bssid" | awk -F= '{print $NF}' | tr [:lower:] [:upper:]`
		connectStatus=`wpa_cli -i wlan0 status | grep -rsi wpa_state | awk -F= '{print $NF}'`
		connectedip=`wpa_cli -i wlan0 status | grep -rsw "ip_address" | awk -F= '{print $NF}'`
		if [ "$connectedip" == "" ]; then
			/sbin/ifup wlan0
			sleep 3
		fi
		connectedip=`wpa_cli -i wlan0 status | grep -rsw "ip_address" | awk -F= '{print $NF}'`
		connectedipblock=`wpa_cli -i wlan0 status | grep -rsw "ip_address" | awk -F= '{print $NF}'| awk -F. '{print $1"."$2"."$3}'`
		autoIp=`wpa_cli -i wlan0 status | grep -rsw "ip_address" | awk -F= '{print $NF}' | awk -F. '{print $1"."$2}'`
		ApIP=`wifi_ap_get_config.sh | grep "ip=" | awk -F= '{print $2}' | cut -d '"' -f 2 | awk -F. '{print $1"."$2"."$3}'`
		
		if [ "$connectedip" == "" ] || [ "$autoIp" == "169.254" ]; then
			if [ "$connectedmac" != "" ] && [ "$connectStatus" == "COMPLETED" ]; then
				if [ "$Debugmode" == "1" ]; then
					timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
					echo $timestamp ": autoip_generation.sh auto ip generation" "$connectedip" "$connectedmac" "$connectStatus" >> /tmp/wificlientap.log
				fi
				/etc/init.d/S50avahi-daemon stop
				killall zcip
				/sbin/zcip wlan0 /etc/zcip.script
			fi
		elif [ "$ApIP" == "$connectedipblock" ]; then
			Ap_1=`wifi_ap_get_config.sh | grep "ip=" | awk -F= '{print $2}' | cut -d '"' -f 2 | awk -F. '{print $1}'`
			Ap_2=`wifi_ap_get_config.sh | grep "ip=" | awk -F= '{print $2}' | cut -d '"' -f 2 | awk -F. '{print $2}'`
			Ap_3=`wifi_ap_get_config.sh | grep "ip=" | awk -F= '{print $2}' | cut -d '"' -f 2 | awk -F. '{print $3}'`
			if [ "$Ap_3" == "254" ]; then
				Ap_3=0
			else
				Ap_3=`expr $Ap_3 + 1`
			fi
			Ap_4=`wifi_ap_get_config.sh | grep "ip=" | awk -F= '{print $2}' | cut -d '"' -f 2 | awk -F. '{print $4}'`
			newAPIP=$Ap_1"."$Ap_2"."$Ap_3"."$Ap_4
			echo $newAPIP > /tmp/autoIPgeneration
			wlan1_if=`ifconfig | grep ^wlan1`
			if [ "$wlan1_if" != "" ]; then 
				wifi_ap_set_config.sh --enabled true --ip "$newAPIP" 
			else
				ifconfig wlan1 ${newAPIP} up
				sed -i 's/AP_IP=.*/AP_IP='${newAPIP}'/' /etc/nas/config/wifinetwork-param.conf
				ifconfig wlan1 down
				RefreshDHCPconf ${newAPIP}
			fi
			sleep 10
			/etc/init.d/S90multi-role restart
			 
		fi
		RestartService > /dev/null 2>&1 &
		rm /tmp/AutoIP_Generation
	fi
fi 
