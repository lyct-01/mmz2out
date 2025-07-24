#!/bin/bash

file_path=/mmz/upgrade
dst_path=/mmz

upgrade_file="\
$file_path/afrmc_uart \
$file_path/afrmc_monitor \
$file_path/afrmc_control \
$file_path/afrmc_invup \
$file_path/startAfrmc.sh \
$file_path/checkafrc \
"

echo "$(date) upgrade.sh running" >> $dst_path/runinfo
cp -rf $upgrade_file $dst_path
chmod a+x /mmz/afrmc_* /mmz/*.sh

conf_path=/mmz/conf/afrmc.conf 
cfg_powerset="UART_POWER_SET"
if [ ! "$(cat $conf_path |grep -w $cfg_powerset)" ];then
    sed -i '/UART_INVERTER_NUM=9#/aUART_POWER_SET=1#' $conf_path
fi

old_monitor_server="MONITOR_SERVER_IP=47.88.8.200#"
new_monitor_server="MONITOR_SERVER_IP=47.102.152.71#"
if [ "$(cat $conf_path |grep -w $old_monitor_server)" ];then
    sed -i "s/$old_monitor_server/$new_monitor_server/g" $conf_path
fi


sync
killall -9 afrmc_uart afrmc_monitor afrmc_control
