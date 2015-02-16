--
-- Created by IntelliJ IDEA.
-- User: Christian_Chen
-- Date: 14-12-31
-- Time: 上午9:48
-- Github: freestyletime@foxmail.com
-- To change this template use File | Settings | File Templates.
--
module("luci.api.tools.utils", package.seeall)

--local debug = require "luci.api.tools.debug"

local json = require "luci.api.tools.json"

function get_system_version_info()
    local source = luci.util.exec
    local data = source("cat /version/v.json")

    return json.decode(data)
end

function get_wireless_devs()
    local ntm = require "luci.model.network".init()
    local rv = {}

    local dev
    for _, dev in ipairs(ntm:get_wifidevs()) do
        local rd = {
            id = dev:name(),
            up = dev:is_up(),
            name = dev:get_i18n()
        }
        rv[#rv+1] = rd
    end

    return rv
end

function get_equipment_type(mac)
    local db_path = "/usr/lib/lua/luci/api/tools/mac2type.db"
    local db_file = io.open(db_path,"r")
    mac = string.upper(mac)

    if db_file then
        local equipment_type = ""
        for line in db_file:lines() do
            if(string.match(line, "-type:*")) then
                equipment_type = string.sub(line, 7)
            elseif(string.match(mac, line.."*")) then
                return equipment_type
            end
        end
    end

    return ""
end

function get_equipment_alias(mac)
    local db_path = "/usr/lib/lua/luci/api/tools/device_map.db"
    local db_file = io.open(db_path,"r")
    mac = string.upper(mac)

    if db_file then
        for line in db_file:lines() do
            if mac == string.sub(line, 1, string.find(line, " ")-1) then
                return string.sub(line, string.find(line, " ")+1, #line)
            end
        end
    end
    return nil
end

function set_equipment_alias(mac, name)
    local db_path = "/usr/lib/lua/luci/api/tools/device_map.db"
    local db_file = io.open(db_path,"r")
    local data = {}

    if db_file then
        for line in db_file:lines() do
            local mac2 = string.sub(line, 1, string.find(line, " ")-1)
            local name2 = string.sub(line, string.find(line, " ")+1, #line)
            data[mac2] = name2
        end
        db_file:close();
    end

    data[string.upper(mac)] = name
    db_file = io.open(db_path,"w")

    if db_file then
        for k,v in pairs(data) do
            db_file:write(k.." "..v.."\n");
        end
        db_file:close();
    end
end

function action_restart(args)
    local uci = require "luci.model.uci".cursor()
    if args then
        local service
        local services = { }

        for service in args:gmatch("[%w_-]+") do
            services[#services+1] = service
        end

        local command = uci:apply(services, true)
        if nixio.fork() == 0 then
            local i = nixio.open("/dev/null", "r")
            local o = nixio.open("/dev/null", "w")

            nixio.dup(i, nixio.stdin)
            nixio.dup(o, nixio.stdout)

            i:close()
            o:close()

            nixio.exec("/bin/sh", unpack(command))
        else
            luci.http.write("{\"id\":\"\",\"result\":null,\"error\":null}")
            os.exit(0)
        end
    end
end

function get_hw_type()
    local devs = get_wireless_devs()
    local dev_id
    for _, dev in ipairs(devs) do
        dev_id = dev.id
        break
    end

    local index = dev_id and string.find(dev_id,"wifi")
    if index and index > 0 then
        return "atheros"
    end

    index = dev_id and string.find(dev_id,"ra")
    if index and index > 0 then
        return "ralink"
    end
end

function httppost(url, params)
    local source = luci.util.exec
    local param = ""
    for k, v in pairs(params) do
        param = param .. k .. "=" ..v .. "&"
    end

    param = string.sub(param, 1, #param-1)
    local result = source("curl -s -X POST -d '"..param.."' '"..url:gsub("'", "").."'")
    result , _ = string.gsub(result, "\\u0022", "")

    return json.decode(result)
end

function fork_exec(command)
    local pid = nixio.fork()
    if pid > 0 then
        return
    elseif pid == 0 then
        nixio.chdir("/")

        local null = nixio.open("/dev/null", "w+")
        if null then
            nixio.dup(null, nixio.stderr)
            nixio.dup(null, nixio.stdout)
            nixio.dup(null, nixio.stdin)

            if null:fileno() > 2 then
                null:close()
            end
        end

        nixio.exec("/bin/sh", "-c", command)
    end
end

function lua_string_split(str, split_char)
    local sub_str_tab = {};

    while (true) do
        local pos = string.find(str, split_char);
        if (not pos) then
            local size_t = #sub_str_tab
            table.insert(sub_str_tab,size_t + 1,str);
            break;
        end

        local sub_str = string.sub(str, 1, pos - 1);
        local size_t = #sub_str_tab
        table.insert(sub_str_tab,size_t + 1,sub_str);
        local t = string.len(str);
        str = string.sub(str, pos + 1, t);
    end

    return sub_str_tab;
end
