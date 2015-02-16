
module("luci.api.v1.sys", package.seeall)

local utils = require "luci.api.tools.utils"
local json = require "luci.api.tools.json"

function get_memory_info()
    local _, _, memtotal, memcached, membuffers, memfree, _, swaptotal, swapcached, swapfree = luci.sys.sysinfo()
    local result = {
        memtotal = memtotal,
        memcached = memcached,
        membuffers = membuffers,
        memfree = memfree,
        swaptotal = swaptotal,
        swapcached = swapcached,
        swapfree = swapfree
    }
    return result
end

function reboot()
    luci.sys.reboot()
end

function reset()
    local source = luci.util.exec
    source("firstboot")
    reboot()
end

function is_upgrade()

    local result = {}
    local newver = {}
    local currver = {}
    local data = utils.get_system_version_info()

    local uci = require "luci.model.uci".cursor()
    local new_version = uci:get("openwrtapi","firmware","newver")
    local new_description = uci:get("openwrtapi","firmware","description")
    local path = uci:get("openwrtapi","firmware","path")

    currver.version = data.fw_version
    currver.description = data.release_notes

    if new_version and path then
        newver.version = new_version
        local des = json.decode(new_description)
        newver.path = path
        if utils.get_hw_type() == "atheros" then
            local mime = require  "mime"
            newver.description , _ = mime.b64(des.r[1].descCN)
        end
    end

    result.currver = currver
    result.newver = newver
    return result
end

function upgrade(path)
    local result = {}
    local bin = io.open(path,"r")
    local uci = require "luci.model.uci".cursor()

    uci:set("openwrtapi","firmware","newver","")
    uci:set("openwrtapi","firmware","description","")
    uci:set("openwrtapi","firmware","path","")
    uci:save("openwrtapi")
    uci.commit("openwrtapi")

    if bin then
        bin:close()
        utils.fork_exec("/etc/init.d/uhttpd stop;sleep 1;/sbin/sysupgrade "..path)
        result.result = "success"
    else
        result.result = "failure"
    end

    return result
end







