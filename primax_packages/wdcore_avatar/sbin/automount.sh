#!/bin/sh

source /etc/power.conf
devstr=$1
destdir=/media
dev=${devstr:0:3}

create_loop_device()
{
    if [ ! -d "/CacheVolume/.wd-alert" ]; then
        if [ ! -d "/media/sdb1/.wdcache" ]; then
            rm -rf /CacheVolume
        fi	
        mkdir /CacheVolume/.wd-alert                                                                                                                                                                                                                                              
        chmod 775 /CacheVolume/.wd-alert
    fi 
    HDDSpace=`df | grep /DataVolume | awk '{print $4}'`    
    if [ -f /media/sdb1/.wdcache/safeloop ]; then
        mount -o force,loop /media/sdb1/.wdcache/safeloop /CacheVolume/.wd-alert 
        rm /etc/safeloop
    else
        if [ -f /media/sdb1/.wdcache/.wd-alert/wd-alert-desc.db ]; then
            cp 	/media/sdb1/.wdcache/.wd-alert/wd-alert-desc.db /tmp/
	fi
	if [ -f /media/sdb1/.wdcache/.wd-alert/wd-alert.db ]; then
            cp 	/media/sdb1/.wdcache/.wd-alert/wd-alert.db /tmp/
	fi
        if [ $HDDSpace -gt 10240 ]; then
            safenode="/media/sdb1/.wdcache/safeloop"
            dd if=/dev/zero of=$safenode bs=1M count=10
            mkexfat -f $safenode
            mount -o force,loop ${safenode} /CacheVolume/.wd-alert	
            rm /etc/safeloop
        else
            safenode="/etc/safeloop"
            if [ ! -f /etc/safeloop ]; then
                dd if=/dev/zero of=$safenode bs=1M count=10                   
                mkexfat -f $safenode                                          
                mount -o force,loop ${safenode} /CacheVolume/.wd-alert
            else
                mount -o force,loop ${safenode} /CacheVolume/.wd-alert
            fi
        fi
	if [ -f /tmp/wd-alert-desc.db ]; then
            cp 	/tmp/wd-alert-desc.db /media/sdb1/.wdcache/.wd-alert/wd-alert-desc.db 
	fi
	if [ -f /tmp/wd-alert.db ]; then
            cp 	/tmp/wd-alert.db /media/sdb1/.wdcache/.wd-alert/wd-alert.db
	fi
    fi    
}


check_DeviceNode()
{
    ishddrive=0
    issdcard=0
    vendor=`cat /sys/block/$dev/device/vendor | awk '{print $1}'`
    model=`cat /sys/block/$dev/device/model`
    size=`cat /sys/block/$dev/size`
    if [ "$vendor" == "WD" ] && [ "$model" == "My Passport 083C" ] && [ $size -gt 8388608 ]; then
        HDDdev=$dev
        ishddrive=1
        echo "/dev/${HDDdev}" > /tmp/HDDDevNode
    fi
    if [ "$vendor" == "Multiple" ] && [ "$model" == "Card  Reader    " ]; then
        SDdev=$dev
        issdcard=1
    fi
}

my_umount()
{
    if [ -f /tmp/SDDevNode ]; then
        SDdev=`cat /tmp/SDDevNode | cut -c 6-8`
    fi 
    echo "my_umount $dev $SDdev" >> /tmp/automount.log
    if [ "$dev" == "$SDdev" ]; then
        mount_point=SDcard
        #update smb.conf
        #sed -i '/\[SD\]/{N;N;N;N;N;N;N;N;d;}' /etc/samba/smb.conf
        #echo "Notify smb update share"
        #killall -SIGHUP smbd
        #sed -i '/\[SD\]/{N;N;N;N;N;N;N;d;}' /etc/afp.conf
        #echo "Notify afp update share"                                 
        #killall -SIGHUP netatalk
    else
	if [ "${powerprofile}" == "max_system_performance" ]; then
        	mount_point=sdb1
	else
        	mount_point=sdb1_fuse
	fi
    fi

    if grep -qs "^/dev/$1 " /proc/mounts ; then
        umount -l "${destdir}/$mount_point";
        #umount /dev/$1;
    fi

    [ -d "${destdir}/$mount_point" ] && rmdir "${destdir}/$mount_point"

    if [ "$dev" == "$SDdev" ]; then
       #smbstatus | grep "SD" | awk '{print $2}' | xargs -n 1 kill -9
       umount -l /media/AFPSDcard
       if [ ! -d "${destdir}/$mount_point" ]; then
           rm -f /tmp/SDDevNode
           sed -i 's/TransferStatus=.*/TransferStatus=completed/' /etc/nas/config/sdcard-transfer-status.conf
       	   echo "18;0;" > /tmp/MCU_Cmd
       else
           umount -l "${destdir}/$mount_point";
           rm -f /tmp/SDDevNode
           sed -i 's/TransferStatus=.*/TransferStatus=completed/' /etc/nas/config/sdcard-transfer-status.conf
            echo "18;0;" > /tmp/MCU_Cmd
       fi 
    fi

}
                         
