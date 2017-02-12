#!/bin/sh
mac=`echo $1 | tr [A-Z] [a-z]`
iw wlan1 station del $mac
OUT=$?
exit $OUT
