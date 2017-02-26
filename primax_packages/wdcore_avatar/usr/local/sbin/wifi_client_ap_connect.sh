#!/bin/bash
#
# � 2010 Western Digital Technologies, Inc. All rights reserved.
#
# wifi_client_ap_connect.sh
#
#


PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
. /etc/nas/config/share-param.conf
source /etc/nas/config/wifinetwork-param.conf
if [ -f "/tmp/WiFiClientApDebugModeEnabledLog" ]; then
	Debugmode=1
else
	Debugmode=0
fi

macSetting=0
confjoin=1
hiddenSsid=0
ChangeNetwork=false
cliDhcp=true
clientDHCP=true
CurrentRank=${STA_CONF_ORDER}
trusted=false
auto_join=true
#auto_login=true
remember=true
maclone=false
if [ "$Debugmode" == "1" ]; then
	timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
	echo $timestamp ": wifi_client_ap_connect.sh" $@ >> /tmp/wificlientap.log
fi
function trans_to_hex {
	for i in $(echo $1 | sed -e "s/\./ /g"); do  
      	printf '%02x' $i >/dev/null 2>/dev/null < /dev/null
    done
}

RemoveWPS() {
	if [ -f "/tmp/clientStatus" ]; then
		rm /tmp/clientStatus
	fi
	if [ -f "/tmp/WPSpinMethod" ]; then
		rm /tmp/WPSpinMethod
	fi
}

ErrorCode(){
	echo "wifi_client_ap_connect.sh --connect <mac>|<ssid> [--security_key <key>] [--security_mode <mode>] \
[--auto_join true|false] [--remember_network true|false] [--trusted true|false] \
[--dhcp_enabled true|false] [--ip <ip>] [--netmask <netmask>] [--gateway <gateway> ] \
[--dns0 <dns0> ] [--dns1 <dns1>] [--dns2 <dns2>][--mac_clone_enable < mac_clone_enable > ] \
[--clone_mac_address  < clone_mac_address >] | --disconnect <mac> | --pinconnect <wps_pin> --mac <mac> | \
 --ssid <ssid> [--trusted true|false]"

	if [ "$Debugmode" == "1" ]; then
		timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
		echo $timestamp ": wifi_client_ap_connect.sh input parameter error" "$1"  >> /tmp/wificlientap.log
	fi
	exit 1
}

