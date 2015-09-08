#!/bin/sh
source /usr/share/libubox/jshn.sh

ip=8.8.8.8
host=www.google.com
api_url=https://api.polkaspots.com
url=$api_url/api/v1/ping.json
splashprocess=chilli
mtucheck=0
splashcheck=0
urlstatus=0
icmpip=0
icmphost=0

icmp_check () {
	ping -c 2 $1 >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		icmpcheck=1
  else
		icmpcheck=0
	fi
}

icmp_check $ip

if [ $icmpcheck -eq 1 ] ; then
	icmpip=1
fi

icmp_check $host

if [ $icmpcheck -eq 1 ] ; then
	icmphost=1
fi

url_status_check () {
	res=$(curl --connect-timeout 5 -k -s -o /dev/null -w '%{http_code}' $1)
	if [ $res -eq 200 ] ; then
		urlstatus=1
	fi
}

splash_check () {
	pidof $splashprocess >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		splashcheck=1
	fi
}

sync_id () {
	syncstatus=`cat /etc/sync`
}

mtu_check () {
	mtu=`cat /etc/config/network | grep mtu | awk -F"'" '{ print $2 }'`
	ping -c 2 -s $mtu 8.8.8.8 >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		mtucheck=1
	fi
}

serial_check () {
	serial=`cat /etc/serial`
}

mac_check () {
	mac=`cat /etc/mac`
}

url_status_check $url
splash_check $splashcheck
sync_id
mac_check
mtu_check
serial_check

json_init
json_add_object "data"
json_add_boolean "icmp_host" $icmphost
json_add_boolean "icmp_ip" $icmpip
json_add_boolean "ct" $urlstatus
json_add_boolean "splash" $splashcheck
json_add_boolean "mtu_check" $mtucheck
json_add_string "sync_id" "$syncstatus"
json_close_object

health_check=`json_dump`

echo $health_check

post_ct () {
	curl --connect-timeout 5 -d "$health_check" -s -H "Content-Type: application/json" -X POST  $api_url/api/v1/nas/reporter\?mac\=$mac\&serial\=$serial\&type\=doctor -k
}

post_ct
