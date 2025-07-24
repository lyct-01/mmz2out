#!/bin/sh

#quectel-pppd devname apn user password
echo "quectel-qmi options in effect:"
QL_DEVNAME=/dev/ttyUSB3
QL_APN=vmobile.jp
QL_USER=qtnet@bbiq.jp
QL_PASSWORD=bbiq
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