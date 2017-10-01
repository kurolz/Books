#!/bin/bash
MYSQL_VERSION=5.6
MYSQL_PKG=mysql-5.6.31-linux-glibc2.5-x86_64.tar.gz
USER=mysql
# 安装目录
read -p "Please specify the installation directory: " WORK_DIR
if [ ! -d $WORK_DIR ]; then
    if ! $(mkdir -p $WORK_DIR); then
        exit
    fi
fi
MYSQL_DIR=$(echo $WORK_DIR|sed 's/\/$//')/mysql$MYSQL_VERSION
# 创建用户
if ! $(id $USER >/dev/null 2>&1); then
    useradd -M $USER -s /sbin/nologin
fi

# if ! $(wget http://10.51.54.130:88/$MYSQL_PKG); then
#     echo "Mysql binary package not download failure!"
#     exit
# fi
# 解压
echo "In the decompression..."
tar zxf $MYSQL_PKG -C $WORK_DIR
cd $WORK_DIR
mv $(echo "$MYSQL_PKG"| sed 's/.tar.gz//') mysql$MYSQL_VERSION
# 初始化
$MYSQL_DIR/scripts/mysql_install_db --basedir=$MYSQL_DIR --datadir=$MYSQL_DIR/data --user=$USER
if [ -f /etc/my.cnf ]; then
    mv /etc/my.cnf /etc/my.cnf.bak
fi
# 修改配置文件
echo "
[mysqld]
port = 3306
basedir = $MYSQL_DIR
datadir = $MYSQL_DIR/data
lower_case_table_names = 1
character_set_server = utf8
character_set_client = utf8
wait_timeout = 86400
max_connections=3600
" > $MYSQL_DIR/my.cnf
# 配置守护进程启动
cp $MYSQL_DIR/support-files/mysql.server /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld 
sed -r -i "/^basedir=/s#(.*)#\1$MYSQL_DIR#" /etc/init.d/mysqld
sed -r -i "/^datadir=/s#(.*)#\1$MYSQL_DIR/data#" /etc/init.d/mysqld
service mysqld start
# 通过端口和进程判断是否启动成功，如果启动成功设置root密码
if [ $(netstat -antp |grep -c 3306) -eq 1 -a $(ps -ef |grep "$MYSQL_DIR" |grep -cv grep) -ge 2 ]; then
    INIT_PASS=$(cat /proc/sys/kernel/random/uuid |cut -c 1-12)
    $MYSQL_DIR/bin/mysqladmin -uroot password "$INIT_PASS"
    echo "--------------------------------------------------"
    echo -e "|The root initial password is: \033[32;40m$INIT_PASS\033[0m"
    echo "--------------------------------------------------"
else
    echo "MySQL startup failure!"
fi
echo "PATH=$PATH:$MYSQL_DIR/bin" >> /etc/profile
. /etc/profile  # 不生效，请手动执行
