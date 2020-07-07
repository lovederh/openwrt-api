# 如何使用

修改synccode.sh，将其中的ip地址，修改为我们自己的192.168.2.1
然后执行./synccode.sh，将程序拷贝到openwrt路由器中
执行下面的curl命令进行测试

# Using the OpenWrt API
LuCI provides some of its libraries to external applications through a JSON-RPC API. This Howto shows how to use it and provides information about available functions.    
openwrt-api 

基于json-rpc规范在LuCI原生的框架上扩展了一套api接口,为远程设备提供业务层面上的服务调用。

# Basics
LuCI comes with an efficient JSON De-/Encoder together with a JSON-RPC-Server which implements the JSON-RPC 1.0 and 2.0 (partly) specifications. The LuCI JSON-RPC server offers several independent APIs. Therefore you have to use different URLs for every exported library. Assuming your LuCI-Installation can be reached through /cgi-bin/luci any exported library can be reached via /cgi-bin/luci/api/LIBRARY.    

json-rpc 是一种以json为消息格式的远程调用服务，它是一套允许运行在不同操作系统、不同环境的程序实现基于Internet过程调用的规范和一系列的实现。这种远程过程调用可以使用http作为传输协议，也可以使用其它传输协议，传输的内容是json消息体。

api分为一下几类：
    
auth 认证类 ：提供认证类的服务接口，不需要使用token认证    
net 网络类；提供网络相关的服务接口，需要使用token认证    
sys 系统类；提供系统相关的服务接口，需要使用token认证
info 信息类；提供信息相关的服务接口，不需要使用token认证


# Authentication
Most exported libraries will require a valid authentication to be called with. If you get an HTTP 403 Forbidden status code you are probably missing a valid authentication token. To get such a token you have to call the function login of the RPC-Library auth. Following our example from above this login function would be provided at /cgi-bin/luci/rpc/auth. The function accepts 2 parameters: username and password (of a valid user account on the host system) and returns an authentication token.

If you want to call any exported library which requires an authentication token you have to append it as an URL parameter auth to the RPC-Server URL. So instead of calling /cgi-bin/luci/api/LIBRARY you have to call /cgi-bin/luci/api/LIBRARY?auth=TOKEN.

大多数api接口需要使用正确的认证方式才能使用，如果api调用后收到http 403 forbidden的回应，可能是因为没有提供正确的token。使用auth类的login方法输入正确的用户名和密码才能够得到正确的token。

# Exported Libraries

`
curl -i -X POST -d '{"jsonrpc": "2.0", "method": "login", "params": { "user": "root", "password":"root"}, "id": 1}' http://192.168.2.1/cgi-bin/luci/rpc/auth
curl -i -d '{"jsonrpc": "2.0", "method": "wifi.iwscan", "params": ["root","root"], "id": 1}' \
--header 'Content-Type: application/json'  \
--header 'Cookie: sysauth=f58cf98779e5f69970251ad5d0e2253c' \
http://192.168.2.1/cgi-bin/luci/rpc/sys?auth=f58cf98779e5f69970251ad5d0e2253c`


## auth 认证类接口

### method: admin_login
#### @ description 登录
#### @ param password: password
#### @ return token: authentication token
#### @ example
`curl -i -X POST -d '{"method":"admin_login","params":["root"]}' http://192.168.2.1/cgi-bin/luci/api/auth`

`{"id":"","result":{"token":"bd946bd87ff467ca9ca0663b4058f114"},"error":null}`

### method: admin_logout
#### @ description 登出
#### @ param none
#### @ return none
#### @ example
`curl -i -X POST -d '{"method":"logout"}' http://192.168.8.1/cgi-bin/luci/api/auth`

`{"id":"","result":{},"error":null}`

### method: admin_change_password
#### @ description 改变后台管理密码
#### @ param oldpassword: old password
#### @ param newpassword: new password
#### @ return none
#### @ example
`curl -i -X POST -d '{"method":"admin_change_password","params":["root","root"]}' http://192.168.2.1/cgi-bin/luci/api/auth`

`{"id":"","result":{},"error":null}`

## net 网络类接口

