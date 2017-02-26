#!/bin/sh
FW_Version=`cat output/target/etc/version`
rm -f MyPassportWireless_$FW_Version.bin
make clean
rm -Rf outputFWupg/
echo "Done"
