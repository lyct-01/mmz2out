#!/bin/sh
#==================== reconnect_network.sh ====================

Return_Sub_Str=NULL

# 防止重复启动
ps | grep "/mmz/reconnect_network.sh" | grep -v grep | grep -v $$ >/dev/null && exit

#------------------------------------------
# 从 afrmc.conf 获取值
#------------------------------------------
Sub_Str()
{
    if [ "$1" = "" ]; then
        return 1
    fi
    line=$(grep -n "$1" /mmz/conf/afrmc.conf | cut -d ":" -f 1)
    typeInf=$(head -n $line /mmz/conf/afrmc.conf | tail -n 1)
    typeInf=${typeInf%%#*}
    Return_Sub_Str=${typeInf##*=}
    return 0
}

#------------------------------------------
# 配置WiFi
#------------------------------------------
Set_Wifi_Info()
{
    Sub_Str "WIFI_NAME"
    Check_Return=$?
    if [ $Check_Return -eq 0 ] && [ "$Return_Sub_Str" != "NULL" ]; then
        WIFI_NAME=$Return_Sub_Str
    fi

    Return_Sub_Str=NULL
    Sub_Str "WIFI_PASSWORD"
    Check_Return=$?
    if [ $Check_Return -eq 0 ] && [ "$Return_Sub_Str" != "NULL" ]; then
        WIFI_PASSWORD=$Return_Sub_Str
    fi

    # 写 wpa_supplicant 配置
    cat > /mmz/wifi/wpa_supplicant.conf <<EOF
ctrl_interface=/var/run/wpa_supplicant
ap_scan=1
network={
ssid="$WIFI_NAME"
psk="$WIFI_PASSWORD"
}
EOF
}

#------------------------------------------
# 配置DNS
#------------------------------------------
echo "nameserver 114.114.114.114
nameserver 8.8.8.8" > /etc/resolv.conf

#------------------------------------------
# 读取配置
#------------------------------------------
Sub_Str "MONITOR_SENSOR_TYPE"; Network_Way=$Return_Sub_Str
Sub_Str "MODE_4G"; Mode_4G=$Return_Sub_Str
Sub_Str "CONTROL_NTP_SERVER"; CONTROL_NTP_SERVER=$Return_Sub_Str

#------------------------------------------
# 4G拨号函数
#------------------------------------------
do_4g_ppp()
{
    echo "-------------4G PPP reconnection-------------"
    killall pppd
    sleep 3
    killall -9 pppd 2>/dev/null
    sleep 2
    sh /mmz/ppp/peers/quectel-pppd.sh &

    # 等待 ppp0 接口出现
    timeout=30
    while [ $timeout -gt 0 ]; do
        if ifconfig ppp0 >/dev/null 2>&1; then
            echo "ppp0 up"
            return 0
        fi
        sleep 1
        timeout=$((timeout-1))
    done
    echo "ppp0 did not appear, 4G failed"
    return 1
}

#------------------------------------------
# 主逻辑
#------------------------------------------
case "$Network_Way" in
"4G")
    if [ "$Mode_4G" = "PPP" ]; then
        do_4g_ppp
    elif [ "$Mode_4G" = "QMI" ]; then
        killall -9 quectel-CM
        sleep 2
        sh /mmz/qmi/quectel-CM.sh &
    else
        echo "请设置 MODE_4G 为 PPP 或 QMI"
    fi
    sleep 10
    ;;
"WIFI")
    echo "-------------WiFi reconnection-------------"
    Set_Wifi_Info
    ifconfig wlan0 down
    ifconfig wlan0 up
    iw dev wlan0 scan
    wpa_supplicant -Dnl80211 -iwlan0 -c/mmz/wifi/wpa_supplicant.conf -B >/dev/null 2>&1
    udhcpc -i wlan0
    ;;
"ETH")
    echo "-------------ETH reconnection-------------"
    killall -9 udhcpc
    sleep 1
    udhcpc -i eth0
    ;;
"AUTO")
    echo "-------------AUTO reconnection-------------"
    ifconfig eth0 down
    ifconfig eth0 up
    udhcpc -i eth0
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "[AUTO] ETH connection OK"
    else
        echo "[AUTO] ETH failed, try 4G"
        do_4g_ppp
    fi
    ;;
*)
    echo "Network type error"
    exit 1
    ;;
esac

#------------------------------------------
# NTP同步
#------------------------------------------
time_num=0
while true; do
    ntpdate "$CONTROL_NTP_SERVER"
    if [ $? -eq 0 ]; then
        hwclock -u -w
        user_gpio GPIO5 3 1
        echo "NTP sync success"
        exit 0
    else
        user_gpio GPIO5 3 0
        echo "NTP sync failed"
    fi
    if [ $time_num -gt 5 ]; then
        exit 0
    fi
    sleep 2
    time_num=$((time_num+1))
done

exit 0