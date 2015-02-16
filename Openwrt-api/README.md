OPENWRT API
===
Openwrt api use json-rpc protocol for remote control purpose.

Installation
---
Add next line to feeds.conf:
src-git openwrtapi https://gitlab.ezlink-wifi.com/limengxiang/openwrtapi.git

./scripts/feeds update -a
./scripts/feeds install -a

make menuconfig 
Select 'openwrtapi' option with build-in
Select 'luci-->modules->luci-mod-rpc' with build-in

make V=s

网页加载时，有可能回同时发送大量api请求，如果超出了httpd的处理请求的限制，会造成api请求无法响应，所以需要调整httpd.conf中请求数量的限制：
uci set uhttpd.main.max_requests=30
uci commit

Remove 
---