### method: get_wan_status 
#### @ description 获取wan口状态
#### @ param none
#### @ return 
ipaddrs: ip related address    
ip6addrs: ip6 related address    
proto: 网络协议 dhcp / static / pppoe     
rx_bytes: 已接收到的字节数    
tx_bytes: 已发送的字节数    
tx_packets: 已发送的数据包    
rx_packets: 已接收的数据包    
uptime: 正常运行的时间    
is_up: 网络接口是否正常工作    
#### @ example
`curl -i -X POST -d '{"method":"get_wan_status"}' http://192.168.2.1/cgi-bin/luci/api/net?auth=e9698278cd3725cf26f8cb2c4327f31a`

`{"id":"","result":{"rx_bytes":0,"ifname":"apcli0","tx_bytes":0,"ipaddrs":[{"netmask":"255.255.255.0","addr":"192.168.10.208","prefix":24}],"gwaddr":"192.168.10.1","tx_packets":0,"dnsaddrs":["192.168.10.1"],"rx_packets":0,"proto":"dhcp","id":"wan","ip6addrs":[],"uptime":2535,"subdevices":[],"is_up":true,"macaddr":"66:51:7E:80:09:F4","type":"ethernet","name":"apcli0"},"error":null}`

### method: get_wan_config
#### @ description 获取wan口配置信息
#### @ param none
#### @ return
proto: 网络协议 dhcp / static / pppoe
ipaddr: ip address     
netmask: 网络掩码 255.255.255.0     
gateway: 网关地址     
dns: dns地址 可为多个 "192.168.0.1 8.8.8.8"     
username: pppoe username      
password: pppoe password      
mtu 最大传输速度      
mrt 最大接收速度      
dns_mode dns模式 手动: hand/自动: auto
pppd_options pppd选项
#### @ example
`curl -i -X POST -d '{"jsonrpc":"2.0","method":"get_wan_config","params":[],"id":1}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":null,"result":{"proto":"dhcp","dns_mode":"auto"},"error":null}`

### method: set_wan_config_pppoe
#### @ description 设置wan口pppoe配置参数
#### @ param reload: true/false 是否重启网络服务 
#### @ param username: pppoe username 
#### @ param password: pppoe password 
#### @ return 
#### @ example
`curl -i -X POST -d '{"method":"set_wan_config_pppoe","params":["false","090704","12345678"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":{},"error":null}`

### method: set_wan_config_pppoe_advanced
#### @ description 高级设置-设置wan口pppoe配置参数
#### @ param reload: true/false 是否重启网络服务
#### @ param username: pppoe username
#### @ param password: pppoe password
#### @ param mtu: 最大传输单位
#### @ param mru: 最大接收单位
#### @ param option: 高级pppd选项
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"set_wan_config_pppoe_advanced","params":["true","090704","12345678"，"1492","1200",""]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":{},"error":null}`

### method: set_wan_config_dhcp
#### @ description 设置wan口dhcp配置参数
#### @ param reload: true/false 是否重启网络服务 
#### @ return 
#### @ example
`curl -i -X POST -d '{"method":"set_wan_config_dhcp","params":["false"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":{},"error":null}`

### method: set_wan_config_dhcp_advanced
#### @ description 高级设置-设置wan口dhcp配置参数
#### @ param reload: true/false 是否重启网络服务
#### @ param dns_mode: 自动获取: auto/手动输入: hand
#### @ param dns: dns地址 可为多个 "192.168.0.1 8.8.8.8"
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"set_wan_config_dhcp_advanced","params":["false","auto",""]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":{},"error":null}`

### method: set_wan_config_static
#### @ description 设置wan口静态地址配置参数
#### @ param reload: true/false 是否重启网络服务 
#### @ param ipaddr: ip address 
#### @ param netmask: 网络掩码 255.255.255.0 
#### @ param gateway: 网关地址
#### @ param dns: dns地址 可为多个 "192.168.0.1 8.8.8.8" 
#### @ return 
#### @ example
`curl -i -X POST -d '{"method":"set_wan_config_static","params":["false","192.168.0.222","255.255.255.0","192.168.0.1","8.8.8.8 4.4.4.4"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":{},"error":null}`

