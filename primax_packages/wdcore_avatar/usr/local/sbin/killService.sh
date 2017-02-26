#!/bin/sh
case $1 in
    "hdd")
		    kill `pidof smbd`;
		    /etc/init.d/S99crond stop;
		    /etc/init.d/S95RestAPI stop;
		    /etc/init.d/S92wdnotifierd stop;
		    /etc/init.d/S92twonkyserver stop;
		    kill `pidof twonkystarter`;
		    /etc/init.d/S91smb stop;
		    /etc/init.d/S85wdmcserverd stop;
		    /etc/init.d/S70vsftpd stop;
		    /etc/init.d/S50netatalk stop;
		    killall mv
		    killall cp
		    sync
		    umount /DataVolume/;
		    umount /media/SDcard;
		    umount /media/AFPSDcard;
		    umount /var/ftp/Public;
		    umount /media/sdb1;
		    umount /media/sdb1_fuse;
		    echo 0 > /tmp/CacheMgrFile
		    rm -f /tmp/HDDDevNode
		    ;;
    "network")
		    ;;
    "hddup")
		    /etc/init.d/S35mdev start;
		    /etc/init.d/S48initdisk start;
		    /etc/init.d/S50netatalk start;
		    /etc/init.d/S70vsftpd start;
            /etc/init.d/S80swapfile start;
		    /etc/init.d/S85wdmcserverd stop;
		    sleep 1
		    /etc/init.d/S85wdmcserverd start;
		    /etc/init.d/S91smb start;
		    /etc/init.d/S92twonkyserver start;
		    /etc/init.d/S92wdnotifierd start;
		    /etc/init.d/S95RestAPI start;
		    /etc/init.d/S99crond start;
		    ;;
    "networkup")
		    ;;
    *)
		    exit 1
		    ;;
esac

exit 0
