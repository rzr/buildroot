#!/bin/bash
#
#
# wifi_ap_get_config.sh
#
#


PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
. /etc/nas/config/share-param.conf
. /etc/nas/config/wifinetwork-param.conf 2>/dev/null

if [ -f "/tmp/WiFiApDebugModeEnabledLog" ]; then
	Debugmode=1
else
	Debugmode=0
fi
if [ "$Debugmode" == "1" ]; then
	timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
	echo $timestamp ": wifi_ap_set_config.sh" $@ >> /tmp/wifiap.log
fi
option=$1
hotspot=$2
LIMIT_SSID_LEN=32
borderChannel_L=0
disconnectime=0
max_channels=`iwlist wlan0 channel | grep wlan0 | awk -F " " '{print $2}'`
filter='^[0-9]+$'

if ! [[ $max_channels =~ $filter ]] ; then
     max_channels=11
fi
borderChannel_R=$max_channels

RestartService(){
	/etc/init.d/S50avahi-daemon restart	
	/etc/init.d/S91upnp restart
}

if [ "$option" != "--enabled" ]; then
	echo "wifi_ap_set_config.sh --enabled <true | false> [ --ssid <value> ] [ --broadcast <value> ] [ --security_key <value> ] [ --security_mode <value> ] [--channel <value>] [--static_ip <value>] [--subnet_mask <value>] [--network_mode <value>] [--channel_mode <value>]"
	exit 1
fi

if [ "$hotspot" == "false" ]; then
  	sed -i 's/AP_HOTSPOT=.*/AP_HOTSPOT=false/' /etc/nas/config/wifinetwork-param.conf
	ifconfig wlan1 down
	killall dhcpd
	killall hostapd
	exit 0	
