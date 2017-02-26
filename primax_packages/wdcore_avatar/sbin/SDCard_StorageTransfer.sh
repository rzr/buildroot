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
source /etc/power.conf
ACMode=`cat /tmp/battery | cut -d " " -f 1`
RuningStatus=0
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
#timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
function finishSdBackup()
{
	/sbin/AdaptCPUfreq.sh endbackup
	sleep 2
	echo "18;0;" > /tmp/MCU_Cmd
	/usr/local/sbin/incUpdateCount.pm storage_transfer &
	echo "TransferStatus=completed" > /etc/nas/config/sdcard-transfer-status.conf
	total=`cat /tmp/sdsize_total | sed -n '1p' | sed -n 's/.*=//p'` 
	echo "transferred_size_in_bytes=${total}" > /tmp/sdsize
	if [ $total -gt 0 ];then                                           
		while [ "$rsyncCt" == "0" ]; do
			rsyncCt=`ps aux | grep rsync | grep rv | wc -l`
			sleep 2
		done
		sed -i "s/status=.*/status=completed/" /tmp/sdstats
	fi
	/usr/local/sbin/storage_transfer_status.sh > /dev/null 2>&1 &
}

function removeTempfile()
{
	if [ -f "/tmp/AllCmpDir" ]; then
		rm /tmp/AllCmpDir
	fi

	if [ -f "/tmp/DoneFolder" ]; then
		rm /tmp/DoneFolder
	fi

	if [ -f "/tmp/BackUpTemplist" ]; then
		rm /tmp/BackUpTemplist
	fi
}
#timestamp=$(date "+%m-%d-%Y-%H%M")
timestamp=$(date "+%Y-%m-%d")

SDVolume=`df | grep /media/SDcard | awk '{ print $3 }'`
HDDSpace=`df | grep /DataVolume | awk '{ print $4 }'`
if [ "$SDVolume" == "" ]; then
	echo "18;0;" > /tmp/MCU_Cmd 
	exit 1
fi
echo 0 > /tmp/SDStatusError
echo status=waiting > /tmp/sdstats
echo "total_size_in_bytes=1024" > /tmp/sdsize_total
echo "transferred_size_in_bytes=1" > /tmp/sdsize
sctool `cat /tmp/SDDevNode`
[ -s "/tmp/CIDbackup" ] && CID=`cat /tmp/CIDbackup`
#CID=SDCard_`date +%Y.%m.%d.%H%M`
fullCID=`cat /tmp/fullCID`
#newCID=${CID}

#check CID mapping{ 
if [ `ls -al /media/sdb1/.wdcache/ | grep ${fullCID} | wc -l` -eq 0 ]; then
	CIDpath=`find /media/sdb1/SD\ Card\ Imports/ -name .${fullCID} -type f -maxdepth 3`
    if [ "${CIDpath}" != "" ]; then
    	CID=`echo ${CIDpath} | cut -c 29-40`
    fi
else
    CIDtmp=`cat /media/sdb1/.wdcache/.${fullCID}`
    if [ "$CIDtmp" != "$CID" ]; then
    	rm /media/sdb1/.wdcache/.${fullCID}
    else
    	CID=`cat /media/sdb1/.wdcache/.${fullCID}`
    fi	
fi
#} check CID mapping

if [ -d /media/sdb1_fuse ]; then
	ImportDIR="/media/sdb1_fuse/SD Card Imports/${CID}"
    SDcard="/media/sdb1_fuse/SD Card Imports/${CID}/${timestamp}"
