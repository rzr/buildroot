#!/bin/bash
#
# � 2010 Western Digital Technologies, Inc. All rights reserved.
#
# storage_transfer_start_now.sh
#
# Used to manually initiate a Storage Transfer process
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

echo status=waiting > /tmp/sdstats
echo "total_size_in_bytes=0" > /tmp/sdsize_total
echo "transferred_size_in_bytes=0" > /tmp/sdsize

if [ ! -d /media/SDcard ]; then
    echo "Unable to locate storage device"
    exit 1
fi

if [ "$1" == "move" ] || [ "$1" == "copy" ]; then
	if [ "${TransferStatus}" == "process" ]; then
		exit 1
	fi
	if [ "$1" == "move" ]; then
		/sbin/SDCard_StorageTransfer.sh move true &
	fi
	if [ "$1" == "copy" ]; then
		/sbin/SDCard_StorageTransfer.sh copy true &
	fi
else
#	if [ ${AutoTransfer} == "true" ] && [ $# == 0 ]; then
		/sbin/SDCard_StorageTransfer.sh ${TransferMode} true &
#	else
#		exit 2
#	fi
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

