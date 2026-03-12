#!/bin/bash

upgrade = /mmz/upgrade
mmz_dir = /mmz
backup_dir = /mmz/backup #TODO
new_package_zip = /mmz/$upgrade/mmz_1E23190002.zip

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 开始升级
log "==================== 开始mmz升级流程 ===================="

# 检查新包存在与否

if [ ! -f "$new_package_zip" ]; then
    error_exit "新mmz包不存在: $new_package_zip"
fi

# 解压新包

cd $upgrade
unzip -o $new_package_zip -d $upgrade/new_mmz
echo "解压完成"

# 配置迁移
new_conf = "$upgrade_dir/"
old_conf = $backup/afrmc.conf

if [ -f "$old_conf" ] && [ -f "new_conf" ]; then
    # 提取旧配置项
    get_value(){
        grep "^$1=" "$old_conf" 2>/dev/null | cut -d'=' -f2 | cut -d'#' -f1 | sed 's/ *$//' 
    }

    # 更新配置项
    upgrade_config(){
        local key = $1
        local old_value = $(get_value "$key")
        [ -z $old_value ] && return

        if grep -q "^$key=" "$new_conf"; then
            sed -i "s|^$key=.*|$key=$old_value|" "$new_conf"
            echo "更新：$key=$old_value"
        fi

    }
    update_config "MONITOR_PLATFORM"
    # ...  
fi

if [ -d "$upgrade/new_mmz" ]; then
    mv "$mmz_dir" "$backup_dir/mmz_old"

    # 移动新目录
    mv "$upgrade_dir/new_mmz"

    echo "替换mmz目录"
    
fi

# 设置权限
chmod +x $mmz_dir/afrmc_* $mmz_dir/*.sh 2>/dev/null
chmod +x $mmz_dir/checkafrc 2>/dev/null


#更新启动脚本

# file_path = /mmz/upgrade
# dst_path = /mmz
# conf_file = /mmz/conf/afrmc.conf
# zip_file = /mmz/upgrade/mmz_1E23190002.zip


cp $conf_file $file_path

unzip -o $zip_file -d $file_path


rm /mmz/

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
