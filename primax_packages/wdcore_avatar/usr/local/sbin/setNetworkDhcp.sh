#!/bin/bash
#
# � 2010 Western Digital Technologies, Inc. All rights reserved.
#
# setNetworkDhcp.sh
#
#

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
. /etc/nas/config/share-param.conf
. /etc/nas/config/networking-general.conf 2>/dev/null
. /etc/nas/config/wifinetwork-param.conf
NorestartService=0
tmp_conf=/etc/.tmp_netconf


while [ "$1" != "" ]; do
	gw_mac=`echo ${1} | grep "gateway_mac_address="`
	if [ "${gw_mac}" == "" ]; then
		iname=`echo ${1}`
   		if [ "${iname}" == "wlan0-connect" ]; then
      		NorestartService=1
      		iname=wlan0
   		else
   			iname=wlan0
   		fi
   		if [ "${iname}" != "wlan0" ]; then
       		exit 1
   		fi	
	else
		gw_mac=`echo ${1} | grep "gateway_mac_address=" | cut -d'=' -f2`
	fi
	shift
done

if [ "$gw_mac" == "" ] && [ "$iname" == "" ]; then
	echo "usage: setNetworkDhcp.sh <iname>  gateway_mac_address=<gateway_mac_address>"
	exit 0
fi

if [ "${iname}" != "" ]; then
   if_found=""
   while read aline
   do
       echo ${aline} | grep "iface ${iname} " > /dev/null
       if [ $? -eq 0 ]; then
	   if_found="yes"
           echo "iface ${iname} inet dhcp" >> ${tmp_conf}
           #if [ "${iname}" != "ath0" ]; then
           #    echo "allow-hotplug ${iname}" >> ${tmp_conf}
           #fi
           # skip the old config lines for this iname
           while read modline
           do
              echo ${modline} | grep 'auto' > /dev/null
              if [ $? -eq 0 ]; then
                  echo "" >> ${tmp_conf}
                  echo ${modline} >> ${tmp_conf}
                  break
              fi
           done
       else
           echo ${aline} >> ${tmp_conf}
       fi
   done < ${networkConfig}
   if [ "${if_found}" != "yes" ]; then
       echo "" >> ${tmp_conf}
       echo "auto ${iname}" >> ${tmp_conf}
       echo "iface ${iname} inet dhcp" >> ${tmp_conf}
       #echo "allow-hotplug ${iname}" >> ${tmp_conf}
   fi