### method: get_lan_status
#### @ description 获取lan口状态
#### @ param none
#### @ return 
ipaddrs: ip related address    
ip6addrs: ip6 related address    
proto: 网络协议 dhcp / static / pppoe     
rx_bytes: 已接收到的字节数    
tx_bytes: 已发送的字节数    
tx_packets: 已发送的数据包    
rx_packets: 已接收的数据包    
uptime: 正常运行的时间    
is_up: 网络接口是否正常工作    
#### @ example
`curl -i -X POST -d '{"method":"get_lan_status"}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":{"rx_bytes":736184,"ifname":"br-lan","tx_bytes":2001786,"ipaddrs":[{"netmask":"255.255.255.0","addr":"192.168.8.1","prefix":24}],"tx_packets":3242,"dnsaddrs":[],"rx_packets":3912,"proto":"static","id":"lan","ip6addrs":[{"netmask":"FFFF:FFFF:FFFF:FFF0:0:0:0:0","addr":"FD45:D9A2:4C5:0:0:0:0:1","prefix":60}],"uptime":2543,"is_up":true,"macaddr":"64:51:7E:80:09:F4","type":"bridge","name":"br-lan"},"error":null}`

### method: set_lan_config_static
#### @ description 设置lan口静态地址配置参数
#### @ param reload: true/false 是否重启网络服务 
#### @ param ipaddr: ip address 
#### @ param netmask: 网络掩码 255.255.255.0 
#### @ return 
#### @ example
`curl -i -X POST -d '{"method":"set_wan_config_static","params":["ture","ipaddr","netmask"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":{},"error":null}`

### method: get_wifi_2g_status 
#### @ description 获取2g wifi接口状态
#### @ param none
#### @ return 
encryption: 加密方式     
bssid:     
mode:     
quality:     
noise:     
ssid:     
up: 网络接口是否正常工作     
id:     
txpower: 信号强度 1：强/2：中/3：弱
如果无线网卡支持多发射功率设定，则使用该参数设定发射，单位为dBm，如果指定为W（毫瓦），只转换公式为：
dBm=30+log(W)。参数on/off可以打开和关闭发射单元，auto和fixed指定无线是否自动选择发射功率。     
channel: 使用信道     
signal: 信号强度     
#### @ example
`curl -i -X POST -d '{"method":"get_wifi_2g_status"}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":{"ifname":"ra0","encryption":"-","bssid":"64:51:7E:80:09:F4","mode":"Client","quality":0,"noise":0,"ssid":"wrtnode-limx","up":false,"assoclist":[],"txpoweroff":0,"bitrate":300,"txpower":0,"name":"Client \u0022wrtnode-limx\u0022","channel":1,"id":"ra0.network1","country":"00","signal":0},"error":null}`

### method: get_wifi_5g_status 
#### @ description 获取5g wifi接口状态
#### @ param none
#### @ return 
encryption: 加密方式     
bssid:     
mode:     
quality:     
noise:     
ssid:     
up: 网络接口是否正常工作     
id:     
txpower: 信号强度 1：强/2：中/3：弱
如果无线网卡支持多发射功率设定，则使用该参数设定发射，单位为dBm，如果指定为W（毫瓦），只转换公式为：
dBm=30+log(W)。参数on/off可以打开和关闭发射单元，auto和fixed指定无线是否自动选择发射功率。     
channel: 使用信道     
signal: 信号强度
channel_mode: 信号模式 手动模式: hand/自动模式: auto
#### @ example
`curl -i -X POST -d '{"method":"get_wifi_2g_status"}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":{"ifname":"ra0","encryption":"-","bssid":"64:51:7E:80:09:F4","mode":"Client","quality":0,"noise":0,"ssid":"wrtnode-limx","up":false,"assoclist":[],"txpoweroff":0,"bitrate":300,"txpower":0,"name":"Client \u0022wrtnode-limx\u0022","channel":1,"id":"ra0.network1","country":"00","signal":0},"error":null}`

### method: set_wifi_2g_config
#### @ description 设置wifi接口wpa方式的安全配置参数
#### @ param reload: true/false 是否重启网络服务 
#### @ param ssid:  
#### @ param password:  
#### @ param txpower: 信号强度 1：强/2：中/3：弱
#### @ return 
#### @ example
`curl -i -X POST -d '{"method":"set_wifi_2g_config","params":["false","domy_wifi","88888888","1"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":null,"error":null}`

