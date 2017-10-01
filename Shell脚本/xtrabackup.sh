#!/bin/bash
#####################
#
# 第一次执行它的时候它会检查是否有完全备份,否则先创建一个全库备份
# 当你再次运行它的时候，它会根据脚本中的设定来基于之前的全库备份进行增量备份
# yao
#
####################
APP_HOME="/data/backup/xtrabackup"
cd $APP_HOME || exit 255
source /etc/profile
set -e

ScriptVersion="1.0"
ScriptAuthor="yao"
ScriptModify="20170403"

#INNOBACKUPEX的命令
INNOBACKUPEX_PATH=innobackupex  
#INNOBACKUPEX的命令路径
INNOBACKUPEXFULL="/usr/bin/${INNOBACKUPEX_PATH}"
#MySQL目标服务器以及用户名和密码
MYSQL_CMD="--host=127.0.0.1 --user=root --password=zabbixroot --port=3306"
#mysql的用户名和密码
MYSQL_UP="--user=root --password=zabbixroot -pzabbixroot"
#日志路径
TMPLOG="/tmp/innobackupex.$$.log"
#mysql的配置文件
MY_CNF="/etc/my.cnf"
MYSQL="/usr/bin/mysql"
MYSQL_ADMIN="/usr/bin/mysqladmin"
# 备份的主目录
BACKUP_DIR=${APP_HOME}/backup
mkdir -p ${BACKUP_DIR}
# 全库备份的目录
FULLBACKUP_DIR=${BACKUP_DIR}/full
mkdir -p ${FULLBACKUP_DIR}
# 增量备份的目录
INCRBACKUP_DIR=${BACKUP_DIR}/incre
mkdir -p ${INCRBACKUP_DIR}
# 全库备份的间隔周期，时间：秒，至少一天
FULLBACKUP_INTERVAL=172800
# 至少保留个天全库备份
KEEP_FULLBACKUP_COUNT=2
# 计算删除的日期+1
KEEP_FULLBACKUP=$(($(($((${FULLBACKUP_INTERVAL}/86400))*${KEEP_FULLBACKUP_COUNT}))+1))
logfiledir=${APP_HOME}/log
mkdir -p ${logfiledir}
logfiledate=${logfiledir}/mysql_backup_`date +%Y%m%d%H%M`.log
#开始时间
STARTED_TIME=`date +%s`

#归档目录
ARCHIVE_DIR=${APP_HOME}/archive
mkdir -p ${ARCHIVE_DIR}

#备份文件后缀名
BackupExt=MySQLDB.dump.tar.gz

#备份使用最大内存
USEMEM="2G"
 
#############################################################################
# 显示错误并退出
#############################################################################
error()
{
    echo "$1" 1>&2
    exit 1
}
 
# 检查执行环境
if [ ! -x ${INNOBACKUPEXFULL} ]; then
    error "$INNOBACKUPEXFULL未安装或未链接到/usr/bin."
fi
 
if [ ! -d ${BACKUP_DIR} ]; then
    error "备份目标文件夹:$BACKUP_DIR不存在."
fi
 
if [ -z "`${MYSQL_ADMIN} ${MYSQL_UP} status | grep 'Uptime'`" ] ; then
    error "MySQL 没有启动运行."
fi
 
 
if ! `echo 'exit' | ${MYSQL} -s ${MYSQL_CMD}` ; then
    error "提供的数据库用户名或密码不正确!"
fi

genDebug(){
echo "#----------------------------"
echo "#"
echo "# $0: MySQL备份脚本"
echo "# ${1}于: `date +%F' '%T' 星期['%w]`"
echo "#"
echo "# ScriptVersion: ${ScriptVersion}"
echo "# ScriptAuthor:  ${ScriptAuthor}"
echo "# ScriptModify:  ${ScriptModify}"
echo "#"
echo "#----------------------------"
}
# 备份的头部信息
genDebug "开始" | tee -ai ${logfiledate}

 
 
#查找最新的完全备份
LATEST_FULL_BACKUP=`find ${FULLBACKUP_DIR} -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1`
if [ -z ${LATEST_FULL_BACKUP} ];then
    :
else
    echo -e "# 最新的完全备份:\t\t[ ${LATEST_FULL_BACKUP} ]" | tee -ai ${logfiledate}
fi

