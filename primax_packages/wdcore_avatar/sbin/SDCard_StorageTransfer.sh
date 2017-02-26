#!/bin/bash
#
# SDCard_StorageTransfer.sh
#
# Used to triiger Storage Transfer process
#

#---------------------

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
. /etc/nas/config/sdcard-param.conf
. /etc/nas/config/sdcard-transfer-status.conf
. /etc/system.conf

#SYSTEM_SCRIPTS_LOG=${SYSTEM_SCRIPTS_LOG:-"/dev/null"}
## Output script log start info
#{ 
#echo "Start: `basename $0` `date`"
#echo "Param: $@" 
#} >> ${SYSTEM_SCRIPTS_LOG}
##
#{
#---------------------
# Begin Script
#---------------------

SDVolume=`df | grep /media/SDcard | awk '{ print $3 }'`
HDDSpace=`df | grep /DataVolume | awk '{ print $4 }'`
if [ "$SDVolume" == "" ]; then
	exit 1
fi

echo status=waiting > /tmp/sdstats
echo "total_size_in_bytes=0" > /tmp/sdsize_total
echo "transferred_size_in_bytes=0" > /tmp/sdsize
sctool `cat /tmp/SDDevNode`
[ -s "/tmp/CIDbackup" ] && CID=`cat /tmp/CIDbackup`
#CID=SDCard_`date +%Y.%m.%d.%H%M`
fullCID=`cat /tmp/fullCID`
#newCID=${CID}

#check CID mapping{ 
if [ `ls -al /media/sdb1/.wdcache/ | grep ${fullCID} | wc -l` -eq 0 ]; then
    if [ `find /media/sdb1/SD\ Card\ Imports/ -name .${fullCID} | wc -l` != 0 ]; then
	CIDpath=`find /media/sdb1/SD\ Card\ Imports/ -name .${fullCID}`
    	CID=`echo ${CIDpath} | cut -c 29-40`
    fi
else
    CID=`cat /media/sdb1/.wdcache/.${fullCID}`	
fi
#} check CID mapping

if [ -d /media/sdb1_fuse ]; then
    SDcard="/media/sdb1_fuse/SD Card Imports/${CID}"
else
    SDcard="/media/sdb1/SD Card Imports/${CID}"
fi

sdgpio=`grep gpio-27 /sys/kernel/debug/gpio | awk '{print $5}'`                                         
if [ "$sdgpio" == "hi" ]; then                   
	echo `ps | grep rsync | awk '{print $1}'` > /tmp/Krsync
	kill `cat /tmp/Krsync` >> /dev/null 2>&1 
	`rm /tmp/Krsync`
	echo "TransferStatus=completed" > /etc/nas/config/sdcard-transfer-status.conf                        
	echo "18;0;" > /tmp/MCU_Cmd 	
	exit 0                               
fi
	
if [ "$1" == "" ]; then
	method=${TransferMode}
else
	method=$1
fi
if [ "$2" == "" ]; then
	autotransfer=${AutoTransfer}
else
	autotransfer=$2
fi
if [ "$autotransfer" == "false" ]; then
	exit 0
else
   if [ "$SDVolume" -gt "$HDDSpace" ]; then                                             
        /usr/local/sbin/sendAlert.sh 2010 &
        /usr/local/sbin/incUpdateCount.pm storage_transfer &
        echo "status=failed" > /tmp/sdstats
        exit 1                                                                       
   fi 
fi

if [ ! -d "/shares/Public/SD Card Imports" ]; then
    mkdir -p "/shares/Public/SD Card Imports"
fi

#ArchiveNum=`ls -ltn /shares/Public/SD\ Card\ Imports/${CID}/ | grep Archive__ | wc -l`
#if [ ${ArchiveNum} -eq 0 ]; then
#	Count=1
#else
#        OldArchive=`ls -ltn /shares/Public/SD\ Card\ Imports/${CID}/ | grep Archive__ | sed -n '1p' | awk '{print $9}'`
#	OldCount=${OldArchive#*__}
#	Count=$((${OldCount}+1))
#fi