### method: set_wifi_2g_config_advanced
#### @ description 设置wifi接口wpa方式的安全配置参数
#### @ param reload: true/false 是否重启网络服务
#### @ param ssid: 无线名称
#### @ param hide_ssid: 隐藏无线 true: 隐藏/false: 显示
#### @ param password: 无线密码
#### @ param hwmode: 无线模式 auto: /802.11g+n: 11ng/802.11g: 11g/802.11b: 11b/802.11ac: 11ac/802.11a+n: 11na/802.11a: 11a
#### @ param htmode: 频道宽带 auto: /80MHz: HT80/40MHz: HT40+/20MHz: HT20
#### @ param channel: 信道 auto: auto/%d = %d
#### @ param auth_type: 无线认证类型 无: none/WAP-PSK: psk/WAP2-PSK: psk2
#### @ param encrypt_type: 无线加密方式 AES: ccmp/TKIP+AES: tkip+ccmp
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"set_wifi_2g_config_advanced","params":["false","domy_wifi","false","88888888","11ng","HT40+","9","psk2","ccmp"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":null,"error":null}`

### method: set_wifi_5g_config_advanced
#### @ description 设置wifi接口wpa方式的安全配置参数
#### @ param reload: true/false 是否重启网络服务
#### @ param ssid: 无线名称
#### @ param hide_ssid: 隐藏无线 true: 隐藏/false: 显示
#### @ param password: 无线密码
#### @ param hwmode: 无线模式 auto: /802.11g+n: 11ng/802.11g: 11g/802.11b: 11b/802.11ac: 11ac/802.11a+n: 11na/802.11a: 11a
#### @ param htmode: 频道宽带 auto: /80MHz: HT80/40MHz: HT40+/20MHz: HT20
#### @ param channel: 信道 auto: auto/%d = %d
#### @ param auth_type: 无线认证类型 无: none/WAP-PSK: psk/WAP2-PSK: psk2
#### @ param encrypt_type: 无线加密方式 AES: ccmp/TKIP+AES: tkip+ccmp
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"set_wifi_5g_config_advanced","params":["false","domy_wifi","false","88888888","11ng","HT40+","9","psk2","ccmp"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":null,"error":null}`

### method: set_wifi_5g_config
#### @ description 设置wifi接口wpa方式的安全配置参数
#### @ param reload: true/false 是否重启网络服务 
#### @ param ssid:  
#### @ param password:  
#### @ param txpower: 信号强度 1：强/2：中/3：弱
#### @ return 
#### @ example
`curl -i -X POST -d '{"method":"set_wifi_2g_config","params":["false","domy_wifi","88888888","1"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":null,"error":null}`

### method: get_dhcp_status 
#### @ description 获取dhcp信息
#### @ param none
#### @ return 
expires: DHCP过期时间     
macaddr:     
ipaddr:     
hostname:     
#### @ example
`curl -i -X POST -d '{"method":"get_dhcp_leases"}' \
--header 'Content-Type: application/json'  \
--header 'Cookie: sysauth=f58cf98779e5f69970251ad5d0e2253c' \
http://192.168.2.1/cgi-bin/luci/api/net?auth=f58cf98779e5f69970251ad5d0e2253c`

`{"id":"","result":[{"expires":-27592,"macaddr":"48:d7:05:b7:a7:b5","ipaddr":"192.168.8.221","hostname":"appledeAir"}],"error":null}`

### method: get_network_associate_list
#### @ description 获取所有网络上关联的设备
#### @ param name: none 
#### @ return
linktype 设备接入方式 2.4g/5g/lan      
devicename 设备名称      
devicetype 设备类型     
macaddr mac地址     
ipaddr ip地址     
txpackets 已上传字节数     
rxpackets 已接收字节数     
#### @ example
`curl -i -X POST -d '{"method":"get_network_associate_list"}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":[{"linktype":"2.4g","devicename":"domy-box","devicetype":"domy-box","macaddr":"ff:ff:ff:ff:ff","ipaddr":"192.168.8.44","txpackets":"44","rxpackets","55"}}],"error":null}`

### method: get_synflood_config_enable
#### @ description Dos防护是否开启
#### @ param name: none
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"get_synflood_config_enable"}' http://192.168.1.1/cgi-bin/luci/api/net?auth=c3f843d8db37daff0055f7db8bb565f7`

`{"id":null,"result":{"enable":"false"},"error":null}`

### method: get_firewall_config_enable
#### @ description 获取云安全配置
#### @ param name: none
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"get_firewall_config_enable"}' http://192.168.1.1/cgi-bin/luci/api/net?auth=c3f843d8db37daff0055f7db8bb565f7`