elif [ "$hotspot" == "true" ]; then
	if [ "$3" == "" ]; then
		if [ "${AP_HOTSPOT}" == "false" ]; then 
			sed -i 's/AP_HOTSPOT=.*/AP_HOTSPOT=true/' /etc/nas/config/wifinetwork-param.conf
			#/etc/init.d/S60hostapd restart
			/usr/sbin/dhcpd -q wlan1
			/sbin/wifi-restart AP &
   		fi
   		exit 0
	fi
	shift
	while [ "$2" != "" ]; do
    case $2 in
        --ssid )    shift
                    ssid="${2}"
        			if [ ${#ssid} -gt ${LIMIT_SSID_LEN} ]; then 
        				#echo "wifi_ap_set_config.sh ssid does not support more than 32 alphanumeric characters."
        				exit 2
        			fi
        			echo "${ssid}" | grep -q '\"\|\$\|\&\|/\||\|\\'
					if [ $? == 0 ]; then
						echo $ssid > /tmp/kkk
						sed -i 's/\\/\\\\/g' /tmp/kkk
						sed -i 's/"/\\"/g' /tmp/kkk
						sed -i 's/\$/\\$/g' /tmp/kkk
						sed -i 's/&/\\&/g' /tmp/kkk
						sed -i 's/\//\\\//g' /tmp/kkk
						sed -i 's/|/\\|/g' /tmp/kkk
						#sed -i 's/\`/\\`/g' /tmp/kkk
						ssid=`cat /tmp/kkk`
						rm /tmp/kkk
					fi 	
					disconnectime=1
					
                                ;;
        --broadcast )           shift
                                broadcast="$2"
                                if [ "$broadcast" == "true" ]; then
                                	b_broadcast=true
                                	conf_broadcast=0
                                else
                                  if [ "$broadcast" == "false" ]; then
                                	  b_broadcast=false
                                	  conf_broadcast=1
                                	  disconnectime=1
                                  else
                                  	exit 1
                                  fi                              
                                fi
                                ;;
        --security_key )        shift
                                security_key="$2"
                                #if [ `expr $(echo $security_key | wc -m) - 1` == 0 ]; then
                                #	key_security_mode=NONE
                                #	secure=false
                                # 	break
                                #fi
                                echo "${security_key}" | grep -q '\"\|\$\|\&\|/\||\|\\'
								if [ $? == 0 ]; then
									echo $security_key > /tmp/pwd
									sed -i 's/\\/\\\\/g' /tmp/pwd
									sed -i 's/"/\\"/g' /tmp/pwd
									sed -i 's/\$/\\$/g' /tmp/pwd
									sed -i 's/&/\\&/g' /tmp/pwd
									sed -i 's/\//\\\//g' /tmp/pwd
									sed -i 's/|/\\|/g' /tmp/pwd
									security_key=`cat /tmp/pwd`
									rm /tmp/pwd
								fi
								disconnectime=1
                                ;;
        --security_mode )       shift
                                security_mode="$2"
                                #if [ "$security_mode" == "WEP" ]; then
                                #	if [ `expr $(echo $security_key | wc -m) - 1` == 5 ] || [ `expr $(echo $security_key | wc -m) - 1` == 10 ] || [ `expr $(echo $security_key | wc -m) - 1` == 13 ] || [ `expr $(echo $security_key | wc -m) - 1` == 26 ]; then
                                #	  secure=true
                                #	  key_security_mode=WEP
                                #  else
                                #   exit 1
                                #  fi
                                #fi
                                #if [ "$security_mode" == "WPA" ] || [ "$security_mode" == "WPA2" ] || [ "$security_mode" == "WPA-AUTO" ]; then
                                # 	if [ `expr $(echo $security_key | wc -m) - 1` -ge 8 ] && [ `expr $(echo $security_key | wc -m) - 1` -le 63 ]; then
                                #	  secure=true
                                #	  key_security_mode=$security_mode
                                #  	else
                                #   		exit 1
                                #  	fi
                                #fi
                                #if [ "$security_mode" == "NONE" ]; then
                                #	if [ "$security_key" != "" ]; then
                                #		exit 1
                                #	else
                                #		key_security_mode=$security_mode
                                #	fi
                                #fi
                                disconnectime=1
                                ;;
   		--ip )       			shift
       							ipaddr="$2"
       							disconnectime=1
       							;;						
       	--netmask )				shift
       							netmask="$2"
       							disconnectime=1
       							;;
       	--channel_mode )        shift
       							ChannelMode="$2"
       							if [ "$ChannelMode" != "auto" ] && [ "$ChannelMode" != "manual" ]; then
       								exit 1	
       							fi 
       							;;
        --channel )				shift
        						wifichannel="$2"
        						if [ ${wifichannel} -lt ${borderChannel_L} ] || [ ${wifichannel} -gt ${borderChannel_R} ]; then
        							exit 1
        						fi 
        						;;
		--network_mode )		shift
        						wifi_mode="$2"
        						if [ "${wifi_mode}" != "bgn" ] && [ "${wifi_mode}" != "bg" ] && [ "${wifi_mode}" != "b" ]; then
        							exit 1
        						fi 
        						;;  
        --enable_dhcp )			shift
        						dhcp_server="$2"
        						if [ "${dhcp_server}" != "true" ] && [ "${dhcp_server}" != "false" ]; then
        							exit 1
        						fi
        						disconnectime=1
        						;;						     
        * )                     echo "wifi_ap_set_config.sh --enabled <true | false> [ --ssid <value> ] [ --broadcast <value> ] [ --security_key <value> ] [ --security_mode <value> ] [--channel <value>] [--static_ip <value>] [--subnet_mask <value>] [--network_mode <value>] [--channel_mode <value>]"
                                exit 1
                                ;;
    esac
    shift
	done
elif [ "$hotspot" == "EnabledHomeNetwork" ]; then
	#/etc/init.d/S60hostapd restart
	#/etc/init.d/S60hostapd restart
	#/etc/init.d/S60hostapd restart
	#/usr/sbin/dhcpd -q wlan1
	/sbin/wifi-restart AP 
	
	#/etc/init.d/S91upnp restart
	exit 0