if [ "$method" == "move" ] || [ "$method" == "copy" ]; then
	sed -i 's/TransferStatus=.*/TransferStatus=process/' /etc/nas/config/sdcard-transfer-status.conf
	if [ "$SDVolume" -gt "$HDDSpace" ]; then                                             
		/usr/local/sbin/sendAlert.sh 2010 &                                          
		exit 1                                                                       
	fi 
	if [ `ls -1 /media/SDcard/ | wc -l` -eq 0 ]; then
		mkdir -p "${SDcard}"
		sed -i "s/status=.*/status=completed/" /tmp/sdstats
		exit 0
	fi
	mkdir -p "${SDcard}"
	if [ "$method" == "move" ]; then
		if [ `ps aux | grep rsync | grep /media/SDcard | wc -l` -ne 0 ] && [ `cat /etc/nas/config/sdcard-transfer-status.conf | grep process | wc -l` -ne 0 ]; then
			exit 1
		else
			echo "TransferStatus=process" > /etc/nas/config/sdcard-transfer-status.conf
			echo "22;0;"  > /tmp/MCU_Cmd
			sleep 2
			echo "18;1;" > /tmp/MCU_Cmd	
			/usr/local/sbin/incUpdateCount.pm storage_transfer &
			total_size=`rsync -rv /media/SDcard/ | grep "total size is" | awk '{print $4}' | sed -n 's/,//gp'`
            if [ $? -eq 0 ]; then
			    sed -i 's/total_size_in_bytes=.*/total_size_in_bytes='${total_size}'/' /tmp/sdsize_total
            else
                echo "TransferStatus=completed" > /etc/nas/config/sdcard-transfer-status.conf
                sleep 1
                echo "18;0;" > /tmp/MCU_Cmd
                if [ -f /tmp/SDCard_Process_Canceled ]; then
                    echo "status=canceled" > /tmp/sdstats
                    rm -f /tmp/SDCard_Process_Canceled
                else
                    echo "status=failed" > /tmp/sdstats
                fi
                /usr/local/sbin/incUpdateCount.pm storage_transfer &
                exit 1
            fi
			echo "status=running" > /tmp/sdstats			
			rsync --backup --suffix=_tmparchive -ahP --info=progress2  /media/SDcard/* "${SDcard}"/ > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				`rm -rf /media/SDcard/*`
				`chmod -R 777 "${SDcard}"`
			else
				echo "TransferStatus=completed" > /etc/nas/config/sdcard-transfer-status.conf
				#echo "SDcard rsync fail !"
				sleep 1
				echo "18;0;" > /tmp/MCU_Cmd
                if [ -f /tmp/SDCard_Process_Canceled ]; then
                    echo "status=canceled" > /tmp/sdstats
                    rm -f /tmp/SDCard_Process_Canceled
                else
				    echo "status=failed" > /tmp/sdstats
                fi
				/usr/local/sbin/incUpdateCount.pm storage_transfer &
				exit 1
			fi
            sync
            sync
            sync
		fi
	fi	
	if [ "$method" == "copy" ]; then
                if [ `ps aux | grep rsync | grep /media/SDcard | wc -l` -ne 0 ] && [ `cat /etc/nas/config/sdcard-transfer-status.conf | grep process | wc -l` -ne 0 ]; then
			exit 1
		else
			echo "TransferStatus=process" > /etc/nas/config/sdcard-transfer-status.conf
			echo "22;0;"  > /tmp/MCU_Cmd
			sleep 2
			echo "18;1;" > /tmp/MCU_Cmd
			/usr/local/sbin/incUpdateCount.pm storage_transfer &
			total_size=`rsync -rv /media/SDcard/ | grep "total size is" | awk '{print $4}' | sed -n 's/,//gp'`
            if [ $? -eq 0 ]; then
                sed -i 's/total_size_in_bytes=.*/total_size_in_bytes='${total_size}'/' /tmp/sdsize_total
            else
                echo "TransferStatus=completed" > /etc/nas/config/sdcard-transfer-status.conf
                sleep 1
                echo "18;0;" > /tmp/MCU_Cmd
                if [ -f /tmp/SDCard_Process_Canceled ]; then
                    echo "status=canceled" > /tmp/sdstats
                    rm -f /tmp/SDCard_Process_Canceled
                else
                    echo "status=failed" > /tmp/sdstats
                fi
                /usr/local/sbin/incUpdateCount.pm storage_transfer &
                exit 1
            fi
			echo "status=running" > /tmp/sdstats
			rsync --backup --suffix=_tmparchive -ahP --info=progress2  /media/SDcard/* "${SDcard}"/ > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				`chmod -R 777 "${SDcard}"`
			else
				echo "TransferStatus=completed" > /etc/nas/config/sdcard-transfer-status.conf
				sleep 1
				echo "18;0;" > /tmp/MCU_Cmd
                if [ -f /tmp/SDCard_Process_Canceled ]; then
                    echo "status=canceled" > /tmp/sdstats
                    rm -f /tmp/SDCard_Process_Canceled
                else
                    echo "status=failed" > /tmp/sdstats
                fi
				/usr/local/sbin/incUpdateCount.pm storage_transfer &
				exit 1
			fi    		

			sync
			sync
			sync
		fi
	fi
fi

# archive the file with the same name{
find /media/sdb1/SD\ Card\ Imports/${CID}/ -name "*_tmparchive" > /tmp/sdArchivePath
ArchiveCount=`cat /tmp/sdArchivePath | grep -c _tmparchive`
if [ ${ArchiveCount} != 0 ]; then
    for  ((i=1; i<=$ArchiveCount; i=i+1))    
    do
        ArchivePath=`cat /tmp/sdArchivePath | sed -n "${i}p"`
        SDpath="${ArchivePath%/*}"
        tmpname=${ArchivePath##*/}
	oldname=${tmpname%%_tmparchive} 
	name=${oldname%.*}     
	havepoint=`echo ${oldname} | grep "\." | wc -l`
	if [ `echo ${oldname} | grep "\." | wc -l` -eq 0 ]; then
            newname="${name}-backup-`date +%Y.%m.%d.%H%M`"
	else
	    subname=${oldname##*.}                                                                            
	    newname="${name}-backup-`date +%Y.%m.%d.%H%M`.${subname}"
	fi
	mv "${SDpath}/${tmpname}" "${SDpath}/${newname}"
    done
    rm /tmp/sdArchivePath
fi
#} archive the file with the same name
echo ${CID} > /media/sdb1/.wdcache/.${fullCID}
echo ${CID} > /media/sdb1/SD\ Card\ Imports/${CID}/.${fullCID}
total=`cat /tmp/sdsize_total  | sed -n '1p' | sed -n 's/.*=//p'` 
if [ $total -gt 0 ];then                                           
	sed -i "s/status=.*/status=completed/" /tmp/sdstats
fi
/usr/local/sbin/incUpdateCount.pm storage_transfer &
echo "TransferStatus=completed" > /etc/nas/config/sdcard-transfer-status.conf
sleep 2
echo "18;0;" > /tmp/MCU_Cmd
exit 0
#---------------------
# End Script
#---------------------
## Copy stdout to script log also
#} # | tee -a ${SYSTEM_SCRIPTS_LOG}
## Output script log end info
#{ 
#echo "End:$?: `basename $0` `date`" 
#echo ""
#} >> ${SYSTEM_SCRIPTS_LOG}


