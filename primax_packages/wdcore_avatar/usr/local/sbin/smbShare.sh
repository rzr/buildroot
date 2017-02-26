#! /bin/sh
#
# � 2010 Western Digital Technologies, Inc. All rights reserved.
#
#Script used to change host name and description.
#Usage:
#  machineName.sh Newname 'A nice description of machine'
#
# NOTE:  Caller to do all input validation
#

#---------------------


PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
. /etc/nas/config/share-param.conf
. /etc/system.conf

#---------------------
# Begin Script
#---------------------

if [ $# != 3 ]; then
	echo "usage: smbShare.sh <add|modify|delete> <share_name> <media_serving=ture/false>"
	exit 1
fi

echo $3 > media_serving_status

if [ $1 != "modify" ]; then
	exit 1
else
	if [ $2 == "Public" ]; then
		MediaServing=`cat media_serving_status | awk 'BEGIN {FS="="}  {printf $2"\n"}'`
		if [ $MediaServing == "true" ]; then 
#			echo [Public] MediaServing=$MediaServing
			
			#set twonkyserver-default.ini
			#sed -i 's/contentdir=.*/contentdir=+A|\/Public/' /usr/local/twonky/twonkyserver-default.ini
			#sed -i 's/servermanagedmusicdir=.*/servermanagedmusicdir=\/shares\/Public\//' /usr/local/twonky/twonkyserver-default.ini
			#sed -i 's/servermanagedpicturedir=.*/servermanagedpicturedir=\/shares\/Public\//' /usr/local/twonky/twonkyserver-default.ini
			#sed -i 's/servermanagedvideodir=.*/servermanagedvideodir=\/shares\/Public\//' /usr/local/twonky/twonkyserver-default.ini
            sed -i 's/contentdir=.*/contentdir=+A|\/Public/' /CacheVolume/.twonkymedia/twonkyserver.ini
			#restart server
			/etc/init.d/S92twonkyserver restart
			
		fi
		if [ $MediaServing == "false" ]; then
#			echo [Public] MediaServing=$MediaServing

                        #set twonkyserver-default.ini
                        #sed -i 's/contentdir=.*/contentdir=-A|\/Public/' /usr/local/twonky/twonkyserver-default.ini
                        #sed -i 's/servermanagedmusicdir=.*/servermanagedmusicdir=\/shares\/Public\//' /usr/local/twonky/twonkyserver-default.ini
                        #sed -i 's/servermanagedpicturedir=.*/servermanagedpicturedir=\/shares\/Public\//' /usr/local/twonky/twonkyserver-default.ini
                        #sed -i 's/servermanagedvideodir=.*/servermanagedvideodir=\/shares\/Public\//' /usr/local/twonky/twonkyserver-default.ini
            sed -i 's/contentdir=.*/contentdir=-A|\/Public/' /CacheVolume/.twonkymedia/twonkyserver.ini
            #restart server
            /etc/init.d/S92twonkyserver restart

		fi

	fi

	if [ $2 == "Private" ]; then
                MediaServing=`cat media_serving_status | awk 'BEGIN {FS="="}  {printf $2"\n"}'`
                if [ $MediaServing == "true" ]; then
#                        echo [Private] MediaServing=$MediaServing

                        #set twonkyserver-default.ini
                        #sed -i 's/contentdir=.*/contentdir=+A|\//' /usr/local/twonky/twonkyserver-default.ini
                        #sed -i 's/servermanagedmusicdir=.*/servermanagedmusicdir=\/shares\//' /usr/local/twonky/twonkyserver-default.ini
                        #sed -i 's/servermanagedpicturedir=.*/servermanagedpicturedir=\/shares\//' /usr/local/twonky/twonkyserver-default.ini
                        #sed -i 's/servermanagedvideodir=.*/servermanagedvideodir=\/shares\//' /usr/local/twonky/twonkyserver-default.ini
                        sed -i 's/contentdir=.*/contentdir=+A|\//' /CacheVolume/.twonkymedia/twonkyserver.ini
                        #restart server
                        /etc/init.d/S92twonkyserver restart 

                fi                                                                           
                if [ $MediaServing == "false" ]; then                                        
#                        echo [Private] MediaServing=$MediaServing 

                        #set twonkyserver-default.ini
                        #sed -i 's/contentdir=.*/contentdir=+A|\//' /usr/local/twonky/twonkyserver-default.ini
                        #sed -i 's/servermanagedmusicdir=.*/servermanagedmusicdir=\/shares\//' /usr/local/twonky/twonkyserver-default.ini            
                        #sed -i 's/servermanagedpicturedir=.*/servermanagedpicturedir=\/shares\//' /usr/local/twonky/twonkyserver-default.ini        
                        #sed -i 's/servermanagedvideodir=.*/servermanagedvideodir=\/shares\//' /usr/local/twonky/twonkyserver-default.ini        
                        sed -i 's/contentdir=.*/contentdir=-A|\//' /CacheVolume/.twonkymedia/twonkyserver.ini
                        #restart server                                                                                                             
                        /etc/init.d/S92twonkyserver restart  

                fi 
	fi 	
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



