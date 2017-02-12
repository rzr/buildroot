#!/bin/bash

EXEC_PATH=$PWD
PATCH_FILE_DIR=$EXEC_PATH/primax_patch/rootfs_config_patch_dir
#PATCH_TARGET_DIR=$EXEC_PATH/output/target
PATCH_TARGET_DIR=$TARGET_DIR
PATCH_FILE_NUM=$(ls -lR $PATCH_FILE_DIR | grep '^-' | wc -l)
PATCH_SOURCE_CONFIG=$EXEC_PATH/.config

if [ $PATCH_FILE_NUM = 0 ]; then
    exit;
fi

cd $PATCH_FILE_DIR

PATCH_LIST=$(ls -Ald * | awk '{print $9}')

echo "$PATCH_LIST" &> /tmp/BUILDROOT_PATCH_TMP.$$

while read FILENAME
do 
    cd $PATCH_TARGET_DIR
    patch -p0 < $PATCH_FILE_DIR/$FILENAME
done < /tmp/BUILDROOT_PATCH_TMP.$$

rm -rf /tmp/BUILDROOT_PATCH_TMP.$$

DEFAULTSETTINGS_CONFIG=$(grep "BR2_PACKAGE_PMXPACKAGE_DEFAULTSETTINGS=y" ${PATCH_SOURCE_CONFIG} | wc -l)
if [ ${DEFAULTSETTINGS_CONFIG} -eq "1" ]; then
   if [ -f ${PATCH_TARGET_DIR}/etc/default/build_defconfig.sh ]; then
       echo "Generated Default Settings"
       ${PATCH_TARGET_DIR}/etc/default/build_defconfig.sh
       rm -f ${PATCH_TARGET_DIR}/etc/default/build_defconfig.sh
       rm -f ${PATCH_TARGET_DIR}/etc/default/saveconfigfiles.txt
   fi
fi
