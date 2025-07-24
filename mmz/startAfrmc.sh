#!/bin/bash

applDir=/mmz/
applUpgrade=/mmz/upgrade

upgradeFile=/mmz/upgrade/afrmc_upgrade.zip
upgrade_sh=/mmz/upgrade/upgrade.sh


acPid=$(ps | grep afrmc_control | grep -v grep | awk '{print $1}')
amPid=$(ps | grep afrmc_monitor | grep -v grep | awk '{print $1}')
auPid=$(ps | grep afrmc_uart | grep -v grep | awk '{print $1}')


# Returns 0 if the process with PID $1 is running.
checkProcessIsRunning() {
    local pid="$1"
    if [ -z "$pid" -o "$pid" == " " ]; then return 1; fi
    if [ ! -e /proc/$pid ]; then return 1; fi
    return 0; }


startAfrmc() {

    cd "$applDir" || return 1 
    if checkProcessIsRunning $acPid
    then
        kill -s USR1 $acPid
    fi
    chmod +x /mmz/afrmc_control 
    /mmz/afrmc_control >> /dev/null 2>&1 &

    if checkProcessIsRunning $amPid
    then
        kill -s USR1 $amPid
    fi
    chmod +x /mmz/afrmc_monitor
    /mmz/afrmc_monitor >> /dev/null 2>&1 &


    if checkProcessIsRunning $auPid
    then
        kill -s USR1 $auPid
    fi
    chmod +x /mmz/afrmc_uart
    /mmz/afrmc_uart >> /dev/null 2>&1 &

    echo "start afrmc app successful"
}

stopAfrmc() {
    if checkProcessIsRunning $acPid
    then
        kill -s USR1 $acPid        
    fi

    if checkProcessIsRunning $amPid
    then
        kill -s USR1 $amPid        
    fi

    if checkProcessIsRunning $auPid
    then
        kill -s USR1 $auPid        
    fi

    
}

upgradeAfrmc() {
    stopAfrmc
    
    cd "$applUpgrade" || return 1

    
    #check upgrade file is exist
    if [ ! -f "$upgradeFile" ]; 
    then 
	echo "$(date) upgrade file is not exist" >> /mmz/runinfo
        return 1; 
    fi
    
    cd /mmz/upgrade || return 1;
    unzip -o afrmc_upgrade.zip
	
    if [ $? -eq 0 ]; then
        echo "$(date) unzip afrmc_upgrade.zip ok" >> /mmz/runinfo
        
        #check upgrade.sh file
        if [ ! -f "$upgrade_sh" ] ;
        then
            echo "$(date) $upgrade_sh is not exist" >> /mmz/runinfo
            return 1;
        fi

        sh /mmz/upgrade/upgrade.sh
        echo $(date) upgrade successful >> /mmz/runinfo
        return 0  
    fi

    return 1
}

invup_info_path=/mmz/upgrade/invup_info
upgradeInv() {
   

    cd "$applUpgrade" || return 1

    #check upgrade file is exist
    if [ ! -f "$invup_info_path" ]; 
    then 
	echo "$(date) invup_info file is not exist" >> /mmz/runinfo
        return 1; 
    fi
    
    killall -s SIGUSR1 afrmc_uart 
    /mmz/afrmc_invup >> /dev/null 
    echo $(date) invup successful >> /mmz/runinfo

    return 0
}

main() {
    echo "$(date) startAfrmc $1" >> /mmz/runinfo
    RETVAL=0
    case "$1" in
        start) 
            startAfrmc
            ;;
        stop) 
            stopAfrmc
            ;;
        upgrade)
            upgradeAfrmc
            startAfrmc
            ;;
        upinv)
            upgradeInv
            stopAfrmc
            startAfrmc
            ;;
        *)
            echo "Usage: $0 {start|stop|upgrade}"
            exit 1
            ;;
    esac
    
    exit $RETVAL
}

main $1
