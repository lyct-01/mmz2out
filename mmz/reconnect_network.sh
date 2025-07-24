#!/bin/sh
#------------------------------------------------------------------------------
# fun:Sub_Str
# input arg:$1 --- process name
# return:
# 0 is exist, 1 is no exist
#------------------------------------------------------------------------------
Return_Sub_Str=NULL
Sub_Str()
{
  #check input arg
  if [ "$1" = "" ];
  then
    return 1
  fi
  line=$(grep -n "$1"  /mmz/conf/afrmc.conf | cut -d ":" -f 1)
  #读取SysConfig.ini第二行
  typeInf=$(head -n $line /mmz/conf/afrmc.conf|tail -n 1)
  #去除右边第一个'#'开始的后边所有字符
  typeInf=${typeInf%%#*}
  #去除左边最后一个'='前面所有字符
  Return_Sub_Str=${typeInf##*=}
  return 0
}

Set_Wifi_Info()
{
 #读取WiFi账号
 Sub_Str "WIFI_NAME"
 Check_Return=$?
 #Sub_Str函数返回值为0，并且Return_Sub_Str不为NULL
 #if [[ $Check_Return = 0 ]&&[ "$Return_Sub_Str" != "NULL"]];then
 #if [ $Check_Return = 0 && "$Return_Sub_Str" != "NULL"];then
 #if (( $Check_Return = 0 )) && (( "$Return_Sub_Str" != "NULL" ));then
 #if [ $Check_Return -eq 0 -a "$Return_Sub_Str" -ne "NULL" ];then
 if [ $Check_Return -eq 0 ] ;then
 if [ "$Return_Sub_Str" != "NULL" ];then
 WIFI_NAME=$Return_Sub_Str
 echo $WIFI_NAME
 fi
 fi
 #读取WiFi密码
 Return_Sub_Str=NULL
 Sub_Str "WIFI_PASSWORD"
 Check_Return=$?
 if [ $Check_Return -eq 0 ];then
 if [ "$Return_Sub_Str" != "NULL" ];then
 WIFI_PASSWORD=$Return_Sub_Str
 echo $WIFI_PASSWORD
 fi 
 fi 
 #配置WiFi
 echo "ctrl_interface=/var/run/wpa_supplicant
ap_scan=1
network={
ssid=\"$WIFI_NAME\"
psk=\"$WIFI_PASSWORD\"
}" > /mmz/wifi/wpa_supplicant.conf
 return 0
}

#配置DNS
echo "nameserver 114.114.114.114
nameserver 8.8.8.8" > /etc/resolv.conf

#读取联网方式
 Return_Sub_Str=NULL
 Sub_Str "MONITOR_SENSOR_TYPE"
 Check_Return=$?
 if [ $Check_Return -eq 0 ];then
 if [ "$Return_Sub_Str" != "NULL" ];then
 Network_Way=$Return_Sub_Str
 echo $Network_Way
 fi 
 fi 
 
 #4G重连
if [ "$Network_Way" = "4G" ];then
 echo "-------------4G reconnection-------------"
 killall quectel-CM
#  source /mmz/ppp/peers/quectel-pppd.sh &
#替换为qmi拨号
sh /mmz/qmi/quectel-CM.sh &

 sleep 10
#wifi重连
elif [ "$Network_Way" = "WIFI" ]; then
#rmmod /mmz/wifi/bcmdhd.ko
#sleep 1
#insmod /mmz/wifi/bcmdhd.ko
 echo "-------------wifi reconnection-------------"
 Set_Wifi_Info
 Check_Set_Wifi_Info_Return=$?
 if [ $Check_Set_Wifi_Info_Return -eq 0 ];then
 {
	ifconfig wlan0 down
	ifconfig wlan0 up
	iw dev wlan0 scan
	wpa_supplicant -Dnl80211 -iwlan0 -c/mmz/wifi/wpa_supplicant.conf -B > /dev/null 2>&1
	udhcpc -i wlan0
	#route add default dev wlan0
 }
 fi

#网线自动获取IP重连
elif [ "$Network_Way" = "ETH" ]; then
 echo "-------------ETH reconnection-------------"
 ifconfig eth0 down
 ifconfig eth0 up
 udhcpc -i eth0
 #route add default dev eth0
 #以太网/4G自适应
elif [ "Network_Way" = "AUTO" ]; then
	echo "-------------[AUTO] reconnection-------------"
	#先尝试以太网连接
	ifconfig eth0 down
	ifconfig eth0 up
	udhcpc -i eth0
	#核对网络连接性
	if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
		echo "[AUTO] ETH connection OK"
	#以太网失效连接4G
	else
		echo ""
		killall -9 pppd
		Ethernet "[AUTO] try 4G connection ."
		source /mmz/ppp/peers/quectel-pppd.sh &
		sleep 10
		if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
			echo "[AUTO] 4G OK"
		else
			echo "-------------Network[ETH&4G] error-------------"
			exit 1
		fi
	fi
else
#联网参数错误
 echo "-------------Network type error-------------"
 exit 1
fi

time_num=0		#每1分钟自增一次，计时40分钟ping 114网关
while [ 1 ] ; do
	ntpdate re-ene.kyuden.co.jp
	Check_time=$?
	if [ $Check_time -eq 0 ];then
		hwclock -u -w
		echo "-------------hwclock -u -w-------------"
		user_gpio GPIO5 3 1
		exit 0
	else
		user_gpio GPIO5 3 0
		echo "-------------ntpdate failed-------------"
	fi
	if [[ $time_num -gt 5 ]];then
		exit 0
	fi
	sleep 2
	let time_num+=1
done
exit 0

