#!/usr/local/bin/bash 
iplist=`cat /backup/scripts/iplist.txt|grep -v "#"|awk '{print $1}'` #过滤服务器IP
dir='/backup/base' #目标路径
thread_num=6 #自定义并发数，根据自身服务器性能或应用调整大小，开始千万别定义太大，避免管理机宕机
tmp_fifo_file="/tmp/$$.fifo" #以进程ID号命名管道文件

mkfifo $tmp_fifo_file #创建临时管道文件
exec 4<>$tmp_fifo_file #以读写方式打开tmp_fifo_file管道文件,文件描述符为4，也可以取3-9任意描述符
rm -f $tmp_fifo_file #删除临时管道文件，也可不删除

for ((i=0;i<$thread_num;i++)) #利用for循环向管道中输入并发数量的空行
	do
	echo "" #输出空行
	done >&4 #输出重导向到定义的文件描述符4上

for ip in $iplist #循环所有要执行的服务器
	do
	read -u4 #从管道中读取行，每次一行，所有行读取完毕后执行挂起，直到管道有空闲的行
	#所有要批量执行的命令都放在大括号内
	{
	echo " host $ip is backuping ....."
	/usr/local/bin/rsync -azvS --delete -e ssh --exclude-from=/backup/scripts/exclude.txt root@$ip:/ /backup/base/$ip
	sleep 3 #暂停3秒，给系统缓冲时间，达到限制并发进程数量
	echo "" >&4 #再写入一个空行，使挂起的循环继续执行

	}& #放入后台执行
	done

wait #等待所有后台进程执行完成
exec 4>&- #删除文件描述符

/usr/local/bin/rsync -azv -e ssh /backup/base 10.0.2.10:/backup
zfs snapshot backup@`date +%Y_%m_%d-%H%M`
ssh 10.0.2.10 zfs snapshot backup@`date +%Y_%m_%d-%H%M`
zfs snapshot data2@`date +%Y_%m_%d-%H%M`
exit 0