# 查找最近修改的最新备份
LATEST_FULL_BACKUP_CREATED_TIME=`stat -c %Y ${FULLBACKUP_DIR}/${LATEST_FULL_BACKUP}`
if [ -z ${LATEST_FULL_BACKUP} ];then
    :
else
    echo -e "# 最近修改的最新备份:\t\t[ ${LATEST_FULL_BACKUP} ]" | tee -ai ${logfiledate}
fi

#如果全备有效进行增量备份否则执行完全备份
if [ "${LATEST_FULL_BACKUP}" -a `expr ${LATEST_FULL_BACKUP_CREATED_TIME} + ${FULLBACKUP_INTERVAL} + 5` -ge ${STARTED_TIME} ] ; then
    ISFullBackup=F
    # 如果最新的全备未过期则以最新的全备文件名命名在增量备份目录下新建目录
    echo "# 完全备份 [ ${LATEST_FULL_BACKUP} ] 未过期" | tee -ai ${logfiledate}
    echo "# 将根据 [ ${LATEST_FULL_BACKUP} ] 名字作为增量备份目录命名" | tee -ai ${logfiledate}
    NEW_INCRDIR=${INCRBACKUP_DIR}/${LATEST_FULL_BACKUP}
    mkdir -p ${NEW_INCRDIR}
 
    # 不使用增量的增量
    if [ 1 -eq 2 ];then
        # 查找最新的增量备份是否存在.指定一个备份的路径作为增量备份的基础
        LATEST_INCR_BACKUP=`find ${NEW_INCRDIR} -mindepth 1 -maxdepth 1 -type d | sort -nr | head -1`
        if [ ! ${LATEST_INCR_BACKUP} ];then
            INCRBASEDIR=${FULLBACKUP_DIR}/${LATEST_FULL_BACKUP}
        else
            INCRBASEDIR=${LATEST_INCR_BACKUP}
        fi
    fi
    
    # 每次都使用上次全量备份备份
    INCRBASEDIR=${FULLBACKUP_DIR}/${LATEST_FULL_BACKUP}
    
    echo "----------------------------"    | tee -ai ${logfiledate}
    echo "# 使用 [ ${INCRBASEDIR} ] "      | tee -ai ${logfiledate}
    echo "# 作为 [ 增量 ] 备份的基础目录"     | tee -ai ${logfiledate}
    echo "----------------------------"    | tee -ai ${logfiledate}
    echo ${INNOBACKUPEXFULL} --defaults-file=${MY_CNF} --use-memory=${USEMEM} ${MYSQL_CMD} --incremental ${NEW_INCRDIR} --incremental-basedir ${INCRBASEDIR} >> ${logfiledate}
    ${INNOBACKUPEXFULL} --defaults-file=${MY_CNF} --use-memory=${USEMEM} ${MYSQL_CMD} --incremental ${NEW_INCRDIR} --incremental-basedir ${INCRBASEDIR} >> ${logfiledate} 2>&1
else
    ISFullBackup=T
    echo "#----------------------------"         | tee -ai ${logfiledate}
    echo "# 正在执行 [ 完全 ] 备份, 请稍等..."    | tee -ai ${logfiledate}
    echo "#----------------------------"         | tee -ai ${logfiledate}
    echo ${INNOBACKUPEXFULL} --defaults-file=${MY_CNF} --use-memory=${USEMEM} ${MYSQL_CMD} ${FULLBACKUP_DIR} >> ${logfiledate}
    ${INNOBACKUPEXFULL} --defaults-file=${MY_CNF} --use-memory=${USEMEM} ${MYSQL_CMD} ${FULLBACKUP_DIR} >> ${logfiledate} 2>&1
fi


if [ -z "`tail -1 ${logfiledate} | grep 'completed OK'`" ] ; then
    echo "# ${INNOBACKUPEX}命令执行失败:"                   | tee -ai ${logfiledate}
    echo "# tail -1 ${logfiledate} | grep 'completed OK'"   | tee -ai ${logfiledate}
    exit 1
else
    THISBACKUP=`awk -- "/Backup created in directory/ { split( \\\$0, p, \"'\" ) ; print p[2] }" ${logfiledate} | tail -1`
    echo "# 数据库成功备份到:" | tee -ai ${logfiledate}
    echo "# [ ${THISBACKUP} ]" | tee -ai ${logfiledate}
