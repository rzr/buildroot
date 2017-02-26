#!/bin/bash
#
# � 2010 Western Digital Technologies, Inc. All rights reserved.
#
# getNetworkConfig.sh
#
#


PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
. /etc/nas/config/share-param.conf
. /etc/nas/config/networking-general.conf 2>/dev/null
. /etc/nas/config/wifinetwork-param.conf
# Backward compatibility to support no iface argument (default to wired wlan0)
iname=wlan0
NotConnect=0
#connectStatus=`iw dev wlan0 link`

if [ $# -gt 0 ]; then
    iname=$1
fi

if [ "${iname}" == "wlan0" ]; then
	if [ $STA_CLIENT == "true" ]; then
		cliipaddr=`ifconfig wlan0 | grep "inet addr" | awk 'BEGIN {FS="addr:"}{print $NF}'| cut -d ' ' -f 1`
		connectStatus=`wpa_cli -i wlan0 status | grep -rsi wpa_state | awk -F= '{print $NF}'`
		connectedip=`wpa_cli -i wlan0 status | grep -rsw "ip_address" | awk -F= '{print $NF}'`
	else
		echo "disconnected"
		exit 0
	fi

	if [ "${connectStatus}" == "SCANNING" ] || [ "${connectStatus}" == "4WAY_HANDSHAKE" ] || [ "${connectedip}" == "" ]; then
		#if [ "${cliipaddr}" == "" ]; then
		#NotConnect=1
		#fi
		echo "disconnected"
		exit 0
	fi
	configurationMethod=`awk -v name="$iname" '{ if ($1 == "iface" && $2 == name) { print $4; exit 0; } }' ${networkConfig}`
	#essid=`iwconfig wlan0 | grep ESSID | awk -F: '{print $2}' | awk -F/ '{print $1}'`
	autoIp=`wpa_cli -i wlan0 status | grep -rsw "ip_address" | awk -F= '{print $NF}' | awk -F. '{print $1"."$2}'`
	connectedmac=`wpa_cli -i wlan0 status | grep -rsw "bssid" | awk -F= '{print $NF}' | tr [:lower:] [:upper:]`
	if [ "$configurationMethod" == "dhcp" ]; then	
    	connection=`cat /etc/resolv.conf 2> /dev/null`
    	if [ $? == 0 ]; then
    		if [ "${NotConnect}" == "1" ]; then
    			echo "disconnected"
    		else
    			echo "dhcp"
    			echo address `ifconfig wlan0 | grep inet | sed 's/[ ][ ]*/:/g' | awk -F: '{print $4}'`
    			echo netmask `ifconfig wlan0 | grep inet | sed 's/[ ][ ]*/:/g' | awk -F: '{print $8}'`
    			if [ "$autoIp" != "169.254" ]; then
    				echo gateway `ip route | awk '/default/ { print $3 }'`
    				cat $dnsConfig | awk '{if ($1 == "nameserver" && $2 != "") printf("nameserver %s\n",$2)}'
    			fi
    			echo "gateway_mac_address" $connectedmac 	
    		fi
    	else
    		if [ "$autoIp" = "169.254" ]; then
    			echo "dhcp"
    			echo address `ifconfig wlan0 | grep inet | sed 's/[ ][ ]*/:/g' | awk -F: '{print $4}'`
    			echo netmask `ifconfig wlan0 | grep inet | sed 's/[ ][ ]*/:/g' | awk -F: '{print $8}'`
    			echo "gateway_mac_address" $connectedmac 	
    		else
    			echo "disconnected"
    		fi
    	fi
    	
	elif [ "${configurationMethod}" == "static" ]; then
		if [ "${NotConnect}" == "1" ]; then
			echo "disconnected"
			exit 0
		fi
		echo "static"
    	while read aline
    	do
        	# find the iface config record
        	echo ${aline} | grep "\<iface $iname\>" > /dev/null
        	if [ $? -eq 0 ];  then
            	while read confline
            	do
                	echo $confline | grep '^\s*\(iface\|mapping\|auto\|allow-\)' > /dev/null
                	if [ $? -eq 0 ]; then
                    	break
                	fi
                	echo $confline | grep "address" | sed 's/^[ \t]*//'
                	echo $confline | grep "netmask" | sed 's/^[ \t]*//'
                	echo $confline | grep "gateway" | sed 's/^[ \t]*//'
            	done
            	# Done searching.
            	break
        	fi

    	done < ${networkConfig}
    	cat $dnsConfig | awk '{if ($1 == "nameserver" && $2 != "") printf("nameserver %s\n",$2)}'
    	connectedmac=`wpa_cli -i wlan0 status | grep -rsw "bssid" | awk -F= '{print $NF}' | tr [:lower:] [:upper:]`
    	echo "gateway_mac_address" $connectedmac 
	fi
elif [ "${iname}" == "wlan1" ]; then
	echo "static"
	echo address "$AP_IP"
	echo netmask "$AP_MASK"
elif [ "${iname}" == "lo" ]; then
	echo "static"
	echo address "127.0.0.1"
	echo netmask "255.0.0.0"
fi
	
	

