--[[  IN IT'S CURRENT STATE, IT IS NON-FUNCTIONAL. PLEASE DONT ATTEMPT TO USE IT
    Net messages:
        _SERVER => ???:
            B: "DNS WHOMASTER" - broadcasted on port 53, if no response is made within 5s then it assumes master role, else it caches the UUID of
                the server that responded then does "GETTABLE"

        MASTER => SLAVE:
            B: "DNS UPDATE <os.time()>" - broadcasted out to the SLAVES, if the slave table's timstamp is different then it requests a new one

            "DNS TABLE <serialized table>" - gets sent to the client after it requests it

            "DNS IAMMASTER" - tells a slave that it is the master server

        SLAVE => MASTER:
            "DNS GETTABLE" - asks the server for the current name table

            "DNS ASSIGN <UUID> <NAME>" - registers a new computer with the master server, gets sent after a client registers, parameters are from
                sending computer

            "DNS UNASSIGN <UUID>" - deregisters a computer from the master server, <UUID> is from computer deregistering

        CLIENT => SLAVE:
            B: "DNS WHOSERVER" - sent by clients to get the closest SLAVES, caches the first 2 results for using as a lookup source

            "DNS LOOKUP <UUID>" - asks the server for the friendly name of <UUID>, return value is the name or _UNKNOWN_ if it doesn't exist

            "DNS WHOIS <NAME>" - asks the server for the UUID for <FRIENDLYNAME>, return value is the UUID or _UNKNOWN_ if it doesn't exist

            "DNS REG <NAME>" - asks the server to register <NAME> to it's UUID, sends back to the client a boolean number on success/fail

            "DNS DEREG" - asks the server to deregister it's UUID from the database

        SLAVE => CLIENT:
            "DNS IAMSERVER" - sent to the client that requests WHOSERVER

            "DNS R_LOOKUP <NAME>" - sent to the client when it requests LOOKUP

            "DNS R_WHOIS <UUID>" - sent the the client that requests WHOIS

            "DNS R_REG <INT>" - sent to the client that requests REG

            "DNS R_DEREG <INT>" - same as R_REG but for R_DEREG


    On startup in server mode, server will first broadcast out "DNS WHOMASTER" on port 53 with a timeout of 5s. If a "DNS IAMMASTER" is not received
    in that time, the server assumes that it is the first server and thus, the master. If a "DNS IAMMASTER" is received in time then it becomes a slave
    server and goes about being a SLAVE server

    The MASTER server will contain the master copy of the table, the SLAVES will cache this and update it when they become out of date. The server will
    send out UPDATE commands every 10 mins which will tell the SLAVES to get a fresh copy of the table. UPDATE will also be sent when a new address gets
    added

    Clients will (on startup) broadcast a message "DNS WHOSERVER" on port 53, the SLAVES will send back "DNS IAMSERVER" to the client who is listening on
    port 54. The client will cache the first two IDs that respond with IAMSERVER.
]]
-- SERVER CODE
local component = require( "component" )
local event = require( "event" )
local WhoAmI = "_UNKNOWN_"
local m
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
        WhoAmI = "CLONE"
        MY_MASTER = from
    end
else
    WhoAmI == "MASTER"
end

if WhoAmI == "MASTER" then
    doMasterStuff()
elseif WhoAmI == "SLAVE" then
    m.send( MY_MASTER, 53, "DNS GETTABLE")
    local _, _, from, _, _, data = event.pull("modem_message")
    if (from == MY_MASTER) and (data:sub(1,9) == "DNS TABLE") then
        NameTable = serialization.unserialize( data:sub(-0, 10))
    end
end

function WittyFunctionNameHere( LAddr, RAddr, P, Dist, Data )
    if WhoAmI == "MASTER" then
        if
end


event.listen( "modem_message", WittyFunctionNameHere )


