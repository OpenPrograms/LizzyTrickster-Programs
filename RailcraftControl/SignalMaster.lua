-- Here we go!

local event = require("event")
local component = require("component")
local SignalNetwork = component.proxy( component.get("") )
local ManagementNetwork = component.proxy( component.get("") )

local SignalMap = {
    ["0"] = {},
    ["1"] = {},
    ["2"] = {},
    ["3"] = {}
    -- Should I make these use A, B, C & D instead? will be less likely that it gets confused with the string numbers and i
    -- can also do stuff like `SignalMap.A.something`

}

function AspectListener( EventName, Address, SignalName, Aspect) -- Not 100% on this currently, need to test in game first
    print( "poop" )
    -- This is gonna need a fair bit of logic :s

function NetworkMessage( EventName, LocalAddr, RemoteAddr, Port, Distance, ...)
    if LocalAddr == SignalNetwork.address then
        print( "stuff")
        local Data = table.pack( ... )
        -- This section will be for the MCUs sending messages like for instance on startup or firmware upgrade
    elseif LocalAddr == ManagementNetwork.address then
        print("boo")
        -- communication with the other management devices
