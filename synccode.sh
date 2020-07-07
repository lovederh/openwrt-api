#!/bin/bash

if [[ "$1" = "" ]]; then
    echo "synccode [remote ip]"
    echo "./synccode.sh 192.168.2.1"
    exit
fi


#scp -r Openwrt-api/files/luci/ root@$1:/usr/lib/lua/
rsync -P --rsh=ssh Openwrt-api/files/luci/ root@$1:/usr/lib/lua/