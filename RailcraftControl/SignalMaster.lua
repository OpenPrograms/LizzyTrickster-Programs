-- Here we go!

local event = require("event")
local component = require("component")
local SignalNetwork = component.proxy( component.get("") )
local ManagementNetwork = component.proxy( component.get("") )
local ID = 0
local InPort, OutPort = 2223, 2222
local SignalMap = {
  [A] = { 
      [99] = {Ad = "SomeID", As = {1, 1} } 
  },
  [B] = {  },
  [C] = {  },
  [D] = {  }
  -- Should I make these use A, B, C & D instead? will be less likely that it gets confused with the string numbers and i
  -- can also do stuff like `SignalMap.A.something`

}

function AspectListener( EventName, Address, SignalName, Aspect) -- Not 100% on this currently, need to test in game first
  print( "poop" )
  -- This is gonna need a fair bit of logic :s
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
    local D, I = Src:sub(1,1), Src:sub(2,2)
    if Cmd == 0 then
        if SingalMap[D][I] == nil then
            SignalMap[D][I] = {Ad = RemoteAddr, As = {1,1}}
            ReplySend( LocalAddr, RemoteAddr, Src, 1, "11")
            ReplySend( LocalAddr, RemoteAddr, Src, 1, "21")
            -- TODO: convert the above to a proper function
        end
    elseif Cmd == 3 then
        ReplySend( LocalAddr, RemoteAddr, Src, 2, LocalAddr )

    end
  elseif LocalAddr == ManagementNetwork.address then
    print("boo")
    -- communication with the other management devices
  end
end
--[[
  Cmd/MessageID index, sorta
  0: Client2Server-B - Generic 'hello' meessage, used to notify the server it exists
  1: Server2Client-U - Aspect update message, used in general and also to get an mcu up to speed after it's added
  2: Server2Client-U - "I am master", used to tell MCUs of which address to listen to for aspect updates
  3: Client2Server-B - "Where master?", used for MCUs that have lost the master server, server should respond with 2
  4: Server2Clients-B - Update available notification, MCUs should wait a short period before sending a 5
  5: Client2Server-U - Can haz update?
  6: Server2Client-U - here be the update!, EEPROMs are 4096 bytes in size, default max net messages are 8192 bytes
  7: Client2Server-U - Update Complete
  8: Any2Any-U - PING! sent from either mcu to server or visaversa, never from mcu to mcy
  9: Same2AsAbove-U PONG! the response to 7

]]
