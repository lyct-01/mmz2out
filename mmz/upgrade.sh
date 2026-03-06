#!/bin/bash

file_path=/mmz/upgrade
dst_path=/mmz

# upgrade_file="\
# $file_path/afrmc_uart \
# $file_path/afrmc_monitor \
# $file_path/afrmc_control \
# $file_path/afrmc_invup \
# $file_path/startAfrmc.sh \
# $file_path/checkafrc \
# $file_path/S99aforeinit.sh \
# $file_path/reconnect_network.sh \
# "

echo "$(date) upgrade.sh running" >> $dst_path/runinfo
# cp -rf $upgrade_file $dst_path
# chmod a+x /mmz/afrmc_* /mmz/*.sh

# rm /etc/rc5.d/S99aforeinit.sh
# cp /mmz/S99aforeinit.sh /etc/rc5.d/

conf_path=/mmz/conf/afrmc.conf 
cfg_powerset="UART_POWER_SET"
if [ ! "$(cat $conf_path | grep -w $cfg_powerset)" ];then
    sed -i '/UART_INVERTER_NUM=9#/aUART_POWER_SET=1#' "$conf_path"
fi

# 配置监控数据文件和串口参数
cfg_mode4G="UART_MODE_4G"
cfg_uartbaud_1E0A="UART_BAUD_1E0A"
cfg_uartbaud_1E2X="UART_BAUD_1E2X"
cfg_uartcapacity_1E0A="UART_STATION_CAPACITY_1E0A"
cfg_uartcapacity_1E2X="UART_STATION_CAPACITY_1E2X"

cfg_server_name="CONTROL_SERVER_NAME"
cfg_server_url="CONTROL_SERVER_URL"
cfg_ntp_server="CONTROL_NTP_SERVER"
cfg_control_id="CONTROL_ID"
cfg_sim_apn="SIM_APN"
cfg_sim_user="SIM_USER"
cfg_sim_password="SIM_PASSWORD"


# if [ ! "$(cat $conf_path | grep -w $cfg_mode4G)" ];then
#     # 在 MONITOR_DATA_FILE 行后插入新配置
#     sed -i 'MONITOR_DATA_FILE=/mmz/data/monitor.data#/aMODE_4G=PPP#' "$conf_path"
# fi

# if [ ! "$(cat $conf_path | grep -w $cfg_uartbaud_1E0A)" ];then
#     sed -i '/\[AFUART\]/aUART_BAUD_1E0A=9600#' "$conf_path"
# fi

# if [ ! "$(cat $conf_path | grep -w $cfg_uartbaud_1E2X)" ];then
#     sed -i '/\[AFUART\]/aUART_BAUD_1E2X=9600#' "$conf_path"
# fi

# if [ ! "$(cat $conf_path | grep -w $cfg_uartcapacity_1E0A)" ];then
#     sed -i '/UART_BAUD_1E0A=/aUART_STATION_CAPACITY_1E0A=5500#' "$conf_path"
# fi

# if [ ! "$(cat $conf_path | grep -w $cfg_uartcapacity_1E2X)" ];then
#     sed -i '/UART_BAUD_1E2X=/aUART_STATION_CAPACITY_1E2X=9900#' "$conf_path"
# fi

# 配置文件
# if [ ! "$(cat $conf_path | grep -w $cfg_server_url)" ];then
#     sed -i '/CONTROL_SERVER_NAME=/aCONTROL_SERVER_URL=https://re-ene.kyuden.co.jp/scheduleSend/#' "$conf_path"
# fi

# if [ ! "$(cat $conf_path | grep -w $cfg_control_id)" ];then
#     sed -i '/CONTROL_ID=/aCONTROL_NTP_SERVER=re-ene.kyuden.co.jp#' "$conf_path"
# fi

# if [ ! "$(cat $conf_path | grep -w $cfg_sim_apn)" ];then
#     sed -i '/CONTROL_NTP_SERVER=/aSIM_APN=soracom.io#' "$conf_path"
# fi

# if [ ! "$(cat $conf_path | grep -w $cfg_sim_user)" ];then
#     sed -i '/SIM_APN=/aSIM_USER=sora#' "$conf_path"
# fi

# if [ ! "$(cat $conf_path | grep -w $cfg_sim_password)" ];then
#     sed -i '/SIM_USER=/aSIM_PASSWORD=#' "$conf_path"
# fi


# old_monitor_server="MONITOR_SERVER_IP=.*#"
# new_monitor_server="MONITOR_SERVER_IP=47.254.74.158#"
# if [ "$(cat $conf_path |grep -w $old_monitor_server)" ];then
#     sed -i "s/$old_monitor_server/$new_monitor_server/g" $conf_path
# fi

# 修改出力控制类型
old_uart_power_set="UART_POWER_SET=.*#"
new_uart_power_set="UART_POWER_SET=1#"
if [ "$(cat $conf_path |grep -w $old_uart_power_set)" ];then
    sed -i "s/$old_uart_power_set/$new_uart_power_set/g" $conf_path
fi



sync
killall -9 afrmc_uart afrmc_monitor afrmc_control
