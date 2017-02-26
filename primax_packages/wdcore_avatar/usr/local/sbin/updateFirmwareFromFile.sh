#!/bin/bash
#
# � 2010 Western Digital Technologies, Inc. All rights reserved.
#
# updateFirmwareFromFile.sh <filename> [check_filesize]"
#

# prepare for starup all process
start_all_services()
{
    [ -e /etc/init.d/S50avahi-daemon ]    && /etc/init.d/S50avahi-daemon start 2>/dev/null
    [ -e /etc/init.d/S50netatalk ]        && /etc/init.d/S50netatalk start 2>/dev/null
    [ -e /etc/init.d/S70vsftpd ]          && /etc/init.d/S70vsftpd start 2>/dev/null
    [ -e /etc/init.d/S85wdmcserverd ]     && /etc/init.d/S85wdmcserverd start 2>/dev/null
    [ -e /etc/init.d/S91smb ]             && /etc/init.d/S91smb start 2>/dev/null
    [ -e /etc/init.d/S92twonkyserver ]    && /etc/init.d/S92twonkyserver start 2>/dev/null
    [ -e /etc/init.d/S92wdnotifierd ]     && /etc/init.d/S92wdnotifierd start 2>/dev/null
    [ -e /etc/init.d/S95RestAPI ]         && /etc/init.d/S95RestAPI start 2>/dev/null
    [ -e /etc/init.d/S95lld2d ]           && /etc/init.d/S95lld2d start 2>/dev/null
    [ -e /etc/init.d/S99crond ]           && /etc/init.d/S99crond start 2>/dev/null
}

# prepare for shutdown process
shutdown_all_services()
{
    [ -e /etc/init.d/S99crond ]           && /etc/init.d/S99crond stop 2>/dev/null
    [ -e /etc/init.d/S99rsynchk ]         && /etc/init.d/S99rsynchk stop 2>/dev/null
    [ -e /etc/init.d/S95lld2d ]           && /etc/init.d/S95lld2d stop 2>/dev/null
    [ -e /etc/init.d/S95RestAPI ]         && /etc/init.d/S95RestAPI stop 2>/dev/null
    [ -e /etc/init.d/S92wdnotifierd ]     && /etc/init.d/S92wdnotifierd stop 2>/dev/null
    [ -e /etc/init.d/S92twonkyserver ]    && /etc/init.d/S92twonkyserver stop 2>/dev/null
    [ -e /etc/init.d/S91smb ]             && /etc/init.d/S91smb stop 2>/dev/null
    [ -e /etc/init.d/S85wdmcserverd ]     && /etc/init.d/S85wdmcserverd stop 2>/dev/null
    [ -e /etc/init.d/S70vsftpd ]          && /etc/init.d/S70vsftpd stop 2>/dev/null
    [ -e /etc/init.d/S50netatalk ]        && /etc/init.d/S50netatalk stop 2>/dev/null
    [ -e /etc/init.d/S50avahi-daemon ]    && /etc/init.d/S50avahi-daemon stop 2>/dev/null
}

# post entries to updatelog
uplog()
{
    logtext=${@}
    logtag="`basename $0`:`date -u +"%D %T"`:"
    echo "${logtag}${logtext}" 2>&1 | tee -a ${updatelog}
}

# flag error after attempting to apply upgrade using dpkg
pre-update_error()
{
    errortext=${@}
    echo "Error fw_update_status: ${errortext}" 2>&1 | tee -a ${updatelog}
    echo  ${errortext} > /tmp/fw_update_status
    uplog ${errortext}
    rm -f ${FW_UPDATE_MUTEX}
    #send alert for firmware update fail
    sendAlert.sh 1003
    sleep 1
    echo "11;0;" > /tmp/MCU_Cmd
    start_all_services
    isFromWebUI=`echo "${filename}" | grep "/CacheVolume" | wc -l`
    if [ ${isFromWebUI} -eq "1" ]; then
        rm -f ${filename}
    fi
    exit 1
}

# prepare for pkg upgrades
pkg_upgrade_init()
{
    incUpdateCount.pm firmware_update
    sync
    sleep 2
    cat /etc/saveconfigfiles.txt | xargs tar cvf /etc/saveconfigfiles.tar
}