elif [ "$hotspot" == "LeaveHomeNetwork" ]; then
	ifconfig wlan1 down
	killall dhcpd
	killall hostapd
	/etc/init.d/S91upnp restart
	exit 0
	
else
	echo "wifi_ap_set_config.sh --enabled <true | false> [ --ssid <value> ] [ --broadcast <value> ] [ --security_key <value> ] [ --security_mode <value> ] [--channel <value>] [--static_ip <value>] [--subnet_mask <value>] [--network_mode <value>] [--channel_mode <value>]"
	exit 1
fi

#checking security mode & security key

if [ "${security_mode}" == "NONE" ]; then
	if [ `expr $(echo "$security_key" | wc -m) - 1` -ne 0 ]; then
		exit 1
	else 
		secure=false
		security_key=""
		emptykey="sed -i 's/AP_ENCRYPTION_KEY=.*/AP_ENCRYPTION_KEY=/' /etc/nas/config/wifinetwork-param.conf"
		eval $emptykey
		key_security_mode=$security_mode
	fi
fi

if [ "${security_mode}" != "" ] && [ "${security_key}" != "" ]; then
	securitype=`echo ${security_mode} | awk -F/ '{print $1}'`
	ciphertype=`echo ${security_mode} | awk -F/ '{print $2}'`
	
	if [ "$securitype" == "WPAPSK" ] || [ "$securitype" == "WPA2PSK" ] || [ "$securitype" == "WPAPSK1WPAPSK2" ]; then
		if [ `expr $(echo "$security_key" | wc -m) - 1` -ge 8 ] && [ `expr $(echo "$security_key" | wc -m) - 1` -le 63 ]; then
      		secure=true
        	key_security_mode=$securitype
    	else
    		exit 4
    	fi
	elif [ "$securitype" == "WEP" ]; then
    	if [ `expr $(echo "$security_key" | wc -m) - 1` == 5 ] || [ `expr $(echo "$security_key" | wc -m) - 1` == 10 ] || [ `expr $(echo "$security_key" | wc -m) - 1` == 13 ] || [ `expr $(echo "$security_key" | wc -m) - 1` == 26 ]; then
    		if [ `expr $(echo "$security_key" | wc -m) - 1` == 10 ] || [ `expr $(echo "$security_key" | wc -m) - 1` == 26 ]; then
    			for ((index=1; index<=`expr $(echo "$security_key" | wc -m) - 1`; index++ )); do
    				character=`echo "${security_key}" | sed 's/\(.\{1\}\)/\1 /g' | awk -v num=$index '{print $num}'`
    				echo ${character} | grep -q -v '[A-Fa-f0-9]'
    				if [ $? == 0 ]; then
						#echo "not allowed characters "
						exit 5
					fi
    			done
    		fi
    		secure=true
        	key_security_mode=$securitype
    	else
    		exit 6
    	fi
	fi
	
elif [ "${security_mode}" == "" ] && [ "${security_key}" != "" ]; then
	
	if [ "${AP_ENCRYPTION_TYPE}" == "WPAPSK" ] || [ "${AP_ENCRYPTION_TYPE}" == "WPA2PSK" ] || [ "${AP_ENCRYPTION_TYPE}" == "WPAPSK1WPAPSK2" ]; then
		if [ `expr $(echo $security_key | wc -m) - 1` -ge 8 ] && [ `expr $(echo $security_key | wc -m) - 1` -le 63 ]; then
      		secure=true
    	else
    		exit 4
    	fi

	elif [ "${AP_ENCRYPTION_TYPE}" == "WEP" ]; then
    	if [ `expr $(echo "$security_key" | wc -m) - 1` == 5 ] || [ `expr $(echo "$security_key" | wc -m) - 1` == 10 ] || [ `expr $(echo "$security_key" | wc -m) - 1` == 13 ] || [ `expr $(echo "$security_key" | wc -m) - 1` == 26 ]; then
    		if [ `expr $(echo "$security_key" | wc -m) - 1` == 10 ] || [ `expr $(echo "$security_key" | wc -m) - 1` == 26 ]; then
    			for ((index=1; index<=`expr $(echo "$security_key" | wc -m) - 1`; index++ )); do
    				character=`echo "${security_key}" | sed 's/\(.\{1\}\)/\1 /g' | awk -v num=$index '{print $num}'`
    				echo "${character}" | grep -q -v '[A-Fa-f0-9\ ]'
    				if [ $? == 0 ]; then
						#echo "not allowed characters "
						exit 5
					fi
    			done
    		fi
    		secure=true
    	else
    		exit 6
    	fi
	fi

