#!/bin/sh
#
# � 2014 Western Digital Technologies, Inc. All rights reserved.
#

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

source /etc/system.conf

if [ ! -f "/tmp/HDSerial" ]; then
    HDSerial=`hdparm -I \`cat /tmp/HDDDevNode\` | sed -n -e 's/.*Serial Number:\(.*\)/\1/p' | sed -e 's/^[ \t]*//' | awk '{gsub("WD-","",$0); print $0}'`
    echo "$HDSerial" > /tmp/HDSerial
    echo "$HDSerial"
else
    cat /tmp/HDSerial
fi

