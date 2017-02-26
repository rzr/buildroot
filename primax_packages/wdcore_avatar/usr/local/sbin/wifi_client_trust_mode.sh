#!/bin/sh
#
# (c) 2013 Western Digital Technologies, Inc. All rights reserved.
#
# getTemperatureStatus.sh
#
#
PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

execRemember=$2
ifaction=$1
#AP_Status=`/usr/local/sbin/wifi_ap_get_config.sh | awk 'BEGIN {FS="enabled="} {print $2}' | cut -d " " -f 1`	
interface=`pidof hostapd`
if [ "$interface" != "" ]; then
	AP_Status=true
else
	AP_Status=false
fi

if [ ! -f "/tmp/wifi_client_trust_execute" ]; then
	if [ "$ifaction" == "up" ]; then
		if [ "$execRemember" == "" ]; then
			echo "go trust" > /tmp/wifi_client_trust_execute
			sleep 25
		else
			sleep 15
		fi
	fi
	connectedmac=`wpa_cli -i wlan0 status | grep -rsw "bssid" | awk -F= '{print $NF}' | tr [:lower:] [:upper:]`
	autoIp=`wpa_cli -i wlan0 status | grep -rsw "ip_address" | awk -F= '{print $NF}' | awk -F. '{print $1"."$2}'`
	
	if [ "$connectedmac" != "" ]; then
		killall zcip
		if [ "$autoIp" == "169.254" ]; then
			/sbin/ifdown wlan0
			exit 0
		fi
		/sbin/ifup wlan0
		/sbin/ifup wlan0
		/sbin/ifup wlan0
		
		connectedCipher=`wpa_cli -i wlan0 status | grep -rsw "pairwise_cipher" | awk -F= '{print $NF}'`
		if [ "$connectedCipher" == "WEP-40" ] || [ "$connectedCipher" == "WEP-104" ]; then
			networkConfig=`/usr/local/sbin/getNetworkConfig.sh`
			if [ "$networkConfig" == "disconnected" ]; then
				rm /tmp/wifi_client_trust_execute
				exit 0
			fi
		fi	
		#clear file retry count 
		echo 0 > /tmp/ApCliRetry 
		trusted=`grep -rsi \""${connectedmac}"\" /etc/nas/config/wifinetwork-remembered.conf | awk 'BEGIN {FS="trusted="} {print $2}'| cut -d '"' -f 2 | head -1` 
		
		if [ "$trusted" != "" ]; then
			apcliChan=`iwlist wlan0 channel | grep "Current" | awk '{print $NF}' | cut -d ')' -f 1`
			if [ -f "/tmp/CurrentChannel" ]; then
				apchan=`cat /tmp/CurrentChannel`
			fi
			
			if [ "$apcliChan" != "$apchan" ]; then
				#ifconfig wlan1 down
				#iw dev wlan1 set channel 11 HT20
				#ifconfig wlan1 up
				echo $apcliChan > /tmp/CurrentChannel	
			fi
			
			if [ "$trusted" == "true" ]; then
				if [ -f "/tmp/ConnectionMode" ]; then
					CMode=`cat /tmp/ConnectionMode`
				fi
				if [ -f "/tmp/executeTrust" ]; then
					HomeConnect=`cat /tmp/executeTrust`
				fi
				if [ "$AP_Status" == "true" ] && [ "$CMode" != "ForceShareMode" ] && [ "$HomeConnect" == "executeTrust" ]; then
					#wifi-restart AP &
					#/usr/local/sbin/wifi_ap_set_config.sh --enabled LeaveHomeNetwork > /dev/null 2> /dev/null < /dev/null
					echo "ShareMode" > /tmp/ConnectionMode
					rm /tmp/executeTrust > /dev/null 2> /dev/null < /dev/null
				#else
					#wifi-restart AP &
				#	echo "ShareMode" > /tmp/ConnectionMode
				fi
				echo "trusted" > /tmp/ifplugd_trust
				
				/usr/sbin/iptables -D INPUT -i wlan0 -p tcp --dport 80 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p tcp --dport 5353 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p tcp --dport 9000 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p udp --dport 1900 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p udp --dport 137:138 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p tcp --dport 139 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p tcp --dport 445 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p tcp --dport 22 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p udp --dport 5353 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p tcp --dport 548 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p tcp --dport 21 -j DROP > /dev/null 2> /dev/null < /dev/null
				
				#/usr/sbin/iptables -D INPUT -i wlan0 -p icmp --icmp-type echo-request -j DROP > /dev/null 2> /dev/null < /dev/null
			else
				if [ "$AP_Status" == "false" ]; then
					/usr/local/sbin/wifi_ap_set_config.sh --enabled EnabledHomeNetwork > /dev/null 2> /dev/null < /dev/null
				#else
				#	wifi-restart AP &
				fi
				echo "untrusted" > /tmp/ifplugd_trust
				echo "ShareMode" > /tmp/ConnectionMode
				/usr/sbin/iptables -D INPUT -i wlan0 -p tcp --dport 80 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p tcp --dport 5353 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p tcp --dport 9000 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p udp --dport 1900 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p udp --dport 137:138 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p tcp --dport 139 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p tcp --dport 445 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p tcp --dport 22 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p udp --dport 5353 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p tcp --dport 548 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -D INPUT -i wlan0 -p tcp --dport 21 -j DROP > /dev/null 2> /dev/null < /dev/null
				#/usr/sbin/iptables -D INPUT -i wlan0 -p icmp --icmp-type echo-request -j DROP > /dev/null 2> /dev/null < /dev/null
				
				/usr/sbin/iptables -A INPUT -i wlan0 -p tcp --dport 80 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -A INPUT -i wlan0 -p tcp --dport 5353 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -A INPUT -i wlan0 -p tcp --dport 9000 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -A INPUT -i wlan0 -p udp --dport 1900 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -A INPUT -i wlan0 -p udp --dport 137:138 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -A INPUT -i wlan0 -p tcp --dport 139 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -A INPUT -i wlan0 -p tcp --dport 445 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -A INPUT -i wlan0 -p tcp --dport 22 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -A INPUT -i wlan0 -p udp --dport 5353 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -A INPUT -i wlan0 -p tcp --dport 548 -j DROP > /dev/null 2> /dev/null < /dev/null
				/usr/sbin/iptables -A INPUT -i wlan0 -p tcp --dport 21 -j DROP > /dev/null 2> /dev/null < /dev/null
				#/usr/sbin/iptables -A INPUT -i wlan0 -p icmp --icmp-type echo-request -j DROP > /dev/null 2> /dev/null < /dev/null
			fi
		fi
	else
		#connectMode=`cat /tmp/ifplugd_trust`
		echo "nontrusted" > /tmp/ifplugd_trust
		echo "ApMode" > /tmp/ConnectionMode
		echo "192.168.60.1" > /tmp/resolv.conf
		sleep 3
		/etc/init.d/S91upnp restart > /dev/null 2>&1 &
		#if [ "$connectMode" == "trusted" ]; then
		#	if [ "$AP_Status" == "false" ]; then
		#		/usr/local/sbin/wifi_ap_set_config.sh --enabled EnabledHomeNetwork > /dev/null 2> /dev/null < /dev/null
		#	fi
		#fi
		#echo "Add iptables rule block" >> /tmp/ifplugd_trust
		#/usr/sbin/iptables -A INPUT -i wlan0 -p tcp --dport 80 -j DROP > /dev/null 2> /dev/null < /dev/null
		#/usr/sbin/iptables -A INPUT -i wlan0 -p tcp --dport 5353 -j DROP > /dev/null 2> /dev/null < /dev/null
		#/usr/sbin/iptables -A INPUT -i wlan0 -p tcp --dport 9000 -j DROP > /dev/null 2> /dev/null < /dev/null
		#/usr/sbin/iptables -A INPUT -i wlan0 -p udp --dport 1900 -j DROP > /dev/null 2> /dev/null < /dev/null
		#/usr/sbin/iptables -A INPUT -i wlan0 -p udp --dport 137:138 -j DROP > /dev/null 2> /dev/null < /dev/null
		#/usr/sbin/iptables -A INPUT -i wlan0 -p tcp --dport 139 -j DROP > /dev/null 2> /dev/null < /dev/null
		#/usr/sbin/iptables -A INPUT -i wlan0 -p tcp --dport 445 -j DROP > /dev/null 2> /dev/null < /dev/null
		#/usr/sbin/iptables -A INPUT -i wlan0 -p tcp --dport 22 -j DROP > /dev/null 2> /dev/null < /dev/null
	fi
	
	rm /tmp/wifi_client_trust_execute
fi
