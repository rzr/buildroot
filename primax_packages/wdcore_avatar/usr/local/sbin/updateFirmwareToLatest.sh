#!/bin/bash
#
# � 2013 Western Digital Technologies, Inc. All rights reserved.
#
# updateFirmwareToLatest.sh reboot | {imagelink} | {imagelink} download | install
#

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
. /etc/nas/config/share-param.conf
. /etc/system.conf
#[ -f /usr/local/sbin/ledConfig.sh ] && . /usr/local/sbin/ledConfig.sh


logtag="`basename $0`:`date -u +"%D %T"`:"
logger -s -t "${logtag}" "( $@ )"

OPT_REBOOT=""
OPT_LINK=""

if [ "${1}" == "reboot" ]; then
    OPT_REBOOT='true'
    OPT_LINK="${2}"
else
    OPT_LINK="${1}"
    if [ "${2}" == "reboot" ]; then
        OPT_REBOOT='true'
    fi
fi


FW_DOWNLOAD_MUTEX=/tmp/fw_download_mutex
CHECK_FILESIZE="check_filesize"

[ -f ${FW_DOWNLOAD_MUTEX} ] && exit 0
touch ${FW_DOWNLOAD_MUTEX}

if [ -z "${OPT_LINK}" ]; then
    if [ -s "${upgrade_link}" ]; then
        cat "${upgrade_link}" > /tmp/update_url
    else
        logger -s -t "$0" "no upgrade"
        rm -f ${FW_DOWNLOAD_MUTEX}
        exit 1;
    fi
else
    echo "${OPT_LINK}" > /tmp/update_url
	CHECK_FILESIZE=""
fi

update_site=`cat /etc/fwupdate.conf`
model=$modelNumber
current_version=`cat /etc/version`
update_file="/var/tmp/updateFile.deb"

# delete any old update files
rm -f ${update_file}

# check disk usage
fwUpdateSpace=`echo 209715200`
dfout=`df -B 1 /var/tmp | sed -e /Filesystem/d`
avail=`echo "$dfout" | awk '{print $2-$3}'`
if [ "${avail}" -lt "${fwUpdateSpace}" ] ; then
    error="failed 201 \"not enough space on device for upgrade\""
    echo  ${error} > /tmp/fw_update_status
    echo ${error} 
    rm -f ${FW_DOWNLOAD_MUTEX}
    exit 1
fi

echo "downloading" > /tmp/fw_update_status
sleep 1
curl -4 "`cat /tmp/update_url`" > ${update_file} 2>/tmp/fw_download_status
status=$?
if [ $status != 0 ]; then
    # set error status for update errors
    error="failed 202 \"failed to get FW link for upgrade\""
    echo  ${error} > /tmp/fw_update_status
    echo ${error} 
    rm -f /tmp/update_url
    rm -f ${update_file}
    rm -f ${FW_DOWNLOAD_MUTEX}
    exit $status
fi

# check that update_file actually exists before starting update sequence
if [ -s ${update_file} ]; then
    #ledCtrl.sh LED_EV_FW_UPDATE LED_STAT_IN_PROG
    #send alert for firmware downloaded
    clearAlerts.sh 2001
    sendAlert.sh 2002
    echo "" > /FWupgfromInternet
    updateFirmwareFromFile.sh ${update_file} ${CHECK_FILESIZE}
    status=$?
fi 

rm -f /tmp/update_url
rm -f ${update_file}
rm -f ${FW_DOWNLOAD_MUTEX}

if [ $status == 0 ]; then
    if [ "${OPT_REBOOT}" == "reboot" ]; then
        reboot;
    fi
fi

exit $status
