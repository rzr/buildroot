#!/bin/bash
#
# � 2010 Western Digital Technologies, Inc. All rights reserved.
#
# storage_transfer_get_config.sh
#
# Used to update the auto Storage Transfer property in the configuration.
#

#---------------------

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
. /etc/nas/config/sdcard-param.conf
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

while [ "$1" != "" ]; do
	case $1 in
			--auto_transfer )       shift
                              if [ "$1" == "true" ] || [ "$1" == "false" ]; then
                                sed -i 's/AutoTransfer=.*/AutoTransfer='${1}'/' /etc/nas/config/sdcard-param.conf
                              else
                                exit 1
                              fi                              
                              ;;
			--transfer_mode )       shift
                              if [ "$1" == "move" ] || [ "$1" == "copy" ]; then
                                sed -i 's/TransferMode=.*/TransferMode='${1}'/' /etc/nas/config/sdcard-param.conf
                              else
                                exit 1
                              fi                              
                              ;;
      * )                     echo "storage_transfer_get_config.sh  --auto_transfer true --transfer_mode move"
                              ;;      
	esac
	shift
done

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