else
	ImportDIR="/media/sdb1/SD Card Imports/${CID}"
    SDcard="/media/sdb1/SD Card Imports/${CID}/${timestamp}"
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
        echo "18;0;" > /tmp/MCU_Cmd 
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
	#sed -i 's/TransferStatus=.*/TransferStatus=process/' /etc/nas/config/sdcard-transfer-status.conf
	if [ "$SDVolume" -gt "$HDDSpace" ]; then                                             
		/usr/local/sbin/sendAlert.sh 2010 &                                          
		echo "18;0;" > /tmp/MCU_Cmd 
		exit 1                                                                       
	fi 
	if [ `ls -1 /media/SDcard/ | wc -l` -eq 0 ]; then
		mkdir -p "${SDcard}"
		sed -i "s/status=.*/status=completed/" /tmp/sdstats
		echo "18;0;" > /tmp/MCU_Cmd 
		exit 0
	fi
	
	mkdir -p "${SDcard}"
	if [ "$method" == "move" ]; then
		if [ `ps aux | grep rsync | grep /media/SDcard | wc -l` -ne 0 ] && [ `cat /etc/nas/config/sdcard-transfer-status.conf | grep process | wc -l` -ne 0 ]; then
			rm -rf "${SDcard}"
			killall -9 rsync
			echo "18;0;" > /tmp/MCU_Cmd 
			exit 1
		else
			echo "TransferStatus=process" > /etc/nas/config/sdcard-transfer-status.conf
			echo "22;0;"  > /tmp/MCU_Cmd
			sleep 2
			echo "18;1;" > /tmp/MCU_Cmd	
			/usr/local/sbin/incUpdateCount.pm storage_transfer &
			total_size=`rsync -rv /media/SDcard/ | grep "total size is" | awk '{print $4}' | sed -n 's/,//gp'`
            if [ $? -eq 0 ]; then
            	if [ "$total_size" != "" ] && [ "$total_size" != "0" ]; then
                	sed -i 's/total_size_in_bytes=.*/total_size_in_bytes='${total_size}'/' /tmp/sdsize_total
                fi
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
              	/sbin/AdaptCPUfreq.sh endbackup
                exit 1
            fi
            
            rsync -rv "${SDcard}" | grep "total size is" | awk '{print $4}' | sed -n 's/,//gp' > /tmp/sdbackedupsize
          	
			echo "${SDcard}" > /tmp/runningSDBackup
			#rsync --backup --suffix=_tmparchive -ahP --info=progress2  /media/SDcard/* "${SDcard}"/ > /dev/null 2>&1
			#rsync -ahP --info=progress2 --existing --backup --suffix=_tmparchive /media/SDcard/* "${SDcard}"/ > /dev/null 2>&1
			#sleep 1
			removeTempfile
			echo "status=running" > /tmp/sdstats	
			/sbin/AdaptCPUfreq.sh startbackup	
			SDCard_CalTransfer.sh > /dev/null 2>&1 &
			ls -F "${ImportDIR}"/ | grep \/$ > /tmp/DoneFolder
			cat /tmp/DoneFolder | while read DoneFolders
			do
				if [ "$timestamp"\/ == "$DoneFolders" ]; then
					filenum=`ls -al "${SDcard}" | wc -l`
					if [ "$filenum" -eq 1 ]; then
						continue	
					fi
				fi
				CmpDirs=""${ImportDIR}"/${DoneFolders}"
				AllDir="$AllDir"" "\""$CmpDirs"\"
				echo "$AllDir" > /tmp/AllCmpDir
			done

			cat /tmp/DoneFolder | while read DoneFolders
			do
				CmpDirs=""${ImportDIR}"/${DoneFolders}"
				nice -n -19 rsync -ah --existing --backup --suffix=_tmparchive /media/SDcard/ "${CmpDirs}" > /dev/null 2>&1
				if [ $? != 0 ]; then
					echo "1" > /tmp/SDStatusError
					break
				fi
				find "${CmpDirs}" -name "*_tmparchive" > /tmp/sdArchivePath
				ArchiveCount=`cat /tmp/sdArchivePath | grep -c _tmparchive`
				if [ ${ArchiveCount} != 0 ]; then
   					for  ((i=1; i<=$ArchiveCount; i=i+1))    
    				do
        				ArchivePath=`cat /tmp/sdArchivePath | sed -n "${i}p"`
        				filetimestamp=`stat -c %y "${ArchivePath}" | cut -d "." -f 1`
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
						#Rpathname=`echo $ArchivePath | cut -c ${#CmpDirs}-${#ArchivePath}`
						#nobackup=${Rpathname%%$tmpname} 
						#echo "nobackup" "$nobackup"
						mv "${SDpath}/${tmpname}" "${SDpath}/${newname}"
						touch --date="${filetimestamp}" "${SDpath}/${newname}"
    				done
    				rm /tmp/sdArchivePath
				fi
			done

			if [ -f "/tmp/AllCmpDir" ]; then
				AllCmpDirs=`cat /tmp/AllCmpDir`		
				RsyncExecmd="rsync -avun --modify-window=1 --iconv=UTF-8 --delete"${AllCmpDirs}" /media/SDcard/ | grep -v ".wdmc" > /tmp/BackUpTemplist" 
				eval "$RsyncExecmd"	
				cat /tmp/BackUpTemplist | grep "RSYNC_delete_DIR" | while read backupfile
				do
					backupfile=`echo "$backupfile" | awk 'BEGIN{FS="RSYNC_delete_DIR " } {print $NF}'`
					#echo "DIR backupfile" "$backupfile"
					if [ -d "/media/SDcard/${backupfile}" ] && [ ! -d "${SDcard}/${backupfile}" ]; then
						fname=`dirname "${SDcard}"\/"${backupfile}"`
						if [ ! -d "${fname}" ]; then
							mkdir -p "${fname}"
							#echo "create" "$fname"
						fi
						execmd="nice -n -19 mv -f \"/media/SDcard/${backupfile}\" \"${SDcard}/${backupfile}\" > /dev/null 2>&1"
						eval "$execmd"
						#echo "Move directory execmd:" "$execmd"
					fi
				done
		
				cat /tmp/BackUpTemplist | grep "RSYNC_delete_ITEM" | while read backupfile
				do
					backupfile=`echo "$backupfile" | awk 'BEGIN{FS="RSYNC_delete_ITEM " } {print $NF}'`
					#echo "ITEM backupfile" "$backupfile"
					fname=`dirname "${SDcard}"\/"${backupfile}"`
					if [ ! -d "${fname}" ]; then
						mkdir -p "${fname}"
						#echo "create" "$fname"
					fi
					if [ ! -d "${SDcard}/${backupfile}" ] && [ ! -f "${SDcard}/${backupfile}" ]; then
						execmd="nice -n -19 mv -f \"/media/SDcard/${backupfile}\" \"${SDcard}/${backupfile}\" > /dev/null 2>&1"
						#echo "execmd" "$execmd"
						eval "$execmd"
						if [ $? != 0 ]; then
							echo "1" > /tmp/SDStatusError
							break
						fi	
					fi
				done
			else
				execmd="nice -n -19 mv -f /media/SDcard/* \"${SDcard}/\" > /dev/null 2>&1"
				eval "$execmd"
				if [ $? != 0 ]; then
					echo "1" > /tmp/SDStatusError
				fi
				
				execmd="nice -n -19 mv -f /media/SDcard/.[^.]* \"${SDcard}/\" > /dev/null 2>&1"
				eval "$execmd"
				if [ $? != 0 ]; then
					echo "1" > /tmp/SDStatusError
				fi
				#echo "$execmd"
			fi		
		
			if [ "$(cat /tmp/BackUpTemplist | grep "RSYNC_delete_DIR")" == "" ] && [ "$(cat /tmp/BackUpTemplist | grep "RSYNC_delete_ITEM")" == "" ]; then
				filenum=`ls -al "${SDcard}" | wc -l`
				if [ "$filenum" -eq 1 ]; then
					rm -rf "${SDcard}"		
					#finishSdBackup
				fi
			fi
			removeTempfile
			RuningStatus=`cat /tmp/SDStatusError`
			if [ "${RuningStatus}" -eq 0 ]; then
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
				if [ -f "/tmp/runningSDBackup" ]; then
					rm /tmp/runningSDBackup
				fi
				/sbin/AdaptCPUfreq.sh endbackup
				killall -9 rsync > /dev/null 2>&1
				exit 1
			fi
            sync
            sync
            sync
		fi
	fi	
	if [ "$method" == "copy" ]; then
        if [ `ps aux | grep rsync | grep /media/SDcard | wc -l` -ne 0 ] && [ `cat /etc/nas/config/sdcard-transfer-status.conf | grep process | wc -l` -ne 0 ]; then
			rm -rf "${SDcard}"
			killall -9 rsync > /dev/null 2>&1
			exit 1
		else
			echo "TransferStatus=process" > /etc/nas/config/sdcard-transfer-status.conf
			echo "22;0;"  > /tmp/MCU_Cmd
			sleep 2
			echo "18;1;" > /tmp/MCU_Cmd
			/usr/local/sbin/incUpdateCount.pm storage_transfer &
			total_size=`rsync -rv /media/SDcard/ | grep "total size is" | awk '{print $4}' | sed -n 's/,//gp'`
            if [ $? -eq 0 ]; then
            	if [ "$total_size" != "" ] && [ "$total_size" != "0" ]; then
                	sed -i 's/total_size_in_bytes=.*/total_size_in_bytes='${total_size}'/' /tmp/sdsize_total
                fi
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
            #sleep 1
            rsync -rv "${SDcard}" | grep "total size is" | awk '{print $4}' | sed -n 's/,//gp' > /tmp/sdbackedupsize
			echo "${SDcard}" > /tmp/runningSDBackup
			removeTempfile
			echo "status=running" > /tmp/sdstats
			/sbin/AdaptCPUfreq.sh startbackup
			SDCard_CalTransfer.sh > /dev/null 2>&1 &
			ls -F "${ImportDIR}"/ | grep \/$ > /tmp/DoneFolder
			cat /tmp/DoneFolder | while read DoneFolders
			do
				if [ "$timestamp"\/ == "$DoneFolders" ]; then
					filenum=`ls -al "${SDcard}" | wc -l`
					if [ "$filenum" -eq 1 ]; then
						continue	
					fi
				fi
				CmpDirs=""${ImportDIR}"/${DoneFolders}"
				AllDir="$AllDir"" "\""$CmpDirs"\"
				echo "$AllDir" > /tmp/AllCmpDir
			done
			
			if [ -f "/tmp/AllCmpDir" ]; then
				AllCmpDirs=`cat /tmp/AllCmpDir`		
				RsyncExecmd="rsync -avun --modify-window=1 --iconv=UTF-8 --delete"${AllCmpDirs}" /media/SDcard/ | grep -v ".wdmc" > /tmp/BackUpTemplist" 
				eval "$RsyncExecmd"	
				cat /tmp/BackUpTemplist | grep "RSYNC_delete_DIR" | while read backupfile
				do
					backupfile=`echo "$backupfile" | awk 'BEGIN{FS="RSYNC_delete_DIR " } {print $NF}'`
					#echo backupfile "$backupfile"
					if [ -d "/media/SDcard/${backupfile}" ] && [ ! -d "${SDcard}/${backupfile}" ]; then
						fname=`dirname "${SDcard}"\/"${backupfile}"`
						if [ ! -d "${fname}" ]; then
							mkdir -p "${fname}"
							#echo "create" "$fname"
						fi
						#echo "create" "${SDcard}"\/"${backupfile}"
						execmd="nice -n -19 cp -a \"/media/SDcard/${backupfile}\" \"${SDcard}/${backupfile}\" > /dev/null 2>&1"
						eval "$execmd"
						#echo "copy directory execmd:" "$execmd"
					fi
				done
				
				cat /tmp/BackUpTemplist | grep "RSYNC_delete_ITEM" | while read backupfile
				do
					backupfile=`echo "$backupfile" | awk 'BEGIN{FS="RSYNC_delete_ITEM " } {print $NF}'`
					#echo backupfile "$backupfile"
					if [ -d "/media/SDcard/${backupfile}" ] && [ ! -d "${SDcard}/${backupfile}" ]; then
						mkdir -p "${SDcard}"\/"${backupfile}"
						#echo "create" "${SDcard}"\/"${backupfile}"
					else
						fname=`dirname "${SDcard}"\/"${backupfile}"`
						if [ ! -d "${fname}" ]; then
							mkdir -p "${fname}"
							#echo "create" "$fname"
						fi
						if [ ! -d "${SDcard}/${backupfile}" ] && [ ! -f "${SDcard}/${backupfile}" ]; then
							execmd="nice -n -19 cp -a \"/media/SDcard/${backupfile}\" \"${SDcard}/${backupfile}\" > /dev/null 2>&1"
							eval "$execmd"
							if [ $? != 0 ]; then
								echo "1" > /tmp/SDStatusError
								break
							fi
							#echo "execmd" "$execmd"
						fi
					fi
				done
			else
				execmd="nice -n -19 cp -a /media/SDcard/* \"${SDcard}/\" > /dev/null 2>&1"
				eval "$execmd"
				if [ $? != 0 ]; then
					echo "1" > /tmp/SDStatusError
				fi
				execmd="nice -n -19 cp -a /media/SDcard/.[^.]* \"${SDcard}/\" > /dev/null 2>&1"
				eval "$execmd"
				if [ $? != 0 ]; then
					echo "1" > /tmp/SDStatusError
				fi
				#echo "$execmd"
			fi
			cat /tmp/DoneFolder | while read DoneFolders
			do
				CmpDirs=""${ImportDIR}"/${DoneFolders}"
				nice -n -19 rsync -ah --existing --backup --suffix=_tmparchive /media/SDcard/ "${CmpDirs}" > /dev/null 2>&1
				if [ $? != 0 ]; then
					echo "1" > /tmp/SDStatusError
					break
				fi
				find "${CmpDirs}" -name "*_tmparchive" > /tmp/sdArchivePath
				ArchiveCount=`cat /tmp/sdArchivePath | grep -c _tmparchive`
				if [ ${ArchiveCount} != 0 ]; then
   					for  ((i=1; i<=$ArchiveCount; i=i+1))    
    				do
        				ArchivePath=`cat /tmp/sdArchivePath | sed -n "${i}p"`
        				filetimestamp=`stat -c %y "${ArchivePath}" | cut -d "." -f 1`
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
						#Rpathname=`echo $ArchivePath | cut -c ${#CmpDirs}-${#ArchivePath}`
						#nobackup=${Rpathname%%$tmpname} 
						#echo "nobackup" "$nobackup"
						mv "${SDpath}/${tmpname}" "${SDpath}/${newname}"
						touch --date="${filetimestamp}" "${SDpath}/${newname}"
						
						#if [ ! -d "${SDcard}/${nobackup}" ]; then
						#	mkdir -p "${SDcard}/${nobackup}"
						#fi
						#echo "create" "${SDcard}/${nobackup}"
						#if [ ! -f "${SDcard}/${nobackup}${oldname}" ]; then
						#	cp -f "${SDpath}/${oldname}" "${SDcard}/${nobackup}"
						#fi
						#mv -f "${SDpath}/${newname}" "${SDpath}/${oldname}"
    				done
    				rm /tmp/sdArchivePath
				fi
			done
			
			if [ "$(cat /tmp/BackUpTemplist | grep "RSYNC_delete_DIR")" == "" ] && [ "$(cat /tmp/BackUpTemplist | grep "RSYNC_delete_ITEM")" == "" ]; then
				filenum=`ls -al "${SDcard}" | wc -l`
				if [ "$filenum" -eq 1 ]; then
					#finishSdBackup
					rm -rf "${SDcard}"		
				fi
			fi	
			removeTempfile
			#rsync --backup --suffix=_tmparchive -ahP --info=progress2 /media/SDcard/* "${SDcard}"/ > /dev/null 2>&1
			RuningStatus=`cat /tmp/SDStatusError`
			if [ "${RuningStatus}" -eq 0 ]; then
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
				if [ -f "/tmp/runningSDBackup" ]; then
					rm /tmp/runningSDBackup
				fi
				/sbin/AdaptCPUfreq.sh endbackup
				killall -9 rsync > /dev/null 2>&1
				exit 1
			fi    		
			
			sync
			sync
			sync
		fi
	fi
