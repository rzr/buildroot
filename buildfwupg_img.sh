#!/bin/sh
make
rm -Rf output/build/busybox-1.21.0/
sleep 3
make
sleep 5
mkdir -p outputFWupg
cp -a FWupg.config outputFWupg/.config
make O=./outputFWupg
sleep 2
cp -a outputFWupg/build/linux-custom/arch/arm/configs/am335x_fwupdate_defconfig outputFWupg/build/linux-custom/.config
sleep 2
make O=./outputFWupg
FW_Version=`cat output/target/etc/version`
rm -f MyPassportWireless_$FW_Version.bin
mkdir -p fwupg_images
cd fwupg_images
echo "AV1W" > package
cp ../fwupg_patch/upgrade.sh .
cp ../output/images/MLO .
cp ../output/images/u-boot.img .
cp ../output/images/uImage .
cp ../output/images/AsmSataFw.bin .
cp ../outputFWupg/images/rootfs.cpio .
cp ../outputFWupg/images/uImage uImage-update
cp ../output/target/etc/version .
cp ../output/target/etc/version.packages .
cp ../output/target/etc/version.buildtime .
cd ..
tar cvfz "MyPassportWireless_$FW_Version.bin" fwupg_images/
rm -Rf fwupg_images/
md5sum "MyPassportWireless_$FW_Version.bin"
