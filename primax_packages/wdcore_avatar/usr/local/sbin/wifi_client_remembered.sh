#!/bin/sh
#
# (c) 2013 Western Digital Technologies, Inc. All rights reserved.
#
# getTemperatureStatus.sh
#
#
PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

source /etc/nas/config/wifinetwork-param.conf
SaveLimit=20
ifAction=$1
ifdelay=$2

CheckSaveProfileNum(){
	#only restore 20 profile
	SaveNum=`cat /etc/nas/config/wifinetwork-remembered.conf | wc -l`
	if [ "${SaveNum}" -gt "${SaveLimit}" ]; then
		echo "Delete SaveNum" $SaveNum >> /tmp/ifplugdaction
		sed -i '21,$d' /etc/nas/config/wifinetwork-remembered.conf
	fi
}

if [ ! -f "/tmp/wifi_client_remembered_execute" ]; then
	echo "go remembered" > /tmp/wifi_client_remembered_execute
	#sleep 15 
	if [ "$ifdelay" == "" ]; then
		sleep 15 
	else
		sleep "${ifdelay}"
	fi
	/sbin/ifup wlan0
	connectedmac=`wpa_cli -i wlan0 status | grep -rsw "bssid" | awk -F= '{print $NF}' | tr [:lower:] [:upper:]`
	#echo "connectedmac" $connectedmac >> /tmp/ifplugdaction
	connectStatus=`wpa_cli -i wlan0 status | grep -rsi wpa_state | awk -F= '{print $NF}'`
	#connectedip=`wpa_cli -i wlan0 status | grep -rsw "ip_address" | awk -F= '{print $NF}'`
	echo "connectStatus" $connectStatus >> /tmp/ifplugdaction
	#echo "connectedip" $connectedip >> /tmp/ifplugdaction
	#if [ "$connectStatus" == "COMPLETED" ] && [ "$connectedip" != "" ]; then
	connectedCipher=`wpa_cli -i wlan0 status | grep -rsw "pairwise_cipher" | awk -F= '{print $NF}'`
	sleep 1
	networkConfig=`/usr/local/sbin/getNetworkConfig.sh`
	if [ "$connectedCipher" == "WEP-40" ] || [ "$connectedCipher" == "WEP-104" ]; then
		if [ "$networkConfig" == "disconnected" ]; then
			rm /tmp/wifi_client_remembered_execute
			exit 0
		fi
	fi
	if [ "$connectStatus" == "COMPLETED" ] && [ "$connectedmac" != "" ]; then
		ConnectProfile=`head -n 1 /tmp/wifinetwork-remembered.conf`	
		cli2Ssid=`echo ${ConnectProfile} | awk 'BEGIN{FS=" mac=" }{print $1}' | cut -d '=' -f 2`
		cli2key=`echo ${ConnectProfile} | awk 'BEGIN{FS="security_key=" } {print $NF}' | cut -d '"' -f 2`
		cli2mac=`echo ${ConnectProfile} | awk 'BEGIN{FS="mac=" } {print $NF}' | cut -d '"' -f 2`
   		cli2join=`echo ${ConnectProfile} | awk 'BEGIN{FS="auto_join=" } {print $NF}' | cut -d '"' -f 2`
   		cli2trust=`echo ${ConnectProfile} | awk 'BEGIN{FS="trusted=" } {print $NF}' | cut -d '"' -f 2`
   		cli2encryptype=`echo ${ConnectProfile} | awk 'BEGIN{FS="security_mode=" } {print $NF}' | cut -d '"' -f 2 | awk -F/ '{print $1}'`
   		cli2cipher=`echo ${ConnectProfile} | awk 'BEGIN{FS="security_mode=" } {print $NF}' | cut -d '"' -f 2 | awk -F/ '{print $2}' | awk '{print $1}'`
   		cli2bssid=`echo ${ConnectProfile} | awk 'BEGIN{FS="bssi\/dmap=" } {print $NF}' | cut -d ' ' -f 1`
   		cli2key=`echo ${ConnectProfile} | awk 'BEGIN{FS="security_key=" } {print $NF}' | cut -d '"' -f 2` 
   		cli2Signal=`echo ${ConnectProfile} | awk 'BEGIN{FS="signal_strength=" } {print $NF}' | cut -d ' ' -f 1`
		clisecured=`echo ${ConnectProfile} | awk 'BEGIN{FS="secured=" } {print $NF}' | cut -d ' ' -f 1`
		cliDhcp=`echo ${ConnectProfile} | awk 'BEGIN{FS="dhcp_enabled=" } {print $NF}' | cut -d '"' -f 2`
		cliclone=`echo ${ConnectProfile} | awk 'BEGIN{FS="mac_clone_enable=" } {print $NF}' | cut -d '"' -f 2`
		clicloneaddr=`echo ${ConnectProfile} | awk 'BEGIN{FS="cloned_mac_address=" } {print $NF}' | cut -d '"' -f 2`
		
		if [ "$cli2Ssid" == "" ] && [ "$cli2mac" == "" ] && [ "$cli2encryptype" == "" ]; then
			rm /tmp/wifi_client_remembered_execute
			exit 0
		elif [ "$cli2Ssid" == "" ]; then
			cli2Ssid=`wpa_cli -i wlan0 status | grep -rsw "ssid" | awk -F= '{print $NF}'`
		fi
		if [ "$cliDhcp" == "false" ]; then
			cliip=`echo ${ConnectProfile} | awk 'BEGIN{FS="ip=" } {print $NF}' | cut -d '"' -f 2`
			climask=`echo ${ConnectProfile}  | awk 'BEGIN{FS="netmask=" } {print $NF}' | cut -d '"' -f 2`
			cligw=`echo ${ConnectProfile} | awk 'BEGIN{FS="gateway=" } {print $NF}' | cut -d '"' -f 2`
			clidns0=`echo ${ConnectProfile} | awk 'BEGIN{FS="dns0=" } {print $NF}' | cut -d '"' -f 2`
			clidns1=`echo ${ConnectProfile} | awk 'BEGIN{FS="dns1=" } {print $NF}' | cut -d '"' -f 2`
			clidns2=`echo ${ConnectProfile} | awk 'BEGIN{FS="dns2=" } {print $NF}' | cut -d '"' -f 2`
		else			
			echo $networkConfig | while read dhcpConfig
			do 
				echo $dhcpConfig > /tmp/netconf
			done
			dhcpConfig=`cat /tmp/netconf`
				dhcpip=`echo "$dhcpConfig" | awk '{print $2}'`
				if [ "$dhcpip" == "address" ]; then
					cliip=`echo "$dhcpConfig" | awk '{print $3}'`
					echo " cliip" "$cliip" >> /tmp/ifplugdaction
				fi
				dhcpmask=`echo "$dhcpConfig" | awk '{print $4}'`
				if [ "$dhcpmask" == "netmask" ]; then
					climask=`echo "$dhcpConfig" | awk '{print $5}'`
					echo " climask" "$climask" >> /tmp/ifplugdaction
				fi
				dhcpgw=`echo "$dhcpConfig" | awk '{print $6}'`
				if [ "$dhcpgw" == "gateway" ]; then
					cligw=`echo "$dhcpConfig" | awk '{print $7}'`
					echo " cligw" "$cligw" >> /tmp/ifplugdaction
				fi
				dhcpdns0=`echo "$dhcpConfig" | awk '{print $8}'`
				if [ "$dhcpdns0" == "nameserver" ]; then
					clidns0=`echo "$dhcpConfig" | awk '{print $9}'`
					echo " clidns0" "$clidns0" >> /tmp/ifplugdaction
				fi
	
				dhcpdns1=`echo "$dhcpConfig" | awk '{print $10}'`
				if [ "$dhcpdns1" == "nameserver" ]; then
					clidns1=`echo "$dhcpConfig" | awk '{print $11}'`
					echo " clidns1" "$clidns1" >> /tmp/ifplugdaction
				fi
				dhcpdns2=`echo "$dhcpConfig" | awk '{print $12}'`
				if [ "$dhcpdns2" == "nameserver" ]; then
					clidns2=`echo "$dhcpConfig" | awk '{print $13}'`
					echo " clidns2" "$clidns2" >> /tmp/ifplugdaction
				fi
			rm /tmp/netconf
		fi
		connectedSsid=`wpa_cli -i wlan0 status | grep -rsw "ssid" | awk -F= '{print $NF}'`
		if [ ${STA_CONF_HIDDEN} == "1" ]; then
			sed -i 's/STA_CONF_HIDDEN=.*/STA_CONF_HIDDEN=0/' /etc/nas/config/wifinetwork-param.conf		
			if [ "$cli2key" == "MyPassportWirelessPBCSecurityKeyTEMPoRarily" ]; then
				echo "WPS PBC" >> /tmp/ifplugdaction
				scantmp=`grep -rsi "\"${connectedmac}\"" /tmp/scan_result`
				if [ -f "/tmp/WPSpinKEY" ]; then
					wpapsk=`cat /tmp/WPSpinKEY` 
					#echo "${wpapsk}" | grep -q '\"\|\$\|\&\|/\||\|\\'
					#if [ $? == 0 ]; then
					#	echo $wpapsk > /tmp/clientpwd
					#	sed -i 's/\\/\\\\/g' /tmp/clientpwd
					#	sed -i 's/"/\\"/g' /tmp/clientpwd
					#	sed -i 's/\$/\\$/g' /tmp/clientpwd
					#	sed -i 's/&/\\&/g' /tmp/clientpwd
					#	sed -i 's/\//\\\//g' /tmp/clientpwd
					#	sed -i 's/|/\\|/g' /tmp/clientpwd
					#	wpapsk=`cat /tmp/clientpwd`
						len=${#wpapsk}
						clen=`expr $len - 2`
						wpapsk=`expr substr $wpapsk 2 $clen`
						rm /tmp/clientpwd
					#fi
					rm /tmp/WPSpinKEY	
				fi
				echo " WPS PIN PSK" "$wpapsk" >> /tmp/ifplugdaction
				if [ "$scantmp" != "" ]; then
					echo $scantmp > /tmp/wifinetwork-remembered.conf
					sed -i '/'"${connectedmac}"'/ s/security_key=.*/security_key='\"${wpapsk}\"' /' /tmp/wifinetwork-remembered.conf
				else 	
					key_mgmt=`wpa_cli -i wlan0 status | grep -rsw "key_mgmt" | awk -F= '{print $NF}'`
					if [ "$key_mgmt" == "WPA-PSK" ]; then
						key_mgmt="WPAPSK"
					else 
						key_mgmt="WPA2PSK"
					fi
				
					hiddenProfile="ssid=\""${connectedSsid}"\" mac=\""$connectedmac"\" signal_strength=\""80"\" auto_join=\""true"\" trusted=\""false"\" security_mode=\""${key_mgmt}/AES"\" connected=\""false"\" remembered=\""true"\" secured=\"true\" bssi/dmap=0 security_key=\"${wpapsk}\""
					cli2encryptype=${key_mgmt}
					cli2cipher="AES"
					
					echo $hiddenProfile > /tmp/wifinetwork-remembered.conf	
				fi
				cli2key="${wpapsk}"
				
				confSsid="${connectedSsid}"
				echo "${confSsid}" | grep -q '\"\|\$\|\&\|/\||\|\\'
				if [ $? == 0 ]; then
					echo "$confSsid" > /tmp/clientssid
					sed -i 's/\\/\\\\/g' /tmp/clientssid
					sed -i 's/"/\\"/g' /tmp/clientssid
					sed -i 's/\$/\\$/g' /tmp/clientssid
					sed -i 's/&/\\&/g' /tmp/clientssid
					sed -i 's/\//\\\//g' /tmp/clientssid
					sed -i 's/|/\\|/g' /tmp/clientssid
					confSsid=`cat /tmp/clientssid`
					rm /tmp/clientssid
				fi
				
				sed -i 's/STA_SSID_NAME=.*/STA_SSID_NAME='\""${confSsid}"\"'/' /etc/nas/config/wifinetwork-param.conf
				sed -i '/STA_SSID_NAME/ s/\\/\\\\/g' /etc/nas/config/wifinetwork-param.conf
				sed -i '/STA_SSID_NAME/ s/|/\\|/g' /etc/nas/config/wifinetwork-param.conf
				sed -i '/STA_SSID_NAME/ s/"/\\"/g' /etc/nas/config/wifinetwork-param.conf
				sed -i '/STA_SSID_NAME/ s/\$/\\\$/g' /etc/nas/config/wifinetwork-param.conf
				sed -i '/STA_SSID_NAME/ s/`/\\`/g' /etc/nas/config/wifinetwork-param.conf
				sed -i '/STA_SSID_NAME/ s/\\"/"/' /etc/nas/config/wifinetwork-param.conf
				sed -i '/STA_SSID_NAME/ s/\(.*\)\\"/\1"/' /etc/nas/config/wifinetwork-param.conf		
				
				confpsk="${wpapsk}"
				echo "${confpsk}" | grep -q '\"\|\$\|\&\|/\||\|\\'
					if [ $? == 0 ]; then
						echo $confpsk > /tmp/clientpwd
						sed -i 's/\\/\\\\/g' /tmp/clientpwd
						sed -i 's/"/\\"/g' /tmp/clientpwd
						sed -i 's/\$/\\$/g' /tmp/clientpwd
						sed -i 's/&/\\&/g' /tmp/clientpwd
						sed -i 's/\//\\\//g' /tmp/clientpwd
						sed -i 's/|/\\|/g' /tmp/clientpwd
						confpsk=`cat /tmp/clientpwd`
						rm /tmp/clientpwd
				fi
				sed -i 's/STA_PSK_KEY=.*/STA_PSK_KEY='\"${confpsk}\"'/' /etc/nas/config/wifinetwork-param.conf
				sed -i '/STA_PSK_KEY/ s/\\/\\\\/g' /etc/nas/config/wifinetwork-param.conf
				sed -i '/STA_PSK_KEY/ s/|/\\|/g' /etc/nas/config/wifinetwork-param.conf
				sed -i '/STA_PSK_KEY/ s/"/\\"/g' /etc/nas/config/wifinetwork-param.conf
				sed -i '/STA_PSK_KEY/ s/\$/\\$/g' /etc/nas/config/wifinetwork-param.conf
				sed -i '/STA_PSK_KEY/ s/\\"/"/' /etc/nas/config/wifinetwork-param.conf
				sed -i '/STA_PSK_KEY/ s/`/\\`/g' /etc/nas/config/wifinetwork-param.conf
				sed -i '/STA_PSK_KEY/ s/\(.*\)\\"/\1"/' /etc/nas/config/wifinetwork-param.conf
				STA_SSID_NAME="$connectedSsid"
				echo "22;0;"  > /tmp/MCU_Cmd
			fi
		
			echo "connectedSsid" "$connectedSsid" >> /tmp/ifplugdaction
			confSsid="${STA_SSID_NAME}"
				echo "${confSsid}" | grep -q '\"\|\$\|\&\|/\||\|\\'
				if [ $? == 0 ]; then
					echo "$confSsid" > /tmp/clientssid
					sed -i 's/\\/\\\\/g' /tmp/clientssid
					sed -i 's/"/\\"/g' /tmp/clientssid
					sed -i 's/\$/\\$/g' /tmp/clientssid
					sed -i 's/&/\\&/g' /tmp/clientssid
					sed -i 's/\//\\\//g' /tmp/clientssid
					sed -i 's/|/\\|/g' /tmp/clientssid
					confSsid=`cat /tmp/clientssid`
					rm /tmp/clientssid
				fi
			echo "STA_SSID_NAME" "$STA_SSID_NAME" >> /tmp/ifplugdaction
			if [ "$STA_SSID_NAME" == "$connectedSsid" ]; then				
				if [ "$cli2encryptype" == "NONE" ]; then
					hiddenProfile="ssid=\""${connectedSsid}"\" mac=\""${connectedmac}"\" signal_strength=${cli2Signal} auto_join=\""$cli2join"\" trusted=\""$cli2trust"\" security_mode=\""${cli2encryptype}"\" connected=\""true"\" remembered=\""true"\" secured=${clisecured} \
					dhcp_enabled=\""$cliDhcp"\" ip=\""$cliip"\" netmask=\""$climask"\" gateway=\""$cligw"\" dns0=\""$clidns0"\" dns1=\""$clidns1"\" dns2=\""$clidns2"\" mac_clone_enable=\""$cliclone"\" cloned_mac_address=\""$clicloneaddr"\" bssi/dmap=0 security_key=\"${cli2key}\""
				elif [ "$cli2encryptype" == "WEP" ]; then
					hiddenProfile="ssid=\""${connectedSsid}"\" mac=\""${connectedmac}"\" signal_strength=${cli2Signal} auto_join=\""$cli2join"\" trusted=\""$cli2trust"\" security_mode=\""${cli2encryptype}"\" connected=\""true"\" remembered=\""true"\" secured=${clisecured} \
					dhcp_enabled=\""$cliDhcp"\" ip=\""$cliip"\" netmask=\""$climask"\" gateway=\""$cligw"\" dns0=\""$clidns0"\" dns1=\""$clidns1"\" dns2=\""$clidns2"\" mac_clone_enable=\""$cliclone"\" cloned_mac_address=\""$clicloneaddr"\" bssi/dmap=0 security_key=\"${cli2key}\""
				else
					hiddenProfile="ssid=\""${connectedSsid}"\" mac=\""${connectedmac}"\" signal_strength=${cli2Signal} auto_join=\""$cli2join"\" trusted=\""$cli2trust"\" security_mode=\""${cli2encryptype}/${cli2cipher}"\" connected=\""true"\" remembered=\""true"\" secured=${clisecured} \
					dhcp_enabled=\""$cliDhcp"\" ip=\""$cliip"\" netmask=\""$climask"\" gateway=\""$cligw"\" dns0=\""$clidns0"\" dns1=\""$clidns1"\" dns2=\""$clidns2"\" mac_clone_enable=\""$cliclone"\" cloned_mac_address=\""$clicloneaddr"\" bssi/dmap=0 security_key=\"${cli2key}\""
				fi
		
				if [ "${STA_CONF_REMB}" == "1" ]; then
					sed -i 's/STA_CONF_REMB=.*/STA_CONF_REMB=0/' /etc/nas/config/wifinetwork-param.conf
					echo "STA_CONF_REMB" ${STA_CONF_REMB} >> /tmp/ifplugdaction
					matchssid=`grep -rsnw \""${connectedSsid}"\" /etc/nas/config/wifinetwork-remembered.conf`
					if [ "${matchssid}" != "" ]; then
						lineNum=`echo "$matchssid" | cut -d ':' -f 1`
						echo "lineNum" $lineNum >> /tmp/ifplugdaction
						sed ${lineNum}d /etc/nas/config/wifinetwork-remembered.conf > /tmp/wifinetwork-remembered_tmp.conf
						cat /tmp/wifinetwork-remembered_tmp.conf > /etc/nas/config/wifinetwork-remembered.conf
					fi
					cat /etc/nas/config/wifinetwork-remembered.conf > /tmp/wifinetwork-remembered_tmp.conf
					echo $hiddenProfile > /etc/nas/config/wifinetwork-remembered.conf
					sed -i 's/\\"/"/g' /etc/nas/config/wifinetwork-remembered.conf
					cat /tmp/wifinetwork-remembered_tmp.conf >> /etc/nas/config/wifinetwork-remembered.conf
					#sed -i 's/\\\\/\\/g' /etc/nas/config/wifinetwork-remembered.conf
				
					rm /tmp/wifinetwork-remembered_tmp.conf
					CheckSaveProfileNum
				else
					matchssid=`grep -rsnw \""${connectedSsid}"\" /etc/nas/config/wifinetwork-remembered.conf`
					if [ "${matchssid}" != "" ]; then
						lineNum=`echo "$matchssid" | cut -d ':' -f 1`
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
					fi
				fi
				
				echo $hiddenProfile > /tmp/wifinetwork-remembered.conf
				echo "hiddenProfile" $hiddenProfile >> /tmp/ifplugdaction
				sed -i 's/\\"/"/g' /tmp/wifinetwork-remembered.conf
			fi
		else
			#ConnectProfile=`head -n 1 /tmp/wifinetwork-remembered.conf`	
			#cli2mac=`echo ${ConnectProfile} | awk 'BEGIN{FS="mac=" } {print $NF}' | cut -d '"' -f 2`
			#cli2key=`echo ${ConnectProfile} | awk 'BEGIN{FS="security_key=" } {print $NF}' | cut -d '"' -f 2`
			
			#echo "cli2mac" $cli2mac >> /tmp/ifplugdaction
			echo "connectedmac" $connectedmac >> /tmp/ifplugdaction
			echo "connectedSsid" $connectedSsid >> /tmp/ifplugdaction
			if [ "$STA_MAC_ADDRESS" == "$connectedmac" ] || [ "\"$connectedSsid"\" == "$cli2Ssid" ]; then
				echo "Match SSID" $cli2Ssid >> /tmp/ifplugdaction
				if [ "$cli2key" == "MyPassportWirelessWPSSecurityKeyTEMPoRarily" ]; then
					echo "WPS PIN TMPE" >> /tmp/ifplugdaction
					if [ -f "/tmp/WPSpinKEY" ]; then
						wpapsk=`cat /tmp/WPSpinKEY` 
						#echo "${wpapsk}" | grep -q '\"\|\$\|\&\|/\||\|\\'
						#if [ $? == 0 ]; then
						#	echo $wpapsk > /tmp/clientpwd
						#	sed -i 's/\\/\\\\/g' /tmp/clientpwd
						#	sed -i 's/"/\\"/g' /tmp/clientpwd
						#	sed -i 's/\$/\\$/g' /tmp/clientpwd
						#	sed -i 's/&/\\&/g' /tmp/clientpwd
						#	sed -i 's/\//\\\//g' /tmp/clientpwd
						#	sed -i 's/|/\\|/g' /tmp/clientpwd
						#	wpapsk=`cat /tmp/clientpwd`
							len=${#wpapsk}
							clen=`expr $len - 2`
							wpapsk=`expr substr $wpapsk 2 $clen`
							#rm /tmp/clientpwd
						#fi
						echo "WPS PIN PSK" $wpapsk >> /tmp/ifplugdaction
						cli2key="${wpapsk}"
						rm /tmp/WPSpinKEY	
					fi
					sed -i 's/STA_PSK_KEY=.*/STA_PSK_KEY='\"${cli2key}\"'/' /etc/nas/config/wifinetwork-param.conf
					sed -i '/STA_PSK_KEY/ s/\\/\\\\/g' /etc/nas/config/wifinetwork-param.conf
					sed -i '/STA_PSK_KEY/ s/|/\\|/g' /etc/nas/config/wifinetwork-param.conf
					sed -i '/STA_PSK_KEY/ s/"/\\"/g' /etc/nas/config/wifinetwork-param.conf
					sed -i '/STA_PSK_KEY/ s/\$/\\$/g' /etc/nas/config/wifinetwork-param.conf
					sed -i '/STA_PSK_KEY/ s/\\"/"/' /etc/nas/config/wifinetwork-param.conf
					sed -i '/STA_PSK_KEY/ s/`/\\`/g' /etc/nas/config/wifinetwork-param.conf
					sed -i '/STA_PSK_KEY/ s/\(.*\)\\"/\1"/' /etc/nas/config/wifinetwork-param.conf
					echo "22;0;"  > /tmp/MCU_Cmd
				fi
								
				if [ "$cli2encryptype" == "NONE" ]; then
					hiddenProfile="ssid=\""${connectedSsid}"\" mac=\""${connectedmac}"\" signal_strength=${cli2Signal} auto_join=\""$cli2join"\" trusted=\""$cli2trust"\" security_mode=\""${cli2encryptype}"\" connected=\""true"\" remembered=\""true"\" secured=${clisecured} \
					dhcp_enabled=\""$cliDhcp"\" ip=\""$cliip"\" netmask=\""$climask"\" gateway=\""$cligw"\" dns0=\""$clidns0"\" dns1=\""$clidns1"\" dns2=\""$clidns2"\" mac_clone_enable=\""$cliclone"\" cloned_mac_address=\""$clicloneaddr"\" bssi/dmap=1 security_key=\"${cli2key}\""
				elif [ "$cli2encryptype" == "WEP" ]; then
					hiddenProfile="ssid=\""${connectedSsid}"\" mac=\""${connectedmac}"\" signal_strength=${cli2Signal} auto_join=\""$cli2join"\" trusted=\""$cli2trust"\" security_mode=\""${cli2encryptype}"\" connected=\""true"\" remembered=\""true"\" secured=${clisecured} \
					dhcp_enabled=\""$cliDhcp"\" ip=\""$cliip"\" netmask=\""$climask"\" gateway=\""$cligw"\" dns0=\""$clidns0"\" dns1=\""$clidns1"\" dns2=\""$clidns2"\" mac_clone_enable=\""$cliclone"\" cloned_mac_address=\""$clicloneaddr"\" bssi/dmap=1 security_key=\"${cli2key}\""
				else
					hiddenProfile="ssid=\""${connectedSsid}"\" mac=\""${connectedmac}"\" signal_strength=${cli2Signal} auto_join=\""$cli2join"\" trusted=\""$cli2trust"\" security_mode=\""${cli2encryptype}/${cli2cipher}"\" connected=\""true"\" remembered=\""true"\" secured=${clisecured} \
					dhcp_enabled=\""$cliDhcp"\" ip=\""$cliip"\" netmask=\""$climask"\" gateway=\""$cligw"\" dns0=\""$clidns0"\" dns1=\""$clidns1"\" dns2=\""$clidns2"\" mac_clone_enable=\""$cliclone"\" cloned_mac_address=\""$clicloneaddr"\" bssi/dmap=1 security_key=\"${cli2key}\""
				fi
				#echo "hiddenProfile" $hiddenProfile >> /tmp/ifplugdaction
				#sed '/'"${connectedSsid}"'/d' /etc/nas/config/wifinetwork-remembered.conf > /tmp/wifinetwork-remembered_tmp.conf				
				#cat /tmp/wifinetwork-remembered_tmp.conf > /etc/nas/config/wifinetwork-remembered.conf
				if [ "${STA_CONF_REMB}" == "1" ]; then
					sed -i 's/STA_CONF_REMB=.*/STA_CONF_REMB=0/' /etc/nas/config/wifinetwork-param.conf
					echo "STA_CONF_REMB" ${STA_CONF_REMB} >> /tmp/ifplugdaction
					matchssid=`grep -rsnw \""${connectedSsid}"\" /etc/nas/config/wifinetwork-remembered.conf`
					if [ "${matchssid}" != "" ]; then
						lineNum=`echo "$matchssid" | cut -d ':' -f 1`
						echo "lineNum" $lineNum >> /tmp/ifplugdaction
						sed ${lineNum}d /etc/nas/config/wifinetwork-remembered.conf > /tmp/wifinetwork-remembered_tmp.conf
						cat /tmp/wifinetwork-remembered_tmp.conf > /etc/nas/config/wifinetwork-remembered.conf
					fi
					cat /etc/nas/config/wifinetwork-remembered.conf > /tmp/wifinetwork-remembered_tmp.conf
					echo $hiddenProfile > /etc/nas/config/wifinetwork-remembered.conf
					sed -i 's/\\"/"/g' /etc/nas/config/wifinetwork-remembered.conf
					cat /tmp/wifinetwork-remembered_tmp.conf >> /etc/nas/config/wifinetwork-remembered.conf
					#sed -i 's/\\\\/\\/g' /etc/nas/config/wifinetwork-remembered.conf
				
					rm /tmp/wifinetwork-remembered_tmp.conf
					CheckSaveProfileNum
				else
					matchssid=`grep -rsnw \""${connectedSsid}"\" /etc/nas/config/wifinetwork-remembered.conf`
					if [ "${matchssid}" != "" ]; then
						lineNum=`echo "$matchssid" | cut -d ':' -f 1`
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
					fi
				fi
				
				echo $hiddenProfile > /tmp/wifinetwork-remembered.conf
				echo "hiddenProfile" $hiddenProfile >> /tmp/ifplugdaction
				sed -i 's/\\"/"/g' /tmp/wifinetwork-remembered.conf
				#sed -i 's/\\\\/\\/g' /tmp/wifinetwork-remembered.conf
			fi
		fi
		/usr/local/sbin/wifi_client_trust_mode.sh up execRemember > /dev/null 2>&1 &
	fi
	rm /tmp/wifi_client_remembered_execute
fi