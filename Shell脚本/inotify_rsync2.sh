#!/bin/sh
#此脚本仅用于文件热备而非实时同步，增加修改写入都会发送，目录修改属性不触发操作，rsync只同步改变的文件而非扫描整个目录。
#这种方式并非完全可靠会有事件遗漏导致文件不同步，如果要保持热备文件与数据源一致需要定期同步清理删除文件。
#需要多点写入并且数据严格同步以及数据完整的场合需要使用群集文件系统或者分布式文件系统。
PWD=/data/scripts/rsync.snd
SRC=/data/rom/
DST=file@10.0.2.237::rom/
/usr/bin/inotifywait -mrq --format='%w%f' -e modify,create,close_write ${SRC} | while read file
            do
                    /usr/bin/rsync -al --password-file=$PWD "$file" $DST > /dev/null 2>&1
            done