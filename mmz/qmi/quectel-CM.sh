#!/bin/sh

#读取配置文件
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
# 读取SIM卡APN
Return_Sub_Str=NULL
Sub_Str "SIM_APN"
Check_Return=$?
if [ $Check_Return -eq 0 ];then
if [ "$Return_Sub_Str" != "NULL" ];then
QL_APN=$Return_Sub_Str
echo $QL_APN
fi 
fi
#读取SIM卡用户
Return_Sub_Str=NULL
Sub_Str "SIM_USER"
Check_Return=$?
if [ $Check_Return -eq 0 ];then
if [ "$Return_Sub_Str" != "NULL" ];then
QL_USER=$Return_Sub_Str
echo $QL_USER
fi 
fi
#读取SIM卡密码
Return_Sub_Str=NULL
Sub_Str "SIM_USER"
Check_Return=$?
if [ $Check_Return -eq 0 ];then
if [ "$Return_Sub_Str" != "NULL" ];then
QL_PASSWORD=$Return_Sub_Str
echo $QL_PASSWORD
fi 
fi

#quectel-pppd devname apn user password
echo "quectel-qmi options in effect:"
QL_DEVNAME=/dev/ttyUSB3
# QL_APN=vmobile.jp
# QL_USER=qtnet@bbiq.jp
# QL_PASSWORD=bbiq
if [ $# -ge 1 ]; then
	QL_DEVNAME=$1	
	echo "devname   $QL_DEVNAME    # (from command line)"
else
	echo "devname   $QL_DEVNAME    # (default)"
fi
if [ $# -ge 2 ]; then
	QL_APN=$2	
	echo "apn       $QL_APN    # (from command line)"
else
	echo "apn       $QL_APN    # (default)"
fi
if [ $# -ge 3 ]; then
	QL_USER=$3	
	echo "user      $QL_USER   # (from command line)"
else
	echo "user      $QL_USER   # (default)"
fi
if [ $# -ge 4 ]; then
	QL_PASSWORD=$4	
	echo "password  $QL_PASSWORD   # (from command line)"
else
	echo "password  $QL_PASSWORD   # (default)"
fi

#开启4G网卡wwan0
/mmz/qmi/quectel-CM -s $QL_APN $QL_USER $QL_PASSWORD & 