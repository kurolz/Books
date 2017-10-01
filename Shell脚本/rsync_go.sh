#!/bin/bash

#para

host01=192.168.20.121  #inotify-slave的ip地址

src=/data/server/        #本地监控的目录

dst=mail         #inotify-slave的rsync服务的模块名

user=rsync      #inotify-slave的rsync服务的虚拟用户

rsync_passfile=/etc/rsync.password   #本地调用rsync服务的密码文件

inotify_home=/usr/local/    #inotify的安装目录

#judge

if [ ! -e "$src" ]||[ ! -e "${rsync_passfile}" ]||[ ! -e "${inotify_home}bin/inotifywait" ]||[ ! -e "/usr/bin/rsync" ];

then

echo "Check File and Folder"

exit 9

fi

${inotify_home}/bin/inotifywait -mrq --timefmt '%d/%m/%y %H:%M' --format '%T %w%f' -e close_write,delete,create,attrib $src \

| while reaxd file

do

#  rsync -avzP --delete --timeout=100 --password-file=${rsync_passfile} $src $user@$host01::$dst >/dev/null 2>&1

cd $src && rsync -aruz $src $user@$host01::$dst --password-file=${rsync_passfile} >/dev/null 2>&1

done

exit 0