elif [ "${security_mode}" != "" ] && [ "${security_key}" == "" ]; then
	securitype=`echo ${security_mode} | awk -F/ '{print $1}'`
	ciphertype=`echo ${security_mode} | awk -F/ '{print $2}'`

	if [ "${securitype}" == "WPAPSK" ] || [ "${securitype}" == "WPA2PSK" ] || [ "${securitype}" == "WPAPSK1WPAPSK2" ]; then
		if [ `expr $(echo $AP_ENCRYPTION_KEY | wc -m) - 1` -ge 8 ] && [ `expr $(echo $AP_ENCRYPTION_KEY | wc -m) - 1` -le 63 ]; then
      		secure=true
      		key_security_mode=$securitype
    	else
    		exit 4
    	fi

	elif [ "${securitype}" == "WEP" ]; then
    	if [ `expr $(echo $AP_ENCRYPTION_KEY | wc -m) - 1` == 5 ] || [ `expr $(echo $AP_ENCRYPTION_KEY | wc -m) - 1` == 10 ] || [ `expr $(echo $AP_ENCRYPTION_KEY | wc -m) - 1` == 13 ] || [ `expr $(echo $AP_ENCRYPTION_KEY | wc -m) - 1` == 26 ]; then
    		if [ `expr $(echo $AP_ENCRYPTION_KEY | wc -m) - 1` == 10 ] || [ `expr $(echo $AP_ENCRYPTION_KEY | wc -m) - 1` == 26 ]; then
    			for ((index=1; index<=`expr $(echo $AP_ENCRYPTION_KEY | wc -m) - 1`; index++ )); do
    				character=`echo ${AP_ENCRYPTION_KEY} | sed 's/\(.\{1\}\)/\1 /g' | awk -v num=$index '{print $num}'`
    				echo ${character} | grep -q -v '[A-Fa-f0-9]'
    				if [ $? == 0 ]; then
						#echo "not allowed characters "
						exit 5
					fi
    			done
    		fi
    		secure=true
    		key_security_mode=$securitype
    	else
    		exit 6
    	fi
	fi
fi
  
sync  

if [ ! -f "/etc/nas/config/wifinetwork-param.conf" ]; then
	cp -a /etc/nas/config/wifinetwork-param.default.conf /etc/nas/config/wifinetwork-param.conf
	. /etc/nas/config/wifinetwork-param.conf 2>/dev/null
else
	Apinface=`cat /etc/nas/config/wifinetwork-param.conf | grep -rsw AP_IFACE`
	Cliinface=`cat /etc/nas/config/wifinetwork-param.conf | grep STA_IFACE`

	if [ "$Apinface" != "AP_IFACE=wlan1" ] || [ "$Cliinface" != "STA_IFACE=wlan0" ]; then
		cp -a /etc/nas/config/wifinetwork-param.default.conf /etc/nas/config/wifinetwork-param.conf
		. /etc/nas/config/wifinetwork-param.conf 2>/dev/null
	fi
fi

