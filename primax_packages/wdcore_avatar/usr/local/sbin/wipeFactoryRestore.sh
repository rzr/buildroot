#!/bin/bash
#
# � 2010 Western Digital Technologies, Inc. All rights reserved.
#
# wipefactoryRestore.sh - Kick off factory restore with wipe
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

configFile="/etc/default/factory.conf"

reset_reg()
{
	fct_regdom=`fw_printenv | grep regdom | cut -d '=' -f 2`
	cur_regdom=`cat /etc/hostapd/hostapd.conf | grep country_code | cut -d '=' -f 2`
	if [ "$fct_regdom" != "" ] && [ "$cur_regdom" != "" ]; then
		if [ "$cur_regdom" != "$fct_regdom" ]; then
			sed -i 's/country_code='"$cur_regdom"'/country_code='"$fct_regdom"'/g' /etc/hostapd/hostapd.conf
		fi
	fi
}
AC_check()
{
    #check battery power for update
    echo "12;0;" > /tmp/MCU_Cmd
    AC=`cat /tmp/battery  | awk '{print $1}'`
    BatLevel=`cat /tmp/battery  | awk '{print $2}'`
    #echo ${BatLevel} ${AC}
    if [ ${BatLevel} -lt 25 ] || [ ${AC} == "discharging" ]; then
        echo  "insufficient_power"> /tmp/wipe-status
        exit 10
    fi 
}

if [ "$1" != "nopowercheck" ]; then
    AC_check
fi

if [ -f /usr/local/sbin/formatHDDMBR.sh ]; then
	echo "inprogress 0" > /tmp/wipe-status
	/usr/local/sbin/formatHDDparted.sh exfat llf >/dev/null 2>&1
	#echo "complete" > /tmp/wipe-status
	if [ -f $configFile ]; then
		tar -xvf $configFile -C / >/dev/null 2>&1
        if [ -f /etc/.eula_accepted ]; then
		    rm /etc/.eula_accepted
        fi
		rm -Rf /etc/updateCounts
        if [ -f /usr/local/nas/orion/orion.db ]; then
		    rm -f /usr/local/nas/orion/orion.db
        fi
        if [ -f /usr/local/nas/orion/jobs.db ]; then
            rm -f /usr/local/nas/orion/jobs.db
        fi
        /usr/local/sbin/device_security_set_config.sh false
        if [ -f "/etc/nas/.product_improvement_opt_in" ]; then
            rm -f /etc/nas/.product_improvement_opt_in
        fi
        #if [ -f "/etc/.device_configured" ]; then
        #    rm -f /etc/.device_configured
        #fi
	    reset_reg
        exit 0
	fi	
else
	exit 1
fi

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

