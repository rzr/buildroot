#!/bin/sh
enabled=$1
ACMode=`cat /tmp/battery | cut -d " " -f 1`

if [ "${enabled}" == "true" ] || [ "${enabled}" == "false" ]; then
    if [ "${enabled}" == "false" ]; then
        if [ -f /tmp/wipe-status ];then
            status=`cat /tmp/wipe-status`
            if [ "$status" == "insufficient_power" ]; then
                rm -f /tmp/wipe-status
            fi
        fi
    fi
    /usr/local/sbin/setMediaCrawlerPowerMode.sh ${enabled} & > /dev/null 2> /dev/null
    /etc/init.d/S98powerprofile restart
    echo -n "Stop SWAP sevice: "
    /sbin/EnableDisableSwap.sh disable
    echo "done"
    echo -n "Starting SWAP sevice: "
    if [ "${ACMode}" == "charging" ] ; then
        /sbin/EnableDisableSwap.sh enable
    fi
    exit 0
else
    echo "SetPowerProfile.sh true | false"
    exit 1
fi