sed -i 's/AP_HOTSPOT=.*/AP_HOTSPOT=true/' /etc/nas/config/wifinetwork-param.conf
if [ "$ssid" != "" ]; then
#	sed -i 's/AP_SSID_NAME=.*/AP_SSID_NAME='\""${AP_SSID_NAME}"\"'/' /etc/nas/config/wifinetwork-param.conf
#else
	sed -i 's/AP_SSID_NAME=.*/AP_SSID_NAME='\""${ssid}"\"'/' /etc/nas/config/wifinetwork-param.conf
	sed -i '/AP_SSID_NAME/ s/\\/\\\\/g' /etc/nas/config/wifinetwork-param.conf
	sed -i '/AP_SSID_NAME/ s/"/\\"/g' /etc/nas/config/wifinetwork-param.conf
	sed -i '/AP_SSID_NAME/ s/\$/\\$/g' /etc/nas/config/wifinetwork-param.conf
	sed -i '/AP_SSID_NAME/ s/\\"/"/' /etc/nas/config/wifinetwork-param.conf
	sed -i '/AP_SSID_NAME/ s/`/\\`/g' /etc/nas/config/wifinetwork-param.conf
	sed -i '/AP_SSID_NAME/ s/\(.*\)\\"/\1"/' /etc/nas/config/wifinetwork-param.conf		
fi
 		
if [ "$b_broadcast" == "" ]; then
	sed -i 's/AP_BROADCAST=.*/AP_BROADCAST='${AP_BROADCAST}'/' /etc/nas/config/wifinetwork-param.conf
else
	sed -i 's/AP_BROADCAST=.*/AP_BROADCAST='${b_broadcast}'/' /etc/nas/config/wifinetwork-param.conf
fi
if [ "$key_security_mode" == "" ]; then
	sed -i 's/AP_ENCRYPTION_TYPE=.*/AP_ENCRYPTION_TYPE='${AP_ENCRYPTION_TYPE}'/' /etc/nas/config/wifinetwork-param.conf
else
	sed -i 's/AP_ENCRYPTION_TYPE=.*/AP_ENCRYPTION_TYPE='${key_security_mode}'/' /etc/nas/config/wifinetwork-param.conf
fi
if [ "$ciphertype" == "" ]; then
	sed -i 's/AP_CIPHER_TYPE=.*/AP_CIPHER_TYPE='${AP_CIPHER_TYPE}'/' /etc/nas/config/wifinetwork-param.conf
else
	sed -i 's/AP_CIPHER_TYPE=.*/AP_CIPHER_TYPE='${ciphertype}'/' /etc/nas/config/wifinetwork-param.conf
fi
#if [ "$security_key" == "" ]; then
#	if [ "${security_mode}" != "NONE" ]; then
#		sed -i 's/AP_ENCRYPTION_KEY=.*/AP_ENCRYPTION_KEY='\"${AP_ENCRYPTION_KEY}\"'/' /etc/nas/config/wifinetwork-param.conf
#	fi
#else

if [ "$security_key" != "" ]; then
	sed -i 's/AP_ENCRYPTION_KEY=.*/AP_ENCRYPTION_KEY='\""${security_key}"\"'/' /etc/nas/config/wifinetwork-param.conf
	sed -i '/AP_ENCRYPTION_KEY/ s/\\/\\\\/g' /etc/nas/config/wifinetwork-param.conf
	sed -i '/AP_ENCRYPTION_KEY/ s/"/\\"/g' /etc/nas/config/wifinetwork-param.conf
	sed -i '/AP_ENCRYPTION_KEY/ s/\$/\\$/g' /etc/nas/config/wifinetwork-param.conf
	sed -i '/AP_ENCRYPTION_KEY/ s/\\"/"/' /etc/nas/config/wifinetwork-param.conf
	sed -i '/AP_ENCRYPTION_KEY/ s/`/\\`/g' /etc/nas/config/wifinetwork-param.conf
	sed -i '/AP_ENCRYPTION_KEY/ s/\(.*\)\\"/\1"/' /etc/nas/config/wifinetwork-param.conf	
fi

