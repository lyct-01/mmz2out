#!/bin/sh
source /etc/profile
chmod 755 /mmz/checkafrc
ifconfig eth0 192.168.1.123
rm /dev/ttymxc3
rm /mmz/log/*.log.*
rm /mmz/upgrade/*
sleep 1
ln /dev/ttymxc1 /dev/ttymxc3
cat /dev/ttyUSB2  > /mmz/4g_signal &
sleep 1
cd /mmz/
/mmz/afrmc_uart >> /dev/null &
sleep 1
/mmz/afrmc_control >> /dev/null &
sleep 1
/mmz/afrmc_monitor >> /dev/null &
sleep 1
/mmz/checkafrc >> /dev/null &
exit 0
