#!/bin/sh

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

PROGNAME=`basename $0`
VERSION="Version 1.1,"
AUTHOR="2009, Mike Adolphs (http://www.matejunkie.com/)"

ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3
hostname="localhost"
port=80
path_pid=/var/run
name_pid="nginx.pid"
status_page="nginx_status"
pid_check=1
secure=0

print_version() {
    echo "$VERSION $AUTHOR"
}

print_help() {
    print_version $PROGNAME $VERSION
    echo ""
    echo "$PROGNAME is a Nagios plugin to check whether nginx is running."
    echo "It also parses the nginx's status page to get requests and"
    echo "connections per second as well as requests per connection. You"
    echo "may have to alter your nginx configuration so that the plugin"
    echo "can access the server's status page."
    echo "The plugin is highly configurable for this reason. See below for"
    echo "available options."
    echo ""
    echo "$PROGNAME -H localhost -P 80 -p /var/run -n nginx.pid "
	echo "  -s nginx_statut -o /tmp [-w INT] [-c INT] [-S] [-N]"
    echo ""
    echo "Options:"
    echo "  -H/--hostname)"
    echo "     Defines the hostname. Default is: localhost"
    echo "  -P/--port)"
    echo "     Defines the port. Default is: 80"
    echo "  -p/--path-pid)"
    echo "     Path where nginx's pid file is being stored. You might need"
    echo "     to alter this path according to your distribution. Default"
    echo "     is: /var/run"
    echo "  -n/--name_pid)"
    echo "     Name of the pid file. Default is: nginx.pid"
    echo "  -N/--no-pid-check)"
    echo "     Turn this on, if you don't want to check for a pid file"
    echo "     whether nginx is running, e.g. when you're checking a"
    echo "     remote server. Default is: off"
    echo "  -s/--status-page)"
    echo "     Name of the server's status page defined in the location"
    echo "     directive of your nginx configuration. Default is:"
    echo "     nginx_status"
    echo "  -S/--secure)"
    echo "     In case your server is only reachable via SSL, use this"
    echo "     this switch to use HTTPS instead of HTTP. Default is: off"
    echo "  -w/--warning)"
    echo "     Sets a warning level for requests per second. Default is: off"
    echo "  -c/--critical)"
    echo "     Sets a critical level for requests per second. Default is:"
	echo "     off"
    exit $ST_UK
}

while test -n "$1"; do
    case "$1" in
        -help|-h)
            print_help
            exit $ST_UK
            ;;
        --version|-v)
            print_version $PROGNAME $VERSION
            exit $ST_UK
            ;;
        --hostname|-H)
            hostname=$2
            shift
            ;;
        --port|-P)
            port=$2
            shift
            ;;
        --path-pid|-p)
            path_pid=$2
            shift
            ;;
        --name-pid|-n)
            name_pid=$2
            shift
            ;;
        --no-pid-check|-N)
            pid_check=0
            ;;
        --status-page|-s)
            status_page=$2
            shift
            ;;
        --secure|-S)
            secure=1
            ;;
        --warning|-w)
            warning=$2
            shift
            ;;
        --critical|-c)
            critical=$2
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            print_help
            exit $ST_UK
            ;;
        esac
    shift
done

get_wcdiff() {
    if [ ! -z "$warning" -a ! -z "$critical" ]
    then
        wclvls=1

        if [ ${warning} -ge ${critical} ]
        then
            wcdiff=1
        fi
    elif [ ! -z "$warning" -a -z "$critical" ]
    then
        wcdiff=2
    elif [ -z "$warning" -a ! -z "$critical" ]
    then
        wcdiff=3
    fi
}

val_wcdiff() {
    if [ "$wcdiff" = 1 ]
    then
        echo "Please adjust your warning/critical thresholds. The warning \
must be lower than the critical level!"
        exit $ST_UK
    elif [ "$wcdiff" = 2 ]
    then
        echo "Please also set a critical value when you want to use \
warning/critical thresholds!"
        exit $ST_UK
    elif [ "$wcdiff" = 3 ]
    then
        echo "Please also set a warning value when you want to use \
warning/critical thresholds!"
        exit $ST_UK
    fi
}

check_pid() {
    if [ -f "$path_pid/$name_pid" ]
    then
        retval=0
    else
        retval=1
    fi
}

get_status() {
    if [ "$secure" = 1 ]
    then
        wget_opts="-O- -q -t 3 -T 3 --no-check-certificate"
        out1=`wget ${wget_opts} http://${hostname}:${port}/${status_page}`
        sleep 1
        out2=`wget ${wget_opts} http://${hostname}:${port}/${status_page}`
    else        
        wget_opts="-O- -q -t 3 -T 3"
        out1=`wget ${wget_opts} http://${hostname}:${port}/${status_page}`
        sleep 1
        out2=`wget ${wget_opts} http://${hostname}:${port}/${status_page}`
    fi

    if [ -z "$out1" -o -z "$out2" ]
    then
        echo "UNKNOWN - Local copy/copies of $status_page is empty."
        exit $ST_UK
    fi
}

get_vals() {
    tmp1_reqpsec=`echo ${out1}|awk '{print $10}'`
    tmp2_reqpsec=`echo ${out2}|awk '{print $10}'`
    reqpsec=`expr $tmp2_reqpsec - $tmp1_reqpsec`

    tmp1_conpsec=`echo ${out1}|awk '{print $9}'`
    tmp2_conpsec=`echo ${out2}|awk '{print $9}'`
    conpsec=`expr $tmp2_conpsec - $tmp1_conpsec`

    reqpcon=`echo "scale=2; $reqpsec / $conpsec" | bc -l`
    if [ "$reqpcon" = ".99" ]
    then
        reqpcon="1.00"
    fi
}

do_output() {
    output="nginx is running. $reqpsec requests per second, $conpsec \
connections per second ($reqpcon requests per connection)"
}

do_perfdata() {
    perfdata="'reqpsec'=$reqpsec 'conpsec'=$conpsec 'conpreq'=$reqpcon"
}

# Here we go!
get_wcdiff
val_wcdiff

if [ ${pid_check} = 1 ]
then
    check_pid
    if [ "$retval" = 1 ]
    then
        echo "There's no pid file for nginx. Is nginx running? Please \
also make sure whether your pid path and name is correct."
        exit $ST_CR
    fi
fi

get_status
get_vals
do_output
do_perfdata

if [ -n "$warning" -a -n "$critical" ]
then
    if [ "$reqpsec" -ge "$warning" -a "$reqpsec" -lt "$critical" ]
    then
        echo "WARNING - ${output} | ${perfdata}"
	exit $ST_WR
    elif [ "$reqpsec" -ge "$critical" ]
    then
        echo "CRITICAL - ${output} | ${perfdata}"
	exit $ST_CR
    else
        echo "OK - ${output} | ${perfdata} ]"
	exit $ST_OK
    fi
else
    echo "OK - ${output} | ${perfdata}"
    exit $ST_OK
fi
