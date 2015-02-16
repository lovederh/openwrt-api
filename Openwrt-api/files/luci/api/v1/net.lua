
module("luci.api.v1.net", package.seeall)

local debug = require "luci.api.tools.debug"
local utils = require "luci.api.tools.utils"
local json = require "luci.api.tools.json"
local status = require "luci.tools.status"

function service_reload(wireless,network,firewall,dhcp)
    local config = ""

    if wireless == "true" then
        config = config .. "wireless "
    end

    if network == "true" then
        config = config .. "network "
    end

    if firewall == "true" then
        config = config .. "firewall "
    end

    if dhcp == "true" then
        config = config .. "dhcp "
    end

    debug.output("service reload:"..config)
    utils.action_restart(config)
end

function get_wan_status()
    local source = luci.util.exec
    local netm = require "luci.model.network".init()
    local rv = { }
    local wan

    local ifaces = "wan"
    local iface
    for iface in ifaces:gmatch("[%w%.%-_]+") do
        local net = netm:get_network(iface)
        local device = net and net:get_interface()
        if device then
            local _data = json.decode(source("devstatus eth0"))
            local data = {
                id         = iface,
                proto      = net:proto(),
                uptime     = net:uptime(),
                gwaddr     = net:gwaddr(),
                dnsaddrs   = net:dnsaddrs(),
                name       = device:shortname(),
                type       = device:type(),
                ifname     = device:name(),
                macaddr    = _data.macaddr, --device:mac(),
                is_up      = device:is_up(),
                rx_bytes   = device:rx_bytes(),
                tx_bytes   = device:tx_bytes(),
                rx_packets = device:rx_packets(),
                tx_packets = device:tx_packets(),

                ipaddrs    = { },
                ip6addrs   = { },
                subdevices = { }
            }

            local _, a
            for _, a in ipairs(device:ipaddrs()) do
                data.ipaddrs[#data.ipaddrs+1] = {
                    addr      = a:host():string(),
                    netmask   = a:mask():string(),
                    prefix    = a:prefix()
                }
            end
            for _, a in ipairs(device:ip6addrs()) do
                if not a:is6linklocal() then
                    data.ip6addrs[#data.ip6addrs+1] = {
                        addr      = a:host():string(),
                        netmask   = a:mask():string(),
                        prefix    = a:prefix()
                    }
                end
            end

            --[[
            for _, device in ipairs(net:get_interfaces() or {}) do
                data.subdevices[#data.subdevices+1] = {
                    name       = device:shortname(),
                    type       = device:type(),
                    ifname     = device:name(),
                    macaddr    = device:mac(),
                    macaddr    = device:mac(),
                    is_up      = device:is_up(),
                    rx_bytes   = device:rx_bytes(),
                    tx_bytes   = device:tx_bytes(),
                    rx_packets = device:rx_packets(),
                    tx_packets = device:tx_packets(),
                }
            end
            ]]

            rv[#rv+1] = data
            wan = data
        else
            rv[#rv+1] = {
                id   = iface,
                name = iface,
                type = "ethernet"
            }
            wan = rv[#rv]
        end
    end
    
    return wan
end

function get_wan_config()
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    local data = {}
    local proto = uci:get("network","wan","proto")
    if proto then
        data.proto = proto
        if proto == "dhcp" then
            local dns_mode = uci:get("openwrtapi","wan","dns_mode")
            if dns_mode then
                data.dns_mode = dns_mode
            end
        end
    end

    local username = uci:get("network","wan","username")
    if username then
        data.username = username
    end

    local password = uci:get("network","wan","password")
    if password then
        data.password = password
    end

    local ipaddr = uci:get("network","wan","ipaddr")
    if ipaddr then
        data.ipaddr = ipaddr
    end

    local netmask = uci:get("network","wan","netmask")
    if netmask then
        data.netmask = netmask
    end

    local gateway = uci:get("network","wan","gateway")
    if gateway then
        data.gateway = gateway
    end

    local dns = uci:get("network","wan","dns")
    if dns then
        data.dns = dns
    end

    local mtu = uci:get("network","wan","mtu")
    if mtu then
        data.mtu = mtu
    end

    local mru = uci:get("network","wan","mru")
    if mru then
        data.mru = mru
    end

    local pppd_options = uci:get("network","wan","pppd_options")
    if pppd_options then
        data.pppd_options = pppd_options
    end

    return data
end

function set_wan_config_pppoe(reload,username,password)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    uci:set("network","wan","proto","pppoe")
    uci:set("network","wan","username",username)
    uci:set("network","wan","password",password)
    uci:delete("network","wan","ipaddr")
    uci:delete("network","wan","ip6addr")
    uci:delete("network","wan","ip6prefix")
    uci:delete("network","wan","ip6gw")
    uci:delete("network","wan","netmask")
    uci:delete("network","wan","gateway")
    uci:delete("network","wan","dns")

    uci:save("network")
    uci.commit("network")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function set_wan_config_pppoe_advanced(reload,username,password,mtu,mru,option)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    uci:set("network","wan","proto","pppoe")
    uci:set("network","wan","username",username)
    uci:set("network","wan","password",password)

    uci:delete("network","wan","ipaddr")
    uci:delete("network","wan","netmask")
    uci:delete("network","wan","gateway")
    uci:delete("network","wan","ip6addr")
    uci:delete("network","wan","ip6prefix")
    uci:delete("network","wan","ip6gw")

--    if dns_mode == "auto" then
--        uci:set("network","wan","peerdns",1)
--        uci:delete("network","wan","dns")
--    else
--        uci:set("network","wan","peerdns",0)
--        uci:set("network","wan","dns",dns)
--    end

    uci:set("network","wan","mtu",mtu)
    uci:set("network","wan","mru",mru)

    if option then
        uci:set("network","wan","pppd_options",option)
    end

    uci:save("network")
    uci.commit("network")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function set_wan_config_dhcp(reload)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    uci:set("network","wan","proto","dhcp")
    uci:set("network","wan","peerdns",1)
    uci:set("openwrtapi","wan","dns_mode","auto")

    uci:delete("network","wan","username")
    uci:delete("network","wan","password")
    uci:delete("network","wan","ipaddr")
    uci:delete("network","wan","netmask")
    uci:delete("network","wan","ip6addr")
    uci:delete("network","wan","ip6prefix")
    uci:delete("network","wan","ip6gw")
    uci:delete("network","wan","gateway")
    uci:delete("network","wan","dns")
    uci:delete("network","wan","mtu")
    uci:delete("network","wan","mru")
    uci:delete("network","wan","pppd_options")

    uci:save("openwrtapi")
    uci.commit("openwrtapi")
    uci:save("network")
    uci.commit("network")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function set_wan_config_dhcp_advanced(reload,dns_mode,dns)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    uci:set("network","wan","proto","dhcp")
    uci:delete("network","wan","username")
    uci:delete("network","wan","password")
    uci:delete("network","wan","ipaddr")
    uci:delete("network","wan","netmask")
    uci:delete("network","wan","gateway")
    uci:delete("network","wan","mtu")
    uci:delete("network","wan","mru")
    uci:delete("network","wan","ip6addr")
    uci:delete("network","wan","ip6prefix")
    uci:delete("network","wan","ip6gw")
    uci:delete("network","wan","pppd_options")

    if dns_mode == "auto" then
        uci:set("network","wan","peerdns",1)
        uci:delete("network","wan","dns")
        uci:set("openwrtapi","wan","dns_mode",dns_mode)
    elseif dns_mode == "hand" then
        uci:set("network","wan","peerdns",0)
        uci:set("network","wan","dns",dns)
        uci:set("openwrtapi","wan","dns_mode",dns_mode)
    end

    uci:save("openwrtapi")
    uci:save("network")
    uci.commit("openwrtapi")
    uci.commit("network")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function set_wan_config_static(reload,ipaddr,netmask,gateway,dns)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    uci:delete("network","wan","username")
    uci:delete("network","wan","password")
    uci:delete("network","wan","mtu")
    uci:delete("network","wan","mru")
    uci:delete("network","wan","pppd_options")
    uci:delete("network","wan","ip6addr")
    uci:delete("network","wan","ip6prefix")
    uci:delete("network","wan","ip6gw")

    uci:set("network","wan","proto","static")
    if ipaddr then 
        uci:set("network","wan","ipaddr",ipaddr)
    end
    if netmask then
        uci:set("network","wan","netmask",netmask)
    end
    if gateway then 
        uci:set("network","wan","gateway",gateway)
    end
    if dns then
        uci:set("network","wan","dns",dns)
    end

    uci:save("network")
    uci.commit("network")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function set_wan_config_enable(enable)
    local iface = "wan"
    local uci = require "luci.model.uci".cursor()
    local netmd = require "luci.model.network".init()
    local net = netmd:get_network(iface)

    if enable == "true" then
        if net then
            uci:set("network",iface,"proto",uci:get("openwrtapi",iface,"proto"))
            uci:set("openwrtapi",iface,"proto","")
            uci:set("openwrtapi",iface,"enable","0")
            luci.sys.call("env -i /sbin/ifup %q >/dev/null 2>/dev/null" % iface)
        end
    else
        if net then
            uci:set("openwrtapi",iface,"proto",uci:get("network",iface,"proto"))
            uci:set("network",iface,"proto","none")
            uci:set("openwrtapi",iface,"enable","1")
            luci.sys.call("env -i /sbin/ifdown %q >/dev/null 2>/dev/null" % iface)
        end
    end

    uci:save("openwrtapi")
    uci:save("network")
    uci.commit("openwrtapi")
    uci.commit("network")
end

function get_wan_config_enable()
    local result = {}
    local uci = require "luci.model.uci".cursor()
    result.enable = (tostring(uci:get("openwrtapi","wan","enable")) == "0")

    return result
end

function get_wan_config_ipv6()
    local result = {}
    local uci = require "luci.model.uci".cursor()
    local iface = "wan"

    local ip6 = uci:get("openwrtapi",iface,"ip6")
    if ip6 then
        if ip6 == "dhcp" or ip6 == "static" then
            result.proto = ip6

            if ip6 == "static" then
                result.ip6addr = uci:get("network",iface,"ip6addr")
                result.ip6prefix = uci:get("network",iface,"ip6prefix")
                result.gateway = uci:get("network",iface,"ip6gw")
                result.dns = uci:get("network",iface,"dns")
            end

            return result
        end
    end

    result.proto = "none"
    return result
end

function set_wan_config_ipv6(proto, ip6addr, ip6prefix, gateway, dns)
    local uci = require "luci.model.uci".cursor()
    local iface = "wan"

    if proto == "none" then
        utils.fork_exec("/etc/init.d/network restart;sleep 1;/etc/init.d/6relayd stop;sleep 1;/etc/init.d/6relayd disable")
        uci:delete("openwrtapi",iface,"ip6")
    elseif proto == "dhcp" then
        uci:delete("network",iface,"username")
        uci:delete("network",iface,"password")
        uci:delete("network",iface,"ipaddr")
        uci:delete("network",iface,"ip6addr")
        uci:delete("network",iface,"ip6prefix")
        uci:delete("network",iface,"ip6gw")
        uci:delete("network",iface,"netmask")
        uci:delete("network",iface,"gateway")
        uci:delete("network",iface,"mtu")
        uci:delete("network",iface,"mru")
        uci:delete("network",iface,"pppd_options")
        uci:set("network",iface,"proto",proto)

        utils.fork_exec("/etc/init.d/network restart;sleep 1;/etc/init.d/6relayd enable;sleep 1;/etc/init.d/6relayd restart")
        uci:set("openwrtapi",iface,"ip6",proto)
    elseif proto == "static" then
        local sid

        uci:delete("network",iface,"username")
        uci:delete("network",iface,"password")
        uci:delete("network",iface,"pppd_options")
        uci:delete("network",iface,"mtu")
        uci:delete("network",iface,"mru")
        uci:set("network",iface,"proto","static")

        if ip6addr then
            uci:set("network",iface,"ip6addr",ip6addr)
        end
        if ip6prefix then
            uci:set("network",iface,"ip6prefix",ip6prefix)
        end
        if gateway then
            uci:set("network",iface,"ip6gw",gateway)
        end
        if dns then
            uci:set("network",iface,"dns",dns)
        end

        uci_r:foreach("network", "route6",
            function(s)
                if s.interface == iface then
                    sid = s['.name']
                    return false
                end
            end)

        if sid == nil then
            sid = uci_r:section("network", "route6", nil, {})
        end

        if gateway and sid then
            uci:set("network",sid,"interface",iface)
            uci:set("network",sid,"target","::0/0")
            uci:set("network",sid,"gateway",gateway)
        end

        utils.fork_exec("/etc/init.d/network restart;sleep 1;/etc/init.d/6relayd enable;sleep 1;/etc/init.d/6relayd restart")
        uci:set("openwrtapi",iface,"ip6", proto)
    end

    uci:save("openwrtapi")
    uci.commit("openwrtapi")
    uci:save("network")
    uci.commit("network")
end

function get_lan_status()
    local netm = require "luci.model.network".init()
    local rv = { }
    local lan

    local ifaces = "lan"
    local iface
    for iface in ifaces:gmatch("[%w%.%-_]+") do
        local net = netm:get_network(iface)
        local device = net and net:get_interface()
        if device then
            local data = {
                id = iface,
                proto = net:proto(),
                uptime = net:uptime(),
                gwaddr = net:gwaddr(),
                dnsaddrs = net:dnsaddrs(),
                name = device:shortname(),
                type = device:type(),
                ifname = device:name(),
                macaddr = device:mac(),
                is_up = device:is_up(),
                rx_bytes = device:rx_bytes(),
                tx_bytes = device:tx_bytes(),
                rx_packets = device:rx_packets(),
                tx_packets = device:tx_packets(),

                ipaddrs = { },
                ip6addrs = { },
                subdevices = { }
            }

            local _, a
            for _, a in ipairs(device:ipaddrs()) do
                data.ipaddrs[#data.ipaddrs+1] = {
                    addr = a:host():string(),
                    netmask = a:mask():string(),
                    prefix = a:prefix()
                }
            end
            for _, a in ipairs(device:ip6addrs()) do
                if not a:is6linklocal() then
                    data.ip6addrs[#data.ip6addrs+1] = {
                        addr = a:host():string(),
                        netmask = a:mask():string(),
                        prefix = a:prefix()
                    }
                end
            end

            --[[
            for _, device in ipairs(net:get_interfaces() or {}) do
                data.subdevices[#data.subdevices+1] = {
                    name = device:shortname(),
                    type = device:type(),
                    ifname = device:name(),
                    macaddr = device:mac(),
                    macaddr = device:mac(),
                    is_up = device:is_up(),
                    rx_bytes = device:rx_bytes(),
                    tx_bytes = device:tx_bytes(),
                    rx_packets = device:rx_packets(),
                    tx_packets = device:tx_packets(),
                }
            end
            ]]

            rv[#rv+1] = data
            lan = data
        else
            rv[#rv+1] = {
                id   = iface,
                name = iface,
                type = "ethernet"
            }
            lan = rv[#rv]
        end
    end
    
    return lan
end

function set_lan_config_static(reload,ipaddr,netmask)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    uci:set("network","lan","proto","static")
    if ipaddr then 
        uci:set("network","lan","ipaddr",ipaddr)
    end
    if netmask then
        uci:set("network","lan","netmask",netmask)
    end

    uci:save("network")
    uci.commit("network")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function get_wifi_2g_status()
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    if utils.get_hw_type() == "ralink" then
        local result = get_wireless_iface_by_id("ra0.network1")
        local section = ntm._wifi_lookup("ra0.network1") 
        local key = uci:get("wireless",section,"key")
        result.key = key
        return result
    else
        local result = get_wireless_iface_by_id("wifi0.network1")
        local section = ntm._wifi_lookup("wifi0.network1")
        local key = uci:get("wireless",section,"key")
        local dev = uci:get("wireless",section,"device")
        local channel = uci:get("wireless",dev,"channel")

        result.macfilter = uci:get("wireless",section,"macfilter")
        result.maclist = uci:get("wireless",section,"maclist")
        result.encryption_cipher = uci:get("wireless",section,"encryption")
        result.hwmode = uci:get("wireless",dev,"hwmode")
        result.htmode = uci:get("wireless",dev,"htmode")
        result.hide_ssid = uci:get_bool("wireless",section,"hidden")
        result.key = key
        local txpower = tonumber(result.txpower)

        if channel == "auto" then
            result.channel_mode = channel
        else
            result.channel_mode = "hand"
        end

        if txpower >= 20 then
            result.txpower = 1
        elseif txpower >= 15 then
            result.txpower = 2
        else
            result.txpower = 3
        end

        return result
    end
end

function get_wifi_5g_status()
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    if utils.get_hw_type() == "ralink" then
        return get_wireless_iface_by_id("ra0.network2")
    else 
        local result = get_wireless_iface_by_id("wifi1.network1")
        local section = ntm._wifi_lookup("wifi1.network1")
        local key = uci:get("wireless",section,"key")
        local dev = uci:get("wireless",section,"device")
        local channel = uci:get("wireless",dev,"channel")

        result.macfilter = uci:get("wireless",section,"macfilter")
        result.maclist = uci:get("wireless",section,"maclist")
        result.encryption_cipher = uci:get("wireless",section,"encryption")
        result.hwmode = uci:get("wireless",dev,"hwmode")
        result.htmode = uci:get("wireless",dev,"htmode")
        result.hide_ssid = uci:get_bool("wireless",section,"hidden")
        result.key = key

        local txpower = tonumber(result.txpower)

        if channel == "auto" then
            result.channel_mode = channel
        else
            result.channel_mode = "hand"
        end

        if txpower >= 20 then
            result.txpower = 1
        elseif txpower >= 15 then
            result.txpower = 2
        else
            result.txpower = 3
        end
        return result
    end
end

function set_wifi_2g_config(reload,ssid,password,strength)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    local section
    if utils.get_hw_type() == "ralink" then
        section = ntm._wifi_lookup("ra0.network1") 
    else
        section = ntm._wifi_lookup("wifi0.network1") 
    end

    local dev = uci:get("wireless",section,"device")

    if section then
        if strength == "1" then
            uci:set("wireless",dev,"txpower",20)
        elseif strength == "2" then
            uci:set("wireless",dev,"txpower",15)
        elseif strength == "3" then
            uci:set("wireless",dev,"txpower",10)
        end

        uci:set("wireless",section,"ssid", ssid)
        uci:set("wireless",section,"key", password)
        uci:set("wireless",section,"encryption","psk2")
        uci:save("wireless")
        uci.commit("wireless")
    end

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function set_wifi_2g_config_advanced(reload,ssid,hide_ssid,password,hwmode,htmode,channel,auth_type,encrypt_type)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    local section
    if utils.get_hw_type() == "ralink" then
        section = ntm._wifi_lookup("ra0.network1") 
    else
        section = ntm._wifi_lookup("wifi0.network1")
        uci:set("wireless","wifi0","hwmode",hwmode)
        uci:set("wireless","wifi0","htmode",htmode)
        uci:set("wireless","wifi0","channel",channel)
    end

    if section then
        uci:set("wireless",section,"ssid",ssid)
        if hide_ssid == "true" then
            uci:set("wireless",section,"hidden",1)
        else
            uci:delete("wireless",section,"hidden")
        end
        uci:set("wireless",section,"encryption",auth_type.."+"..encrypt_type)
        uci:set("wireless",section,"key",password)
        uci:save("wireless")
        uci.commit("wireless")
    end

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function set_wifi_5g_config(reload,ssid,password,strength)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    local section
    if utils.get_hw_type() == "ralink" then
        section = ntm._wifi_lookup("ra0.network2") 
    else
        section = ntm._wifi_lookup("wifi1.network1") 
    end

    local dev = uci:get("wireless",section,"device")

    if section then
        if strength == "1" then
            uci:set("wireless",dev,"txpower",20)
        elseif strength == "2" then
            uci:set("wireless",dev,"txpower",15)
        elseif strength == "3" then
            uci:set("wireless",dev,"txpower",10)
        end

        uci:set("wireless",section,"ssid",ssid)
        uci:set("wireless",section,"key",password)
        uci:set("wireless",section,"encryption","psk2")
        uci:save("wireless")
        uci.commit("wireless")
    end

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function set_wifi_5g_config_advanced(reload,ssid,hide_ssid,password,hwmode,htmode,channel,auth_type,encrypt_type)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    local section
    if utils.get_hw_type() == "ralink" then
        section = ntm._wifi_lookup("ra0.network1") 
    else
        section = ntm._wifi_lookup("wifi1.network1") 
        uci:set("wireless","wifi1","hwmode",hwmode)
        uci:set("wireless","wifi1","htmode",htmode)
        uci:set("wireless","wifi1","channel",channel)
    end

    if section then
        uci:set("wireless",section,"ssid",ssid)
        if hide_ssid == "true" then
            uci:set("wireless",section,"hidden",1)
        else
            uci:delete("wireless",section,"hidden")
        end
        uci:set("wireless",section,"encryption",auth_type.."+"..encrypt_type)
        uci:set("wireless",section,"key",password)
        uci:save("wireless")
        uci.commit("wireless")
    end

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function set_wifi_black_list_enable(reload,enable)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)
    local macfilter = nil

    if enable == "true" then
        macfilter = "deny"
    elseif enable == "false" then
        macfilter = "disable"
    end

    if macfilter then
        local section = ntm._wifi_lookup("wifi0.network1")
        uci:set("wireless",section,"macfilter", macfilter)

        section = ntm._wifi_lookup("wifi1.network1")
        uci:set("wireless",section,"macfilter", macfilter)

        uci:save("wireless")
        uci.commit("wireless")
    end

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function get_wifi_black_list_enable()
    local result = {}
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    local section = ntm._wifi_lookup("wifi0.network1")
    local macfilter = uci:get("wireless",section,"macfilter")

    section = ntm._wifi_lookup("wifi1.network1")

    if macfilter ~= uci:get("wireless",section,"macfilter") then
        uci:set("wireless",section,"macfilter", macfilter)
        uci:save("wireless")
        uci.commit("wireless")
    end

    if macfilter then
        if macfilter == "disable" or macfilter == "allow" then
            result.enable = false
        elseif macfilter == "deny" then
            result.enable = true
        end
    else
        result.enable = false
    end

    return result
end

function add_wifi_2g_black_list(reload,mac)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    local section = ntm._wifi_lookup("wifi0.network1")
    local maclist = uci:get("wireless",section,"maclist")

    if maclist then
        uci:set("wireless",section,"maclist", maclist.." "..mac)
    else
        uci:set("wireless",section,"maclist", mac)
    end

    uci:save("wireless")
    uci.commit("wireless")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function add_wifi_5g_black_list(reload,mac)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    local section = ntm._wifi_lookup("wifi1.network1")

    local maclist = uci:get("wireless",section,"maclist")
    if maclist then
        uci:set("wireless",section,"maclist", maclist.." "..mac)
    else
        uci:set("wireless",section,"maclist", mac)
    end

    uci:save("wireless")
    uci.commit("wireless")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function del_wifi_2g_black_list_all(reload)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)
    local section = ntm._wifi_lookup("wifi0.network1")

    uci:delete("wireless",section,"maclist")
    uci:save("wireless")
    uci.commit("wireless")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function del_wifi_5g_black_list_all(reload)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)
    local section = ntm._wifi_lookup("wifi1.network1")

    uci:delete("wireless",section,"maclist")
    uci:save("wireless")
    uci.commit("wireless")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function del_wifi_2g_black_list(reload, mac)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    local section = ntm._wifi_lookup("wifi0.network1")

    local maclist = uci:get("wireless",section,"maclist")
    if maclist then
        if string.find(maclist, mac) then
            maclist = string.gsub(maclist, mac, "")
            maclist = string.gsub(maclist, " +", " ")
            uci:set("wireless", section, "maclist", maclist)
            uci:save("wireless")
            uci.commit("wireless")
        end
    end

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function del_wifi_5g_black_list(reload,mac)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    local section = ntm._wifi_lookup("wifi1.network1")

    local maclist = uci:get("wireless",section,"maclist")
    if maclist then
        if string.find(maclist, mac) then
            maclist = string.gsub(maclist, mac, "")
            maclist = string.gsub(maclist, " +", " ")
            uci:set("wireless", section, "maclist", maclist)
            uci:save("wireless")
            uci.commit("wireless")
        end
    end

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function set_wifi_black_list(reload,array)
    del_wifi_2g_black_list_all(false)
    del_wifi_5g_black_list_all(false)

    if array then
        local list_new = json.decode(array)
        for _, v in ipairs(list_new) do
            if tostring(v.wifi_2g) == "true" then
                add_wifi_2g_black_list("false", v.mac)
            end
            if tostring(v.wifi_5g) == "true" then
                add_wifi_5g_black_list("false", v.mac)
            end
        end
    end

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function get_wifi_black_list()
    local result = {}
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    local section = ntm._wifi_lookup("wifi0.network1")
    local wifi_2g_list = uci:get("wireless",section,"maclist")

    section = ntm._wifi_lookup("wifi1.network1")

    local wifi_5g_list = uci:get("wireless",section,"maclist")

    if wifi_2g_list and #wifi_2g_list ~= 0 then
        local list = utils.lua_string_split(wifi_2g_list, " ")
        for _, v in ipairs(list) do
            if v and #v ~= 0 then
                local tmp = {}
                tmp.mac = v
                tmp.wifi_2g = true
                if wifi_5g_list and string.find(wifi_5g_list, v) then
                    tmp.wifi_5g = true
                    if wifi_5g_list then
                        wifi_5g_list = string.gsub(wifi_5g_list, v, "")
                    end
                else
                    tmp.wifi_5g = false
                end

                result[#result + 1] = tmp
                if wifi_5g_list and #wifi_5g_list ~= 0 then
                    wifi_5g_list = string.gsub(wifi_5g_list, " +", " ")
                end
            end
        end
    end

    if wifi_5g_list and #wifi_5g_list ~= 0 then
        local list = utils.lua_string_split(wifi_5g_list, " ")
        for _, v in ipairs(list) do
            if v and #v ~= 0 then
                local tmp = {
                    mac = v,
                    wifi_2g = false,
                    wifi_5g = true
                }
                result[#result + 1] = tmp
            end
        end
    end

    return result
end

function get_dhcp_status()
    require("luci.tools.status")
    local leases = luci.tools.status.dhcp_leases()
    return leases
end

function get_dhcp_config_status()
    local result = {}
    local uci = require "luci.model.uci".cursor()
    local enable = uci:get("dhcp","lan","ignore")

    result.enable = (enable == nil or (tostring(enable) == "0"))
    result.startaddr = tostring(uci:get("dhcp","lan","start"))
    result.endaddr = tonumber(uci:get("dhcp","lan","limit")) + tonumber(result.startaddr)
    result.expire = uci:get("dhcp","lan","leasetime")

    return result
end

function set_dhcp_config_enable(reload,enable)
    local uci = require "luci.model.uci".cursor()

    if enable == "true" then
        uci:set("dhcp","lan","ignore",0)
    else
        uci:set("dhcp","lan","ignore",1)
    end

    uci:save("dhcp")
    uci.commit("dhcp")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function set_dhcp_config_poll(reload,startaddr,endaddr,expire)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    uci:set("dhcp","lan","start",tonumber(startaddr))
    uci:set("dhcp","lan","limit",tonumber(endaddr)-tonumber(startaddr)+1)
    uci:set("dhcp","lan","leasetime",expire)
    uci:save("dhcp")
    uci.commit("dhcp")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function add_dhcp_config_static(reload,name,ipaddr,macaddr)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    local section = uci:add("dhcp","host")
    uci:set("dhcp",section,"name",name)
    uci:set("dhcp",section,"mac",macaddr)
    uci:set("dhcp",section,"ip",ipaddr)
    uci:save("dhcp")
    uci.commit("dhcp")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function del_dhcp_config_static(reload,name)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    uci:foreach("dhcp", "host",
        function(s)
            if s.name == name then
                section = s['.name']
            end
        end)
    if section then
        uci:delete("dhcp",section)
        uci:save("dhcp")
        uci.commit("dhcp")
    end

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function set_dhcp_config_static_enable(enable)
    local iface = "dhcp"
    local uci = require "luci.model.uci".cursor()

    if enable == "true" then
        uci:set("openwrtapi",iface,"enable","0")
    else
        uci:set("openwrtapi",iface,"enable","1")
    end

    uci:save("openwrtapi")
    uci.commit("openwrtapi")
end

function get_dhcp_config_static_enable()
    local result = {}
    local uci = require "luci.model.uci".cursor()

    result.enable = (tostring(uci:get("openwrtapi","dhcp","enable")) == "0")
    return result
end

function set_dhcp_config_static_list(reload, array)
    local list_old = get_dhcp_config_static_list()

    if list_old then
        for _, v in ipairs(list_old) do
            del_dhcp_config_static("false", v.name)
        end
    end

    if array then
        local list_new = json.decode(array)
        for _, v in ipairs(list_new) do
            add_dhcp_config_static("false", v.name, v.ip, v.mac)
        end
    end

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function get_dhcp_config_static_list()
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    local rv = {}
    local section
    uci:foreach("dhcp", "host",
        function(s)
            local data = {
                name = s.name,
                mac = s.mac,
                ip = s.ip
            }
            rv[#rv+1] = data
        end)
    
    return rv
end

function get_network_associate_list()
    require("luci.sys")
    local uci = require "luci.model.uci".cursor()
    local source = luci.util.exec

    local result = {}
    local arptable = luci.sys.net.arptable()
    local leases = status.dhcp_leases()
    local data = status.wifi_networks()

    local data_2_4_g = data[1]
    local data_5_g = data[2]
    local assoclist_2_4_g = data_2_4_g and data_2_4_g.networks[1].assoclist
    local assoclist_5_g = data_5_g and data_5_g.networks[1].assoclist

    local a
    for _, a in ipairs(arptable) do
        local mac = a["HW address"]
        local MAC = string.upper(mac)
        local _mac, _ = string.gsub(mac, ":", "")
        local index = #result+1
        local is_relate = false
        local tmp = {}
        local k, v, l

        if assoclist_2_4_g and assoclist_2_4_g[string.upper(mac)] then
            tmp.linktype = "2.4g"
            tmp.macaddr = MAC
            tmp.devicetype = utils.get_equipment_type(_mac)
            tmp.ipaddr = a["IP address"]
            is_relate = true
        elseif assoclist_5_g and assoclist_5_g[string.upper(mac)] then
            tmp.linktype = "5g"
            tmp.macaddr = MAC
            tmp.devicetype = utils.get_equipment_type(_mac)
            tmp.ipaddr = a["IP address"]
            is_relate = true
        end

        for _, l in ipairs(leases) do
            if l.macaddr == mac then
                if is_relate then
                    tmp.devicename = l.hostname
                else
                    tmp.linktype = "lan"
                    tmp.macaddr = MAC
                    tmp.devicetype = utils.get_equipment_type(_mac)
                    tmp.devicename = l.hostname
                    tmp.ipaddr = l.ipaddr
                    is_relate = true
                end
            end
        end

        if not is_relate then
            local dev , _= string.find(a["Device"],"eth*")
            if dev ~= 1 then
                tmp.linktype = "lan"
                tmp.macaddr = MAC
                tmp.devicetype = utils.get_equipment_type(_mac)
                tmp.devicename = utils.get_equipment_type(_mac)
                tmp.ipaddr = a["IP address"]
                is_relate = true
            end
        end

        if is_relate then
            local alias = utils.get_equipment_alias(mac)
            if alias then tmp.devicename = alias end

            local rx = tonumber(source("cat /tmp/in_"..tmp.ipaddr..".tmp"))
            local tx = tonumber(source("cat /tmp/out_"..tmp.ipaddr..".tmp"))

            if rx and tx then
                tmp.txpackets = tx
                tmp.rxpackets = rx
            else
                tmp.txpackets = 0
                tmp.rxpackets = 0
            end
            
            tmp.devicename = tmp.devicename or ""
            result[#result+1] = tmp
        end
    end
    return result
end

function get_firewall_config_enable()
    local result = {}
    local uci = require "luci.model.uci".cursor()

    local enable = uci:get("openwrtapi","firewall","enable")
    local packagetype = uci:get("openwrtapi", "firewall", "packagetype")
    local pingswitch = uci:get("openwrtapi", "firewall", "pingswitch")

    if enable == "0" then
        result.enable = "true"
    else
        result.enable = "false"
    end

    if packagetype then
        result.packagetype = packagetype
    else
        result.packagetype = ""
    end

    if pingswitch == "0" then
        result.pingswitch = "true"
    else
        result.pingswitch = "false"
    end

    return result
end

function get_synflood_config_enable()
    local result = {}
    local uci = require "luci.model.uci".cursor()

    local enable = uci:get("openwrtapi","synflood","enable")
    if enable == "0" then
        result.enable = "true"
    else
        result.enable = "false"
    end

    return result
end

function set_device_alias(mac, name)
    utils.set_equipment_alias(mac, name)
end

function set_firewall_config_enable(reload,enable,packagetype,pingswitch)
    local result = {}
    local uci = require "luci.model.uci".cursor()

    if enable == "true" then
        uci:set("openwrtapi","firewall","enable","0")
    elseif enable == "false" then
        uci:set("openwrtapi","firewall","enable","1")
    end

    if packagetype == "dropped" or packagetype == "accepted" or packagetype == "both"then
        uci:set("openwrtapi", "firewall", "packagetype", packagetype)
    else
        uci:delete("openwrtapi", "firewall", "packagetype")
    end

    if pingswitch == "true" then
        uci:set("openwrtapi","firewall","pingswitch","0")
    elseif pingswitch == "false" then
        uci:set("openwrtapi","firewall","pingswitch","1")
    end

    uci:save("openwrtapi")
    uci.commit("openwrtapi")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function set_synflood_config_enable(reload, enable)
    local result = {}
    local uci = require "luci.model.uci".cursor()

    if enable == "true" then
        uci:set("openwrtapi","synflood","enable","0")
    elseif enable == "false" then
        uci:set("openwrtapi","synflood","enable","1")
    end

    uci:save("openwrtapi")
    uci.commit("openwrtapi")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function set_nat_config_enable(reload,enable)
    local uci = require "luci.model.uci".cursor()
    local firewall = require "luci.model.firewall".init(uci)
    local wan_zone = firewall:get_zone("wan")

    if enable == "true" then
        wan_zone:set("masq","1")
    else
        wan_zone:set("masq","0")
    end

    firewall:save("firewall")
    firewall:commit("firewall")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function get_nat_config_enable()
    local result = {}
    local uci = require "luci.model.uci".cursor()
    local firewall = require "luci.model.firewall".init(uci)
    local wan_zone = firewall:get_zone("wan")
    result.enable = wan_zone:masq()

    return result
end

function set_router_config_init(enable)
    local uci = require "luci.model.uci".cursor()

    if enable == "true" then
        uci:set("openwrtapi","setting","init","0")
    elseif enable == "false" then
        uci:set("openwrtapi","setting","init","1")
    end

    uci:save("openwrtapi")
    uci.commit("openwrtapi")
end

function add_route_config_static(reload,target,netmask,gateway)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    local section = uci:add("network","route")
    --uci:set("network",section,"interface","lan")
    uci:set("network",section,"target",target)
    uci:set("network",section,"netmask",netmask)
    uci:set("network",section,"gateway",gateway)

    uci:save("network")
    uci.commit("network")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function del_route_config_static(reload,target,netmask)
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    local section
    uci:foreach("network", "route",
        function(s)
            if s.target == target and s.netmask == netmask then
                section = s['.name']
            end
        end)
    if section then
        uci:delete("network",section)
        uci:save("network")
        uci.commit("network")
    end

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function set_route_config_static_enable(enable)
    local iface = "static_routes"
    local uci = require "luci.model.uci".cursor()

    if enable == "true" then
        uci:set("openwrtapi",iface,"enable","0")
    else
        uci:set("openwrtapi",iface,"enable","1")
    end

    uci:save("openwrtapi")
    uci.commit("openwrtapi")
end

function get_route_config_static_enable()
    local result = {}
    local uci = require "luci.model.uci".cursor()

    result.enable = (tostring(uci:get("openwrtapi","static_routes","enable")) == "0")
    return result
end

function set_route_config_static_list(reload, array)
    local list_old = get_route_config_static_list()

    if list_old then
        for _, v in ipairs(list_old) do
            del_route_config_static("false", v.target, v.netmask)
        end
    end

    if array then
        local list_new = json.decode(array)
        for _, v in ipairs(list_new) do
            add_route_config_static("false", v.target, v.netmask, v.gateway)
        end
    end

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function get_route_config_static_list()
    local uci = require "luci.model.uci".cursor()
    local ntm = require "luci.model.network".init(uci)

    local rv = {}
    local section
    uci:foreach("network", "route",
        function(s)
            local data = {
                target = s.target,
                netmask = s.netmask,
                gateway = s.gateway
            }   
            rv[#rv+1] = data
        end)
    
    return rv
end

function set_upnp_config_enable(reload, enable)
    local uci = require "luci.model.uci".cursor()

    if enable == "true" then
        uci:set("upnpd","config","enable_upnp","1")
    else
        uci:set("upnpd","config","enable_upnp","0")
    end

    uci:save("upnpd")
    uci.commit("upnpd")

    if reload == "true" then
        service_reload("true","true","true","true")
    end
end

function get_upnp_config_enable()
    local result = {}
    local uci = require "luci.model.uci".cursor()
    local enable = uci:get("upnpd","config","enable_upnp")

    result.enable = (tostring(enable) == "1")
    return result
end

function get_wireless_dev_by_id(id)
    local ntm = require "luci.model.network".init()
    local rv = {}

    local dev
    for _, dev in ipairs(ntm:get_wifidevs()) do
        if id == dev:name() then
            rv.id = dev:name()
            rv.up = dev:is_up()
            rv.name = dev:get_i18n()
        end
    end

    return rv
end

function get_wireless_ifaces(dev_id)
    local ntm = require "luci.model.network".init()
    local rv = {}

    local dev
    for _, dev in ipairs(ntm:get_wifidevs()) do
        if dev_id == dev:name() then
            local net
            for _, net in ipairs(dev:get_wifinets()) do
                local rd = {
                    id = net:id(),
                    name = net:shortname(),
                    up = net:is_up()
                }
                rv[#rv+1] = rd
            end
        end
    end

    return rv
end

function get_wireless_iface_by_id(id)
    local ntm = require "luci.model.network".init()
    local radio, ifnidx = id:match("^(%w+)%.network(%d+)$")
    local network = {}

    if radio and ifnidx then
        local dev
        for _, dev in ipairs(ntm:get_wifidevs()) do
            if radio == dev:name() then
                local net
                for _, net in ipairs(dev:get_wifinets()) do
                    if id == net:id() then
                        network.id = net:id()
                        network.name = net:shortname()
                        network.up = net:is_up()
                        network.mode = net:active_mode()
                        network.ssid = net:active_ssid()
                        network.bssid = net:active_bssid()
                        network.encryption = net:active_encryption()
                        network.frequency = net:frequency()
                        network.channel = net:channel()
                        network.signal = net:signal()
                        network.quality = net:signal_percent()
                        network.noise = net:noise()
                        network.bitrate = net:bitrate()
                        network.ifname = net:ifname()
                        network.assoclist = net:assoclist()
                        network.country = net:country()
                        network.txpower = net:txpower()
                        network.txpoweroff = net:txpower_offset()
                        break
                    end
                end
                break
            end
        end
    end

    return network
end