`{"id":null,"result":{"enable":"true","packagetype":"accepted","pingswitch":"true"},"error":null}`

### method: set_device_alias
#### @ description 设置设备别名
#### @ param mac: 要修改设备的mac地址
#### @ param name: 要修改的名称
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"set_device_alias","params":["5c:f9:38:93:c2:40","cc"]}' http://192.168.1.1/cgi-bin/luci/api/net?auth=c3f843d8db37daff0055f7db8bb565f7`

`{"id":"set_device_alias","result":null,"error":null}`

### method: set_firewall_config_enable
#### @ description 设置云安全配置
#### @ param reload: true/false 是否重启网络服务 
#### @ param enable: true/false 是否打开防火墙 
#### @ param packagetype: dropped/accepted/both 
#### @ param pingswitch: true/false
#### @ return 
#### @ example
`curl -i -X POST -d '{"method":"set_firewall_config_enable","params":["true","true","dropped","true"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":{},"error":null}`

### method: set_synflood_config_enable
#### @ description DoS防护设置
#### @ param reload: true/false 是否重启网络服务 
#### @ param enable: 是否打开DoS防护 
#### @ return 
#### @ example
`curl -i -X POST -d '{"method":"set_synflood_config_enable","params":["false","false"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":{},"error":null}`

### method: service_reload
#### @ description 重启相关网络服务
#### @ param wireless: true/false 重启无线服务  
#### @ param network: true/false 重启网络服务  
#### @ param firewall: true/false 重启防火墙服务  
#### @ param dhcp: true/false 重启dhcp服务  
#### @ return 
#### @ example
`curl -i -X POST -d '{"method":"service_reload","params":["false","false","false","false"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":null,"error":null}`

