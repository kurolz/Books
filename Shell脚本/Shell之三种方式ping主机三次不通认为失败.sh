#!/bin/bash
# 方法1
# 将失败次数放到数组里面进行判断
IP_LIST="192.168.18.1 192.168.1.1 192.168.18.9"
for IP in $IP_LIST; do
    NUM=1
    while [ $NUM -le 3 ]; do
        if ping -c 1 $IP > /dev/null; then
            echo "$IP Ping is successful."
            break
        else
            # echo "$IP Ping is failure $NUM"
            FAIL_COUNT[$NUM]=$IP
            let NUM++
        fi
    done
    if [ ${#FAIL_COUNT[*]} -eq 3 ];then
        echo "${FAIL_COUNT[1]} Ping is failure!"
    else
        unset FAIL_COUNT[*]
    fi
done
# 方法2
# 将失败次数放到变量里面进行判断
IP_LIST="192.168.18.1 192.168.1.1 192.168.18.9"
for IP in $IP_LIST; do
    FAIL_COUNT=0
    for ((i=1;i<=3;i++)); do
        if ping -c 1 $IP >/dev/null; then
            echo "$IP Ping is successful."
            break
        else
            # echo "$IP Ping is failure $i"
            let FAIL_COUNT++
        fi
    done
    if [ $FAIL_COUNT -eq 3 ]; then
        echo "$IP Ping is failure!"
    fi
done
# 方法3
# 如果失败会直接跳出循环，否则，执行到最后一条认为失败
ping_success_status() {
    if ping -c 1 $IP >/dev/null; then
        echo "$IP Ping is successful."
        continue
    fi
}
IP_LIST="192.168.18.1 192.168.1.1 192.168.18.9"
for IP in $IP_LIST; do
    ping_success_status
    ping_success_status
    ping_success_status
    echo "$IP Ping is failure!"
done
