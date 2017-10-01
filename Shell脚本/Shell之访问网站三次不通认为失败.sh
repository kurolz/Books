#!/bin/bash
access_web_status() {
    if [ $(curl -o /dev/null -s -w "%{http_code}" $URL) -eq 200 ]; then
        echo "$URL Access successful."
        continue
    fi
}
while true; do
    for URL in $(cat url.txt |sed '/^#/d'); do
       access_web_status
       access_web_status
       access_web_status
       echo "$URL Access failure!"
    done
    echo "sleep 60s..."
    sleep 60
done

#文本内容
$ cat url.txt
www.baidu.com
www.sina.com
