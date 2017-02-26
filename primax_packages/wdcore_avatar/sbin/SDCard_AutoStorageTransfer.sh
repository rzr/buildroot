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

if [ "${AutoTransfer}" == "false" ]; then
	exit 0
else
   SDVolume=`df | grep /media/SDcard | awk '{ print $3 }'`
   HDDSpace=`df | grep /DataVolume | awk '{ print $4 }'`
   if [ "$SDVolume" == "" ]; then
        exit 1
   fi

   if [ "$SDVolume" -gt "$HDDSpace" ]; then                                             
        /usr/local/sbin/sendAlert.sh 2010 &
        /usr/local/sbin/incUpdateCount.pm storage_transfer &
        echo "status=failed" > /tmp/sdstats
        exit 1
   fi
   /usr/local/sbin/storage_transfer_job_start.sh &
fi

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


