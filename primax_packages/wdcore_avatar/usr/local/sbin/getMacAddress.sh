#!/bin/sh
#
# © 2010 Western Digital Technologies, Inc. All rights reserved.
#

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
. /etc/nas/config/wifinetwork-param.conf 2>/dev/null

#ifconfig | grep ^wlan1| awk '{ print $5 }'
iw dev wlan0 info | grep "addr" | awk '{print $2}' | tr [:lower:] [:upper:]
exit 0



	

