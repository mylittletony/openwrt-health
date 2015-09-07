#!/bin/sh
source /usr/share/libubox/jshn.sh

result1=0
ip=8.8.8.8
host=www.google.com
url=https://api.polkaspots.com/api/v1/ping.json
chilli=tun0

#IP & HOST CHECK#

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
  ipstatus=true
else
  ipstatus=false
fi

icmp_check $host

if [ $result1 -eq 1 ] ; then
  hoststatus=true
else
  hoststatus=false
fi

#URL STATUS CHECK#

url_status_check () {
  res=$(curl --connect-timeout 5 -k -s -o /dev/null -w '%{http_code}' $1)
  if [ $res -eq 200 ] ; then
    urlstatus=true
  else
    urlstatus=false
  fi
}

url_status_check $url

#Captive Portal Running [tun0]#

chilli_check () {
  ifconfig $1 >/dev/null 2>&1
  if [ $? -eq 0 ] ; then
    chillistatus=true
  else 
    chillistatus=false
  fi
}

chilli_check $chilli

#Sync ID#

sync_id () {
  syncstatus=`cat /etc/sync`
}

sync_id

#MTU#

mtu_check () {
  mtu=`cat /etc/config/network | grep mtu | awk -F"'" '{ print $2 }'`  
  ping -c 2 -s $mtu 8.8.8.8 >/dev/null 2>&1
  if [ $? -eq 0 ] ; then
    mtustatus=true
  else
    mtustatus=false
  fi
}

mtu_check

#SERIAL#

serial_check () {
  serial=`cat /etc/serial`
}

serial_check

#MAC#

mac_check () {
  mac=`cat /etc/mac`
}

mac_check

#JSON#

json_init
json_add_object "data"
json_add_string "icmp_host" "$hoststatus"
json_add_string "icmp_ip" "$ipstatus"
json_add_string "ct" "$urlstatus"
json_add_string "splash" "$chillistatus"
json_add_string "sync_id" "$syncstatus"
json_add_string "mtu" "$mtustatus"
json_close_object

health_check=`json_dump`

echo $health_check

#CURL#

post_ct () {
  curl --connect-timeout 5 -v -d "$health_check" -s -H "Content-Type: application/json" -X POST  https://api.polkaspots.com/api/v1/nas/reporter\?mac\=$mac\&serial\=$serial\&type\=doctor -k
}

post_ct