if [ "$ipaddr" == "" ]; then
	sed -i 's/AP_IP=.*/AP_IP='${AP_IP}'/' /etc/nas/config/wifinetwork-param.conf
else
	sed -i 's/AP_IP=.*/AP_IP='${ipaddr}'/' /etc/nas/config/wifinetwork-param.conf
fi

if [ "$netmask" == "" ]; then
	sed -i 's/AP_MASK=.*/AP_MASK='${AP_MASK}'/' /etc/nas/config/wifinetwork-param.conf
else
	sed -i 's/AP_MASK=.*/AP_MASK='${netmask}'/' /etc/nas/config/wifinetwork-param.conf
fi

if [ "$ChannelMode" == "auto" ]; then 
	if [ "$AP_CHANNEL" != "0" ]; then
       wifichannel=0
       if [ -f "/tmp/CurrentChannel" ]; then
       		rm /tmp/CurrentChannel
       fi
    fi
fi

if [ "$wifichannel" == "" ]; then
	sed -i 's/AP_CHANNEL=.*/AP_CHANNEL='${AP_CHANNEL}'/' /etc/nas/config/wifinetwork-param.conf
else
	sed -i 's/AP_CHANNEL=.*/AP_CHANNEL='${wifichannel}'/' /etc/nas/config/wifinetwork-param.conf
fi

if [ "$dhcp_server" == "" ]; then
	sed -i 's/AP_DHCPD_ENABLE=.*/AP_DHCPD_ENABLE='${AP_DHCPD_ENABLE}'/' /etc/nas/config/wifinetwork-param.conf
else
	sed -i 's/AP_DHCPD_ENABLE=.*/AP_DHCPD_ENABLE='${dhcp_server}'/' /etc/nas/config/wifinetwork-param.conf
fi

if [ "$wifi_mode" == "" ]; then
	if [ "$AP_NETWORK_MODE" == "" ]; then 
		echo "AP_NETWORK_MODE=bgn" >> /etc/nas/config/wifinetwork-param.conf
	else
		sed -i 's/AP_NETWORK_MODE=.*/AP_NETWORK_MODE='${AP_NETWORK_MODE}'/' /etc/nas/config/wifinetwork-param.conf
	fi
else
	if [ "$AP_NETWORK_MODE" == "" ]; then 
		echo "AP_NETWORK_MODE="$wifi_mode >> /etc/nas/config/wifinetwork-param.conf
	else
		sed -i 's/AP_NETWORK_MODE=.*/AP_NETWORK_MODE='${wifi_mode}'/' /etc/nas/config/wifinetwork-param.conf
	fi
fi

#killall dhcpd
#killall hostapd
if [ "$hotspot" == "true" ]; then
	#/etc/init.d/S60hostapd restart
	#/etc/init.d/S60hostapd restart
	#/etc/init.d/S60hostapd restart
	if [ "$disconnectime" == "1" ]; then
		/sbin/wifi-restart AP LONGDELAY &
	else
		/sbin/wifi-restart AP &
	fi
#	RestartService
#		/etc/init.d/S60hostapd start
#	if [ "$AP_DHCPD_ENABLE" == "true" ]; then
#		/usr/sbin/dhcpd -q wlan1
#	else
#		ifconfig wlan1 $AP_IP $AP_MASK
#	fi
if [ "$ChannelMode" == "manual" ]; then 
	 if [ -f "/tmp/CurrentChannel" ]; then
       		rm /tmp/CurrentChannel
       	fi
fi
fi
/usr/local/sbin/incUpdateCount.pm wifi_ap &
exit 0
# Remove the switches we parsed above.
#shift `expr $OPTIND - 1`

# We want at least one non-option argument. 
# Remove this block if you don't need it.
#if [ $# -eq 0 ]; then
#    echo $USAGE >&2
#    exit 1
#fi

# Access additional arguments as usual through 
# variables $@, $*, $1, $2, etc. or using this loop:
#for PARAM; do
#    echo $PARAM
#done

# EOF

