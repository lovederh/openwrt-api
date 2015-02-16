#!/bin/bash

if [[ "$1" = "" ]]; then
    echo "synccode [remote ip]"
    echo "./synccode.sh 192.168.8.1"
    exit
fi


scp -r Openwrt-api/files/luci/ root@$1:/usr/lib/lua/
