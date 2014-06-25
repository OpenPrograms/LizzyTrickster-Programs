--@name DNS Server
--@author JoshTheEnder
--@Desc like real world DNS servers

local component = require("component")
local event = require("event")
local serial= require("serialization")

local NameTable = { }
if component.isAvailable( "modem" ) then
    m = component.modem
else
    error( "Y U NO GIVE ME MODEM!" )
end
if m.isWireless() then
    print("It appears the primary network card of this computer is wireless")
    print("Beware of duplicate messages / network loops when using this program")
end
m.open( 53 )
m.broadcast( 53, "DNS WHOMASTER" )
local eventN, _, from, port, _, message = event.pull(5, "modem_message")
if eventN ~= nil then
    if (port==53) and (message=="IAMMASTER") then
        WhoAmI = "SLAVE"
        MY_MASTER = from
    end
else
    WhoAmI = "MASTER"
end

print("I have assumed the role of "..WhoAmI)

function WittyFunctionNameHere( LAddr, RAddr, P, Data )
    if WhoAmI == "MASTER" then
        if Data == "DNS WHOMASTER" then
            print("Received WHOMASTER query from "..RAddr..". Telling them that I am the master...")
            m.send(RAddr, P, "IAMMASTER")
        elseif Data == "DNS GETTABLE" then
            print(RAddr.." requested NameTable. Sending NameTable...")
            m.send(RAddr, P, serial.serialize(NameTable) )
        end
    end
end


while true do
    _, LAddr, RAddr, P, _, Data = event.pull( "modem_message" )
    WittyFunctionNameHere( LAddr, RAddr, P, Data)
end


print( WhoAmI )

print("End Of File")