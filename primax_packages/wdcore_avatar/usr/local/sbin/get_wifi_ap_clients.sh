#!/bin/sh
source /etc/nas/config/wifinetwork-param.conf

specified=$1
specifiedMAC=$2

if [ "$AP_DHCPD_ENABLE" == "true" ]; then 
	arp -a > /tmp/apclientARP
	for tmp in `cat /var/run/dhcpd.leases|grep ^lease|awk '{ print $2 }'|sort|uniq`
	do
		client=`cat /var/run/dhcpd.leases|grep -A 8 $tmp|grep client|awk '{ print $2 }'|sort|uniq|sed 's/;*$//'`
		if [ "$client" = "" ]; then
			client="\"\""
		fi
	
		mac=`cat /var/run/dhcpd.leases|grep -A 8 $tmp|grep ethernet|awk '{ print $3 }'|sort|uniq|sed 's/;*$//' | tr [:lower:] [:upper:]`
		wifimac=`iw wlan1 station dump|grep -rsi "$mac" | grep "Station" |awk '{ print $2 }'|sort|uniq | tr [:lower:] [:upper:]`
		if [ "${wifimac}" == "" ];then
  			continue
  		fi
  		echo $mac >> /tmp/getapclient
		
		iptmp=`cat /tmp/apclientARP | grep "wlan1" | grep -rsi "${wifimac}" | tail -1`
  		ipclient=`echo "$iptmp" | cut -c 4-17`
  		if [ "$ipclient" != "" ]; then
  			if [ "$ipclient" != "$tmp" ]; then
  				tmp="${ipclient}"
  			fi
  		fi
  	
		if [ "$specified" == "" ]; then
			if [ "$mac" == "$wifimac" ]; then
  				sta_info="mac:\"$mac\" ip:\"$tmp\" name:$client"
  			fi
  		elif [ "$specified" == "--mac" ]; then
  			specifiedMAC=`echo "$specifiedMAC" | tr [:lower:] [:upper:]`
  			if [ "$specifiedMAC" == "$wifimac" ]; then
  				sta_info="mac:\"$mac\" ip:\"$tmp\" name:$client"
  				break
  			fi
  		fi
  	
  		connectedTime=`iw wlan1 station dump | grep -rsi $mac | grep "connected time:" | awk '{print $NF}'`
  		if [ "$connectedTime" != "" ]; then
  			echo ${sta_info} "connected_time:\"$connectedTime\""
  		else
  			connectedTime=`date +%s`
  			echo ${sta_info} "connected_time:\"$connectedTime\""
  		fi
	done
	
	iw wlan1 station dump | grep "Station" > /tmp/apclientnum
	cat /tmp/apclientnum | while read lineProfile
	do
		wifimac=`echo ${lineProfile}| grep "Station" | awk '{ print $2 }' |  tr [:lower:] [:upper:]`
		if [ "${wifimac}" == "" ];then
  			continue
  		fi
  		if [ -f /tmp/getapclient ]; then
  			cat /tmp/getapclient | grep -rsi "${wifimac}" > /dev/null
  			if [ $? == 0 ]; then
  				continue
  			fi
  		fi
  		
  		iptmp=`cat /tmp/apclientARP | grep "wlan1" | grep -rsi "${wifimac}" | tail -1`
  		ipclient=`echo "$iptmp" | cut -c 4-17`
  		
  		if [ "$specified" == "" ]; then	
  			sta_info="mac:\"$wifimac\" ip:\"${ipclient}\" name:\"Unknown\""
  		elif [ "$specified" == "--mac" ]; then
  			specifiedMAC=`echo "$specifiedMAC" | tr [:lower:] [:upper:]`
  			if [ "$specifiedMAC" == "$wifimac" ]; then
  				sta_info="mac:\"$mac\" ip:\"${ipclient}\" name:\"Unknown\""
  				break;
  			fi
  		fi
  	
  		connectedTime=`iw wlan1 station dump | grep -rsi $wifimac | grep "connected time:" | awk '{print $NF}'`
  		if [ "$connectedTime" != "" ]; then
  			echo ${sta_info} "connected_time:\"$connectedTime\""
  		else
  			connectedTime=`date +%s`
  			echo ${sta_info} "connected_time:\"$connectedTime\""
  		fi
	done
	
	if [ -f /tmp/getapclient ]; then
  			rm /tmp/getapclient		
  	fi
else
	iw wlan1 station dump| grep "Station" > /tmp/apclientnum
	arp -a > /tmp/apclientARP
	cat /tmp/apclientnum | while read lineProfile
	do
		wifimac=`echo ${lineProfile}| grep "Station" | awk '{ print $2 }' |  tr [:lower:] [:upper:]`
		if [ "${wifimac}" == "" ];then
  			continue
  		fi
  			
  		iptmp=`cat /tmp/apclientARP | grep "wlan1" | grep -rsi "${wifimac}" | tail -1`
  		ipclient=`echo "$iptmp" | cut -c 4-17`
  	
  		if [ "$specified" == "" ]; then	
  			sta_info="mac:\"$wifimac\" ip:\"$ipclient\" name:\"Unknown\""
  		elif [ "$specified" == "--mac" ]; then
  			specifiedMAC=`echo "$specifiedMAC" | tr [:lower:] [:upper:]`
  			if [ "$specifiedMAC" == "$wifimac" ]; then
  				sta_info="mac:\"$mac\" ip:\"$ipclient\" name:\"Unknown\""
  				break
  			fi
  		fi
  	
  		connectedTime=`iw wlan1 station dump | grep -rsi $wifimac | grep "connected time:" | awk '{print $NF}'`
  		if [ "$connectedTime" != "" ]; then
  			echo ${sta_info} "connected_time:\"$connectedTime\""
  		else
  			connectedTime=`date +%s`
  			echo ${sta_info} "connected_time:\"$connectedTime\""
  		fi
	done
fi	

exit 0
