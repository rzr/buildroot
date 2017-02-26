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
if [ -f /tmp/SDCard_ButtonProcessing ]; then
    exit 1
fi
touch /tmp/SDCard_ButtonProcessing

SDVolume=`df | grep /media/SDcard | awk '{ print $3 }'`
HDDSpace=`df | grep /DataVolume | awk '{ print $4 }'`
if [ "$SDVolume" == "" ]; then
    rm -f /tmp/SDCard_ButtonProcessing
	exit 1
fi

#echo status=waiting > /tmp/sdstats
#echo "total_size_in_bytes=1024" > /tmp/sdsize_total
#echo "transferred_size_in_bytes=0" > /tmp/sdsize
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
	rm -f /tmp/SDCard_ButtonProcessing
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
if [ "$autotransfer" == "true" ]; then
	rm -f /tmp/SDCard_ButtonProcessing
	exit 0
else
   if [ "$SDVolume" -gt "$HDDSpace" ]; then                                             
        /usr/local/sbin/sendAlert.sh 2010 &
        /usr/local/sbin/incUpdateCount.pm storage_transfer &
        echo "status=failed" > /tmp/sdstats
        rm -f /tmp/SDCard_ButtonProcessing
        exit 1                                                                       
   fi
   Running=`sqlite3 /usr/local/nas/orion/jobs.db  'select jobstate_id from Jobs where jobstate_id=2' | wc -l`
   Waiting=`sqlite3 /usr/local/nas/orion/jobs.db  'select jobstate_id from Jobs where jobstate_id=1' | wc -l`
   if [ "${Running}" -eq "0" ] && [ "${Waiting}" -eq "0" ]; then
       echo status=waiting > /tmp/sdstats
       /usr/local/sbin/storage_transfer_job_start.sh
   fi
   rm -f /tmp/SDCard_ButtonProcessing
   exit 0
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
#	echo "status=running" > /tmp/sdstats
	#mkdir -p ${SDcard}
	if [ "$method" == "move" ]; then
		if [ `ps aux | grep rsync | grep /media/SDcard | wc -l` -ne 0 ] && [ `cat /etc/nas/config/sdcard-transfer-status.conf | grep process | wc -l` -ne 0 ]; then
			exit 1
		else
			echo "TransferStatus=process" > /etc/nas/config/sdcard-transfer-status.conf
			echo "22;0;"  > /tmp/MCU_Cmd
			sleep 2
			echo "18;1;" > /tmp/MCU_Cmd	
#			rsync -aP /media/SDcard/ "${SDcard}"/
#			rsync --backup --backup-dir=Archive__${Count} -aP /media/SDcard/ "${SDcard}"/ > /dev/null 2>&1
			/usr/local/sbin/incUpdateCount.pm storage_transfer &
			rsync --backup --suffix=_tmparchive -ah --info=progress2  /media/SDcard/* "${SDcard}"/ > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				`rm -rf /media/SDcard/*`
				`chmod -R 777 "${SDcard}"`
			else
				echo "TransferStatus=completed" > /etc/nas/config/sdcard-transfer-status.conf
				#echo "SDcard rsync fail !"
				sleep 1
				echo "18;0;" > /tmp/MCU_Cmd
				echo "status=failed" > /tmp/sdstats
				/usr/local/sbin/incUpdateCount.pm storage_transfer &
				total=`cat /tmp/sdsize  | sed -n '1p' | sed -n 's/.*=//p'`
                                if [ $total -eq 0 ];then       
                                    sed -i "s/status=.*/status=completed/" /tmp/sdstats                 
                                fi
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
#			rsync -aP /media/SDcard/ "${SDcard}"/
#			rsync --backup --backup-dir=Archive__${Count} -aP /media/SDcard/ "${SDcard}"/ > /dev/null 2>&1
			/usr/local/sbin/incUpdateCount.pm storage_transfer &
			rsync --backup --suffix=_tmparchive -ah --info=progress2  /media/SDcard/* "${SDcard}"/ > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				`chmod -R 777 "${SDcard}"`
			else
				echo "TransferStatus=completed" > /etc/nas/config/sdcard-transfer-status.conf
				sleep 1
				echo "18;0;" > /tmp/MCU_Cmd
				echo "status=failed" > /tmp/sdstats
				/usr/local/sbin/incUpdateCount.pm storage_transfer &
				total=`cat /tmp/sdsize  | sed -n '1p' | sed -n 's/.*=//p'`
                                if [ $total -eq 0 ];then       
                                    sed -i "s/status=.*/status=completed/" /tmp/sdstats                 
                                fi
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
sleep 2
echo "status=completed" > /tmp/sdstats
/usr/local/sbin/incUpdateCount.pm storage_transfer &
echo "18;0;" > /tmp/MCU_Cmd
echo "TransferStatus=completed" > /etc/nas/config/sdcard-transfer-status.conf
#echo "Transfer completed"
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


