#!/bin/sh

# ========= 自复制到 /tmp 执行（避免运行中被删） =========
if [ "$0" != "/tmp/upgrade.sh" ]; then
    cp $0 /tmp/upgrade.sh
    chmod +x /tmp/upgrade.sh
    exec /tmp/upgrade.sh "$@"
    exit 0
fi

# ================= 路径 =================
UPGRADE_DIR=/mmz/upgrade
NEW_MMZ=$UPGRADE_DIR/mmz
TMP_MMZ=/mmz_new
MMZ_DIR=/mmz
BACKUP_MMZ=/mmz_backup

CONF_FILE=$MMZ_DIR/conf/afrmc.conf
NEW_CONF=/tmp/afrmc.conf.new

LOG=$MMZ_DIR/upgrade.log
LOCK=/tmp/upgrade.lock

exec >> $LOG 2>&1

echo "===== $(date) upgrade start ====="

# ================= 清理 =================
cleanup() {
    echo "cleanup..."
    rm -f $LOCK
}
trap cleanup EXIT

# ================= 日志轮转 =================
LOG_SIZE=$(du -k $LOG 2>/dev/null | awk '{print $1}')
[ ! -z "$LOG_SIZE" ] && [ "$LOG_SIZE" -gt 512 ] && {
    mv $LOG $LOG.old
    echo "log rotated" > $LOG
}

# ================= 锁 =================
[ -f $LOCK ] && {
    echo "upgrade already running"
    exit 0
}
touch $LOCK

# ================= 工具检查 =================
command -v unzip >/dev/null 2>&1 || {
    echo "unzip not found"
    exit 1
}

# ================= 配置读取 =================
get_cfg() {
    key=$1
    grep "^$key=" $CONF_FILE 2>/dev/null | head -n1 | cut -d= -f2 | cut -d'#' -f1
}

# ================= 配置提取（完整保留） =================
UART_BAUD_1E0A=$(get_cfg UART_BAUD_1E0A)
UART_BAUD_1E2X=$(get_cfg UART_BAUD_1E2X)
UART_BAUD_1E0A=${UART_BAUD_1E0A:-9600}
UART_BAUD_1E2X=${UART_BAUD_1E2X:-9600}

CONTROL_SERVER_URL=$(get_cfg CONTROL_SERVER_URL)
CONTROL_SERVER_URL=${CONTROL_SERVER_URL:-https://re-ene.kyuden.co.jp/scheduleSend/}

CONTROL_NTP_SERVER=$(get_cfg CONTROL_NTP_SERVER)
CONTROL_NTP_SERVER=${CONTROL_NTP_SERVER:-re-ene.kyuden.co.jp}

SIM_APN=$(get_cfg SIM_APN)
SIM_USER=$(get_cfg SIM_USER)
SIM_PASSWORD=$(get_cfg SIM_PASSWORD)

SIM_APN=${SIM_APN:-lte-mobile.jp}
SIM_USER=${SIM_USER:-test@aforejapan.ict.sphere.jp}
SIM_PASSWORD=${SIM_PASSWORD:-AFOREJAPAN1}

UART_STATION_CAPACITY_1E0A=$(get_cfg UART_STATION_CAPACITY_1E0A)
UART_STATION_CAPACITY_1E2X=$(get_cfg UART_STATION_CAPACITY_1E2X)

[ -z "$UART_STATION_CAPACITY_1E0A" ] && UART_STATION_CAPACITY_1E0A=$(get_cfg UART_STATION_CAPACITY)
[ -z "$UART_STATION_CAPACITY_1E2X" ] && UART_STATION_CAPACITY_1E2X=$(get_cfg UART_STATION_CAPACITY)

UART1_INVERTER_NUM=$(get_cfg UART1_INVERTER_NUM)
UART2_INVERTER_NUM=$(get_cfg UART2_INVERTER_NUM)

[ -z "$UART1_INVERTER_NUM" ] && UART1_INVERTER_NUM=$(get_cfg UART_INVERTER_NUM)
[ -z "$UART2_INVERTER_NUM" ] && UART2_INVERTER_NUM=$(get_cfg UART_INVERTER_NUM)

UART1_INVERTER_NUM=${UART1_INVERTER_NUM:-5}
UART2_INVERTER_NUM=${UART2_INVERTER_NUM:-0}

MONITOR_SENSOR_SN=$(get_cfg MONITOR_SENSOR_SN)
MONITOR_SENSOR_TYPE=$(get_cfg MONITOR_SENSOR_TYPE)
UART_POWER_SET=$(get_cfg UART_POWER_SET)
CONTROL_ID=$(get_cfg CONTROL_ID)

UART_POWER_SET=${UART_POWER_SET:-1}

[ -z "$MONITOR_SENSOR_SN" ] && {
    echo "sensor SN missing"
    exit 1
}

# ================= 停止服务 =================
echo "stop services..."

killall -9 checkafrc 2>/dev/null
killall -9 afrmc_uart 2>/dev/null
killall -9 afrmc_monitor 2>/dev/null
killall -9 afrmc_control 2>/dev/null

sleep 1
sync

# ================= 校验升级包 =================
cd $UPGRADE_DIR || exit 1

[ ! -f mmz.zip ] && {
    echo "mmz.zip not exist"
    exit 1
}

unzip -l mmz.zip | awk '{print $4}' | grep -qx "upgrade.sh" && {
    echo "invalid package"
    exit 1
}

# ================= 解压 =================
rm -rf $NEW_MMZ
mkdir -p $NEW_MMZ

unzip -o mmz.zip -d $NEW_MMZ || exit 1

[ -d "$NEW_MMZ/mmz" ] && NEW_MMZ="$NEW_MMZ/mmz"
[ -d "$NEW_MMZ/upgrade" ] && rm -rf $NEW_MMZ/upgrade

# ================= 校验 =================
for f in afrmc_monitor afrmc_uart afrmc_control checkafrc
do
    [ ! -f "$NEW_MMZ/$f" ] && {
        echo "missing $f"
        exit 1
    }
done

# ================= 生成配置（完整恢复） =================
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

# ================= 构建新系统 =================
rm -rf $TMP_MMZ
mkdir -p $TMP_MMZ

cp -rf $NEW_MMZ/. $TMP_MMZ/ || exit 1

mkdir -p $TMP_MMZ/conf
mv $NEW_CONF $TMP_MMZ/conf/afrmc.conf

# ================= 原子切换 =================
[ -d "$BACKUP_MMZ" ] && rm -rf $BACKUP_MMZ

mv $MMZ_DIR $BACKUP_MMZ || exit 1

mv $TMP_MMZ $MMZ_DIR || {
    echo "switch failed rollback"
    mv $BACKUP_MMZ $MMZ_DIR
    exit 1
}

sync

# ================= 权限修复 =================
find /mmz -type f -name "*.sh" -exec chmod +x {} \;
chmod +x /mmz/afrmc_* 2>/dev/null
chmod +x /mmz/checkafrc 2>/dev/null

# ================= 启动守护 =================
killall -9 checkafrc 2>/dev/null
sleep 1

/mmz/checkafrc >/dev/null 2>&1 &

# ================= 清理 =================
mkdir -p $MMZ_DIR/upgrade
rm -rf $MMZ_DIR/upgrade/*

echo "===== upgrade success (no reboot) ====="