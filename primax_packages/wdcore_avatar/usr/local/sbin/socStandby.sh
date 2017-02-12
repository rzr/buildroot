#!/bin/sh
echo "12;0;" > /tmp/MCU_Cmd
AC=`cat /tmp/battery  | awk '{print $1}'`
BatLevel=`cat /tmp/battery  | awk '{print $2}'`
if [ ${AC} == "charging" ]; then
    exit 0
fi
#/sbin/wifi-restart UPDATE_STA_CONF
#wpa_cli -i wlan0 disable_network 0
/etc/init.d/S90multi-role stop

/usr/local/sbin/getSerialNumber.sh
killall -16 ghelper
echo 3 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio3/direction
echo "36;0" > /tmp/MCU_Cmd
sleep 3
cd /sys/kernel/debug/omap_mux/board/
echo uart1_rxd.gpio0_14=0x27,rising > standby_gpio_pad_conf
echo "" > /tmp/StandbyMode
echo standby > /sys/power/state
