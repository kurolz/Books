#!/usr/bin/env bash
#
# Original: https://www.zabbix.org/wiki/Docs/howto/zabbix_get_jmx
#
# Modified by:
#  Rodrigo Silva (2016-07-15) - Add support for authentication
#

USERNAME=monitorUser
PASSWORD=yourrandompasswordtoaccessjmxserver
ZBXGET="/usr/bin/zabbix_get"

if [ $# != 5 ]
then
    echo "Usage: $0 <JAVA_GATEWAY_HOST> <JAVA_GATEWAY_PORT> <JMX_SERVER> <JMX_PORT> <KEY>"
    exit;
fi

if [[ -n $USERNAME && -n $PASSWORD ]]; then
	QUERY="{\"request\": \"java gateway jmx\",\"conn\": \"$3\",\"port\": $4,\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"keys\": [\"$5\"]}"
else
	QUERY="{\"request\": \"java gateway jmx\",\"conn\": \"$3\",\"port\": $4,\"keys\": [\"$5\"]}"
fi

$ZBXGET -s $1 -p $2 -k "$QUERY"
