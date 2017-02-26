#!/bin/sh
case $1 in
	"hdd")
        sleep 5;
        /etc/init.d/S35mdev start;
        /etc/init.d/S48initdisk start;
        /etc/init.d/S50netatalk start;
        /etc/init.d/S70vsftpd start;
		/etc/init.d/S85wdmcserverd start;
		/etc/init.d/S91smb start;
		/etc/init.d/S92twonkyserver start;
		/etc/init.d/S92wdnotifierd start;
		/etc/init.d/S95RestAPI start;
		/etc/init.d/S99crond start;
		;;
	"network")
		;;
	*)
		exit 1
		;;
esac

exit 0
