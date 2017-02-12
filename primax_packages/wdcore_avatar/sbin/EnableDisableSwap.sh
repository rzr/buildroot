#!/bin/sh
# Enable or Disable Swap
#

RETVAL=0

enable() {
    #echo "Start Swap"
    if [ ! -f "/tmp/MountedDevNode" ]; then
        echo "Device not mounted!!!"
        exit 1
    fi
    ACMode=`cat /tmp/battery | cut -d " " -f 1`
    if [ "${ACMode}" == "discharging" ]; then
        echo "Battery Discharging!!!"
        exit 1
    fi
    if [ -d "/media/sdb1_fuse" ]; then
        #Use Fuse Cache, Using none cache for swapfile
        if [ -f /media/sdb1_fuse/.wdcache/swapfile ]; then
            /sbin/swapon /media/sdb1_fuse/.wdcache/swapfile
        else
            dd if=/dev/zero of=/media/sdb1_fuse/.wdcache/swapfile bs=1M count=1024
            /sbin/mkswap /media/sdb1_fuse/.wdcache/swapfile
            /sbin/swapon /media/sdb1_fuse/.wdcache/swapfile
        fi
    else
        #Use No Fuse Cache
        if [ -f /media/sdb1/.wdcache/swapfile ]; then
            /sbin/swapon /media/sdb1/.wdcache/swapfile
        else
            dd if=/dev/zero of=/media/sdb1/.wdcache/swapfile bs=1M count=1024
            /sbin/mkswap /media/sdb1/.wdcache/swapfile
            /sbin/swapon /media/sdb1/.wdcache/swapfile
        fi
    fi

}	

disable() {
    #echo "Stop Swap"
    if [ -d "/media/sdb1_fuse" ]; then
        if [ -f /media/sdb1_fuse/.wdcache/swapfile ]; then
            /sbin/swapoff /media/sdb1_fuse/.wdcache/swapfile
        else
            /sbin/swapoff /media/sdb1_fuse/.wdcache/swapfile
        fi
    else
        if [ -f /media/sdb1/.wdcache/swapfile ]; then
            /sbin/swapoff /media/sdb1/.wdcache/swapfile
        else
            /sbin/swapoff /media/sdb1/.wdcache/swapfile
        fi
    fi

}	

restart() {
	disable
	enable
}	

case "$1" in
  enable)
  	enable
	;;
  disable)
  	disable
	;;
  restart)
  	restart
	;;
  *)
	echo "Usage: $0 {enable|disable|restart}"
	exit 1
esac

exit $?
