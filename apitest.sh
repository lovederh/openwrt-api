#!/bin/bash
set +v
set +x

if [[ "$1" = "" ]]; then
    echo "apitest [remote ip] [password] [auth/net/sys/info] [method] [para1] [para2] ..."
    exit
fi

echo -e "\n\n"

ip=$1
echo "ip is : "$ip
shift

password=$1
echo "password is : "$password
shift

class=$1
echo "class is : "$class
shift

method=$1
echo "method is : "$method
shift

while [ $# -ne 0 ]
do
    arg=`echo $1`
    params+="\"$arg\""
    if [ $# -gt 1 ]; then
        params+=","
    fi
    shift
done
echo "params list : "$params

echo -e "\n\n"

set -x
result=`curl -s -i -X POST -d "{\"id\":\"admin_login\",\"method\":\"admin_login\",\"params\":[\"$password\"]}" http://$ip/cgi-bin/luci/api/auth`
set +x

token=`echo $result| grep '\"token\":\"' | sed 's/^.*token\":\"//g' | sed 's/\"},.*$//g'`

if [ -z "$token" ]; then
    echo "token is null !!!"
    exit 0
fi

echo "token is $token" 
echo -e "\n\n"

set -x
result=`curl -s -i -X POST -d "{\"id\":\"$method\",\"method\":\"$method\",\"params\":[$params]}" http://$ip/cgi-bin/luci/api/$class?auth=$token`
set +x

echo -e "\n\n"
#echo $result 2>&1

exit 0






