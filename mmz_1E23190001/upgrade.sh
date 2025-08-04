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
$file_path/S99aforeinit.sh \
$file_path/reconnect_network.sh \
"

echo "$(date) upgrade.sh running" >> $dst_path/runinfo
cp -rf $upgrade_file $dst_path
chmod a+x /mmz/afrmc_* /mmz/*.sh

rm /etc/rc5.d/S99aforeinit.sh
cp /mmz/S99aforeinit.sh /etc/rc5.d/

conf_path=/mmz/conf/afrmc.conf 
cfg_powerset="UART_POWER_SET"
if [ ! "$(cat $conf_path | grep -w $cfg_powerset)" ];then
    sed -i '/UART_INVERTER_NUM=9#/aUART_POWER_SET=1#' $conf_path
fi

# 配置监控数据文件和串口参数
cfg_mode4G="UART_MODE_4G"
cfg_uartbaud_1E0A="UART_BAUD_1E0A"
cfg_uartbaud_1E2X="UART_BAUD_1E2X"
cfg_uartcapacity_1E0A="UART_STATION_CAPACITY_1E0A"
cfg_uartcapacity_1E2X="UART_STATION_CAPACITY_1E2X"

if [ ! "$(cat $conf_path | grep -w $cfg_mode4G)" ];then
    # 在 MONITOR_DATA_FILE 行后插入新配置
    sed -i 'MONITOR_DATA_FILE=/mmz/data/monitor.data#/aMODE_4G=PPP#' "$conf_path"
fi

if [ ! "$(cat $conf_path | grep -w $cfg_uartbaud_1E0A)" ];then
    sed -i '/\[AFUART\]/aUART_BAUD_1E0A=9600#' "$conf_path"
fi

if [ ! "$(cat $conf_path | grep -w $cfg_uartbaud_1E2X)" ];then
    sed -i '/\[AFUART\]/aUART_BAUD_1E2X=9600#' "$conf_path"
fi

if [ ! "$(cat $conf_path | grep -w $cfg_uartcapacity_1E0A)" ];then
    sed -i '/UART_BAUD_1E0A=/aUART_STATION_CAPACITY_1E0A=5500#' "$conf_path"
fi

if [ ! "$(cat $conf_path | grep -w $cfg_uartcapacity_1E2X)" ];then
    sed -i '/UART_BAUD_1E2X=/aUART_STATION_CAPACITY_1E2X=9900#' "$conf_path"
fi


old_monitor_server="MONITOR_SERVER_IP=.*#"
new_monitor_server="MONITOR_SERVER_IP=47.254.74.158#"
if [ "$(cat $conf_path |grep -w $old_monitor_server)" ];then
    sed -i "s/$old_monitor_server/$new_monitor_server/g" $conf_path
fi


sync
killall -9 afrmc_uart afrmc_monitor afrmc_control
