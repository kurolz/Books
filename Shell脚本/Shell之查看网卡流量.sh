#!/bin/bash
function local_nic() {
    local NUM ARRAY_LENGTH
    NUM=0
    for NIC_NAME in $(ls /sys/class/net|grep -vE "lo|docker0"); do
        NIC_IP=$(ifconfig $NIC_NAME |awk -F'[: ]+' '/inet addr/{print $4}')
        if [ -n "$NIC_IP" ]; then
            NIC_IP_ARRAY[$NUM]="$NIC_NAME:$NIC_IP"    #将网卡名和对应IP放到数组
            let NUM++
        fi
    done
    ARRAY_LENGTH=${#NIC_IP_ARRAY[*]}
    if [ $ARRAY_LENGTH -eq 1 ]; then     #如果数组里面只有一条记录说明就一个网卡
        NIC=${NIC_IP_ARRAY[0]%:*}
        return 0
    elif [ $ARRAY_LENGTH -eq 0 ]; then   #如果没有记录说明没有网卡
        echo "No available network card!"
        exit 1
    else
        #如果有多条记录则提醒输入选择
        for NIC in ${NIC_IP_ARRAY[*]}; do
            echo $NIC
        done
        while true; do
            read -p "Please enter local use to network card name: " INPUT_NIC_NAME
            COUNT=0
            for NIC in ${NIC_IP_ARRAY[*]}; do
                NIC_NAME=${NIC%:*}
                if [ $NIC_NAME == "$INPUT_NIC_NAME" ]; then
                    NIC=${NIC_IP_ARRAY[$COUNT]%:*}
                    return 0
                else
                   COUNT+=1
                fi
            done
            echo "Not match! Please input again."
        done
    fi
}
local_nic

while true; do
    OLD_IN=`ifconfig $NIC |awk -F'[: ]+' '/bytes/{if(NR==8)print $4;else if(NR==5)print $6}'`
    OLD_OUT=`ifconfig $NIC |awk -F'[: ]+' '/bytes/{if(NR==8)print $9;else if(NR==7)print $6}'`
    sleep 1
    NEW_IN=`ifconfig $NIC |awk -F'[: ]+' '/bytes/{if(NR==8)print $4;else if(NR==5)print $6}'`
    NEW_OUT=`ifconfig $NIC |awk -F'[: ]+' '/bytes/{if(NR==8)print $9;else if(NR==7)print $6}'`
    IN=`awk 'BEGIN{printf "%.1f\n",'$((${NEW_IN}-${OLD_IN}))'/1024/128}'`
    OUT=`awk 'BEGIN{printf "%.1f\n",'$((${NEW_OUT}-${OLD_OUT}))'/1024/128}'`
    echo -e " In ------ Out"
    echo "${IN}MB/s ${OUT}MB/s"
    sleep 1
done
