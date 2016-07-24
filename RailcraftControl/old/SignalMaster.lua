-- Here we go!
-- not yet complete
local event = require("event")
local component = require("component")
local SignalNetwork = component.proxy( component.get("") )
SignalNetwork.open(2223)
SignalNetwork.broadcast( 2222, "X1", )
local ManagementNetwork = component.proxy( component.get("") )
local ID = 0
local InPort, OutPort = 2223, 2222

local SignalMap = { A = { }, B = { }, C = { }, D = { } }


function AspectListener( EventName, Address, SignalName, Aspect)
    print( "SignalName: ", SignalName, "Aspect", Aspect )
    local Dir, Gate, TA = SignalName:sub(1,1), SignalName:sub(2,2), SignalName:sub(3,3)
    print( Dir, Gate, TA )
    SignalMap[ Dir ][ tonumber( Gate ) ]["As"][ TA ] = Aspect
    if Aspect == 1 then jkl = 4 else jkl = 1 end
    print( "JKL", jkl )
    SignalNetwork.send( SignalMap[ Dir ][ tonumber( Gate ) ].Ad, 2222, Dir..Gate, 1, TA..tostring(jkl) )
    -- This is gonna need a fair bit of logic :s
    -- TODO LOGIC!
end

function ReplySend( LA, RA, ID, CM, Data )
    local N = component.proxy( LA )
    N.send( RA, OutPort, ID, CM, Data )
end

function NetworkMessage( EventName, LocalAddr, RemoteAddr, Port, Distance, ...)
    if LocalAddr == SignalNetwork.address then
        local Data = table.pack( ... )
        -- This section will be for the MCUs sending messages like for instance on startup or 
        -- firmware upgrade
        Src, Cmd = Data[1], Data[2]
        local D, I = Src:sub(1,1), tonumber(Src:sub(2,2)) --TODO Find a more efficient way of doing this
        if Cmd == 0 then
--            if SingalMap[D][I] == nil then -- FIXME
                SignalMap[D][I] = {Ad = RemoteAddr, As = {1,1}}
                ReplySend( LocalAddr, RemoteAddr, Src, 1, "11")
                ReplySend( LocalAddr, RemoteAddr, Src, 1, "21")
                -- TODO: convert the above to a proper function
--            end
        elseif Cmd == 3 then
            ReplySend( LocalAddr, RemoteAddr, Src, 2, LocalAddr )

        end
    elseif LocalAddr == ManagementNetwork.address then
        print("boo")
        -- communication with the other management devices
    end
end
event.listen( "modem_message", NetworkMessage )
event.listen( "aspect_changed", AspectListener )