### method: set_router_config_init
#### @ description 设置路由是否初始化
#### @ param enable: true/false
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"service_reload","params":["false"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":null,"error":null}`

### method: set_nat_config_enable
#### @ description 设置NAT开启/关闭
#### @ param reload: true/false 是否重启网络服务
#### @ param enable: true/false nat开启/关闭
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"set_nat_config_enable","params":["false"，"false"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":null,"error":null}`

### method: get_nat_config_enable
#### @ description 获取NAT开启状态
#### @ param none:
#### @ return
result true/false 开启/关闭
#### @ example
`curl -i -X POST -d '{"method":"get_nat_config_enable"}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"get_nat_config_enable","result":{"enable":false},"error":null}`

### method: set_upnp_config_enable
#### @ description 设置upnp开启/关闭
#### @ param reload: true/false 是否重启网络服务
#### @ param enable: true/false upnp开启/关闭
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"set_upnp_config_enable","params":["false"，"false"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":null,"error":null}`

### method: get_upnp_config_enable
#### @ description 获取upnpd开启状态
#### @ param none:
#### @ return
result true/false 开启/关闭
#### @ example
`curl -i -X POST -d '{"method":"get_upnp_config_enable"}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"get_upnp_config_enable","result":{"enable":false},"error":null}`

### method: set_wan_config_enable
#### @ description 设置wan口开启/关闭
#### @ param enable: true/false wan开启/关闭
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"set_wan_config_enable","params":["false"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"set_wan_config_enable","result":null,"error":null}`

### method: get_wan_config_enable
#### @ description 获取wan开启状态
#### @ param none
#### @ return
result true/false 开启/关闭
#### @ example
`curl -i -X POST -d '{"method":"get_wan_config_enable"}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"get_wan_config_enable","result":{"enable":false},"error":null}`

### method: set_dhcp_config_enable
#### @ description 设置dhcp开启/关闭
#### @ param reload: true/false 是否重启网络服务
#### @ param enable: true/false dhcp开启/关闭
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"set_dhcp_config_enable","params":["false"，"true"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":null,"error":null}`

### method: get_dhcp_config_status
#### @ description 获取dhcp开启状态
#### @ param none:
#### @ return
result true/false 开启/关闭
startaddr: 开始IP
endaddr: 结束IP
expire: IP有效期
#### @ example
`curl -i -X POST -d '{"method":"get_dhcp_config_status"}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"get_dhcp_config_status","result":{"endaddr":250,"expire":"12h","enable":false,"startaddr":"100"},"error":null}`

### method: set_dhcp_config_poll
#### @ description dhcp服务设置-基本设置
#### @ param reload: true/false 是否重启网络服务
#### @ param startaddr: 开始IP: %d
#### @ param endaddr: 结束IP: %d
#### @ param expire: IP有效期: %dh
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"set_dhcp_config_poll","params":["false"，"100","150","12h"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":null,"error":null}`

### method: get_dhcp_config_static_list
#### @ description 获取dhcp静态IP列表
#### @ param none
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"get_dhcp_config_static_list"}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"get_dhcp_config_static_list","result":[{"mac":"5c:f9:38:93:c2:40","name":"cc","ip":"192.168.1.224"}],"error":null}`

### method: set_dhcp_config_static_list
#### @ description 增加dhcp静态IP列表
#### @ param reload: true/false 是否重启网络服务
#### @ param array: jsonarray 设备列表
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"set_dhcp_config_static_list","params":["false", "[{\"mac\":\"5c:f9:38:93:c2:40\",\"name\":\"cc\",\"ip\":\"192.168.1.224\"},{\"mac\":\"8c:f9:38:93:c2:45\",\"name\":\"cccc\",\"ip\":\"192.168.1.120\"}]"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"set_dhcp_config_static_list","result":null,"error":null}`

### method: set_dhcp_config_static_enable
#### @ description 设置dhcp静态列表开启/关闭
#### @ param enable: true/false dhcp列表开启/关闭
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"set_dhcp_config_static_enable","params":["true"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"set_dhcp_config_static_enable","result":null,"error":null}`

### method: get_dhcp_config_static_enable
#### @ description 获取dhcp静态列表开启/关闭
#### @ param none
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"get_dhcp_config_static_enable"}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"get_dhcp_config_static_enable","result":{"enable":true},"error":null}`

### method: set_route_config_static_enable
#### @ description 获取路由静态列表开启/关闭
#### @ param enable: true/false 路由静态列表开启/关闭
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"set_route_config_static_enable","params":["true"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"set_route_config_static_enable","result":null,"error":null}`

### method: get_route_config_static_enable
#### @ description 获取路由静态列表开启/关闭
#### @ param none
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"get_route_config_static_enable"}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"get_route_config_static_enable","result":{"enable":true},"error":null}`

### method: get_route_config_static_list
#### @ description 获取静态路由列表
#### @ param none
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"get_route_config_static_list"}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"get_route_config_static_list","result":[{"target":"192.168.1.224","netmask":"255.255.255.0","gateway":"192.168.10,1"}],"error":null}`

### method: set_route_config_static_list
#### @ description 设置静态路由列表
#### @ param reload: true/false 是否重启网络服务
#### @ param array: jsonarray 设备列表
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"set_route_config_static_list","params":["false", "[{\"target\":\"192.168.1.224\",\"netmask\":\"255.255.255.0\",\"gateway\":\"192.168.10,1\"}]"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"set_route_config_static_list","result":null,"error":null}`

### method: set_wifi_black_list_enable
#### @ description 设置wifi黑名单开启/关闭
#### @ param reload: true/false 是否重启网络服务
#### @ param enable: true/false 路由静态列表开启/关闭
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"set_wifi_black_list_enable","params":["false","true"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"set_wifi_black_list_enable","result":null,"error":null}`

### method: get_wifi_black_list_enable
#### @ description 获取wifi黑名单开启/关闭
#### @ param none
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"get_wifi_black_list_enable"}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"get_wifi_black_list_enable","result":{"enable":true},"error":null}`

### method: set_wifi_black_list
#### @ description 设置wifi连接黑名单
#### @ param reload: true/false 是否重启网络服务
#### @ param array: jsonarray 设备列表
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"set_wifi_black_list","params":["false", "[{"mac":"5c:f9:38:93:c2:40","wifi_2g":"false","wifi_5g":"true"}]"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"set_wifi_black_list","result":null,"error":null}`

### method: get_wifi_black_list
#### @ description 获取wifi连接黑名单
#### @ param none
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"get_wifi_black_list"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"get_wifi_black_list","result":"[{"mac":"5c:f9:38:93:c2:40","wifi_2g":false,"wifi_5g":true}]","error":null}`

### method: set_wan_config_ipv6
#### @ description 设置ipv6
#### @ param proto ipv6设置 关闭: none/native: dhcp/static: static
#### @ param ip6addr ipv6地址
#### @ param ip6prefix ipv6前缀
#### @ param gateway 网关
#### @ param dns DNS
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"set_wan_config_ipv6"]}' http://192.168.8.1/cgi-bin/luci/api/net?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"set_wan_config_ipv6","result":null,"error":null}`

