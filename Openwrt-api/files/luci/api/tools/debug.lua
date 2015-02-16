
module("luci.api.tools.debug", package.seeall)

function output(log)
    local type = type(log)
    if type == "string" or type == "number" then
        local fd = io.open("/tmp/luci.log", "a+")
        fd:write(os.date().." : "..log .. "\n")
        fd:close()
    elseif type == "table" then
        for k, v in pairs(log) do
            output(k)
            output(v)
        end
    end
end



