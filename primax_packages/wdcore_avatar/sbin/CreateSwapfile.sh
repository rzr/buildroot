#!/bin/sh
# Create Swapfile
#

HDDSpace=`df | grep /DataVolume | awk '{print $4}'`

if [ -d "/media/sdb1_fuse" ]; then
    #Use Fuse Cache, Using none cache for swapfile
    if [ ! -f /media/sdb1_fuse/.wdcache/swapfile ] && [ $HDDSpace -gt 1024000 ]; then
        dd if=/dev/zero of=/media/sdb1_fuse/.wdcache/swapfile bs=1M count=1024
        /sbin/mkswap /media/sdb1_fuse/.wdcache/swapfile
        /sbin/swapon /media/sdb1_fuse/.wdcache/swapfile
    fi
else
    #Use No Fuse Cache
    if [ ! -f /media/sdb1/.wdcache/swapfile ] && [ $HDDSpace -gt 1024000 ]; then
        dd if=/dev/zero of=/media/sdb1/.wdcache/swapfile bs=1M count=1024
        /sbin/mkswap /media/sdb1/.wdcache/swapfile
        /sbin/swapon /media/sdb1/.wdcache/swapfile
    fi
fi