#
pkg_upgrade_exec()
{
    tar xvfz "${filename}" -C /tmp 2>&1
    if [ $? != "0" ]; then
        pre-update_error "failed 200 \"invalid firmware package\""
    fi
    if [ ! -f /tmp/fwupg_images/upgrade.sh ]; then
        pre-update_error "failed 200 \"invalid firmware package\""
    fi
    /tmp/fwupg_images/upgrade.sh 2>&1 | tee -a ${updatelog}
    status=$?
}

# flag error after attempting to apply upgrade using dpkg
update_error()
{
    error=${1}
    echo  ${error} > /tmp/fw_update_status
    uplog ${error}
    echo "Error fw_update_status: ${error}" 2>&1 | tee -a ${updatelog}
    [ -z "${update_container}" ] && restoreRaid
    #ledCtrl.sh LED_EV_FW_UPDATE LED_STAT_OK
    rm -f ${FW_UPDATE_MUTEX}
    exit 1
}

pkg_upgrade_verify()
{
    cat ${updatelog} | grep -q "not a debian format archive"
    if [ $? -eq 0 ]; then
        update_error "failed 200 \"invalid firmware package\""
    fi
    
    cat ${updatelog} | grep -q "Install not supported"
    if [ $? -eq 0 ]; then
        update_error "failed 200 \"invalid firmware package\""
    fi
    
    cat ${updatelog} | grep -q "dpkg-deb: subprocess <decompress> returned error"
    if [ $? -eq 0 ]; then
        update_error "failed 202 \"upgrade download failure\""
    fi
    
    if [ ${status} -ne 0 ]; then
        echo "dkpg exited with non-zero status: ${status}"
        update_error "Update failed. Check ${updatelog} for details."
    fi
}

