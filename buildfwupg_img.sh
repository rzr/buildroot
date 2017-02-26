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
md5sum ../fwupg_patch/upgrade.sh | cut -c 1-32 > upgrade.sh.md5
cp ../output/images/MLO .
md5sum ../output/images/MLO | cut -c 1-32 > MLO.md5
cp ../output/images/u-boot.img .
md5sum ../output/images/u-boot.img | cut -c 1-32 > u-boot.img.md5
cp ../output/images/uImage .
md5sum ../output/images/uImage | cut -c 1-32 > uImage.md5
cp ../output/images/AsmSataFw.bin .
md5sum ../output/images/AsmSataFw.bin | cut -c 1-32 > AsmSataFw.bin.md5
cp ../outputFWupg/images/rootfs.cpio .
md5sum ../outputFWupg/images/rootfs.cpio | cut -c 1-32 > rootfs.cpio.md5
cp ../outputFWupg/images/uImage uImage-update
md5sum ../outputFWupg/images/uImage | cut -c 1-32 > uImage-update.md5
cp ../output/target/etc/version .
md5sum ../output/target/etc/version | cut -c 1-32 > version.md5
cp ../output/target/etc/version.packages .
md5sum ../output/target/etc/version.packages | cut -c 1-32 > version.packages.md5
cp ../output/target/etc/version.buildtime .
md5sum ../output/target/etc/version.buildtime | cut -c 1-32 > version.buildtime.md5
md5sum * > checklist
cd ..
tar cvfz "MyPassportWireless_$FW_Version.bin" fwupg_images/
rm -Rf fwupg_images/
md5sum "MyPassportWireless_$FW_Version.bin"
