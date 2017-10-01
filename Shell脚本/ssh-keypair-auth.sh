#!/bin/bash
# Description: configuration local host and remote host ssh keypair authentication, Support Ubuntu and CentOS operation system.
function color_echo() {
    if [ $1 == "green" ]; then
        echo -e "\033[32;40m$2\033[0m"
    elif [ $1 == "red" ]; then
        echo -e "\033[31;40m$2\033[0m"
    fi
}
function os_version() {
    local OS_V=$(cat /etc/issue |awk 'NR==1{print $1}')
    if [ $OS_V == "\S" -o $OS_V == "CentOS" ]; then
        echo "CentOS"
    elif [ $OS_V == "Ubuntu" ]; then
        echo "Ubuntu"
    fi
}
function check_ssh_auth() {
    if $(grep "Permission denied" $EXP_TMP_FILE >/dev/null); then
        color_echo red "Host $IP SSH authentication failure! Login password error."
        exit 1
    elif $(ssh $INFO 'echo yes >/dev/null'); then
        color_echo green "Host $IP SSH authentication successfully."
    fi
    rm $EXP_TMP_FILE >/dev/null
}
function check_pkg() {
    local PKG_NAME=$1
    if [ $(os_version) == "CentOS" ]; then
        if ! $(rpm -ql $PKG_NAME >/dev/null 2>&1); then
            echo no
        else
            echo yes
        fi
    elif [ $(os_version) == "Ubuntu" ]; then
        if ! $(dpkg -l $PKG_NAME >/dev/null 2>&1); then
            echo no
        else
            echo yes
        fi
    fi
}
function install_pkg() {
    local PKG_NAME=$1
    if [ $(os_version) == "CentOS" ]; then
        if [ $(check_pkg $PKG_NAME) == "no" ]; then
            yum install $PKG_NAME -y
            if [ $(check_pkg $PKG_NAME) == "no" ]; then
                color_echo green "The $PKG_NAME installation failure! Try to install again."
                yum makecache
                yum install $PKG_NAME -y
                [ $(check_pkg $PKG_NAME) == "no" ] && color_echo red "The $PKG_NAME installation failure!" && exit 1
            fi
        fi
    elif [ $(os_version) == "Ubuntu" ]; then
        if [ $(check_pkg $PKG_NAME) == "no" ]; then
            apt-get install $PKG_NAME -y
            if [ $(check_pkg $PKG_NAME) == "no" ]; then
                color_echo green "$PKG_NAME installation failure! Try to install again."
                apt-get autoremove && apt-get update
                apt-get install $PKG_NAME --force-yes -y
                [ $(check_pkg $PKG_NAME) == "no" ] && color_echo red "The $PKG_NAME installation failure!" && exit 1
            fi
        fi
    fi
}
function generate_keypair() {
    if [ ! -e ~/.ssh/id_rsa.pub ]; then
        color_echo green "The public/private rsa key pair not exist, start Generating..."
        expect -c "
            spawn ssh-keygen
            expect {
                \"ssh/id_rsa):\" {send \"\r\";exp_continue}
                \"passphrase):\" {send \"\r\";exp_continue}
                \"again:\" {send \"\r\";exp_continue}
            }
        " >/dev/null 2>&1
        if [ -e ~/.ssh/id_rsa.pub ]; then
            color_echo green "Generating public/private rsa key pair successfully."
        else
            color_echo red "Generating public/private rsa key pair failure!"
            exit 1
        fi
    fi
}
EXP_TMP_FILE=/tmp/expect_ssh.tmp
if [[ $1 =~ ^[a-z]+@[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}@.* ]]; then
    install_pkg expect ; generate_keypair
    for i in $@; do
        USER=$(echo $i|cut -d@ -f1)
        IP=$(echo $i|cut -d@ -f2)
        PASS=$(echo $i|cut -d@ -f3)
        INFO=$USER@$IP
        expect -c "
            spawn ssh-copy-id $INFO
            expect {
                \"(yes/no)?\" {send \"yes\r\";exp_continue}
                \"password:\" {send \"$PASS\r\";exp_continue}
            }
        " > $EXP_TMP_FILE  # if login failed, login error info append temp file
        check_ssh_auth
    done
elif [[ $1 =~ ^[a-z]+@[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}@.* ]]; then
    install_pkg expect ; generate_keypair
    START_IP_NUM=$(echo $1|sed -r 's/.*\.(.*)-(.*)@.*/\1/')
    END_IP_NUM=$(echo $1|sed -r 's/.*\.(.*)-(.*)@.*/\2/')
    for ((i=$START_IP_NUM;i<=$END_IP_NUM;i++)); do
        USER=$(echo $1|cut -d@ -f1)
        PASS=$(echo $1|cut -d@ -f3)
        IP_RANGE=$(echo $1|sed -r 's/.*@(.*\.).*/\1/')
        IP=$IP_RANGE$i
        INFO=$USER@$IP_RANGE$i
        expect -c "
            spawn ssh-copy-id $INFO
            expect {
                \"(yes/no)?\" {send \"yes\r\";exp_continue}
                \"password:\" {send \"$PASS\r\";exp_continue}
            }
        " > $EXP_TMP_FILE
        check_ssh_auth
    done
else
    echo "Example1: $0 <root@192.168.1.10-15@password>"
    echo "Example2: $0 <root@192.168.1.10@password>"
    echo "Example3: $0 [root@192.168.1.10@password root@192.168.1.11@password root@192.168.1.12@password ...]"
fi
