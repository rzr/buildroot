#!/bin/bash

if [ -d /media/SDcard ]; then
    echo "`date +%Y/%m/%d-%H:%M:%S`:" >> /media/SDcard/MCU_Temp.log
    if [ -f /tmp/MCU_LongReport ]; then
        echo "31;0" > /tmp/MCU_Cmd
    fi
    cat /tmp/batteryPercent >> /media/SDcard/MCU_Temp.log
    cat /tmp/batterymV >> /media/SDcard/MCU_Temp.log
    cat /tmp/mcuTemperature >> /media/SDcard/MCU_Temp.log
    if [ -f /tmp/MCU_LongReport ]; then
        cat /tmp/batterymA >> /media/SDcard/MCU_Temp.log
        cat /tmp/batteryCycleCount >> /media/SDcard/MCU_Temp.log
        cat /tmp/batteryRemaining >> /media/SDcard/MCU_Temp.log
        cat /tmp/batteryRegister >> /media/SDcard/MCU_Temp.log
    fi
fi

