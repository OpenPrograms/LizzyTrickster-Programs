-- Run on openos
local component = require("component")
local event = require("event")

local Nic1 = component.proxy( component.get( "beep" ) )

function sendUpdate( Zone, Occ)
    Nic1.broadcast( 2345, Zone, Occ )
end

function aspChanged( Event, Address, Signal, Aspect )
    if Event ~= "aspect_changed" then return end
    if string.match( Signal, "[A-Z][A,T][1-9]" ) ~= nil then
        sendUpdate( string.match( Signal, "[A-Z][A,T][1-9]"), Aspect ~= 1 )
    end
end

event.listen( "aspect_changed", aspChanged )
