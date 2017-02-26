#!/bin/bash
#
# � 2010 Western Digital Technologies, Inc. All rights reserved.
#
# wifi_client_ap_scan.sh
#
#


PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
. /etc/nas/config/share-param.conf
source /etc/nas/config/wifinetwork-param.conf
#connectedessid=`iwconfig wlan0 | grep ESSID | awk -F: '{print $2}' | cut -d '"' -f 2`
#connectStatus=`iw dev wlan0 link | grep wlan0 | awk '{print $3}'`
start_scan=0
tempDisable=1
currentstate=0
connectStatus="INACTIVE"

if [ "$STA_CLIENT" == "true" ]; then 
	echo 1 > /tmp/clientStatus
	targetNum=`cat /etc/nas/config/wifinetwork-remembered.conf | wc -l`
	if [ "$targetNum" != "0" ]; then
   		for ((scanwait=1; scanwait<5; scanwait++ )); do
   			pidnum=`pidof wpa_supplicant`
   			if [ "$pidnum" != "" ]; then
   				wpa_cli -i wlan0 status > /dev/null
   				if [ $? == "0" ]; then
   					echo 1 > /tmp/clientStatus
   					break		
   				fi
   			fi
			sleep 2
		done
	fi
    
	connectStatus=`wpa_cli -i wlan0 status | grep -rsi wpa_state | awk -F= '{print $NF}'`
	if [ "$connectStatus" != "COMPLETED" ]; then
		`wpa_cli -i wlan0 disable_network 0 > /dev/null`
	fi
else
	/sbin/ifconfig wlan0 up > /dev/null
fi

if [ "$1" == "" ]; then
  b_all=true
  start_scan=1
fi

while [ "$1" != "" ]; do
   case $1 in
       --current )             shift
                               b_current=true
                               b_remembered=false
                               if [ ! -f "/tmp/scan_result" ]; then
									start_scan=1
							   fi
                               ;;
       --remembered )          shift
                               b_remembered=true
                               b_current=false
                               para1=$1
                               start_scan=1
                               ;;
       --mac )                 shift
                               b_mac=true
                               b_current=false
                               b_remembered=false
                               string_mac=$1
                               start_scan=1
                               #if [ ! -f "/tmp/scan_result" ]; then
							   #		start_scan=1
							   #fi
                               ;;
       * )                     echo "/usr/local/sbin/wifi_client_ap_scan.sh --current or /usr/local/sbin/ wifi_client_ap_scan.sh --remembered"
                               if [ "$tempDisable" == "1" ]; then
    								rm /tmp/clientStatus
    								if [ "$STA_CLIENT" == "true" ]; then 
									wpa_cli -i wlan0 enable_network 0 > /dev/null
								fi
								fi
                               exit 1
                               ;;
   esac
   shift
done

