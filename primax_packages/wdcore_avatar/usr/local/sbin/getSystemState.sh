#! /bin/sh
#
# � 2010 Western Digital Technologies, Inc. All rights reserved.
#
# getSystemState.sh
# 	get current system state
#
#

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

. /etc/nas/config/share-param.conf

if [ -f /tmp/ready ]; then
	echo "ready"
else
	echo "initializing"
fi





