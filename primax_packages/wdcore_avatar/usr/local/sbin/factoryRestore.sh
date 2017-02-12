#!/bin/bash

#---------------------


PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

#logger -s -t "$(basename $0)" "begin script: $@"
#. /etc/nas/config/wd-nas.conf 2>/dev/null
#. /etc/nas/config/share-param.conf
. /etc/system.conf

# accept parameter for skipping reformat (noreformat)

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
#CMD=${1:-"ext4"}

##########################################
# � 2010 Western Digital Technologies, Inc. All rights reserved.
#
# factoryRestore.sh - This script kicks off the factory restore process
##########################################
#echo "$CMD" > ${reformatDataVolume}

#/usr/bin/touch ${RESTORE_SETTINGS_FROM_DIR_TRIGGER}

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

AC_check_25_percent()
{
    echo "12;0;" > /tmp/MCU_Cmd
    AC=`cat /tmp/battery  | awk '{print $1}'`
    BatLevel=`cat /tmp/battery  | awk '{print $2}'`
    if [ ${BatLevel} -lt 25 ]; then
        echo  "insufficient_power"> /tmp/wipe-status
        exit 11
    fi
}

AC_check()
{
    echo "12;0;" > /tmp/MCU_Cmd
    AC=`cat /tmp/battery  | awk '{print $1}'`
    BatLevel=`cat /tmp/battery  | awk '{print $2}'`
    if [ ${BatLevel} -lt 25 ] || [ ${AC} == "discharging" ]; then
        echo  "insufficient_power"> /tmp/wipe-status
        exit 10
    fi
}

if [ $# -eq 0 ]; then
	AC_check
	/usr/local/sbin/wipeFactoryRestore.sh nocheckpower &
	if [ $? -eq 0 ]; then
		exit 0
	else
		exit 1
	fi
fi

if [ "$1" != "noreformat" ]; then
	exit 1
fi

AC_check_25_percent
if [ -f $configFile ] && [ ! -f /tmp/reset_done ]; then
    if [ -f "/etc/language.conf" ]; then
        rm -f /etc/language.conf
    fi
    tar -xvf $configFile -C / >/dev/null 2>&1
    #[ $? == "0" ] && echo "compeleted" > /etc/FacRestore
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
    if [ -f /CacheVolume/.twonkymedia/twonkyserver.ini ]; then
        /etc/init.d/S92twonkyserver stop
        rm -f /CacheVolume/.twonkymedia/twonkyserver.ini
        rm -f /CacheVolume/.twonkymedia/twonky.dat
        rm -f /CacheVolume/.twonkymedia/twonky.roles
        rm -f /CacheVolume/.twonkymedia/twonky.users
        rm -f /CacheVolume/.twonkymedia/twonky-locations-70.db
    fi
    #if [ -f "/etc/.device_configured" ]; then
    #	rm -f /etc/.device_configured
    #fi
    /usr/local/sbin/device_security_set_config.sh false &
    if [ -f "/etc/nas/.product_improvement_opt_in" ]; then
        rm -f /etc/nas/.product_improvement_opt_in
    fi
    reset_reg
    echo "compeleted" > /etc/FacRestore
    echo "29;1" > /tmp/MCU_Cmd 2>/dev/null
    echo "0" > /tmp/reset_done
else
    exit 1
fi

sqlite3 /CacheVolume/.wd-alert/wd-alert.db "DELETE FROM AlertHistory where 1"

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

