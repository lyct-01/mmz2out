#!/bin/bash
version=1E23170009.bin


file_path=$(pwd)
dst_path=$(pwd)/upgrade

upgrade_file="\
$file_path/afrmc_uart \
$file_path/afrmc_monitor \
$file_path/afrmc_control \
$file_path/afrmc_invup \
$file_path/startAfrmc.sh \
$file_path/checkafrc \
"
rm -rf $dst_path/*
cp upgrade.sh  $upgrade_file $dst_path
cd $dst_path

zip afrmc_upgrade.zip ./*
mv afrmc_upgrade.zip $version
exit 0
