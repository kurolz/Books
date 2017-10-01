#!/bin/bash
#--------------info-------------#
#londyoffice@163.com
#2013-06-02
#-------------------------------#

#基本的环境变量信息
NGINX="nginx-xxx"
PCRE="pcre-xxx"

#添加用户和安装软件依赖环境
apt-get update
apt-get install openssl libssl-dev build-essential -y

#下载软件
cd /root

if [ ! -f "$NGINX.tar.gz" ];then
        wget http://xxx/$NGINX.tar.gz
fi

if [ ! -f "$PCRE.tar.gz" ];then
        wget http://xxx/$PCRE.tar.gz
fi


#安装pcre
cd /root
tar xzvf ${PCRE}.tar.gz
cd $PCRE
./configure
make && make install
ln -s /usr/local/lib/libpcre.so.0.0.1 /lib/libpcre.so.0

#安装nginx
useradd www-data -s /bin/nologin
cd ..
tar xzvf ${NGINX}.tar.gz
cd $NGINX
./configure --user=www-data --group=www-data --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module
make && make install

#创建配置目录
mkdir -p /data/log/nginx/
mkdir -p /usr/local/nginx/conf/vhost

#复制配置模板
cd /root
cp nginx.conf /usr/local/nginx/conf/
cp default.conf /usr/local/nginx/conf/vhost

rm -rf  /root/$NGINX
rm -rf  /root/$PCRE