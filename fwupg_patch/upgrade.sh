#!/bin/sh
#
# upgrade.sh
#
echo "10;0" >/tmp/MCU_Cmd &
if [ -f /CacheVolume/.twonkymedia/twonkyserver.ini ]; then
    rm -f /CacheVolume/.twonkymedia/twonkyserver.ini
fi
if [ -f /CacheVolume/.twonkymedia/twonky-locations-70.db ]; then
    rm -f /CacheVolume/.twonkymedia/twonky-locations-70.db
fi
if [ -d /DataVolume/upload ]; then
    mv /DataVolume/upload /DataVolume/Upload
fi
if [ -d /CacheVolume/.twonkymedia/db ]; then
    rm -Rf /CacheVolume/.twonkymedia/db/*
fi
if [ -d /CacheVolume/Upload ]; then
    rm -Rf /CacheVolume/Upload/*
fi
echo "upgrading 15" > /tmp/fw_update_status
if [ -f "/tmp/fwupg_images/MLO" ]; then
	flash_erase /dev/mtd0 0 0
	flash_erase /dev/mtd1 0 0
	flash_erase /dev/mtd2 0 0
	flash_erase /dev/mtd3 0 0
	echo "upgrading 20" > /tmp/fw_update_status
	sleep 1
fi
if [ -f "/tmp/fwupg_images/u-boot.img" ]; then
	flash_erase /dev/mtd4 0 0
#	flash_erase /dev/mtd5 0 0
	echo "upgrading 30" > /tmp/fw_update_status
	sleep 1
fi
if [ -f "/tmp/fwupg_images/uImage" ]; then
	flash_erase /dev/mtd6 0 0
	echo "upgrading 35" > /tmp/fw_update_status
	sleep 1
fi
if [ -f "/tmp/fwupg_images/MLO" ]; then
	nandwrite -p /dev/mtd0 /tmp/fwupg_images/MLO
	nandwrite -p /dev/mtd1 /tmp/fwupg_images/MLO
	nandwrite -p /dev/mtd2 /tmp/fwupg_images/MLO
	nandwrite -p /dev/mtd3 /tmp/fwupg_images/MLO
	echo "upgrading 45" > /tmp/fw_update_status
	sleep 1
fi
if [ -f "/tmp/fwupg_images/u-boot.img" ]; then
	nandwrite -p /dev/mtd4 /tmp/fwupg_images/u-boot.img
	echo "upgrading 55" > /tmp/fw_update_status
	sleep 1
fi
if [ -f "/tmp/fwupg_images/uImage" ]; then
	nandwrite -p /dev/mtd6 /tmp/fwupg_images/uImage
	echo "upgrading 65" > /tmp/fw_update_status
	sleep 1
fi
# Cleanup Cache file
echo 1 > /tmp/CacheMgrFile
echo 3 > /proc/sys/vm/drop_caches
# move image to ramdisk
mv /tmp/fwupg_images/rootfs.cpio /tmp/rootfs.cpio
mv /tmp/fwupg_images/uImage-update /tmp/uImage-update

if [ -f "/tmp/fwupg_images/AsmSataFw.bin" ]; then
    mv /tmp/fwupg_images/AsmSataFw.bin /tmp/AsmSataFw.bin
	/etc/init.d/S92twonkyserver stop
	/sbin/EnableDisableSwap.sh disable
	umount /media/sdb1/.wdcache/.wd-alert
	umount /var/ftp/Public
	umount /DataVolume
	umount /media/sdb1
	umount /media/sdb1_fuse
	HDD=`cat /tmp/HDDDevNode`
	/sbin/asmupdate -u $HDD /tmp/AsmSataFw.bin
	echo "upgrading 75" > /tmp/fw_update_status
	sleep 2
fi

kexec -l /tmp/uImage-update --ramdisk=/tmp/rootfs.cpio --command-line="root=/dev/ram rw console=ttyO0,115200" --atags &
echo "upgrading 85" > /tmp/fw_update_status
sleep 5
echo "upgrading 100" > /tmp/fw_update_status
sleep 10
kexec -e
