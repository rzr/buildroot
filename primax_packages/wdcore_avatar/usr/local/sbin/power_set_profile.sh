#!/bin/bash
#
# � 2010 Western Digital Technologies, Inc. All rights reserved.
#
# battery_set_power_profile.sh 
#
#

#---------------------



PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
. /etc/nas/config/share-param.conf
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
status=$1

case ${status} in
	max_life)
		echo "powerprofile="${status} > /etc/power.conf
		/usr/local/sbin/killService.sh hdd > /dev/null 2>&1
		/usr/local/sbin/stopFUSE.sh > /dev/null 2>&1
		/usr/local/sbin/killService.sh hddup > /dev/null 2>&1
		/etc/init.d/S98powerprofile restart > /dev/null 2>&1
        exit 0
        ;;
	max_system_performance)
		echo "powerprofile="${status} > /etc/power.conf
		/usr/local/sbin/killService.sh hdd > /dev/null 2>&1
		/usr/local/sbin/stopFUSE.sh > /dev/null 2>&1
		/usr/local/sbin/killService.sh hddup > /dev/null 2>&1
		/etc/init.d/S98powerprofile restart > /dev/null 2>&1
        exit 0
        ;;
	*)
		echo "usage: battery_set_power_profile.sh <max_life/max_system_performance>" 
        exit 1
esac
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