if [ $# == 0 ]; then
	ErrorCode "--All"
fi

#if [ "$STA_CLIENT" == "false" ]; then 
#	if [ "$Debugmode" == "1" ]; then
#		timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
#		echo $timestamp ": wifi_client_ap_connect.sh Wifi client off" >> /tmp/wificlientap.log
#	fi
#	exit 1
#fi

if [ -f /tmp/clientStatus ]; then
	ApCliStatus=`cat /tmp/clientStatus`
	if [ "$ApCliStatus" != "0" ] && [ "$ApCliStatus" != "1" ]; then
		if [ "$Debugmode" == "1" ]; then
			timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
			echo $timestamp ": wifi_client_ap_connect.sh wlan0 Busy:" "$ApCliStatus" >> /tmp/wificlientap.log
		fi
		exit 2
	fi
fi


option_connect=$1
if [ "$option_connect" == "--connect" ]; then
  	if [ ! -f "/tmp/scan_result" ]; then
  		/usr/local/sbin/wifi_client_ap_scan.sh > /dev/null
	fi
  	string_mac="$2"
  
  	RememberAP=`grep -rsi "\"${string_mac}\"" /etc/nas/config/wifinetwork-remembered.conf | grep -v 'signal_strength="0"'`
  	if [ "$RememberAP" != "" ]; then
  		RememberedConnect=1
  		cliSignal=`echo ${RememberAP} | awk 'BEGIN{FS="signal_strength=" } {print $NF}' | cut -d '"' -f 2`
		if [ "$cliSignal" == "0" ]; then
			if [ "$Debugmode" == "1" ]; then
  				timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
				echo $timestamp ": wifi_client_ap_connect.sh miss target MAC:" "${string_mac}"  >> /tmp/wificlientap.log
  			fi
			exit 2
		fi  		
  		cli2Ssid=`echo ${RememberAP} | awk 'BEGIN{FS=" mac=" }{print $1}' | cut -d '=' -f 2`
    	cli2mac=`echo ${RememberAP} | awk 'BEGIN{FS="mac=" } {print $NF}' | cut -d '"' -f 2`
    	cli2join=`echo ${RememberAP} | awk 'BEGIN{FS="auto_join=" } {print $NF}' | cut -d '"' -f 2`
    	cli2trust=`echo ${RememberAP} | awk 'BEGIN{FS="trusted=" } {print $NF}' | cut -d '"' -f 2`
    	cli2encryptype=`echo ${RememberAP} | awk 'BEGIN{FS="security_mode=" } {print $NF}' | cut -d '"' -f 2 | awk -F/ '{print $1}'`
    	cli2cipher=`echo ${RememberAP} | awk 'BEGIN{FS="security_mode=" } {print $NF}' | cut -d '"' -f 2 | awk -F/ '{print $2}' | awk '{print $1}'`
    	cli2bssid=`echo ${RememberAP} | awk 'BEGIN{FS="bssi\/dmap=" } {print $NF}' | cut -d ' ' -f 1`
    	cli2key=`echo ${RememberAP} | awk 'BEGIN{FS="security_key=" } {print $NF}' | cut -d '"' -f 2` 
    	cliremembered=`echo ${RememberAP} | awk 'BEGIN{FS="remembered=" } {print $NF}' | cut -d '"' -f 2`
    	cliDhcp=`echo ${RememberAP} | awk 'BEGIN{FS="dhcp_enabled=" } {print $NF}' | cut -d '"' -f 2`
		cliip=`echo ${RememberAP} | awk 'BEGIN{FS="ip=" } {print $NF}' | cut -d '"' -f 2`
		climask=`echo ${RememberAP} | awk 'BEGIN{FS="netmask=" } {print $NF}' | cut -d '"' -f 2`
		cligw=`echo ${RememberAP} | awk 'BEGIN{FS="gateway=" } {print $NF}' | cut -d '"' -f 2`
		clidns0=`echo ${RememberAP} | awk 'BEGIN{FS="dns0=" } {print $NF}' | cut -d '"' -f 2`
		clidns1=`echo ${RememberAP} | awk 'BEGIN{FS="dns1=" } {print $NF}' | cut -d '"' -f 2`
		clidns2=`echo ${RememberAP} | awk 'BEGIN{FS="dns2=" } {print $NF}' | cut -d '"' -f 2`
		
		cliclone=`echo ${RememberAP} | awk 'BEGIN{FS="mac_clone_enable=" } {print $NF}' | cut -d '"' -f 2`
		clicloneaddr=`echo ${RememberAP} | awk 'BEGIN{FS="cloned_mac_address=" } {print $NF}' | cut -d '"' -f 2`
	
    	clientDHCP="$cliDhcp"
    	clientIp="$cliip"
    	clientmask="$climask"
       	clientgw="$cligw"
       	clientdns0="$clidns0"
       	clientdns1="$clidns1"
       	clientdns2="$clidns2"
       	maclone="$cliclone"
 		cloneaddr="$clicloneaddr"
 
    	remember="$cliremembered"
    	trusted=$cli2trust
		auto_join=$cli2join
		
		macaddr=$cli2mac
		key_security_mode=$cli2encryptype
       	new_security_mode=$cli2encryptype\\/$cli2cipher
       	ciphertype=$cli2cipher
       	security_key=$cli2key
       		
       	if [ "$Debugmode" == "1" ]; then
  			timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
			echo $timestamp ": wifi_client_ap_connect.sh exist list: ""$cli2Ssid" "$cli2mac" >> /tmp/wificlientap.log
  		fi
       		
		if [ "$cli2bssid" == "1" ]; then
			macSetting=1
			hiddenSsid=0
		else
			macSetting=0
			hiddenSsid=1
		fi

		while [ "$3" != "" ]; do
   			case $3 in
		       	--security_key  )	shift
		                            security_key="$3"
		                            ;;
      			--security_mode )   shift
                               		security_mode="$3"
                               		;;
       			--auto_join )       shift
                               		auto_join="$3"
                              		;;
                           
       			--trusted )			shift
                               		trusted="$3"
                               		;;
       			--remember_network )	shift
                               		remember="$3"
                               		;;
       			--change_network )	   shift
       						   		ChangeNetwork="$3"
        					   		;;
        		--dhcp_enabled )	if [ "$4" != "true" ] && [ "$4" != "false" ]; then
        								ErrorCode "--dhcp_enabled"
        							else
        								shift
       									clientDHCP="$3"
        							fi
       								;;
       			--ip )				if [ "$clientDHCP" == "false" ]; then
       									trans_to_hex "$4"
       									if [ "$?" == 0 ]; then	
       										shift
										 	clientIp="$3"
										else
											ErrorCode "--ip"
										fi
									fi
       								;;
       			--netmask )			if [ "$clientDHCP" == "false" ]; then
       									trans_to_hex "$4"
       									if [ "$?" == 0 ]; then	
       										shift
											clientmask="$3"
										else 
											ErrorCode "--netmask"
										fi
									fi
       								;;

       			--gateway )			if [ "$clientDHCP" == "false" ]; then
       									trans_to_hex "$4"
       									if [ "$?" == 0 ]; then	
       										shift
											clientgw="$3"
										fi
									fi
        							;;
       			--dns0 )			if [ "$clientDHCP" == "false" ]; then
       									trans_to_hex "$4"
       									if [ "$?" == 0 ]; then	
       										shift
											clientdns0="$3"
										fi
									fi
        							;;
       			--dns1 )			if [ "$clientDHCP" == "false" ]; then
       									trans_to_hex "$4"
       									if [ "$?" == 0 ]; then	
       										shift
											clientdns1="$3"
										fi
									fi
        							;;
       			
      		 	--dns2 )			if [ "$clientDHCP" == "false" ]; then
      		 							trans_to_hex "$4"
       									if [ "$?" == 0 ]; then	
       										shift
											clientdns2="$3"
										fi
									fi
        							;;
        		--mac_clone_enable )	if [ "$4" != "true" ] || [ "$4" != "false" ]; then
        								shift							
        								maclone="$3"
        							fi
        							;;
        
        		--cloned_mac_address )	if [ "$maclone" == "true" ]; then
        								shift
        								if [ "$3" == "" ]; then
        									ErrorCode "--cloned_mac_address"
        								else
        									cloneaddr="$3"
        								fi
        							fi
        							;;
   			esac
   			shift
		done
  	else
  		if [ "$3" == "" ]; then
			ErrorCode "-- Not enough parameter"
		fi 
		RememberedConnect=0  	
  		duplicate=`grep -rsi "\"${string_mac}\"" /tmp/scan_result | awk 'BEGIN {FS="mac="} {print $NF}' | cut -d '"' -f 2 | wc -l` 
  		if [ "$duplicate" == "1" ]; then
  			macaddr=`grep -rsi "\"${string_mac}\"" /tmp/scan_result | awk 'BEGIN {FS="mac="} {print $NF}' | cut -d '"' -f 2` 
  		else
  			macaddr=`grep -rsi "\"${string_mac}\"" /tmp/scan_result | awk 'BEGIN {FS="mac="} {print $NF}' | cut -d '"' -f 2 | tail -1` 
  		fi
  	
  		if [ "${string_mac}" ==  "${macaddr}" ]; then
  			macSetting=1
  		fi
  		if [ "$macSetting" == "1" ]; then 
  			found_mac=`grep -rsi "\"${string_mac}\"" /tmp/scan_result | grep -v 'signal_strength="0"' | wc -l`
  			if [ $found_mac -eq 0 ]; then
  				if [ "$Debugmode" == "1" ]; then
  					timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
					echo $timestamp ": wifi_client_ap_connect.sh miss target MAC:" "${string_mac}"  >> /tmp/wificlientap.log
  				fi
  				exit 2
  			fi
  		else
  			found_ssid=`grep -rsw "\"${string_mac}\"" /tmp/scan_result | grep -v 'signal_strength="0"' | wc -l`
  			if [ $found_ssid -eq 0 ]; then
  				hiddenSsid=1
  			fi
  		fi
  	fi  
  	
elif [ "$option_connect" == "--disconnect" ]; then
	string_mac="$2"
	connectMAC=`iwconfig wlan0 | grep "Access Point" | awk '{print $NF}'`	
	if [ "$Debugmode" == "1" ]; then
		timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
		echo $timestamp ": wifi_client_ap_connect.sh connected MAC addr:" "$connectMAC" >> /tmp/wificlientap.log
	fi	
	if [ "$connectMAC" == "$string_mac" ]; then	
		sed -i 's/connected="true"./connected="false" /' /tmp/wifinetwork-remembered.conf
		sed -i 's/connected="true"./connected="false" /' /etc/nas/config/wifinetwork-remembered.conf
		/sbin/wifi-restart UPDATE_STA_CONF
		/etc/init.d/S90multi-role restart
		#echo "1" > /tmp/client_disconnect
		#/usr/local/sbin/wifi_client_trust_mode.sh down &
		#echo 2 > /tmp/ApCliRetry
		#/usr/local/sbin/wifi_client_ap_retry.sh 2
		interface=`pidof hostapd`
		if [ "$interface" == "" ]; then
			/usr/local/sbin/wifi_ap_set_config.sh --enabled EnabledHomeNetwork 
		fi	
		wifi_client_ap_scan.sh --remembered signalCHECK > /dev/null		
		exit 0
	else
		#sed -i '/'\"${string_mac}\"'/ s/connected=true./connected=false /' /etc/nas/config/wifinetwork-remembered.conf
		exit 0
	fi
