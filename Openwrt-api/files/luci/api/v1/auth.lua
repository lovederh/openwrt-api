
module("luci.api.v1.auth", package.seeall)

local jsonrpc = require "luci.jsonrpc"
local sauth = require "luci.sauth"
local http = require "luci.http"
local sys = require "luci.sys"
local ltn12 = require "luci.ltn12"
local util = require "luci.util"
local dsp = require "luci.dispatcher"
local debug = require "luci.api.tools.debug"

local function challenge(user, pass)
    local sid, token, secret

    if sys.user.checkpasswd(user, pass) then
        sid = sys.uniqueid(16)
        token = sys.uniqueid(16)
        secret = sys.uniqueid(16)

        http.header("Set-Cookie", "sysauth=" .. sid.."; path=/")
        sauth.reap()
        sauth.write(sid, {
            user=user,
            token=token,
            secret=secret
        })
        local config = require "luci.config"
        local login = util.ubus("session", "login", {
            username = user,
            password = pass,
            timeout  = tonumber(config.sauth.sessiontime)
        })

        if type(login) == "table" and
           type(login.ubus_rpc_session) == "string"
        then
            util.ubus("session", "set", {
                ubus_rpc_session = login.ubus_rpc_session,
                values = {
                    token = sys.uniqueid(16)
                }
            })

            local sid, sdat = luci.controller.rpc.session_retrieve(login.ubus_rpc_session, { user })
            if sdat then
                return {
                    sid = sid,
                    token = sdat.token
                }
            end
        end
    end

    return sid and {sid=sid, token=token, secret=secret}
end

function admin_login(password)
    local challenge = challenge("root",password)

    local result = {
        token = challenge and challenge.sid
    }        

    return result
end

function admin_logout(...)
    if dsp.context.authsession then
        sauth.kill(dsp.context.authsession)
        dsp.context.urltoken.stok = nil
    end

    luci.http.header("Set-Cookie", "sysauth=; path=" .. dsp.build_url())

    local result = {
    }
    return result
end

function admin_change_password(oldpassword,newpassword)
    if sys.user.checkpasswd("root", oldpassword) then
        luci.sys.user.setpasswd("root",newpassword)
    else
        local result = {
            err = "old password is wrong"        
        }
        return result
    end
end
