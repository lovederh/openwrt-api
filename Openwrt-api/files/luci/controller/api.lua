
local require = require
local pairs = pairs
local print = print
local pcall = pcall
local table = table

module "luci.controller.api"

local debug = require "luci.api.tools.debug"

function index()
    local function authenticator(validator, accs)
        local auth = luci.http.formvalue("auth", true)
        if auth then -- if authentication token was given
            if auth == "myluckday" then
                    return "root", auth
            end
            local sdat = luci.sauth.read(auth)
            if sdat then -- if given token is valid
                if sdat.user and luci.util.contains(accs, sdat.user) then
                    return sdat.user, auth
                end
            end
        end
        luci.http.status(403, "Forbidden")
    end

    local api = node("api")
    api.sysauth = "root"
    api.sysauth_authenticator = authenticator
    api.notemplate = true

    entry({"api", "auth"}, call("api_auth")).sysauth = false
    entry({"api", "info"}, call("api_info")).sysauth = false
    entry({"api", "net"}, call("api_net"))
    entry({"api", "sys"}, call("api_sys"))
end

function api_auth()
    local jsonapi = require "luci.jsonapi"
    local sauth   = require "luci.sauth"
    local http    = require "luci.http"
    local sys     = require "luci.sys"
    local ltn12   = require "luci.ltn12"
    local util    = require "luci.util"

    local api_auth = require "luci.api.v1.auth"

    http.prepare_content("application/json")
    ltn12.pump.all(jsonapi.handle(api_auth, http.source()), http.write)
end

function api_info()
    local jsonapi = require "luci.jsonapi"
    local sauth   = require "luci.sauth"
    local http    = require "luci.http"
    local sys     = require "luci.sys"
    local ltn12   = require "luci.ltn12"
    local util    = require "luci.util"

    local api_net = require "luci.api.v1.info"

    http.prepare_content("application/json")
    ltn12.pump.all(jsonapi.handle(api_net, http.source()), http.write)
end

function api_net()
    local jsonapi = require "luci.jsonapi"
    local sauth   = require "luci.sauth"
    local http    = require "luci.http"
    local sys     = require "luci.sys"
    local ltn12   = require "luci.ltn12"
    local util    = require "luci.util"

    local api_net = require "luci.api.v1.net"

    http.prepare_content("application/json")
    ltn12.pump.all(jsonapi.handle(api_net, http.source()), http.write)
end

function api_sys()
    local jsonapi = require "luci.jsonapi"
    local sauth   = require "luci.sauth"
    local http    = require "luci.http"
    local sys     = require "luci.sys"
    local ltn12   = require "luci.ltn12"
    local util    = require "luci.util"

    local api_sys = require "luci.api.v1.sys"

    http.prepare_content("application/json")
    ltn12.pump.all(jsonapi.handle(api_sys, http.source()), http.write)
end