fi

# archive the file with the same name{
#find /media/sdb1/SD\ Card\ Imports/${CID}/${timestamp}/ -name "*_tmparchive" > /tmp/sdArchivePath
#ArchiveCount=`cat /tmp/sdArchivePath | grep -c _tmparchive`
#if [ ${ArchiveCount} != 0 ]; then
#    for  ((i=1; i<=$ArchiveCount; i=i+1))    
#    do
#        ArchivePath=`cat /tmp/sdArchivePath | sed -n "${i}p"`
#        SDpath="${ArchivePath%/*}"
#        tmpname=${ArchivePath##*/}
#	oldname=${tmpname%%_tmparchive} 
#	name=${oldname%.*}     
#	havepoint=`echo ${oldname} | grep "\." | wc -l`
#	if [ `echo ${oldname} | grep "\." | wc -l` -eq 0 ]; then
#            newname="${name}-backup-`date +%Y.%m.%d.%H%M`"
#	else
#	    subname=${oldname##*.}                                                                            
#	    newname="${name}-backup-`date +%Y.%m.%d.%H%M`.${subname}"
#	fi
#	mv "${SDpath}/${tmpname}" "${SDpath}/${newname}"
#    done
#    rm /tmp/sdArchivePath
#fi
#} archive the file with the same name
echo ${CID} > /media/sdb1/.wdcache/.${fullCID}
echo ${CID} > /media/sdb1/SD\ Card\ Imports/${CID}/${timestamp}/.${fullCID}
finishSdBackup

sync
sync
sync

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


