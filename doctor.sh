#!/bin/sh
source /usr/share/libubox/jshn.sh

result1=0
ip=8.8.8.8
host=www.google.com
url=https://api.polkaspots.com/api/v1/ping.json
chilli=tun0
api_url=https://api.polkaspots.com
mtustatus=0
chillistatus=0
urlstatus=0
ipstatus=0
hoststatus=0

icmp_check () {
ping -c 2 $1 >/dev/null 2>&1
if [ $? -eq 0 ] ; then
result1=1
else 
result1=0
fi
}

icmp_check $ip

if [ $result1 -eq 1 ] ; then
ipstatus=1
fi

icmp_check $host

if [ $result1 -eq 1 ] ; then
hoststatus=1
fi

url_status_check () {
res=$(curl --connect-timeout 5 -k -s -o /dev/null -w '%{http_code}' $1)
if [ $res -eq 200 ] ; then
urlstatus=1
fi
}

url_status_check $url

chilli_check () {
ifconfig $1 >/dev/null 2>&1
if [ $? -eq 0 ] ; then
chillistatus=1
fi
}

chilli_check $chilli

sync_id () {
syncstatus=`cat /etc/sync`
}

sync_id

mtu_check () {
mtu=`cat /etc/config/network | grep mtu | awk -F"'" '{ print $2 }'`  
ping -c 2 -s $mtu 8.8.8.8 >/dev/null 2>&1
if [ $? -eq 0 ] ; then
mtustatus=1
fi
}

mtu_check

serial_check () {
serial=`cat /etc/serial`
}

serial_check

mac_check () {
mac=`cat /etc/mac`
}

mac_check

json_init
json_add_object "data"
json_add_boolean "icmp_host" $hoststatus
json_add_boolean "icmp_ip" $ipstatus
json_add_boolean "ct" $urlstatus
json_add_boolean "splash" $chillistatus
json_add_boolean "mtu" $mtustatus
json_add_string "sync_id" "$syncstatus"
json_close_object

health_check=`json_dump`

echo $health_check

post_ct () {
curl --connect-timeout 5 -d "$health_check" -s -H "Content-Type: application/json" -X POST  $api_url/api/v1/nas/reporter\?mac\=$mac\&serial\=$serial\&type\=doctor -k
}

post_ct