# do NOT change the interface file while the network is up
# ifdown relies on the values to shut down the gateway and
# to know whether to stop the dhcp client.
    
   	if [ "$NorestartService" == "0" ]; then
   		matchssid=`grep -rsni "${gw_mac}" /etc/nas/config/wifinetwork-remembered.conf | grep -v 'signal_strength="0"'`
		if [ "${matchssid}" != "" ]; then
			lineNum=`echo "$matchssid" | cut -d ':' -f 1`
			matchssid=`grep -rsi "${gw_mac}" /etc/nas/config/wifinetwork-remembered.conf | grep -v 'signal_strength="0"'`
			cli2Ssid=`echo ${matchssid} | awk 'BEGIN{FS=" mac=" }{print $1}' | cut -d '=' -f 2`
			cli2key=`echo ${matchssid} | awk 'BEGIN{FS="security_key=" } {print $NF}' | cut -d '"' -f 2`
			cli2mac=`echo ${matchssid} | awk 'BEGIN{FS="mac=" } {print $NF}' | cut -d '"' -f 2`
   			cli2join=`echo ${matchssid} | awk 'BEGIN{FS="auto_join=" } {print $NF}' | cut -d '"' -f 2`
   			cli2trust=`echo ${matchssid} | awk 'BEGIN{FS="trusted=" } {print $NF}' | cut -d '"' -f 2`
   			cli2encryptype=`echo ${matchssid} | awk 'BEGIN{FS="security_mode=" } {print $NF}' | cut -d '"' -f 2 | awk -F/ '{print $1}'`
   			cli2cipher=`echo ${matchssid} | awk 'BEGIN{FS="security_mode=" } {print $NF}' | cut -d '"' -f 2 | awk -F/ '{print $2}' | awk '{print $1}'`
   			cli2bssid=`echo ${matchssid} | awk 'BEGIN{FS="bssi\/dmap=" } {print $NF}' | cut -d ' ' -f 1`
   			cli2key=`echo ${matchssid} | awk 'BEGIN{FS="security_key=" } {print $NF}' | cut -d '"' -f 2` 
   			cli2Signal=`echo ${matchssid} | awk 'BEGIN{FS="signal_strength=" } {print $NF}' | cut -d ' ' -f 1`
			clisecured=`echo ${matchssid} | awk 'BEGIN{FS="secured=" } {print $NF}' | cut -d ' ' -f 1`
		
			if [ "$cli2encryptype" == "NONE" ]; then
				hiddenProfile="ssid=${cli2Ssid} mac=\""${cli2mac}"\" signal_strength=${cli2Signal} auto_join=\""$cli2join"\" trusted=\""$cli2trust"\" security_mode=\""${cli2encryptype}"\" connected=\""true"\" remembered=\""true"\" secured=${clisecured} \
				dhcp_enabled=\"true\" ip=\"\" netmask=\"\" gateway=\"\" dns0=\"\" dns1=\"\" dns2=\"\" bssi/dmap=$cli2bssid security_key=\"${cli2key}\""
			elif [ "$cli2encryptype" == "WEP" ]; then
				hiddenProfile="ssid=${cli2Ssid} mac=\""${cli2mac}"\" signal_strength=${cli2Signal} auto_join=\""$cli2join"\" trusted=\""$cli2trust"\" security_mode=\""${cli2encryptype}"\" connected=\""true"\" remembered=\""true"\" secured=${clisecured} \
				dhcp_enabled=\"true\" ip=\"\" netmask=\"\" gateway=\"\" dns0=\"\" dns1=\"\" dns2=\"\" bssi/dmap=$cli2bssid security_key=\"${cli2key}\""
			else
				hiddenProfile="ssid=${cli2Ssid} mac=\""${cli2mac}"\" signal_strength=${cli2Signal} auto_join=\""$cli2join"\" trusted=\""$cli2trust"\" security_mode=\""${cli2encryptype}/${cli2cipher}"\" connected=\""true"\" remembered=\""true"\" secured=${clisecured} \
				dhcp_enabled=\"true\" ip=\"\" netmask=\"\" gateway=\"\" dns0=\"\" dns1=\"\" dns2=\"\" bssi/dmap=$cli2bssid security_key=\"${cli2key}\""
			fi	
		
			checkloop=1
			if [ -f "/tmp/wifinetwork-remembered_tmp.conf" ]; then
				rm /tmp/wifinetwork-remembered_tmp.conf
			fi
			
			cat /etc/nas/config/wifinetwork-remembered.conf | while read RemProfile
			do
				if [ "$checkloop" == "$lineNum" ]; then
					echo $hiddenProfile >> /tmp/wifinetwork-remembered_tmp.conf
				else
					echo $RemProfile >> /tmp/wifinetwork-remembered_tmp.conf
				fi
		 		checkloop=`expr $checkloop + 1`
			done
			cat /tmp/wifinetwork-remembered_tmp.conf > /etc/nas/config/wifinetwork-remembered.conf
			cat /tmp/wifinetwork-remembered_tmp.conf > /tmp/wifinetwork-remembered.conf
		fi
	fi
     
   	sed -i 's/STA_NETWORK_TYPE=.*/STA_NETWORK_TYPE='dhcp'/' /etc/nas/config/wifinetwork-param.conf
   	mv ${tmp_conf}  ${networkConfig}
   	#mv ${tmp_conf}  /etc/.multif	
   if [ "$NorestartService" == "0" ]; then
   		echo 0 > /tmp/ApCliRetry   
   		/etc/init.d/S45ifplugd restart
   		/sbin/ifup ${iname}
   	fi
fi

