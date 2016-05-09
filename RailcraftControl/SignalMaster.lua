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
    -- This section will be for the MCUs sending messages like for instance on startup or 
    -- firmware upgrade
    Src, Cmd = Data[1], Data[2]
    if Cmd == 
  elseif LocalAddr == ManagementNetwork.address then
    print("boo")
    -- communication with the other management devices

--[[
  Cmd/MessageID index, sorta
  0: Client2Server-B - Generic 'hello' meessage, used to notify the server it exists
  1: Server2Client-U - Aspect update message, used in general and also to get an mcu up to speed after it's added
  2: Server2Client-U - "I am master", used to tell MCUs of which address to listen to for aspect updates
  3: Client2Server-B - "Where master?", used for MCUs that have lost the master server, server should respond with 2
  4: Server2Clients-B - Update available notification, MCUs should wait a short period before sending a 5
  5: Client2Server-U - Can haz update?
  6: Server2Client-U - here be the update!, EEPROMs are 4096 bytes in size, default max net messages are 8192 bytes
  7: Any2Any-U - PING! sent from either mcu to server or visaversa, never from mcu to mcy
  8: Same2AsAbove-U PONG! the response to 7

]]