elif [ "$option_connect" == "--pinconnect" ]; then 
	pincode="$2"
	if [ `expr $(echo $pincode | wc -m) - 1` != 8 ]; then
		if [ "$Debugmode" == "1" ]; then
			timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
			echo $timestamp ": wifi_client_ap_connect.sh WPS PIN Error:" "$pincode" >> /tmp/wificlientap.log
		fi
		exit 7
	fi

	ConnectAP=$3
	if [ "$3" == "--ssid" ]; then
		string_mac="$4"
	elif [ "$3" == "--mac" ]; then
		string_mac="$4"
	fi

	confjoin=2
	echo 2 > /tmp/clientStatus
	macaddr=`grep -rsi "\"${string_mac}\"" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN {FS="mac="} {print $NF}' | cut -d '"' -f 2 | head -1` 
	if [ "${string_mac}" ==  "${macaddr}" ]; then
		macSetting=1
	fi
	wpsupport=`grep -rsi "\"${string_mac}\"" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN {FS="wps_mode="} {print $NF}' | cut -d '"' -f 2 | head -1` 
	if [ "$wpsupport" == "false" ]; then
		echo "WpsNotSupported" > /tmp/WPSpinMethod
	fi
	security_mode=`grep -rsi "\"${string_mac}\"" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="security_mode=" } {print $NF}' | cut -d '"' -f 2 | head -1`
	security_key=MyPassportWirelessWPSSecurityKeyTEMPoRarily

elif [ "$option_connect" == "--PBCconnect" ]; then 
	RemoveWPS
	confjoin=2
	hiddenSsid=1
	string_mac=MyPassportWirelessPBCSSidTEMP
	securitype=WPAPSK1WPAPSK2
	ciphertype=TKIPAES
	security_mode=WPAPSK1WPAPSK2\/TKIPAES
	security_key=MyPassportWirelessPBCSecurityKeyTEMPoRarily
	trusted=true
else 
	ErrorCode "-- option_connect error "
fi

opt_trusted=true
opt_auto_join=true
opt_auto_login=true
opt_remember=true

if [ "$RememberedConnect" != "1" ]; then
	while [ "$3" != "" ]; do
   		case $3 in
       		--security_key  )  shift
                               security_key="$3"
                               
                               ;;
       		--security_mode )  shift
                               security_mode="$3"
                               ;;
       		--auto_join )      shift
                               auto_join="$3"
                               opt_auto_join=true
                               if [ "$auto_join" == "true" ]; then
                               	b_auto_join=true
                               else
                               	if [ "$auto_join" == "false" ]; then
                               		b_auto_join=false
                                else
                                 	ErrorCode "--auto_join"
                                fi                              
                               fi
                               ;;
       #--auto_login )          shift
       #                        auto_login=$3
       #                        opt_auto_login=true
       #                        if [ "$auto_login" == "true" ]; then
       #                        	b_auto_login=true
       #                        else
       #                          if [ "$auto_login" == "false" ]; then
       #                        	  b_auto_login=false
       #                          else
       #                          	exit 1
       #                          fi                              
       #                        fi
       #                        ;;                        
       --trusted )             shift
                               trusted="$3"
                               opt_trusted=true
                               if [ "$trusted" == "true" ]; then
                               	b_trusted=true
                               else
                                 if [ "$trusted" == "false" ]; then
                               	  b_trusted=false
                                 else
                                 	ErrorCode "--trusted"
                                 fi                              
                               fi
                               ;;
       --remember_network )    shift
                               remember="$3"
                               opt_remember=true
                               if [ "$remember" == "true" ]; then
                               	b_remember=true
                               else
                                 if [ "$remember" == "false" ]; then
                               	  b_remember=false
                                 else
                                 	ErrorCode "--remember_network"
                                 fi
                               fi
                               ;;
       --change_network )	   shift
       						   ChangeNetwork="$3"
        					   ;;
       --dhcp_enabled )			if [ "$4" != "true" ] && [ "$4" != "false" ]; then
        							ErrorCode "--dhcp_enabled"
        						else
        							shift
       								clientDHCP="$3"
        						fi
       							;;
     	--ip )					if [ "$clientDHCP" == "false" ]; then
      								trans_to_hex "$4"
       								if [ "$?" == 0 ]; then	
      									shift
									 	clientIp="$3"
									else
										ErrorCode "--ip"
									fi
								fi
      							;;
    	--netmask )				if [ "$clientDHCP" == "false" ]; then
    								trans_to_hex "$4"
       								if [ "$?" == 0 ]; then	
       									shift
										clientmask="$3"
									else 
										ErrorCode "--netmask"
									fi
								fi
       							;;

    	--gateway )				if [ "$clientDHCP" == "false" ]; then
    								trans_to_hex "$4"
       								if [ "$?" == 0 ]; then	
       									shift
										clientgw="$3"
									fi
								fi
        						;;
       	--dns0 )				if [ "$clientDHCP" == "false" ]; then
       								trans_to_hex "$4"
       								if [ "$?" == 0 ]; then	
       									shift
										clientdns0="$3"
									fi
								fi
        						;;
       	--dns1 )				if [ "$clientDHCP" == "false" ]; then
       								trans_to_hex "$4"
       								if [ "$?" == 0 ]; then	
       									shift
										clientdns1="$3"
									fi
								fi
        						;;
       			
      	--dns2 )				if [ "$clientDHCP" == "false" ]; then
      								trans_to_hex "$4"
       								if [ "$?" == 0 ]; then	
       									shift
										clientdns2="$3"
									fi
								fi
        						;;
        						
        --mac_clone_enable )		if [ "$4" != "true" ] || [ "$4" != "false" ]; then
        							shift							
        							maclone="$3"
        						fi
        						;;
        
        --cloned_mac_address )	if [ "$maclone" == "true" ]; then
        							shift
        							if [ "$3" == "" ]; then
        								ErrorCode "--cloned_mac_address"
        							else
        								cloneaddr="$3"
        							fi
        						fi
        						;;
        						
       #* )  					   if [ "$option_connect" == "--pinconnect" ]; then 
        					   #	break;
        					   #else
        #                    	echo "/usr/local/sbin/wifi_client_ap_connect.sh  --connect \"mac_address\""
        #                       	exit 1
                               #fi
        #                       ;;
   esac
   shift
