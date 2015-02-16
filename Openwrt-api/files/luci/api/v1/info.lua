--
-- Created by IntelliJ IDEA.
-- User: Christian_Chen
-- Date: 14-12-31
-- Time: 下午5:09
-- Github: freestyletime@foxmail.com
-- To change this template use File | Settings | File Templates.
--
module("luci.api.v1.info", package.seeall)

local sys = require "luci.sys"
local net = require "luci.api.v1.net"
local utils = require "luci.api.tools.utils"

function get_system_info()
    local result = {
        hostname = luci.sys.hostname(),
        firmware = luci.version.distname..luci.version.distversion.."/"..luci.version.luciname..luci.version.luciversion,
        kernel = luci.sys.exec("uname -r"),
        localtime = os.date(),
        uptime = luci.sys.uptime()
    }

    return result
end

function get_system_log()
    local result = {
        loginfo = luci.sys.exec("logread|grep -v kern|tail -n 5")
    }

    return result
end

function get_network_updown_status()
    local wanup = false
    local lanup = false
    local wifinet = false
    local device = "domy_box"

    local code = sys.net.pingtest("www.hiveview.com")
    if code == 0 then
        wanup = true
    end

    local devs = net.get_network_associate_list()
    for _, dev in ipairs(devs) do
        if dev.devicetype == device then
            lanup = true
            break
        end
    end

    if utils.get_hw_type() == "ralink" then
        wifinet = net.get_wireless_dev_by_id("ra0")
    else
        wifinet = net.get_wireless_dev_by_id("wifi0")
    end

    local wifiup = wifinet and wifinet.up

    local result = {
        uptime = sys.uptime(),
        wan = wanup,
        lan = lanup,
        wifi = wifiup
    }

    return result
end

function get_service_reload_status()
    local data = nixio.fs.readfile("/var/run/luci-reload-status")
    local result = {}

    if data then
        result.progress = string.trim(data)
    else
        result.progress = "finish"
    end

    return result
end

function get_firmware_version()
    local result = {}
    local data = utils.get_system_version_info()
    result.version = data.fw_version

    return result
end

function get_router_config_init()
    local result = {}
    local uci = require "luci.model.uci".cursor()

    local enable = uci:get("openwrtapi","setting","init")
    if enable == "0" then
        result.init = true
    else
        result.init = false
    end

    return result
end

function get_mobile()
    local result = {}
    local url = "http://api.pthv.gitv.tv/api/ip/isGroupUser.json"
    local params = {
        version="1.0"
    }

    local data = net.get_wan_status()
    params.userIP = data.ipaddrs[1].addr

    return utils.httppost(url, params)
end
