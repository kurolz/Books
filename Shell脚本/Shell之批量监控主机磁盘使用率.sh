1）本地磁盘监控
    USE_RATE_LIST=$(df -h |awk '/^\/dev/{print $1"="int($5)}')  #结果/dev/sda1=10
    for USE_RATE in $USE_RATE_LIST; do
        PART_NAME=${USE_RATE%=*}
        USE_RATE=${USE_RATE#*=}
        if [ $USE_RATE -ge 80 ]; then
            echo "Warning: $PART_NAME Partition usage $USE_RATE%!"
        fi
    done
2）少台主机磁盘监控
    HOST_IP=(192.168.1.130 192.168.1.131)
    HOST_SUM=${#HOST_IP[*]}
    TMP_FILE=/tmp/mon_host_disk.tmp
    for ((i=0;i<$HOST_SUM;i++)); do
        ssh root@${HOST_IP[i]} 'df -h' >$TMP_FILE
        USE_RATE_LIST=$(awk '/^\/dev/{print $1"="int($5)}' $TMP_FILE)
        for USE_RATE in $USE_RATE_LIST; do
            PART_NAME=${USE_RATE%=*}
            USE_RATE=${USE_RATE#*=}
            if [ $USE_RATE -ge 80 ]; then
                echo "Warning: $PART_NAME Partition usage $USE_RATE%!"
            fi
        done
    done
3）多台主机磁盘监控
    思路：前提监控端和被监控端可以SSH免交互认证，应写一个配置文件保存远程主机登陆信息
    远程主机用户信息文件格式：IP User Port
    例如：
    $ cat host_info.txt
    192.168.1.130   root    22

    HOST_INFO=./host_info.txt
    for IP in $(awk '/^[^#]/{print $1}' $HOST_INFO); do
        USER=$(awk -v ip=$IP 'ip==$1{print $2}' $HOST_INFO)
        PORT=$(awk -v ip=$IP 'ip==$1{print $3}' $HOST_INFO)
        TMP_FILE=/tmp/mon_host_disk.tmp
        ssh -p $PORT $USER@$IP 'df -h' >$TMP_FILE
        USE_RATE_LIST=$(awk '/^\/dev/{print $1"="int($5)}' $TMP_FILE)
        for USE_RATE in $USE_RATE_LIST; do
            PART_NAME=${USE_RATE%=*}
            USE_RATE=${USE_RATE#*=}
            if [ $USE_RATE -ge 80 ]; then
                echo "Warning: $PART_NAME Partition usage $USE_RATE%!"
            fi
        done
    done
