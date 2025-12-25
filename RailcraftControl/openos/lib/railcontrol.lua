local computer = require "computer"
local serial = require "serialization"
local fs = require "filesystem"
local rc = {}

rc.data = {}
rc.data.trackboxes = {}

local cache = {}


function rc.getTrackVer()
    if cache.trackver and computer.uptime() < cache.trackver.last+30 then 
        return cache.trackver.ver
    else
        cache.trackver = {["ver"]=fs.lastModified("/srv/boot.lua"), ["last"]=computer.uptime()}
        return cache.trackver.ver
    end
end

function rc.registerTrackbox(address, version)
    rc.data.trackboxes[address] = {computer.uptime(), version or "UNKNOWN"}
    return true
end

function rc.getAllTrackboxData()
    local rt = {}
    for trackbox, data in pairs(rc.data.trackboxes) do
        rt[trackbox] = {math.floor(computer.uptime() - data[1]), data[2]}
    end
    return rt
end

function rc.getAllData()
    return rc.data
end

return rc 
