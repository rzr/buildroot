#!/bin/bash
#
# � 2014 Primax Technologies, Inc. All rights reserved.
#
# InternetAccess.sh 
#
#  
#   
#

#---------------------

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

#---------------------
# Begin Script
#---------------------
source /etc/system.conf

TestService="$1"

if [ "$TestService" == "" ]; then
	if [ ! -d "/tmp/avahi_service/AvahiService" ]; then
		echo "creat "
		mkdir -p /etc/avahi/AvahiService 
	fi
	#cd /etc/avahi/
	if [ -d "/tmp/avahi_service/services" ]; then
		rm -rf /tmp/avahi_service/
		mkdir -p /tmp/avahi_service/services
	fi
	cp -a /etc/avahi/services/afpd.service /tmp/avahi_service/services/
	
elif [ "$TestService" == "All" ]; then
	#cd /etc/avahi/
	if [ -d "/tmp/avahi_service/services" ]; then
		rm -rf /tmp/avahi_service/
		
	fi
	mkdir -p /tmp/avahi_service/services
    chmod 755 /tmp/avahi_service/
	cp -a /etc/avahi/services/web.service /tmp/avahi_service/services/
	cp -a /etc/avahi/services/wd2go.service /tmp/avahi_service/services/
	cp -a /etc/avahi/services/smb.service /tmp/avahi_service/services/
	cp -a /etc/avahi/services/ssh.service /tmp/avahi_service/services/
	cp -a /etc/avahi/services/sftp-ssh.service /tmp/avahi_service/services/
	#cp -a /etc/avahi/services/daap.service /etc/avahi/services/
	cp -a /etc/avahi/services/afpd.service /tmp/avahi_service/services/
	#cp -a /etc/avahi/services/adisk.service /tmp/avahi_service/services/
	rm -rf /etc/avahi/AvahiService 
	
	SerialNumeber=`/usr/local/sbin/getSerialNumber.sh`
	if [ "$SerialNumeber" != ""  ]; then
		sed -i 's/serialNumber=.*/serialNumber='$SerialNumeber'\<\/txt-record\>/' /tmp/avahi_service/services/web.service
		sed -i 's/serialNumber=.*/serialNumber='$SerialNumeber'\<\/txt-record\>/' /tmp/avahi_service/services/wd2go.service
	else
		echo "Serial Number not ready to read."
	fi
	sed -i 's/modelNumber=.*/modelNumber='${modelNumber}'\<\/txt-record\>/' /tmp/avahi_service/services/web.service
	sed -i 's/modelNumber=.*/modelNumber='${modelNumber}'\<\/txt-record\>/' /tmp/avahi_service/services/wd2go.service
	
	/etc/init.d/S50avahi-daemon restart
fi


#---------------------
# End Script
#---------------------
