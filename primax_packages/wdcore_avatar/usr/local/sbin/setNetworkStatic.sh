#!/bin/bash
#
# � 2010 Western Digital Technologies, Inc. All rights reserved.
#
# setNetworkStatic.sh
#
#

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
. /etc/nas/config/share-param.conf
. /etc/nas/config/networking-general.conf 2>/dev/null
. /etc/nas/config/wifinetwork-param.conf 2>/dev/null

tmp_conf=/etc/.tmp_netconf
dnsConfig=/etc/resolv.conf
NorestartService=0

echo $1 $2 $3 $4 $5 $6 $7 > /tmp/SetNetworkStatic

if [ $# -lt 2 ]; then
	echo "usage: setNetworkStatic.sh ifname=<iname> <ip> <netmask> <gateway> <dns0> <dns1> <dns2>"
	echo "       Note, <gateway> <dns0> <dns1> <dns2> are optional"
	exit 1
fi

##########################################################
# dot_to_hex()
# Input : $1 = dot-decimal ip address 
# Output: hex string 
##########################################################

function dot_to_hex {
   for i in $(echo $1 | sed -e "s/\./ /g"); do  
      	printf '%02x' $i
   done
}

function trans_to_hex {
	for i in $(echo $1 | sed -e "s/\./ /g"); do  
      	printf '%02x' $i >/dev/null 2>/dev/null < /dev/null
    done
}

RestartService(){
	sleep 40
	#/etc/init.d/S50lighttpd restart
	#/etc/init.d/S80dhcp-server restart
	/etc/init.d/S92twonkyserver restart
	/etc/init.d/S91upnp restart
	#/etc/init.d/S50avahi-daemon restart
}

##########################################################
# get_network_num()
# Input : $1 = dot-decimal ip address 
#         $2 = dot-decimal mask
# Output: Network number in decimal 
##########################################################

function get_network_num() {
   iphex=`dot_to_hex $1`
   maskhex=`dot_to_hex $2` 
   network=$(($((0X$iphex)) & $((0X$maskhex))))
   echo ${network}
}

while [ "$1" != "" ]; do
	iface=`echo ${1} | grep "ifname="`
	gw_mac=`echo ${1} | grep "gateway_mac_address="`
	if [ "${iface}" == "" ] && [ "${gw_mac}" == "" ]; then
		trans_to_hex $1
		if [ "$?" != 0 ]; then	
      		exit 1
   		else
   			if [ "$clientIP" == "" ]; then
   				clientIP="$1"
   			elif [ "$clientmask" == "" ]; then
   				clientmask="$1"
   		 	elif [ "$clientgw" == "" ]; then
   		 		clientgw="$1"
   		 	elif [ "$clientdns0" == "" ]; then
   		 		clientdns0="$1"
   		 	elif [ "$clientdns1" == "" ]; then
   		 		clientdns1="$1"
   		 	elif [ "$clientdns2" == "" ]; then
   		 		clientdns2="$1"
   		 	elif [ "$gw_mac" == "" ]; then
   		 		gw_mac="$1"
   			fi
   		fi
	elif [ "${iface}" != "" ]; then
		iname=`echo ${1} | grep "ifname=" | cut -d'=' -f2`
	elif [ "${gw_mac}" != "" ]; then
		gw_mac=`echo ${1} | grep "gateway_mac_address=" | cut -d'=' -f2`
	fi
	shift
done

if [ "${iname}" == "" ]; then
	iname="wlan0"
fi
if [ "${iname}" == "wlan0-connect" ]; then
   	NorestartService=1
   	iname=wlan0
fi
if [ "${iname}" != "wlan0" ] && [ "${iname}" != "wlan1" ]; then
      exit 2 
fi

if [ "${iname}" == "wlan0" ]; then
   	network=`get_network_num "${clientIP}" "${clientmask}"`
   	othernetwork=`get_network_num ${AP_IP} ${AP_MASK}`
   	if [ ${network} -eq ${othernetwork} ]; then  	 
         exit 3
    fi 
else
	network=`get_network_num "${clientIP}" "${clientmask}"`
   	othernetwork=`get_network_num ${STA_IP} ${STA_MASK}`
   	if [ ${network} -eq ${othernetwork} ]; then  	 
         exit 3
    fi
fi

connection_mac=`wpa_cli -i wlan0 status | grep -rsw "bssid" | awk -F= '{print $NF}' | tr [:lower:] [:upper:]`
       							
if [ "${iname}" != "" ]; then
   if_found=""
   while read aline
   do
       echo ${aline} | grep "iface ${iname} " > /dev/null
       if [ $? -eq 0 ]; then
           if_found="yes"
           echo "iface ${iname} inet static" >> ${tmp_conf}
           if [ "${iname}" == "wlan0" ]; then
           	sed -i 's/STA_IP=.*/STA_IP='${clientIP}'/' /etc/nas/config/wifinetwork-param.conf
           	echo "  address ${clientIP}" >> ${tmp_conf}
           	Bcast=`echo ${clientIP} | awk -F. '{print $1"."$2"."$3}'`
           	BcastIp=$Bcast".255"
           	echo "  broadcast ${BcastIp}" >> ${tmp_conf}
           #else
           #	sed -i 's/AP_IP=.*/AP_IP='${1}'/' /etc/nas/config/wifinetwork-param.conf
           fi
           if [ "${iname}" == "wlan0" ]; then
                #if [ "${2}" != "255.255.255.0" ]; then                                                              
                #        exit 1                                                                                     
                #fi 
			sed -i 's/STA_MASK=.*/STA_MASK='${clientmask}'/' /etc/nas/config/wifinetwork-param.conf
           	echo "  netmask ${clientmask}" >> ${tmp_conf}
           #else
           #	sed -i 's/AP_MASK=.*/AP_MASK='${2}'/' /etc/nas/config/wifinetwork-param.conf
           fi
	   if [ "$clientgw" != "" ]; then
           	if [ "${iname}" == "wlan0" ]; then
           		sed -i 's/STA_DEFAULT_GW=.*/STA_DEFAULT_GW='${clientgw}'/' /etc/nas/config/wifinetwork-param.conf
           		echo "  gateway ${clientgw}" >> ${tmp_conf}
           	fi
	   fi
	   if [ "$clientdns0" != "" ]; then
           	if [ "${iname}" == "wlan0" ]; then
           		echo adding dns ${clientdns0}
           		echo "nameserver ${clientdns0}" > ${dnsConfig}
           		sed -i 's/STA_DNS0=.*/STA_DNS0='${clientdns0}'/' /etc/nas/config/wifinetwork-param.conf
           	fi
	   fi
	   if [ "$clientdns1" != "" ]; then
           	if [ "${iname}" == "wlan0" ]; then
           		echo adding dns ${clientdns1}
           		echo "nameserver ${clientdns1}" >> ${dnsConfig}
          		sed -i 's/STA_DNS1=.*/STA_DNS1='${clientdns1}'/' /etc/nas/config/wifinetwork-param.conf
           	fi
	   fi
	   if [ "$clientdns2" != "" ]; then
           	if [ "${iname}" == "wlan0" ]; then
           		echo adding dns ${clientdns2}
           		echo "nameserver ${clientdns2}" >> ${dnsConfig}
           		sed -i 's/STA_DNS2=.*/STA_DNS2='${clientdns2}'/' /etc/nas/config/wifinetwork-param.conf
           	fi
 	   fi
   	  	
           #echo "iface ${iname} inet static" >> ${tmp_conf}
           #echo "  address ${2}" >> ${tmp_conf}
           #echo "  netmask ${3}" >> ${tmp_conf}
           #if [ "$4" != "" ]; then
           #    echo "  gateway ${4}" >> ${tmp_conf}
           #fi
           #if [ "${iname}" != "ath0" ]; then
           #    echo "allow-hotplug ${iname}" >> ${tmp_conf}
           #fi 
           # TODO: DNS for multiple intefaces
           #if [ "$4" != "" ]; then
           #    echo "nameserver ${4}" > ${dnsConfig}
           #fi
           #if [ "$5" != "" ]; then
           #    echo "nameserver ${5}" >> ${dnsConfig}
           #fi
           #if [ "$6" != "" ]; then
           #    echo "nameserver ${6}" >> ${dnsConfig}
           #fi
           # skip the old config lines for this iname
           while read modline
           do
              echo ${modline} | grep 'auto' > /dev/null
              if [ $? -eq 0 ]; then
                  echo "" > ${tmp_conf}
                  echo "${modline}" >> ${tmp_conf}
                  break
              fi
	
           done
       else
           echo "${aline}" >> ${tmp_conf}
       fi

   done < ${networkConfig}

   if [ "${if_found}" != "yes" ]; then
      echo "iface ${iname} inet static" >> ${tmp_conf}
      if [ "${iname}" == "wlan0" ]; then
      	sed -i 's/STA_IP=.*/STA_IP='${clientIP}'/' /etc/nas/config/wifinetwork-param.conf
      	echo "  address ${clientIP}" >> ${tmp_conf}
      #else
      #	sed -i 's/AP_IP=.*/AP_IP='${1}'/' /etc/nas/config/wifinetwork-param.conf
      fi
      if [ "${iname}" == "wlan0" ]; then
        #if [ "${2}" != "255.255.255.0" ]; then                                                            
        #	exit 1                                                                                    
        #fi 
      	sed -i 's/STA_MASK=.*/STA_MASK='${clientmask}'/' /etc/nas/config/wifinetwork-param.conf
      	echo "  netmask ${clientmask}" >> ${tmp_conf}
      #else
      #	sed -i 's/AP_MASK=.*/AP_MASK='${2}'/' /etc/nas/config/wifinetwork-param.conf
      fi
      if [ "$clientgw" != "" ]; then
      	if [ "${iname}" == "wlan0" ]; then
      		sed -i 's/STA_DEFAULT_GW=.*/STA_DEFAULT_GW='${clientgw}'/' /etc/nas/config/wifinetwork-param.conf
      		echo "  gateway ${clientgw}" >> ${tmp_conf}
      	fi
      fi
      if [ "$clientdns0" != "" ]; then
      	if [ "${iname}" == "wlan0" ]; then
      		echo "nameserver ${clientdns0}" > ${dnsConfig}
      		sed -i 's/STA_DNS0=.*/STA_DNS0='${clientdns0}'/' /etc/nas/config/wifinetwork-param.conf
      	fi
      fi
      if [ "$clientdns1" != "" ]; then
      	if [ "${iname}" == "wlan0" ]; then
      		echo "nameserver ${clientdns1}" >> ${dnsConfig}
      		sed -i 's/STA_DNS1=.*/STA_DNS1='${clientdns1}'/' /etc/nas/config/wifinetwork-param.conf
      	fi
      fi
      if [ "$clientdns2" != "" ]; then
      	if [ "${iname}" == "wlan0" ]; then
      		echo "nameserver ${clientdns2}" >> ${dnsConfig}
      		sed -i 's/STA_DNS2=.*/STA_DNS2='${clientdns2}'/' /etc/nas/config/wifinetwork-param.conf
      	fi
      fi
         
      #echo "" >> ${tmp_conf}
      #echo "auto ${iname}" >> ${tmp_conf}
      #echo "iface ${iname} inet static" >> ${tmp_conf}
      #echo "  address ${2}" >> ${tmp_conf}
      #echo "  netmask ${3}" >> ${tmp_conf}
      #if [ "$4" != "" ]; then
      #    echo "  gateway ${4}" >> ${tmp_conf}
      #fi
      #if [ "${iname}" != "ath0" ]; then
      #    echo "allow-hotplug ${iname}" >> ${tmp_conf}
      #fi 
      ## TODO: DNS for multiple intefaces
      #if [ "$5" != "" ]; then
      #    echo "nameserver ${5}" > ${dnsConfig}
      #fi
      #if [ "$6" != "" ]; then
      #    echo "nameserver ${6}" >> ${dnsConfig}
      #fi
      #if [ "$7" != "" ]; then
      #    echo "nameserver ${7}" >> ${dnsConfig}
      #fi
   fi
   
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
				dhcp_enabled=\"false\" ip=\""$clientIP"\" netmask=\""$clientmask"\" gateway=\""$clientgw"\" dns0=\""$clientdns0"\" dns1=\""$clientdns1"\" dns2=\""$clientdns2"\" bssi/dmap=$cli2bssid security_key=\"${cli2key}\""
			elif [ "$cli2encryptype" == "WEP" ]; then
				hiddenProfile="ssid=${cli2Ssid} mac=\""${cli2mac}"\" signal_strength=${cli2Signal} auto_join=\""$cli2join"\" trusted=\""$cli2trust"\" security_mode=\""${cli2encryptype}"\" connected=\""true"\" remembered=\""true"\" secured=${clisecured} \
				dhcp_enabled=\"false\" ip=\""$clientIP"\" netmask=\""$clientmask"\" gateway=\""$clientgw"\" dns0=\""$clientdns0"\" dns1=\""$clientdns1"\" dns2=\""$clientdns2"\" bssi/dmap=$cli2bssid security_key=\"${cli2key}\""
			else
				hiddenProfile="ssid=${cli2Ssid} mac=\""${cli2mac}"\" signal_strength=${cli2Signal} auto_join=\""$cli2join"\" trusted=\""$cli2trust"\" security_mode=\""${cli2encryptype}/${cli2cipher}"\" connected=\""true"\" remembered=\""true"\" secured=${clisecured} \
				dhcp_enabled=\"false\" ip=\""$clientIP"\" netmask=\""$clientmask"\" gateway=\""$clientgw"\" dns0=\""$clientdns0"\" dns1=\""$clientdns1"\" dns2=\""$clientdns2"\" bssi/dmap=$cli2bssid security_key=\"${cli2key}\""
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
# do NOT change the interface file while the network is up
# ifdown relies on the values to shut down the gateway and
# to know whether to stop the dhcp client.
	if [ "${iname}" == "wlan0" ]; then
		sed -i 's/STA_NETWORK_TYPE=.*/STA_NETWORK_TYPE='static'/' /etc/nas/config/wifinetwork-param.conf
		mv ${tmp_conf}  ${networkConfig}
		
		if [ "$NorestartService" == "0" ]; then     
			echo 0 > /tmp/ApCliRetry   
   			/sbin/ifdown ${iname}
   			ifconfig wlan0 down
   			#mv ${tmp_conf}  /etc/.multif
   			/etc/init.d/S45ifplugd restart
   			/sbin/ifup ${iname}
   			#/etc/init.d/S90multi-role restart
   			RestartService > /dev/null 2>&1 &
   		fi
   		route del -net 0.0.0.0 netmask 0.0.0.0 dev ${iname} metric 1000
   		route add -net 169.254.0.0 netmask 255.255.0.0 dev ${iname}
   	fi
fi


