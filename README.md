# openwrt-api
Using the OpenWrt API
LuCI provides some of its libraries to external applications through a JSON-RPC API. This Howto shows how to use it and provides information about available functions.
openwrt-api

基于json-rpc规范在LuCI原生的框架上扩展了一套api接口,为远程设备提供业务层面上的服务调用。

Basics
LuCI comes with an efficient JSON De-/Encoder together with a JSON-RPC-Server which implements the JSON-RPC 1.0 and 2.0 (partly) specifications. The LuCI JSON-RPC server offers several independent APIs. Therefore you have to use different URLs for every exported library. Assuming your LuCI-Installation can be reached through /cgi-bin/luci any exported library can be reached via /cgi-bin/luci/api/LIBRARY.

json-rpc 是一种以json为消息格式的远程调用服务，它是一套允许运行在不同操作系统、不同环境的程序实现基于Internet过程调用的规范和一系列的实现。这种远程过程调用可以使用http作为传输协议，也可以使用其它传输协议，传输的内容是json消息体。

api分为一下几类：

auth 认证类 ：提供认证类的服务接口，不需要使用token认证
net 网络类；提供网络相关的服务接口，需要使用token认证
sys 系统类；提供系统相关的服务接口，需要使用token认证 info 信息类；提供信息相关的服务接口，不需要使用token认证