done

################
if [ "$clientDHCP" == "false" ]; then
	if [ "$clientIp" == "" ] && [ "$clientmask" == "" ]; then
		ErrorCode "--clientIp --clientmask"
	fi
fi

if [ "$security_mode" == "" ]; then
	ErrorCode "--security_mode"
	exit 1
fi

case $security_mode in
	NONE )
		if [ `expr $(echo $security_key | wc -m) - 1` == 0 ]; then
       		key_security_mode=NONE
       		new_security_mode=$security_mode
       		security_key=""
           	secure=false
       	else
       		if [ "$Debugmode" == "1" ]; then
				timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
				echo $timestamp ": wifi_client_ap_connect.sh OPEN Security with Key:" "$security_key" >> /tmp/wificlientap.log
			fi
       		exit 6
       	fi
		;;
	WEP )
		if [ `expr $(echo $security_key | wc -m) - 1` == 5 ] || [ `expr $(echo $security_key | wc -m) - 1` == 10 ] || [ `expr $(echo $security_key | wc -m) - 1` == 13 ] || [ `expr $(echo $security_key | wc -m) - 1` == 26 ]; then
    		if [ `expr $(echo $security_key | wc -m) - 1` == 10 ] || [ `expr $(echo $security_key | wc -m) - 1` == 26 ]; then
    			for ((index=1; index<=`expr $(echo $security_key | wc -m) - 1`; index++ )); do
    				character=`echo ${security_key} | sed 's/\(.\{1\}\)/\1 /g' | awk -v num=$index '{print $num}'`
    				echo ${character} | grep -q -v '[A-Fa-f0-9]'
    				if [ $? == 0 ]; then
						if [ "$Debugmode" == "1" ]; then
							timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
							echo $timestamp ": wifi_client_ap_connect.sh WEP Security with Key:" "$security_key" >> /tmp/wificlientap.log
						fi
						exit 5
					fi
    			done
    		fi
    		secure=true
           	key_security_mode=$security_mode
           	new_security_mode=$security_mode
        else
        	if [ "$Debugmode" == "1" ]; then
				timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
				echo $timestamp ": wifi_client_ap_connect.sh WEP Security with Key:" "$security_key" >> /tmp/wificlientap.log
			fi
        	exit 4
        fi
		;;
		
	* )
		securitype=`echo ${security_mode} | awk -F/ '{print $1}'`
		ciphertype=`echo ${security_mode} | awk -F/ '{print $2}'`

    	if [ "$securitype" == "WPAPSK" ] || [ "$securitype" == "WPA2PSK" ] || [ "$securitype" == "WPAPSK1WPAPSK2" ]; then
    		if [ "$ciphertype" != "TKIPAES" ] && [ "$ciphertype" != "TKIP" ] && [ "$ciphertype" != "AES" ]; then
        		if [ "$Debugmode" == "1" ]; then
					timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
					echo $timestamp ": wifi_client_ap_connect.sh Unknown Security" >> /tmp/wificlientap.log
				fi
        		exit 5
        	fi
        	if [ `expr $(echo $security_key | wc -m) - 1` -ge 8 ] && [ `expr $(echo $security_key | wc -m) - 1` -le 63 ]; then
        		secure=true
            	key_security_mode=$securitype
            	new_security_mode=$securitype\\/$ciphertype
        	else
        		if [ "$Debugmode" == "1" ]; then
					timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
					echo $timestamp ": wifi_client_ap_connect.sh WPA Security with Key:" "$security_key" >> /tmp/wificlientap.log
				fi
            	exit 4
        	fi
   	 	fi	
		;;
esac
fi 
#RememberedConnect

