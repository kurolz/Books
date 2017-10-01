#!/bin/sh
DIR=$(dirname $0)
SRC="/data/apps/server/fight/*"  # 定义更新文件源的位置
SCP_FILE="${DIR}/scp.txt"         # 定期维护更新此文件
DATE=$(date +%Y%m%d%H%M)
LOGFILE=${DIR}/log/scp-$DATE.log
update() {
for i in $(cat $SCP_FILE)
do	
	echo ${SRC} root@${i}
	scp -r ${SRC} root@${i}
done
}

startup() {
IFS=:
while read -u3 IP DIR
do
	 ssh $IP "sh $DIR/startup_yulong.sh &>/dev/null &  "
	echo "开服执行位置 $IP:$DIR"
	sleep 8s
done 3< $SCP_FILE
}

shutdown() {
IFS=:
while read -u3 IP DIR
do
         ssh $IP "sh $DIR/shutdown_yulong.sh &>/dev/null & "
	echo "关服执行位置 $IP:$DIR"
done 3< $SCP_FILE
}

check() {
IFS=:
while read -u3 IP DIR
do
         ssh $IP " ps aux | grep java | grep -v grep |grep '$DIR/' | wc -l "
        echo "  $IP:$DIR"
done 3< $SCP_FILE
}

case $1 in
  update)
    update
    ;;
  startup)
    startup
    ;;
  shutdown)
    shutdown
    ;;
  check)
    check
     ;;
  *)
   echo $"Usage:$0 {shutdown|update|startup|check}"
   exit 1
esac