if [ "$start_scan" == "1" ]; then	

	for ((index=1; index<4; index++ )); do
    	iwlist wlan0 scan > /tmp/iwlist
    	cat /tmp/iwlist | awk -f /usr/sbin/parse-iwlist.awk > /tmp/scan_temp1
    	needretry=`cat /tmp/scan_temp1`
    	if [ "$needretry" != "" ]; then
			cat /tmp/scan_temp1 > /tmp/scan_temp  	
			break
    	else
    		sleep 5
    	fi
    	#sleep 1
    done
   	
    #emptyscan=`cat /tmp/scan_temp | wc -l`
	if [ -f "/tmp/scan_temp" ]; then
		if [ -f "/tmp/scan_temp_1" ]; then
			rm /tmp/scan_temp_1
		fi
		if [ -f "/tmp/scan_result" ]; then
			rm /tmp/scan_result
		fi
		
		#cat /etc/nas/config/wifinetwork-remembered.conf > /tmp/scan_result
		sed -i 's/connected="true"./connected="false" /' /etc/nas/config/wifinetwork-remembered.conf
		#sed -i 's/connected="true"./connected="false" /' /tmp/scan_result
		if [ "$connectStatus" == "COMPLETED" ]; then
			connectedessid=`wpa_cli -i wlan0 status | grep -rsw "bssid" | awk -F= '{print $NF}' | tr [:lower:] [:upper:]`
			connectedemac=`wpa_cli -i wlan0 status | grep -rsw "ssid" | awk -F= '{print $NF}' > /tmp/connectedemac`
			sed -i 's/\\\\/\\/g' /tmp/connectedemac
			sed -i 's/\\"/"/g' /tmp/connectedemac
			connectedemac=`cat /tmp/connectedemac`
			rm /tmp/connectedemac		
		fi	
		RememberNum=`cat /etc/nas/config/wifinetwork-remembered.conf | wc -l`
		if [ "$RememberNum" != "0" ]; then
			sort -t '"' -k 6 -r -n /tmp/scan_temp > /tmp/scantmp
			cat /tmp/scantmp > /tmp/scan_temp
			rm /tmp/scantmp
			scancopy=0
			ScanSTANum=`cat /tmp/scan_temp | wc -l`
			cat /etc/nas/config/wifinetwork-remembered.conf | while read RemProfile
			do
				RememberMatch=0
				echo $RemProfile > /tmp/wifinetwork-remembered_tmp.conf
				rememberSsid=`echo ${RemProfile} | awk 'BEGIN{FS=" mac=" }{print $1}' | cut -d '=' -f 2`
				rememberMAC=`echo ${RemProfile} | awk 'BEGIN{FS="mac=" } {print $NF}' | cut -d '"' -f 2`
				rememberSignal=`echo $RemProfile | awk -F= '{print $4}' | cut -d '"' -f 2`
				if [ "$connectedessid" == "$rememberMAC" ] && [ "$rememberSsid" == "\"$connectedemac"\" ]; then
					Connected=1
				else
					Connected=0	
				fi
				sed -i 's/connected="true"./connected="false" /' /tmp/wifinetwork-remembered_tmp.conf
				sed -i 's/signal_strength='\""$rememberSignal"\"'./signal_strength="0" /' /tmp/wifinetwork-remembered_tmp.conf
				matchssid=`grep -rsnw "${rememberSsid}" /tmp/scan_temp | head -1`
				#update the remembered APs' information 
				if [ "${matchssid}" != "" ]; then
					lineNum=`echo "$matchssid" | cut -d ':' -f 1`
					#ApSignal=`echo "$matchssid" | cut -d ':' -f 2 | awk 'BEGIN{FS=" signal_strength=" }{print $2}'| cut -d ' ' -f 1`
					ApSignal=`echo "$matchssid" | awk 'BEGIN{FS=" signal_strength=" }{print $2}' | cut -d '"' -f 2`
					sed -i 's/signal_strength="0"./signal_strength='\""$ApSignal"\"' /' /tmp/wifinetwork-remembered_tmp.conf
					if [ "$Connected" == "1" ]; then
						sed -i 's/connected="false"./connected="true" /' /tmp/wifinetwork-remembered_tmp.conf
					fi
					cat /tmp/wifinetwork-remembered_tmp.conf >> /tmp/scan_temp_1
					sed ${lineNum}d /tmp/scan_temp > /tmp/ScanFile
					#echo "lineNum" $lineNum
					cat /tmp/ScanFile > /tmp/scan_temp
					rm /tmp/ScanFile					
					#cat /tmp/scan_temp_1 > /tmp/scan_temp 
					#rm /tmp/scan_temp_1  	
					
				else
					if [ "$Connected" == "1" ]; then
						sed -i 's/connected="false"./connected="true" /' /tmp/wifinetwork-remembered_tmp.conf
					fi
					cat /tmp/wifinetwork-remembered_tmp.conf >> /tmp/scan_temp_1 
				fi
			
				rm /tmp/wifinetwork-remembered_tmp.conf		
			done
			cat /tmp/scan_temp_1 > /tmp/scan_result
		fi
		#cat /tmp/wifinetwork-scanlist > /tmp/scan_result
		#rm /tmp/wifinetwork-scanlist
		#cat /etc/nas/config/wifinetwork-remembered.conf > /tmp/scan_result
		#sed -i 's/\\\\/\\/g' /tmp/scan_result
		cat /tmp/scan_temp >> /tmp/scan_result
		#rm /tmp/scan_temp
		#rm /tmp/scan_temp1
		#if [ "$b_remembered" != "true" ]; then
		#	rm /tmp/scan_temp_1
		#fi
	else
		cat /tmp/scan_result > /tmp/scan_temp
		cat /etc/nas/config/wifinetwork-remembered.conf > /tmp/scan_result
		sed -i 's/\\\\/\\/g' /tmp/scan_result
		cat /tmp/scan_temp >> /tmp/scan_result
		#rm /tmp/scan_temp
		#rm /tmp/scan_temp1
	fi
fi

if [ "$tempDisable" == "1" ]; then
	if [ -f /tmp/clientStatus ]; then
    	rm /tmp/clientStatus
    fi
    if [ "$STA_CLIENT" == "true" ]; then 
		wpa_cli -i wlan0 enable_network 0 > /dev/null
	else
		/sbin/ifconfig wlan0 down > /dev/null 
	fi
fi
	
if [ "$b_all" == "true" ]; then	
	sort -t '"' -k 6 -r -n /tmp/scan_result | awk 'BEGIN {FS="bssi/dmap="} {print $1}' > /tmp/scan_sort
	#sort -t "=" -k 1,2 -u -f /tmp/scan_sort 
	if [ -f "/tmp/scanlist" ]; then
		rm /tmp/scanlist
	fi
	
	touch /tmp/scanlist
	cat /tmp/scan_sort | while read sortProfile
	do
		ScanSsid=`echo ${sortProfile} | awk 'BEGIN{FS=" mac=" }{print $1}' | cut -d '=' -f 2`
		unicSsid=`grep -rsw "${ScanSsid}" /tmp/scanlist | tail -1`
		if [ "$unicSsid" == "" ]; then
			echo "${sortProfile}" >> /tmp/scanlist
		fi
	done
	sort -t "=" -k 1,2 -u -f /tmp/scanlist 
	exit 0
fi

if [ "$b_current" == "true" ]; then
	if [ -f "/tmp/wifi_client_remembered_execute" ]; then
		exit 0
	fi
	connectedCipher=`wpa_cli -i wlan0 status | grep -rsw "pairwise_cipher" | awk -F= '{print $NF}'`
	if [ "$connectedCipher" == "WEP-40" ] || [ "$connectedCipher" == "WEP-104" ]; then
		networkConfig=`/usr/local/sbin/getNetworkConfig.sh`
		if [ "$networkConfig" == "disconnected" ]; then
			exit 0
		fi
	fi
	
	if [ "$connectStatus" == "COMPLETED" ]; then
		sed -i 's/connected="true"./connected="false" /' /etc/nas/config/wifinetwork-remembered.conf
		connectedessid=`wpa_cli -i wlan0 status | grep -rsw "bssid" | awk -F= '{print $NF}' | tr [:lower:] [:upper:]`
		connectedemac=`wpa_cli -i wlan0 status | grep -rsw "ssid" | awk -F= '{print $NF}' > /tmp/connectedemac`
		sed -i 's/\\\\/\\/g' /tmp/connectedemac
		sed -i 's/\\"/"/g' /tmp/connectedemac
		connectedemac=`cat /tmp/connectedemac`
		rm /tmp/connectedemac
		if [ "connectedemac" != "" ] && [ "connectedessid" != "" ]; then
			cat /etc/nas/config/wifinetwork-remembered.conf | while read lineProfile
			do
				echo $lineProfile > /tmp/wifinetwork-remembered_tmp.conf
				rememberSsid=`echo ${lineProfile} | awk 'BEGIN{FS=" mac=" }{print $1}' | cut -d '=' -f 2`
				rememberMAC=`echo ${lineProfile} | awk 'BEGIN{FS="mac=" } {print $NF}' | cut -d '"' -f 2`
				#grep -rsi "\"${connectedessid}\"" /tmp/wifinetwork-remembered_tmp.conf | grep -rsw "${connectedemac}" /tmp/wifinetwork-remembered_tmp.conf > /dev/null
				if [ "$connectedessid" == "$rememberMAC" ] && [ "$rememberSsid" == "\"$connectedemac"\" ]; then
					sed -i '/'\""${connectedessid}"\"'/ s/connected="false"./connected="true" /' /tmp/wifinetwork-remembered_tmp.conf
					cat /tmp/wifinetwork-remembered_tmp.conf | awk 'BEGIN {FS="bssi/dmap="} {print $1}'
					rm /tmp/wifinetwork-remembered_tmp.conf
					touch /tmp/currentsuccess
					exit 0
				fi
				rm /tmp/wifinetwork-remembered_tmp.conf
			done
			#if [ ! -f "/tmp/currentsuccess" ]; then
			#	sed -i 's/connected="true"./connected="false" /' /tmp/wifinetwork-remembered.conf
			#	grep -rsw "\"${connectedemac}\"" /tmp/wifinetwork-remembered.conf > /dev/null
			#	if [ $? == 0 ]; then
			#		sed -i '/'"${connectedemac}"'/ s/mac="00:00:00:00:00:00" /mac='\"${connectedessid}\"' /' /tmp/wifinetwork-remembered.conf
			#		sed -i '/'\""${connectedessid}"\"'/ s/connected="false"./connected="true" /' /tmp/wifinetwork-remembered.conf
			#		grep -rsi "connected=\""true"\"" /tmp/wifinetwork-remembered.conf | awk 'BEGIN {FS="bssi/dmap="} {print $1}'
			#	else
			#		sed -i 's/connected="true"./connected="false" /' /tmp/scan_result
			#		grep -rsi "\"${connectedessid}\""  /tmp/scan_result > /dev/null
			#		if [ $? == 0 ]; then
			#			sed -i '/'\""${connectedessid}"\"'/ s/connected="false"./connected="true" /' /tmp/scan_result
			#			grep -rsi "connected=\""true"\"" /tmp/scan_result | awk 'BEGIN {FS="bssi/dmap="} {print $1}'
			#		fi
			#	fi
			#else
			#	rm /tmp/currentsuccess
			#fi
		fi
	fi
	exit 0
fi

if [ "$b_remembered" == "true" ]; then
	if [ "$para1" == "" ]; then
		cat /tmp/scan_temp_1 > /etc/nas/config/wifinetwork-remembered.conf
		cat /tmp/scan_temp_1 | awk 'BEGIN {FS="bssi/dmap="} {print $1}' | sort -t '"' -k 6 -r -n
	elif [ "$para1" == "signalConnect" ]; then
		cat /tmp/scan_temp_1
	fi
	#sed -i 's/connected="true"./connected="false" /' /etc/nas/config/wifinetwork-remembered.conf
	#sed -i 's/connected="true"./connected="false" /' /tmp/scan_result
	#if [ "$connectStatus" == "COMPLETED" ]; then
	#	connectedessid=`wpa_cli -i wlan0 status | grep -rsw "bssid" | awk -F= '{print $NF}' | tr [:lower:] [:upper:]`
	#	connectedemac=`wpa_cli -i wlan0 status | grep -rsw "ssid" | awk -F= '{print $NF}' > /tmp/connectedemac`
	#	sed -i 's/\\\\/\\/g' /tmp/connectedemac
	#	sed -i 's/\\"/"/g' /tmp/connectedemac
	#	connectedemac=`cat /tmp/connectedemac`
	#	rm /tmp/connectedemac
	#	cat /tmp/scan_temp_1 | while read lineProfile
	#	do
	#		echo $lineProfile > /tmp/wifinetwork-remembered_tmp.conf
	#		#grep -rsi "\"${connectedessid}\"" /tmp/wifinetwork-remembered_tmp.conf | grep -rsw "\"${connectedemac}\"" /tmp/wifinetwork-remembered_tmp.conf > /dev/null
	#		rememberSsid=`echo ${lineProfile} | awk 'BEGIN{FS=" mac=" }{print $1}' | cut -d '=' -f 2`
	#		rememberMAC=`echo ${lineProfile} | awk 'BEGIN{FS="mac=" } {print $NF}' | cut -d '"' -f 2`
	#		if [ "$connectedessid" == "$rememberMAC" ] && [ "$rememberSsid" == "\"$connectedemac"\" ]; then
	#			sed -i '/'\""${connectedessid}"\"'/ s/connected="false"./connected="true" /' /tmp/wifinetwork-remembered_tmp.conf
	#			cat /tmp/wifinetwork-remembered_tmp.conf >> /tmp/wifinetwork-scanlist	
	#		else
	#			echo $lineProfile >> /tmp/wifinetwork-scanlist	
	#		fi
	#		rm /tmp/wifinetwork-remembered_tmp.conf
	#	done
	#	cat /tmp/wifinetwork-scanlist | awk 'BEGIN {FS="bssi/dmap="} {print $1}' | sort -t '"' -k 6 -r -n
	#	rm /tmp/wifinetwork-scanlist
	#else
	#	cat /etc/nas/config/wifinetwork-remembered.conf | awk 'BEGIN {FS="bssi/dmap="} {print $1}' | sort -t '"' -k 6 -r -n
	#fi	
	exit 0
fi

if [ "$b_mac" == "true" ]; then	
	grep -rsi "$string_mac" /etc/nas/config/wifinetwork-remembered.conf > /dev/null
	if [ $? == 0 ]; then
		sed -i 's/connected="true"./connected="false" /' /etc/nas/config/wifinetwork-remembered.conf
		if [ "$connectStatus" == "COMPLETED" ]; then
			connectedessid=`wpa_cli -i wlan0 status | grep -rsw "bssid" | awk -F= '{print $NF}' | tr [:lower:] [:upper:]`
			if [ "$connectedCipher" == "WEP-40" ] || [ "$connectedCipher" == "WEP-104" ]; then
				networkConfig=`/usr/local/sbin/getNetworkConfig.sh`
				if [ "$networkConfig" != "disconnected" ]; then
					sed -i '/'\""${connectedessid}"\"'/ s/connected="false"./connected="true" /' /etc/nas/config/wifinetwork-remembered.conf	
				fi
			else
				sed -i '/'\""${connectedessid}"\"'/ s/connected="false"./connected="true" /' /etc/nas/config/wifinetwork-remembered.conf	
			fi
		fi
		grep -rsi "$string_mac" /etc/nas/config/wifinetwork-remembered.conf | awk 'BEGIN {FS="bssi/dmap="} {print $1}'
	else
		sed -i 's/connected="true"./connected="false" /' /tmp/scan_result
		if [ "$connectStatus" == "COMPLETED" ]; then
			connectedessid=`wpa_cli -i wlan0 status | grep -rsw "bssid" | awk -F= '{print $NF}' | tr [:lower:] [:upper:]`
			if [ "$connectedCipher" == "WEP-40" ] || [ "$connectedCipher" == "WEP-104" ]; then
				networkConfig=`/usr/local/sbin/getNetworkConfig.sh`
				if [ "$networkConfig" != "disconnected" ]; then
					sed -i '/'\""${connectedessid}"\"'/ s/connected="false"./connected="true" /' /tmp/scan_result
				fi
			else
				sed -i '/'\""${connectedessid}"\"'/ s/connected="false"./connected="true" /' /tmp/scan_result
			fi
		fi
		grep -rsi "$string_mac" /tmp/scan_result | sort -t " " -k 1,2 -u | awk 'BEGIN {FS="bssi/dmap="} {print $1}'
	fi
	exit 0
fi


# EOF