if [ "$ChangeNetwork" == "false" ]; then
    echo "executeTrust" > /tmp/executeTrust
	echo 2 > /tmp/clientStatus
	
	if [ "$hiddenSsid" == "1" ]; then
		if [ "$Debugmode" == "1" ]; then
			timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
			echo $timestamp ": wifi_client_ap_connect.sh By Ssid Method" >> /tmp/wificlientap.log
		fi
		if [ "$securitype" == "NONE" ]; then
			hidden_secured=false
		else
			hidden_secured=true
		fi
		
		if [ "${string_mac}" == "MyPassportWirelessPBCSSidTEMP" ]; then
			cliwpsenabled=true
		else
			cliwpsenabled=false
		fi
		
		if [ "$security_mode" == "NONE" ]; then
			hiddenProfile="ssid=\""${string_mac}"\" mac=\""00:00:00:00:00:00"\" signal_strength=\""80"\" auto_join=\""$auto_join"\" trusted=\""$trusted"\" security_mode=\""${key_security_mode}"\" connected=\""false"\" remembered=\""true"\" secured=\""${hidden_secured}"\" wps_enabled="\"${cliwpsenabled}\"" \
			dhcp_enabled=\""$cliDhcp"\" ip=\""$cliip"\" netmask=\""$climask"\" gateway=\""$cligw"\" dns0=\""$clidns0"\" dns1=\""$clidns1"\" dns2=\""$clidns2"\" mac_clone_enable=\""$maclone"\" cloned_mac_address=\""$cloneaddr"\" bssi/dmap=0 security_key=\"${security_key}\""
		elif [ "$security_mode" == "WEP" ]; then
			hiddenProfile="ssid=\""${string_mac}"\" mac=\""00:00:00:00:00:00"\" signal_strength=\""80"\" auto_join=\""$auto_join"\" trusted=\""$trusted"\" security_mode=\""${key_security_mode}"\" connected=\""false"\" remembered=\""true"\" secured=\""${hidden_secured}"\" wps_enabled="\"${cliwpsenabled}\"" \
			dhcp_enabled=\""$cliDhcp"\" ip=\""$cliip"\" netmask=\""$climask"\" gateway=\""$cligw"\" dns0=\""$clidns0"\" dns1=\""$clidns1"\" dns2=\""$clidns2"\" mac_clone_enable=\""$maclone"\" cloned_mac_address=\""$cloneaddr"\" bssi/dmap=0 security_key=\"${security_key}\""
		else
			hiddenProfile="ssid=\""${string_mac}"\" mac=\""00:00:00:00:00:00"\" signal_strength=\""80"\" auto_join=\""$auto_join"\" trusted=\""$trusted"\" security_mode=\""${securitype}/${ciphertype}"\" connected=\""false"\" remembered=\""true"\" secured=\""${hidden_secured}"\" wps_enabled="\"${cliwpsenabled}\"" \
			dhcp_enabled=\""$cliDhcp"\" ip=\""$cliip"\" netmask=\""$climask"\" gateway=\""$cligw"\" dns0=\""$clidns0"\" dns1=\""$clidns1"\" dns2=\""$clidns2"\" mac_clone_enable=\""$maclone"\" cloned_mac_address=\""$cloneaddr"\" bssi/dmap=0 security_key=\"${security_key}\""
		fi
		
		echo $hiddenProfile > /tmp/wifinetwork-remembered.conf
		if [ "$option_connect" == "--connect" ]; then
			conf_remember=`grep -rsi "\"${string_mac}\"" /etc/nas/config/wifinetwork-remembered.conf | grep -v 'signal_strength="0"'`
			if [ "${conf_remember}" != "" ]; then
				sed '/'\""${string_mac}"\"'/d' /etc/nas/config/wifinetwork-remembered.conf > /tmp/wifinetwork-remembered_tmp.conf
				echo $hiddenProfile > /etc/nas/config/wifinetwork-remembered.conf
				cat /tmp/wifinetwork-remembered_tmp.conf >> /etc/nas/config/wifinetwork-remembered.conf	
				rm /tmp/wifinetwork-remembered_tmp.conf		
			fi
		fi
		ssid_found="${string_mac}"
	else
		if [ "$Debugmode" == "1" ]; then
			timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
			echo $timestamp ": wifi_client_ap_connect.sh By MACaddress Method" >> /tmp/wificlientap.log
		fi
		if [ "$duplicate" == "1" ]; then
			ssid_found=`grep -rsi "\"${string_mac}\"" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN {FS="ssid="} {print $NF}' | cut -d '"' -f 2`
		else
			ssid_found=`grep -rsi "\"${string_mac}\"" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN {FS="ssid="} {print $NF}' | cut -d '"' -f 2 | tail -1`
		fi
		if [ "$opt_trusted" == "true" ]; then
			saved_trusted=`grep -rsw "\""${string_mac}"\"" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN {FS="trusted="} {print $NF}' | cut -d '"' -f 2 | head -1`
			if [ "$trusted" == "true" ]; then
				if [ "$saved_trusted" == "true" ]; then
					sed -i '/'\""${string_mac}"\"'/ s/trusted="true"./trusted="true" /' /tmp/scan_result
				else
					sed -i '/'\""${string_mac}"\"'/ s/trusted="false"./trusted="true" /' /tmp/scan_result
				fi
			else
				if [ "$saved_trusted" == "true" ]; then
					sed -i '/'\""${string_mac}"\"'/ s/trusted="true"./trusted="false" /' /tmp/scan_result
				else
					sed -i '/'\""${string_mac}"\"'/ s/trusted="false"./trusted="false" /' /tmp/scan_result
				fi	
			fi 
		fi

		if [ "$opt_auto_join" == "true" ]; then
			saved_auto_join=`grep -rsi "\""${string_mac}"\"" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN {FS="auto_join="} {print $NF}' | cut -d '"' -f 2 | head -1`
			if [ "$auto_join" == "true" ]; then
				if [ "$saved_auto_join" == "true" ]; then
					sed -i '/'\""${string_mac}"\"'/ s/auto_join="true"./auto_join="true" /' /tmp/scan_result
				else
				sed -i '/'\""${string_mac}"\"'/ s/auto_join="false"./auto_join="true" /' /tmp/scan_result
				fi
			else
				if [ "$saved_auto_join" == "true" ]; then
					sed -i '/'\""${string_mac}"\"'/ s/auto_join="true"./auto_join="false" /' /tmp/scan_result
				else
					sed -i '/'\""${string_mac}"\"'/ s/auto_join="false"./auto_join="false" /' /tmp/scan_result
				fi	
			fi 
		fi

		if [ "$opt_remember" == "true" ]; then
			if [ "$duplicate" == "1" ]; then
				saved_remember=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN {FS="remembered="} {print $NF}' | cut -d '"' -f 2 | head -1`
			else
				saved_remember=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN {FS="remembered="} {print $NF}' | cut -d '"' -f 2 | head -1`
			fi
			
			if [ "$remember" == "true" ]; then
				if [ "$saved_remember" == "true" ]; then
					sed -i '/'\""${string_mac}"\"'/ s/remembered="true"./remembered="true" /' /tmp/scan_result
				else
					sed -i '/'\""${string_mac}"\"'/ s/remembered="false"./remembered="true" /' /tmp/scan_result
				fi
			else
				if [ "$saved_remember" == "true" ]; then
					sed -i '/'\""${string_mac}"\"'/ s/remembered="true"./remembered="false" /' /tmp/scan_result
				else
					sed -i '/'\""${string_mac}"\"'/ s/remembered="false"./remembered="false" /' /tmp/scan_result
				fi
			fi	
			
			if [ "${macSetting}" == 1 ]; then
				sed -i '/'\""${string_mac}"\"'/ s/bssi\/dmap=0 /bssi\/dmap=1 /' /tmp/scan_result
			else
				sed -i '/'\""${string_mac}"\"'/ s/bssi\/dmap=1 /bssi\/dmap=0 /' /tmp/scan_result
			fi
				
			ConfSecurity=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="security_mode=" } {print $NF}' | cut -d '"' -f 2 | head -1`
			if [ "$ConfSecurity" == "NONE" ]; then
				ConfSecurity="NONE"
			elif [ "$ConfSecurity" == "WEP" ]; then
				ConfSecurity="WEP"	
			else
				Confsecuritype=`echo ${ConfSecurity} | awk -F/ '{print $1}'`
				Confciphertype=`echo ${ConfSecurity} | awk -F/ '{print $2}'`
				ConfSecurity=$Confsecuritype\\/$Confciphertype
			fi
			sed -i '/'\""${string_mac}"\"'/ s/security_mode='${ConfSecurity}'./security_mode='\""${new_security_mode}"\"' /' /tmp/scan_result
		
			ConfJoin=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="auto_join=" } {print $NF}' | cut -d '"' -f 2 | head -1`	
			sed -i '/'\""${string_mac}"\"'/ s/auto_join='${ConfJoin}'./auto_join='\""${saved_auto_join}"\"' /' /tmp/scan_result
				
			ConfTrust=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="trusted=" } {print $NF}' | cut -d '"' -f 2 | head -1`
			sed -i '/'\""${string_mac}"\"'/ s/trusted='${ConfTrust}'./trusted='\""${saved_trusted}"\"' /' /tmp/scan_result
			
			cat /tmp/scan_result | grep -rsi "\"${string_mac}\"" | grep -v 'signal_strength="0"' > /tmp/wifinetwork-remembered.conf
			#conf_remember=`grep -rnsi "\"${string_mac}\"" /etc/nas/config/wifinetwork-remembered.conf | grep -v 'signal_strength="0"'| head -1`
			#if [ "${conf_remember}" != "" ]; then
			#	lineNum=`echo "$conf_remember" | cut -d ':' -f 1`	
			#	sed ${lineNum}d /etc/nas/config/wifinetwork-remembered.conf > /tmp/wifinetwork-remembered_tmp.conf
			#	cat /tmp/wifinetwork-remembered_tmp.conf > /etc/nas/config/wifinetwork-remembered.conf
			#cat /tmp/scan_result | grep -rsi "\"${string_mac}\"" > /etc/nas/config/wifinetwork-remembered.conf
			#cat /tmp/wifinetwork-remembered_tmp.conf >> /etc/nas/config/wifinetwork-remembered.conf
			#rm /tmp/wifinetwork-remembered_tmp.conf
			#fi
			if [ "$option_connect" == "--connect" ]; then
				conf_remember=`grep -rsw "\"${ssid_found}\"" /etc/nas/config/wifinetwork-remembered.conf | head -1`
				if [ "${conf_remember}" != "" ]; then
					if [ "$Debugmode" == "1" ]; then
						timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
						echo $timestamp ": wifi_client_ap_connect.sh Replace Target:" >> /tmp/wificlientap.log
						echo $timestamp ": wifi_client_ap_connect.sh" "$conf_remember" >> /tmp/wificlientap.log
					fi
						
					sed '/'\""${ssid_found}"\"'/d' /etc/nas/config/wifinetwork-remembered.conf > /tmp/wifinetwork-remembered_tmp.conf
					cat /tmp/wifinetwork-remembered_tmp.conf > /etc/nas/config/wifinetwork-remembered.conf
					rm /tmp/wifinetwork-remembered_tmp.conf
				fi
			fi
		fi
		
		
		#echo "ssid:\""${ssid_found}"\" Security_mode:${key_security_mode} Security_key:${security_key}" > saveclient
	fi