## section: main script

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
source /etc/system.conf
#[ -f /usr/local/sbin/ledConfig.sh ] && . /usr/local/sbin/ledConfig.sh
filename=${1}
check_size=${2:-""}
test=${3:-""}
# check params
if [ $# -lt 1 ]; then
    echo "usage: updateFirmwareFromFile.sh <filename> [check_filesize]"
    exit 1
fi
if [ ! -f "${filename}" ]; then
    echo "File not found"
    exit 1
fi

#check battery power for update
echo "12;0;" > /tmp/MCU_Cmd
AC=`cat /tmp/battery  | awk '{print $1}'`
BatLevel=`cat /tmp/battery  | awk '{print $2}'`
if [ ${BatLevel} -lt 50 ]; then
#    if [ ${AC} == "discharging" ]; then
        error="failed 206 \"Upgrade failure due to Insufficient Power\""
        echo  ${error} > /tmp/fw_update_status                       
        pre-update_error $error
#    fi
fi
# set a 'non-idle' status for the manual update-from-file case
[ ! -f /tmp/fw_update_status ] && echo "downloading" > /tmp/fw_update_status

# startup update process
echo "10;0" >/tmp/MCU_Cmd &
shutdown_all_services
logtag="`basename $0`:`date -u +"%D %T"`:"
logger -s -t "${logtag}" "( $@ )"
echo "upgrading 0" > /tmp/fw_update_status
# initiate updatelog
updatelog="/CacheVolume/update.log"
echo "${logtag}upgrade start: $@" 2>&1 | tee ${updatelog}

FW_UPDATE_MUTEX=/tmp/fw_update_mutex
[ -f ${FW_UPDATE_MUTEX} ] && exit 0
touch ${FW_UPDATE_MUTEX}

uplog "check_size=${check_size}"

# Cleanup Cache file
echo 1 > /tmp/CacheMgrFile
echo 3 > /proc/sys/vm/drop_caches

# Check FW crc using gunzip bypass tar.gz recover method
gunzip -t "${filename}"
if [ $? != "0" ]; then
    pre-update_error "failed 200 \"invalid firmware package\""
fi

#rm -f /CacheVolume/MyPassportWireless.bin
#cp -af "${filename}" /CacheVolume/MyPassportWireless.bin

# check disk usage
fwUpdateSpace=`tar vtzf "${filename}" | awk '{SUM += $3} END {print SUM}'`
dfout=`df -B 1| grep /tmp`
avail=`echo "$dfout" | awk '{printf("%d",$2-$3)}'`
echo "${avail} ${fwUpdateSpace}"
if [ "${avail}" -lt "${fwUpdateSpace}" ]; then
    if [ -f /tmp/MountedDevNode ]; then
         dfout=`df -B 1| grep \`cat /tmp/MountedDevNode\``
         avail=`echo "$dfout" | awk '{printf("%d",$2-$3)}'`
         echo "${avail} ${fwUpdateSpace}"
         if [ "${avail}" -lt "${fwUpdateSpace}" ]; then
             error="failed 201 \"not enough space on device for upgrade\""
             echo  ${error} > /tmp/fw_update_status
             pre-update_error $error
         else
             if [ -d /CacheVolume/fwupg_images ]; then
                 rm -Rf /CacheVolume/fwupg_images
             fi
             mkdir -p /CacheVolume/fwupg_images
             ln -sf /CacheVolume/fwupg_images /tmp/fwupg_images
         fi
    else
        error="failed 201 \"not enough space on device for upgrade\""
        echo  ${error} > /tmp/fw_update_status
        pre-update_error $error
    fi
fi

if [ "${check_size}" != "" ] && [ "${test}" == "test_size" ]; then
    uplog "truncating file for size test..."
    blocksize_ls_original=$(ls -l ${filename} | cut -d' ' -f5)
    uplog "blocksize_ls_original=$blocksize_ls_original"
    dd if=${filename} of=${filename}-new bs=1M count=120
    mv ${filename}-new ${filename}
fi

# check file size if file was downloaded
if [ "${check_size}" != "" ]; then
    FileSize=( $(cat /tmp/fw_upgrade_filesize) )
    blocksize_dpkg0="${FileSize[0]}"
    blocksize_dpkg1="${FileSize[1]}"
    blocksize_ls=$(ls -l ${filename} | cut -d' ' -f5)
    uplog "blocksize_dpkg0=$blocksize_dpkg0"
    uplog "blocksize_dpkg1=$blocksize_dpkg1"
    uplog "blocksize_ls=$blocksize_ls"
    if [ "${blocksize_dpkg0}" != "${blocksize_ls}" ] && [ "${blocksize_dpkg1}" != "${blocksize_ls}" ]; then
        error="failed 202 \"failed download file size check\""
        pre-update_error "${error}"
    fi
fi

version_current=`cat /etc/version | tr -d .-`
#master_package_name=${modelNumber}
master_package_name=`echo AV1W`
version_newfile=`tar -xOzf "${filename}" fwupg_images/version | tr -d .-`
package_newfile=`tar -xOzf "${filename}" fwupg_images/package`
echo "upgrading 10" > /tmp/fw_update_status
# extract master package and update-container names
master_package_new=${package_newfile%%-*}
update_container=${package_newfile#*-}
update_container=${update_container%%-*}
[ "${master_package_name}" == "${update_container}" ] && update_container=''

uplog "version_current=$version_current"
uplog "version_newfile=$version_newfile"
uplog "package_newfile=$package_newfile"
uplog "master_package_name=$master_package_name"
uplog "master_package_new=$master_package_new"
uplog "update_container=$update_container"

# declare arithmetic variable types (ensure conversion to base 10)
let "vnew = $((10#$version_newfile))"
let "vnow = $((10#$version_current))"
if [ "${master_package_new}" == "wd.container" ] || [ "${master_package_new}" == "wd.group" ] || [ "${master_package_new}" == "wd.supergroup" ]; then
    uplog "Package compatiblities will be enforced by the incomming policy rules."
else
    # enforce same 'master-package' name
    if [ "${master_package_name}" != "${master_package_new}" ]; then
            error="failed 200 \"invalid firmware package\""
            pre-update_error $error
    fi
    # ITR#34229: don't allow down rev code to be applied
    # -but allow 'patch updates" with any version
    #if [ -z "${update_container}" ] && [ "${vnew}" -lt "${vnow}" ]; then
    #        error="failed 200 \"invalid firmware package\""
    #        pre-update_error $error
    #fi
fi

status=1

# Prepare for package upgrade
pkg_upgrade_init
# Do pkg upgrades
pkg_upgrade_exec
# Verify upgrade
pkg_upgrade_verify

# Unmount & reboot
rm -f ${FW_UPDATE_MUTEX}
#umount -f /DataVolume
#umount -f /media/sdb1
#umount -f /media/sda1

# sleep 10 seconds to allow UI to detect update
#sleep 10
#reboot -f -h -i &

exit ${status}
