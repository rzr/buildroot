#!/bin/sh
#
# � 2010 Western Digital Technologies, Inc. All rights reserved.
#
# getSmartStatus.sh 
#
#
PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

. /etc/nas/config/share-param.conf
. /etc/system.conf

dfout=`df | grep /DataVolume`
percent=`echo "$dfout" | awk '{printf("%.0f\n",($3*100/$2 + 1)) }'`
echo $percent