else
	#if [ "$duplicate" == "1" ]; then
	#	ssid_found=`grep -rsi "\"${string_mac}\"" /etc/nas/config/wifinetwork-remembered.conf | grep -v 'signal_strength="0"' | awk 'BEGIN {FS="ssid="} {print $NF}' | cut -d '"' -f 2`
	#else		
		ssid_found=`grep -rsi "\"${string_mac}\"" /etc/nas/config/wifinetwork-remembered.conf | grep -v 'signal_strength="0"' | awk 'BEGIN{FS=" mac=" }{print $1}' | cut -d '=' -f 2 | tail -1`
	#fi
	cat /etc/nas/config/wifinetwork-remembered.conf | grep -rsi "\"${string_mac}\"" | grep -v 'signal_strength="0"' > /tmp/wifinetwork-remembered.conf
	
	if [ -f "/tmp/executeTrust" ]; then
		rm /tmp/executeTrust
	fi
fi #ChangeNetwork
#echo "macaddr:"${macaddr}" ssid:\""${ssid_found}"\" Security_mode:${key_security_mode} Security_key:${security_key}" >> /tmp/saveclient

if [ "$ssid_found" != "" ]; then
	OldSsid=${STA_SSID_NAME}
	NewSsid=${ssid_found}
	if [ "$OldSsid" != "$NewSsid" ]; then
		echo 0 > /tmp/ApCliRetry
	fi
	
	echo "${ssid_found}" | grep -q '\"\|\$\|\&\|/\||\|\\'
	if [ $? == 0 ]; then
		echo $ssid_found > /tmp/clientssid
		sed -i 's/\\/\\\\/g' /tmp/clientssid
		sed -i 's/"/\\"/g' /tmp/clientssid
		sed -i 's/\$/\\$/g' /tmp/clientssid
		sed -i 's/&/\\&/g' /tmp/clientssid
		sed -i 's/\//\\\//g' /tmp/clientssid
		sed -i 's/|/\\|/g' /tmp/clientssid
		ssid_found=`cat /tmp/clientssid`
		rm /tmp/clientssid
	fi 	
	sed -i 's/STA_SSID_NAME=.*/STA_SSID_NAME='\""${ssid_found}"\"'/' /etc/nas/config/wifinetwork-param.conf
	sed -i '/STA_SSID_NAME/ s/\\/\\\\/g' /etc/nas/config/wifinetwork-param.conf
	sed -i '/STA_SSID_NAME/ s/"/\\"/g' /etc/nas/config/wifinetwork-param.conf
	sed -i '/STA_SSID_NAME/ s/\$/\\$/g' /etc/nas/config/wifinetwork-param.conf
	sed -i '/STA_SSID_NAME/ s/`/\\`/g' /etc/nas/config/wifinetwork-param.conf
	sed -i '/STA_SSID_NAME/ s/\\"/"/' /etc/nas/config/wifinetwork-param.conf
	sed -i '/STA_SSID_NAME/ s/\(.*\)\\"/\1"/' /etc/nas/config/wifinetwork-param.conf	
fi

if [ "${macSetting}" == "1" ]; then
	sed -i 's/STA_MAC_ADDRESS=.*/STA_MAC_ADDRESS='${macaddr}'/' /etc/nas/config/wifinetwork-param.conf
	sed -i 's/STA_MAC_MAPPING=.*/STA_MAC_MAPPING='${macSetting}'/' /etc/nas/config/wifinetwork-param.conf
else
	sed -i 's/STA_MAC_ADDRESS=.*/STA_MAC_ADDRESS='${macaddr}'/' /etc/nas/config/wifinetwork-param.conf
	sed -i 's/STA_MAC_MAPPING=.*/STA_MAC_MAPPING='${macSetting}'/' /etc/nas/config/wifinetwork-param.conf
fi
if [ "$key_security_mode" == "" ]; then
	sed -i 's/STA_SECURITY_MODE=.*/STA_SECURITY_MODE='${STA_SECURITY_MODE}'/' /etc/nas/config/wifinetwork-param.conf
else
	sed -i 's/STA_SECURITY_MODE=.*/STA_SECURITY_MODE='${key_security_mode}'/' /etc/nas/config/wifinetwork-param.conf
fi
if [ "$ciphertype" == "" ]; then
	if [ "$key_security_mode" == "NONE" ]; then
		sed -i 's/STA_CIPHER_TYPE=.*/STA_CIPHER_TYPE=/' /etc/nas/config/wifinetwork-param.conf
	else	
		sed -i 's/STA_CIPHER_TYPE=.*/STA_CIPHER_TYPE='${STA_CIPHER_TYPE}'/' /etc/nas/config/wifinetwork-param.conf
	fi
else
	sed -i 's/STA_CIPHER_TYPE=.*/STA_CIPHER_TYPE='${ciphertype}'/' /etc/nas/config/wifinetwork-param.conf
