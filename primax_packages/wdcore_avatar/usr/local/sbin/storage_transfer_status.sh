#!/bin/bash
#
if [ `cat /tmp/sdstats | sed -n 's/.*=//p'` == "completed" ]; then
    total=`cat /tmp/sdsize_total  | sed -n '1p' | sed -n 's/.*=//p'`
    sed -i "s/transferred_size_in_bytes=.*/transferred_size_in_bytes=$total/" /tmp/sdsize
fi
cat /tmp/sdsize_total
cat /tmp/sdsize
cat /tmp/sdstats