my_mount()
{
    echo "$dev SD:$SDdev HD:$HDDdev"
    if [ "$dev" == "$SDdev" ]; then
        mount_point=SDcard
        # Remove SD from smb.conf
        #sed -i '/\[SD\]/{N;N;N;N;N;N;N;N;d;}' /etc/samba/smb.conf
        #sed -i '/\[SD\]/{N;N;N;N;N;N;N;d;}' /etc/afp.conf
    else
	if [ "${powerprofile}" == "max_system_performance" ]; then
        	mount_point=sdb1
	else
	        add_video_format
        	mount_point=sdb1_fuse
	fi
    fi
		
    mkdir -p "${destdir}/$mount_point" || exit 1

    isFAT32=`blkid /dev/$1 | grep vfat | wc -l`
    
    #/sbin/StorageAlert.sh $mount_point $devstr $dev &
		
    if [ $isFAT32 -eq 1 ]; then
        if [ "$mount_point" == "sdb1_fuse" ]; then
           mkdir -p "${destdir}/$mount_point" || exit 1
           if ! mount -t auto -o async "/dev/$1" "${destdir}/$mount_point"; then
              	rmdir "${destdir}/$mount_point"
              	/sbin/StorageAlert.sh $mount_point $devstr $dev & 
              	exit 1
           fi
           if [ ! -f /tmp/CacheMgrFile ]; then
              	dd if=/dev/zero of=/tmp/CacheMgrFile count=230 bs=1M
           fi

    	   mkdir -p "${destdir}/sdb1" || exit 1
           /bin/filecache /media/sdb1 -o allow_other -o big_writes -o auto_unmount
        else
          if ! mount -t auto -o async "/dev/$1" "${destdir}/$mount_point"; then
              	rmdir "${destdir}/$mount_point"
              	/sbin/StorageAlert.sh $mount_point $devstr $dev &
              	exit 1
          fi
        fi
    else
        if [ "$mount_point" == "sdb1_fuse" ]; then
           mkdir -p "${destdir}/$mount_point" || exit 1
 
           if ! mount -t auto -o async,force,fmask=0000,dmask=0000 "/dev/$1" "${destdir}/$mount_point"; then
              	rmdir "${destdir}/$mount_point_fuse"
              	/sbin/StorageAlert.sh $mount_point $devstr $dev &
              	exit 1
           fi
           if [ ! -f /tmp/CacheMgrFile ]; then
              	dd if=/dev/zero of=/tmp/CacheMgrFile count=230 bs=1M
           fi
           # echo mount filecache 2
    	   mkdir -p "${destdir}/sdb1" || exit 1
           /bin/filecache /media/sdb1 -o allow_other -o big_writes -o auto_unmount 
           #mount
        else
            if ! mount -t auto -o async,force,fmask=0000,dmask=0000 "/dev/$1" "${destdir}/$mount_point"; then
                # failed to mount, clean up mountpoint
                rmdir "${destdir}/$mount_point" 2>&1 > /dev/null
                /sbin/StorageAlert.sh $mount_point $devstr $dev & 
                exit 1
            fi
        fi
    fi
    
    mounted=`mount | grep "$1 " | wc -l`
    if [ $mounted -eq 0 ]; then
        rmdir "${destdir}/$mount_point" 2>&1 > /dev/null
        exit 1
    fi

    if [ $ishddrive -eq 1 ]; then
        #mount -t auto -o async,force,fmask=0000,dmask=0000 "/dev/$1" /DataVolume
    	isDataV=`mount | grep "DataVolume" | wc -l`
    	if [ $isDataV -eq 0 ]; then
        	mount /media/sdb1 /DataVolume
	fi
        #echo "/dev/${HDDdev}" > /tmp/HDDDevNode
        echo "/dev/$1" > /tmp/MountedDevNode
        rm /var/tmp
        ln -s /CacheVolume /var/tmp
        #exit 1
        factory_conf="/etc/nas/config/factory.conf"
        if [ ! -f $factory_conf ] ||  [ `grep FACTORY_MODE $factory_conf | wc -l` != "1" ] || [ `grep FACTORY_MODE $factory_conf | awk -F= '{print $2}'` != "1" ]; then
                if [ ! -f /media/sdb1/.wdcache ]; then
                        mkdir -p /media/sdb1/.wdcache
                fi
        fi
        create_loop_device
    fi
    if [ ${issdcard} -eq 1 ]; then
            if [ ! -f /tmp/sdsize ]; then
                    echo "total_size_in_bytes=0" > /tmp/sdsize_total
                    echo "transferred_size_in_bytes=0" > /tmp/sdsize
            fi
            if [ ! -f /tmp/sdstats ]; then
	            echo "status=waiting" > /tmp/sdstats
            fi
    fi
    shared=`cat /etc/samba/smb.conf | grep "\[$mount_point\]" | wc -l`
    if [ $shared -eq 0 ]; then
      if [ "$mount_point" == "SDcard" ]; then
        echo "/dev/${SDdev}" > /tmp/SDDevNode
        rm -Rf /media/AFPSDcard/*
        mount /media/SDcard /media/AFPSDcard
#        sed -i '/\[SD\]/{N;N;N;N;N;N;N;N;d;}' /etc/samba/smb.conf
#        echo "[SD]
#path = /media/$mount_point
#guest ok = yes
#oplocks = no
#browseable = yes
#writable = yes
#create mask = 0777
#directory mask = 0777
#" >> /etc/samba/smb.conf

	#echo "Notify smb update share"
#        killall -SIGHUP smbd

#	sed -i '/\[SD\]/{N;N;N;N;N;N;N;d;}' /etc/afp.conf
#	echo "[SD]
#path = /media/$mount_point
#ea = auto               
#convert appledouble = no
#stat vol = no                                                
#file perm = 777
#directory perm = 777
#" >> /etc/afp.conf
	#echo "Notify afp update share"
#        killall -SIGHUP netatalk

    	fi
    fi
}

#Video format for FUSE(file cache)
add_video_format()
{
    rm /tmp/videoformat
    if [ ! -f /usr/local/wdmcserver/bin/mime_types.txt ]; then
        echo .mp4 >> /tmp/videoformat	
        echo .avi >> /tmp/videoformat	
        echo .wmv >> /tmp/videoformat	
        echo .rm >> /tmp/videoformat	
        echo .rmvb >> /tmp/videoformat	
        echo .mov >> /tmp/videoformat	
        echo .dat >> /tmp/videoformat	
        echo .m1v >> /tmp/videoformat	
        echo .mp3 >> /tmp/videoformat	
        echo .wma >> /tmp/videoformat	
        echo .mkv >> /tmp/videoformat	
   else
        cat /usr/local/wdmcserver/bin/mime_types.txt | grep video/  > /tmp/mime_types.tmp1
        sed '/#/d' /tmp/mime_types.tmp1 > /tmp/mime_types.tmp2
        awk '{ {if($2!="")print "."$2} {if($3!="")print "."$3} {if($4!="")print "."$4}  {if($5!="")print "."$5} }' /tmp/mime_types.tmp2  > /tmp/videoformat
        rm /tmp/mime_types.tmp1
        rm /tmp/mime_types.tmp2	
   fi
}

echo "${ACTION} ${DEVNAME} $1 $2 $3 $4" >> /tmp/automount.log
                                                              
case "${ACTION}" in
add|"")
    check_DeviceNode
    if [ ${issdcard} -eq 1 ]; then
	sdgpio=`grep gpio-27 /sys/kernel/debug/gpio | awk '{print $5}'` 
	if [ "$sdgpio" == "lo" ]; then
	    if [ `ls /dev/ | grep ${dev}1 |wc -l` -eq 0 ]; then    
		/sbin/StorageAlert.sh UnsprtSD &
	    fi
	fi
    fi
    isKnownType=`blkid /dev/$1 | grep TYPE | wc -l`
    if [ $isKnownType -eq 0 ]; then
        echo "$1 Type Unknown!!"
        if [ -f /tmp/SDDevNode ]; then
            echo "Do SDCard"
            SDNode=`cat /tmp/SDDevNode | cut -c 6-8`
            echo "Debug $dev $SDNode"
            if [ "$dev" == "$SDNode" ]; then 
                sdcdz=`grep gpio-27 /sys/kernel/debug/gpio | awk '{print $5}'`
                if [ "$sdcdz" == "hi" ]; then
                    #echo "REMOVE event of $1"
                    #`fuser -mk /media/SDcard`
                    my_umount $1
                fi
            fi
        fi
        exit 1
    fi

    if [ -f /tmp/SDDevNode ]; then
        SDdev=`cat /tmp/SDDevNode | cut -c 6-8`
    fi
    if [ "$dev" == "$SDdev" ]; then
      sdcdz=`grep gpio-27 /sys/kernel/debug/gpio | awk '{print $5}'` 
      if [ "$sdcdz" == "lo" ]; then
          echo "SD ADD event of $1"
          isGPT=`blkid /dev/$1 | grep EFI | wc -l`
          if [ $isGPT -eq 1 ]; then
                echo "***GPT found, ignore $1***"
                exit 1
	  fi
          my_mount $1
      fi
      if [ "$sdcdz" == "hi" ]; then
          echo "SD REMOVE event of $1"
          #`fuser -mk /media/SDcard`
          my_umount $1
      fi
    fi
    if [ $ishddrive -eq 1 ]; then
        isHDDMount=`grep /dev/$HDDdev /proc/mounts | wc -l`
        if [ $isHDDMount -eq 1 ]; then
	    echo "HDD already mounted"
        else
	    echo "Try to Mounte HDD"
            isGPT=`blkid /dev/$1 | grep EFI | wc -l`
            if [ $isGPT -eq 1 ]; then
                echo "***GPT found, ignore $1***"
                exit 1
	    fi
            my_mount $1
        fi
    fi
    ;;
remove)
    echo "####${ACTION}####"
    echo "do remove" >> /tmp/automount.log
    my_umount $1
    ;;
esac