fi
if [ "$security_key" == "" ]; then
	if [ "$key_security_mode" == "NONE" ]; then
		sed -i 's/STA_PSK_KEY=.*/STA_PSK_KEY=/' /etc/nas/config/wifinetwork-param.conf
	#else
	#	sed -i 's/STA_PSK_KEY=.*/STA_PSK_KEY='${STA_PSK_KEY}'/' /etc/nas/config/wifinetwork-param.conf
	fi
else
	echo "${security_key}" | grep -q '\"\|\$\|\&\|/\||\|\\'
	if [ $? == 0 ]; then
		echo $security_key > /tmp/clientpwd
		sed -i 's/\\/\\\\/g' /tmp/clientpwd
		sed -i 's/"/\\"/g' /tmp/clientpwd
		sed -i 's/\$/\\$/g' /tmp/clientpwd
		sed -i 's/&/\\&/g' /tmp/clientpwd
		sed -i 's/\//\\\//g' /tmp/clientpwd
		sed -i 's/|/\\|/g' /tmp/clientpwd
		security_key=`cat /tmp/clientpwd`
		rm /tmp/clientpwd
	fi

	sed -i 's/STA_PSK_KEY=.*/STA_PSK_KEY='\""${security_key}"\"'/' /etc/nas/config/wifinetwork-param.conf
	sed -i 's/security_key=.*/security_key='\""${security_key}"\"'/' /tmp/wifinetwork-remembered.conf
	sed -i '/STA_PSK_KEY/ s/\\/\\\\/g' /etc/nas/config/wifinetwork-param.conf
	sed -i '/STA_PSK_KEY/ s/"/\\"/g' /etc/nas/config/wifinetwork-param.conf
	sed -i '/STA_PSK_KEY/ s/\$/\\$/g' /etc/nas/config/wifinetwork-param.conf
	sed -i '/STA_PSK_KEY/ s/\\"/"/' /etc/nas/config/wifinetwork-param.conf
	sed -i '/STA_PSK_KEY/ s/`/\\`/g' /etc/nas/config/wifinetwork-param.conf
	sed -i '/STA_PSK_KEY/ s/\(.*\)\\"/\1"/' /etc/nas/config/wifinetwork-param.conf	
fi

sed -i 's/STA_CONF_JOIN=.*/STA_CONF_JOIN='${confjoin}'/' /etc/nas/config/wifinetwork-param.conf
#if [ "$ChangeNetwork" == "true" ] || [ "$remember" == "false" ]; then
if [ "$remember" == "false" ]; then
	sed -i 's/STA_CONF_REMB=.*/STA_CONF_REMB=0/' /etc/nas/config/wifinetwork-param.conf
else
	sed -i 's/STA_CONF_REMB=.*/STA_CONF_REMB=1/' /etc/nas/config/wifinetwork-param.conf
	sed -i 's/STA_CONF_ORDER=.*/STA_CONF_ORDER=0/' /etc/nas/config/wifinetwork-param.conf
fi
sed -i 's/STA_CONF_HIDDEN=.*/STA_CONF_HIDDEN='${hiddenSsid}'/' /etc/nas/config/wifinetwork-param.conf

if [ "${STA_CLIENT}" == "false" ]; then	
	sed -i 's/STA_CLIENT=.*/STA_CLIENT=true/' /etc/nas/config/wifinetwork-param.conf
fi

if [ -f "/tmp/ClientConnStatus" ]; then
	rm /tmp/ClientConnStatus
fi
#if [ -f "/tmp/ifplugd_trust" ]; then
#	rm /tmp/ifplugd_trust
#fi

if [ "$option_connect" == "--connect" ]; then
RemoveWPS
ScanDHCP=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="dhcp_enabled=" } {print $NF}' | cut -d '"' -f 2 | head -1`
sed -i '/'\""${string_mac}"\"'/ s/dhcp_enabled='\""${ScanDHCP}"\"'./dhcp_enabled='\""${clientDHCP}"\"' /' /tmp/wifinetwork-remembered.conf
ScanIp=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="ip=" } {print $NF}' | cut -d '"' -f 2 | head -1`
sed -i '/'\""${string_mac}"\"'/ s/ip='\""${ScanIp}"\"'./ip='\""${clientIp}"\"' /' /tmp/wifinetwork-remembered.conf
ScanMask=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="netmask=" } {print $NF}' | cut -d '"' -f 2 | head -1`
sed -i '/'\""${string_mac}"\"'/ s/netmask='\""${ScanMask}"\"'./netmask='\""${clientmask}"\"' /' /tmp/wifinetwork-remembered.conf
ScanGW=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="gateway=" } {print $NF}' | cut -d '"' -f 2 | head -1`
sed -i '/'\""${string_mac}"\"'/ s/gateway='\""${ScanGW}"\"'./gateway='\""${clientgw}"\"' /' /tmp/wifinetwork-remembered.conf
ScanDNS0=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="dns0=" } {print $NF}' | cut -d '"' -f 2 | head -1`
sed -i '/'\""${string_mac}"\"'/ s/dns0='\""${ScanDNS0}"\"'./dns0='\""${clientdns0}"\"' /' /tmp/wifinetwork-remembered.conf
ScanDNS1=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="dns1=" } {print $NF}' | cut -d '"' -f 2 | head -1`
sed -i '/'\""${string_mac}"\"'/ s/dns1='\""${ScanDNS1}"\"'./dns1='\""${clientdns1}"\"' /' /tmp/wifinetwork-remembered.conf
ScanDNS2=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="dns2=" } {print $NF}' | cut -d '"' -f 2 | head -1`
sed -i '/'\""${string_mac}"\"'/ s/dns2='\""${ScanDNS2}"\"'./dns2='\""${clientdns2}"\"' /' /tmp/wifinetwork-remembered.conf

if [ "$clientDHCP" == "false" ]; then
	/usr/local/sbin/setNetworkStatic.sh "ifname=wlan0-connect" "$clientIp" "$clientmask" "$clientgw" "$clientdns0" "$clientdns1" "$clientdns2"
	/usr/local/sbin/wifi_client_remembered.sh up 30 &
	/usr/local/sbin/wifi_client_trust_mode.sh up &
else
	/usr/local/sbin/setNetworkDhcp.sh "wlan0-connect"
fi

/etc/init.d/S90multi-role stop
sleep 1
if [ "$maclone" == "true" ]; then
	ifconfig wlan0 down hw ether "${cloneaddr}"
	ScanClone=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="mac_clone_enable=" } {print $NF}' | cut -d '"' -f 2 | head -1`
	sed -i '/'\""${string_mac}"\"'/ s/mac_clone_enable='\""${ScanClone}"\"'./mac_clone_enable='\""${maclone}"\"' /' /tmp/wifinetwork-remembered.conf
	
	ScanCloneAddr=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="cloned_mac_address=" } {print $NF}' | cut -d '"' -f 2 | head -1`
	sed -i '/'\""${string_mac}"\"'/ s/cloned_mac_address='\""${ScanCloneAddr}"\"'./cloned_mac_address='\""${cloneaddr}"\"' /' /tmp/wifinetwork-remembered.conf
