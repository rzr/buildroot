#!/bin/sh
#
# (c) 2013 Western Digital Technologies, Inc. All rights reserved.
#
# getTemperatureStatus.sh
#
#
PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
source /etc/nas/config/wifinetwork-param.conf


timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
echo $timestamp ": Disconnect from" $@ >> /tmp/WifiApConnection.log


