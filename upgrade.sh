#!/bin/sh


# 路径定义

UPGRADE_DIR=/mmz/upgrade
NEW_MMZ=$UPGRADE_DIR/mmz
MMZ_DIR=/mmz
CONF_FILE=$MMZ_DIR/conf/afrmc.conf
NEW_CONF=/tmp/afrmc.conf.new

LOG=$MMZ_DIR/upgrade.log
LOCK=/tmp/upgrade.lock

echo "===== $(date) upgrade start =====" >> $LOG



# 日志轮转（防止日志过大）

LOG_SIZE=$(du -k $LOG 2>/dev/null | awk '{print $1}')

if [ ! -z "$LOG_SIZE" ] && [ "$LOG_SIZE" -gt 512 ]; then
    mv $LOG $LOG.old
    echo "log rotated" > $LOG
fi



# 升级锁

if [ -f $LOCK ]; then
    echo "upgrade already running" >> $LOG
    exit 0
fi

touch $LOCK



# 检查升级工具

command -v unzip >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "unzip not found" >> $LOG
    rm -f $LOCK
    exit 1
fi



# 读取配置函数

get_cfg()
{
    key=$1
    grep "^$key=" $CONF_FILE 2>/dev/null | head -n1 | cut -d= -f2 | cut -d'#' -f1
}



# 提取旧配置

# 规则1：提取若无则默认
UART_BAUD_1E0A=$(get_cfg UART_BAUD_1E0A)
UART_BAUD_1E2X=$(get_cfg UART_BAUD_1E2X)

[ -z "$UART_BAUD_1E0A" ] && UART_BAUD_1E0A=9600
[ -z "$UART_BAUD_1E2X" ] && UART_BAUD_1E2X=9600


CONTROL_SERVER_URL=$(get_cfg CONTROL_SERVER_URL)
[ -z "$CONTROL_SERVER_URL" ] && CONTROL_SERVER_URL=https://re-ene.kyuden.co.jp/scheduleSend/


CONTROL_NTP_SERVER=$(get_cfg CONTROL_NTP_SERVER)
[ -z "$CONTROL_NTP_SERVER" ] && CONTROL_NTP_SERVER=re-ene.kyuden.co.jp


SIM_APN=$(get_cfg SIM_APN)
SIM_USER=$(get_cfg SIM_USER)
SIM_PASSWORD=$(get_cfg SIM_PASSWORD)

[ -z "$SIM_APN" ] && SIM_APN=lte-mobile.jp
[ -z "$SIM_USER" ] && SIM_USER=test@aforejapan.ict.sphere.jp
[ -z "$SIM_PASSWORD" ] && SIM_PASSWORD=AFOREJAPAN1


UART_STATION_CAPACITY_1E0A=$(get_cfg UART_STATION_CAPACITY_1E0A)
UART_STATION_CAPACITY_1E2X=$(get_cfg UART_STATION_CAPACITY_1E2X)

if [ -z "$UART_STATION_CAPACITY_1E0A" ]; then
    UART_STATION_CAPACITY_1E0A=$(get_cfg UART_STATION_CAPACITY)
fi

if [ -z "$UART_STATION_CAPACITY_1E2X" ]; then
    UART_STATION_CAPACITY_1E2X=$(get_cfg UART_STATION_CAPACITY)
fi


UART1_INVERTER_NUM=$(get_cfg UART1_INVERTER_NUM)
UART2_INVERTER_NUM=$(get_cfg UART2_INVERTER_NUM)

if [ -z "$UART1_INVERTER_NUM" ]; then
    UART1_INVERTER_NUM=$(get_cfg UART_INVERTER_NUM)
fi

if [ -z "$UART2_INVERTER_NUM" ]; then
    UART2_INVERTER_NUM=$(get_cfg UART_INVERTER_NUM)
fi


MONITOR_SENSOR_SN=$(get_cfg MONITOR_SENSOR_SN)
MONITOR_SENSOR_TYPE=$(get_cfg MONITOR_SENSOR_TYPE)
UART_POWER_SET=$(get_cfg UART_POWER_SET)
CONTROL_ID=$(get_cfg CONTROL_ID)



# 基本校验

if [ -z "$MONITOR_SENSOR_SN" ]; then
    echo "sensor SN missing, upgrade aborted" >> $LOG
    rm -f $LOCK
    exit 1
fi



# 停止程序

killall -9 afrmc_uart 2>/dev/null
killall -9 afrmc_monitor 2>/dev/null
killall -9 afrmc_control 2>/dev/null

sync



# 校验升级包

cd $UPGRADE_DIR

if [ ! -f mmz.zip ]; then
    echo "mmz.zip not exist" >> $LOG
    rm -f $LOCK
    exit 1
fi

# 解压升级包
rm -rf $NEW_MMZ
unzip -o mmz.zip -d $UPGRADE_DIR >> $LOG 2>&1

if [ ! -d $NEW_MMZ ]; then
    echo "unzip failed" >> $LOG
    rm -f $LOCK
    exit 1
fi



# 生成新配置

cat > $NEW_CONF << EOF
[AFRM]
MONITOR_PLATFORM=SOLARMAN#
MONITOR_SENSOR_SN=${MONITOR_SENSOR_SN}#
MONITOR_SENSOR_TYPE=${MONITOR_SENSOR_TYPE}#
MONITOR_SERVER_IP=47.254.74.158#
MONITOR_SERVER_PORT=10000#
MONITOR_DATA_FILE=/mmz/data/monitor.data#
MODE_4G=PPP#

[AFUART]
UART_BAUD_1E0A=${UART_BAUD_1E0A}#
UART_BAUD_1E2X=${UART_BAUD_1E2X}#
UART_STATION_CAPACITY_1E0A=${UART_STATION_CAPACITY_1E0A}#
UART_STATION_CAPACITY_1E2X=${UART_STATION_CAPACITY_1E2X}#
UART_INVERTER_NUM=9#
UART1_INVERTER_NUM=${UART1_INVERTER_NUM}#
UART2_INVERTER_NUM=${UART2_INVERTER_NUM}#
UART_POWER_SET=${UART_POWER_SET}#

[AFRC]
CONTROL_SERVER_NAME=re-ene.kyuden.co.jp#
CONTROL_SERVER_URL=${CONTROL_SERVER_URL}#
CONTROL_SERVER_PORT=443#
CONTROL_ID=${CONTROL_ID}#
CONTROL_NTP_SERVER=${CONTROL_NTP_SERVER}#

[4G]
SIM_APN=${SIM_APN}#
SIM_USER=${SIM_USER}#
SIM_PASSWORD=${SIM_PASSWORD}#

[WIFI]
WIFI_NAME=www.com#
WIFI_PASSWORD=123456#
EOF


# 整目录升级

echo "replace /mmz ..." >> $LOG
cp -rf $NEW_MMZ/. $MMZ_DIR/


# 写入新配置

mkdir -p $MMZ_DIR/conf
mv $NEW_CONF $CONF_FILE


# 赋予权限

chmod a+x /mmz/*.sh
chmod a+x /mmz/afrmc_*

# 写入启动脚本

rm -f /etc/rc5.d/S99aforeinit.sh
cp /mmz/S99aforeinit.sh /etc/rc5.d/

# 清理升级压缩包

rm -rf $NEW_MMZ
rm -f $UPGRADE_DIR/mmz.zip

sync

echo "===== upgrade success =====" >> $LOG

rm -f $LOCK

reboot