fi
 

 
# 提示应该保留的备份文件起点
# LATEST_FULL_BACKUP=`find $FULLBACKUP_DIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1`
echo "# 必须保留 [ ${KEEP_FULLBACKUP} ] 天的全备和全备 [ ${LATEST_FULL_BACKUP} ] 以后的所有增量备份." | tee -ai ${logfiledate}
echo "# 除了最新的全备份目录和全备份的增量目录，其他备份目录会归档到:" | tee -ai ${logfiledate}
echo "# [ ${ARCHIVE_DIR} ] " | tee -ai ${logfiledate}
# 全量
# FULLBACKUP_DIR=$BACKUP_DIR/full
# 增量
# INCRBACKUP_DIR=$BACKUP_DIR/incre


# rmlistfull=$(ls ${FULLBACKUP_DIR} | awk -vb=${FULLBACKUP_DIR} -va=$(date -d "${KEEP_FULLBACKUP} days ago" +%Y-%m-%d) -F_ '{if($1<a){print b"/"$0}}')
# rmlistincre=$(ls ${INCRBACKUP_DIR} | awk -vb=${INCRBACKUP_DIR} -va=$(date -d "${KEEP_FULLBACKUP} days ago" +%Y-%m-%d) -F_ '{if($1<a){print b"/"$0}}')

# if [ "X${rmlistfull}" = "X" ];then
    # echo "# 没有要删除的[ 全量 ]备份文件夹" | tee -ai ${logfiledate}
# else
    # echo "${rmlistfull}"    | tee -ai ${logfiledate}
# fi

# if [ "X${rmlistincre}" = "X" ];then
    # echo "# 没有要删除的[ 增量 ]备份文件夹" | tee -ai ${logfiledate}
# else
    # echo "${rmlistincre}"   | tee -ai ${logfiledate}
# fi
if [ "${ISFullBackup}" = "F" ];then
    Full_Ret1=$(ls ${FULLBACKUP_DIR} | grep -v ${LATEST_FULL_BACKUP} | awk -va=${FULLBACKUP_DIR} '{print a"/"$0}')
    INCR_Ret2=$(ls ${INCRBACKUP_DIR} | grep -v ${LATEST_FULL_BACKUP} | awk -va=${INCRBACKUP_DIR} '{print a"/"$0}')


    for item in ${Full_Ret1}
    do

        DirName=`dirname ${item}`
        BaseName=`basename ${item}`
        
        echo "# 开始归档历史 [ 全量 ] 文件夹 [ ${BaseName} ]"
        echo /bin/tar zcf ${ARCHIVE_DIR}/Full_${BaseName}.${BackupExt} ${BaseName} --remove-files >> ${logfiledate}
        cd ${DirName} && /bin/tar zcf ${ARCHIVE_DIR}/Full_${BaseName}.${BackupExt} ${BaseName} --remove-files

        
    done

    for item in ${INCR_Ret2}
    do

        DirName=`dirname ${item}`
        BaseName=`basename ${item}`
        
        echo "# 开始归档历史 [ 增量 ] 文件夹 [ ${BaseName} ]"
        echo /bin/tar zcf ${ARCHIVE_DIR}/incre_${BaseName}.${BackupExt} ${BaseName} --remove-files >> ${logfiledate}
        cd ${DirName} && /bin/tar zcf ${ARCHIVE_DIR}/incre_${BaseName}.${BackupExt} ${BaseName} --remove-files 
    done
fi
#这种删除太危险
#删除过期的全备
# echo -e "寻找过期的全备文件并删除" | tee -ai ${logfiledate}
# for efile in $(/usr/bin/find ${FULLBACKUP_DIR}/ -mtime +6)
# do
    # if [ -d ${efile} ]; then
        # rm -rf ${efile}
        # echo -e "删除过期全备目录:${efile}" | tee -ai ${logfiledate}
    # elif [ -f ${efile} ]; then
        # rm -rf ${efile}
        # echo -e "删除过期全备文件:${efile}" | tee -ai ${logfiledate}
    # fi;
 
# done
# if [ $? -eq "0" ];then
   # echo
   # echo -e "未找到可以删除的过期全备文件" | tee -ai ${logfiledate}
# fi
 
genDebug "结束" | tee -ai ${logfiledate}

exit 0