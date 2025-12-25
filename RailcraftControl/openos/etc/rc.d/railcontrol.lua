local railcontrol = require "railcontrol"
local rpc = require "rpc"

function start()
    for k,v in pairs(railcontrol) do
        if type(v) == "function" then
            rpc.register("rc_"..k, v)
        end
    end
end

function stop()
    if not rpc.unregister then return false end
    for k,v in pairs(railcontrol) do
        rpc.unregister("rc_"..k)
    end
end