## sys 系统类接口

### method: get_memory_info 
#### @ description 获取系统内存信息
#### @ param none
#### @ return
membuffers:    
memcached:    
swapcached:    
memtotal:    
swaptotal:    
swapfree:    
memfree:    
#### @ example
`curl -i -X POST -d '{"method":"get_memory_info"}' http://192.168.2.1/cgi-bin/luci/api/sys?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":{"membuffers":3072,"memcached":11428,"swapcached":0,"memtotal":61852,"swaptotal":0,"swapfree":0,"memfree":31512}"error":null}`

### method: reboot 
#### @ description 重启路由器
#### @ param none
#### @ return none
#### @ example
`curl -i -X POST -d '{"method":"reboot"}' http://192.168.8.1/cgi-bin/luci/api/sys?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":{}"error":null}`

### method: reset 
#### @ description 恢复出厂设置
#### @ param none
#### @ return none
#### @ example
`curl -i -X POST -d '{"method":"reset"}' http://192.168.8.1/cgi-bin/luci/api/sys?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"","result":{}"error":null}`

### method: is_upgrade
#### @ description 检查新版本
#### @ param none
#### @ return none
path 固件路径
#### @ example
`curl -i -X POST -d '{"method":"is_upgrade"}' http://192.168.8.1/cgi-bin/luci/api/sys?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"is_upgrade","result":{"currver":{"version":"0.0.1","description":""},"newver":{"version":"0.0.2","description":"",path:""}},"error":null}`

### method: upgrade
#### @ description 升级
#### @ param path 固件路径
#### @ return none
#### @ example
`curl -i -X POST -d '{"method":"upgrade", "params":["/tmp/domy_0.0.2.bin"]}' http://192.168.8.1/cgi-bin/luci/api/sys?auth=bd946bd87ff467ca9ca0663b4058f114`

`{"id":"upgrade","result":null,"error":null}`

## info 信息类接口

### method: get_system_info
#### @ description 获取系统信息
#### @ param none
#### @ return
uptime: 路由器开机时间
hostname: 路由器主机名称
localtime: 路由器本地时间
kernel: 路由器内核版本
firmware: 路由器固件版本
#### @ example
`curl -i -X POST -d '{"method":"get_system_info"}' http://192.168.2.1/cgi-bin/luci/api/info`

`{"id":"","result":{"uptime":12014,"hostname":"OpenWrt","localtime":"Tue Dec 16 05:45:43 2014","kernel":"3.10.44\u000a","firmware":"WRTnode Barrier Breaker r41508/LuCI Trunksvn-r10457"},"error":null}`

### method: get_network_updown_status
#### @ description 获取各个网络接口的工作状态
#### @ param name: none
#### @ return
#### @ example
`curl -i -X POST -d '{"method":"get_network_updown_status"}' http://192.168.8.1/cgi-bin/luci/api/info`

`{"id":"","result":{"wan":"up","lan":"up","wifi":"up"},"error":null}`

### method: get_service_reload_status
#### @ description 获取服务加载状态
#### @ param none
#### @ return
progress: 可以获取到服务重新加载过程信息，当读取到finish后，加载完毕
#### @ example
`curl -i -X POST -d '{"method":"get_service_reload_status"}' http://192.168.8.1/cgi-bin/luci/api/info`

`{"id":"","result":{progress:finish},"error":null}`


### method: get_firmware_version
#### @ description 获取当前固件版本
#### @ param none
#### @ return
version 当前的固件版本
#### @ example
`curl -i -X POST -d '{"method":"get_firmware_version"}' http://192.168.1.1/cgi-bin/luci/api/info`

`{"id":"get_firmware_version","result":{"version":"1.0.0"},"error":null}`

### method: get_router_config_init
#### @ description 判断当前路由是否初始化
#### @ param none
#### @ return
version 当前的固件版本
#### @ example
`curl -i -X POST -d '{"method":"get_router_config_init"}' http://192.168.1.1/cgi-bin/luci/api/info`

`{"id":"get_router_config_init","result":{"init":false},"error":null}`

















