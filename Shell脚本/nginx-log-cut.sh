#!/bin/bash
# 零点切割Nginx PC/M站日志

LOG_DIR=/data/project/nginx1.10/logs
YESTERDAY_TIME=$(date -d "yesterday" +%F)
LOG_DAY_DIR=$LOG_DIR/$YESTERDAY_TIME
LOG_FILE_LIST="www_access.log m_access.log"

for LOG_FILE in $LOG_FILE_LIST; do
    mkdir -p $LOG_DAY_DIR
    mv $LOG_DIR/$LOG_FILE $LOG_DAY_DIR/${LOG_FILE/./_$YESTERDAY_TIME.}
done

kill -USR1 $(cat $LOG_DIR/nginx.pid)