else
	if [ "$STA_HD_ADDR" == "" ]; then 
		phy0macaddr=`cat /sys/module/wlcore/holders/wl18xx/drivers/platform\:wl18xx_driver/wl18xx/ieee80211/phy0/macaddress | tr [:lower:] [:upper:]`
		ifconfig wlan0 down hw ether "${phy0macaddr}"
	else
		ifconfig wlan0 down hw ether "${STA_HD_ADDR}"
	fi
	
	ScanClone=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="mac_clone_enable=" } {print $NF}' | cut -d '"' -f 2 | head -1`
	sed -i '/'\""${string_mac}"\"'/ s/mac_clone_enable='\""${ScanClone}"\"'./mac_clone_enable='\""${maclone}"\"' /' /tmp/wifinetwork-remembered.conf
	ScanCloneAddr=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="cloned_mac_address=" } {print $NF}' | cut -d '"' -f 2 | head -1`
	sed -i '/'\""${string_mac}"\"'/ s/cloned_mac_address='\""${ScanCloneAddr}"\"'./cloned_mac_address='\"""\"' /' /tmp/wifinetwork-remembered.conf
fi

echo ApMode > /tmp/ConnectionMode
/sbin/wifi-restart STA &
if [ "$Debugmode" == "1" ]; then
	timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
	profileleft=`cat /tmp/wifinetwork-remembered.conf`
	echo $timestamp ": wifi_client_ap_connect.sh connect to target Profile " >> /tmp/wificlientap.log
	echo $timestamp ": wifi_client_ap_connect.sh" "$profileleft" >> /tmp/wificlientap.log
fi
exit 0
elif [ "$option_connect" == "--pinconnect" ]; then 
sleep 1
ScanDHCP=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="dhcp_enabled=" } {print $NF}' | cut -d '"' -f 2 | head -1`
sed -i '/'\""${string_mac}"\"'/ s/dhcp_enabled='\""${ScanDHCP}"\"'./dhcp_enabled='\""${clientDHCP}"\"' /' /tmp/wifinetwork-remembered.conf
ScanIp=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="ip=" } {print $NF}' | cut -d '"' -f 2 | head -1`
sed -i '/'\""${string_mac}"\"'/ s/ip='\""${ScanIp}"\"'./ip='\""${clientIp}"\"' /' /tmp/wifinetwork-remembered.conf
ScanMask=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="netmask=" } {print $NF}' | cut -d '"' -f 2 | head -1`
sed -i '/'\""${string_mac}"\"'/ s/netmask='\""${ScanMask}"\"'./netmask='\""${clientmask}"\"' /' /tmp/wifinetwork-remembered.conf
ScanGW=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="gateway=" } {print $NF}' | cut -d '"' -f 2 | head -1`
sed -i '/'\""${string_mac}"\"'/ s/gateway='\""${ScanGW}"\"'./gateway='\""${clientgw}"\"' /' /tmp/wifinetwork-remembered.conf
ScanDNS0=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="dns0=" } {print $NF}' | cut -d '"' -f 2 | head -1`
sed -i '/'\""${string_mac}"\"'/ s/dns0='\""${ScanDNS0}"\"'./dns0='\""${clientdns0}"\"' /' /tmp/wifinetwork-remembered.conf
ScanDNS1=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="dns1=" } {print $NF}' | cut -d '"' -f 2 | head -1`
sed -i '/'\""${string_mac}"\"'/ s/dns1='\""${ScanDNS1}"\"'./dns1='\""${clientdns1}"\"' /' /tmp/wifinetwork-remembered.conf
ScanDNS2=`grep -rsi "${string_mac}" /tmp/scan_result | grep -v 'signal_strength="0"' | awk 'BEGIN{FS="dns2=" } {print $NF}' | cut -d '"' -f 2 | head -1`
sed -i '/'\""${string_mac}"\"'/ s/dns2='\""${ScanDNS2}"\"'./dns2='\""${clientdns2}"\"' /' /tmp/wifinetwork-remembered.conf

if [ "$clientDHCP" == "false" ]; then
	/usr/local/sbin/setNetworkStatic.sh "ifname=wlan0-connect" "$clientIp" "$clientmask" "$clientgw" "$clientdns0" "$clientdns1" "$clientdns2"
	/usr/local/sbin/wifi_client_remembered.sh up 30 &
	/usr/local/sbin/wifi_client_trust_mode.sh up &
else
	/usr/local/sbin/setNetworkDhcp.sh "wlan0-connect"
fi
echo ApMode > /tmp/ConnectionMode
if [ "$maclone" == "true" ]; then
	/etc/init.d/S90multi-role stop
	sleep 1
	ifconfig wlan0 down hw ether "${cloneaddr}"
fi
/sbin/wifi-restart CLEAR_STA_CONF 
/sbin/wifi-restart STA
echo "WPS" > /tmp/clientStatus

if [ "$wpsupport" == "false" ]; then 
	echo "WpsNotSupported" > /tmp/WPSpinMethod
else
	wpa_cli -i wlan0 wps_reg "$string_mac" $pincode
	echo "wps paired device not available" > /tmp/WPSpinMethod
fi
echo "22;1;"  > /tmp/MCU_Cmd

if [ "$Debugmode" == "1" ]; then
	timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
	profileleft=`cat /tmp/wifinetwork-remembered.conf`
	echo $timestamp ": wifi_client_ap_connect.sh connect to targer Profile " >> /tmp/wificlientap.log
	echo $timestamp ": wifi_client_ap_connect.sh" "$profileleft" >> /tmp/wificlientap.log
fi
exit 0
elif [ "$option_connect" == "--PBCconnect" ]; then 
#sleep 5
echo ApMode > /tmp/ConnectionMode
/sbin/wifi-restart CLEAR_STA_CONF 
/sbin/wifi-restart STA
if [ ! -f "/tmp/scan_result" ]; then
	/usr/local/sbin/wifi_client_ap_scan.sh > /dev/null
fi
wpa_cli -i wlan0 wps_pbc
if [ "$Debugmode" == "1" ]; then
	timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
	profileleft=`cat /tmp/wifinetwork-remembered.conf`
	echo $timestamp ": wifi_client_ap_connect.sh connect to targer Profile:" >> /tmp/wificlientap.log
	echo $timestamp ": wifi_client_ap_connect.sh" "$profileleft" >> /tmp/wificlientap.log
fi
exit 0
fi
# EOF
