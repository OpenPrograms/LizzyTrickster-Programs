rs = component.proxy( component.list("redstone")() );
nc = component.proxy( component.list("modem")() );
si = component.proxy( component.list("sign")() );
local sides = { bottom = 0, top = 1, back = 2, front = 3, right = 4, left = 5 }
local aspects = { "red", "yellow", "d-yellow", "green" }
local direct = { "towards", "away"}
local VERSION = 1 
-- Not really a solid version number, just allows for easier updating and stuff (remote command can check to see if it's up-to-date)
ID = si.getValue() -- Sign should be on the font of the MCU and have a 2 digit number on the first line
if ID == nil then error("No sign, you tit!", 0) end
ID = ID:sub(1,2)
nc.open(2222)
function decodeNetwork( e, l, r, p, d, ... )
  local excess = table.pack( ... )
  return e, l, r, p, d, excess
end
 
 
while true do
  a = table.pack( computer.pullSignal() )
  if a[1] == "modem_message" then
    e,l,r,p,d,m = decodeNetwork( table.unpack( a ) ) -- Parameters: EventName, LocalAddress, RemoteAddress, Port, Distance, Message
    if m[1]:sub(1,2) == ID then -- m[1] will be a number represented in string form like "3212"
      dir,asp = tonumber(m[1]:sub(3,3)), tonumber( m[1]:sub(4,4) )
      if dir == 2 then
        rs.setOutput(sides.right, asp )
      elseif dir == 1 then
        rs.setOutput(sides.left, asp )
      end
      si.setValue( string.format("%s\nLast Message\n%q\n%q", ID, direct[dir], aspects[asp] ) )
    end
  end
end

-- TODO Restructure the network message so that it has the ID in the first parameter and the extra data in subsequent ones
-- so like, ID=32, CMD=RED, DATA=12
Num = 3212
--[[
DIR-FROM-INT: 0-3 = South,west,north,east
ZONE-BARRIER#: 1-whatever (only used for sections inside the facility, probably)
DIR-OF-TRVL: 0=towards, 1=away
ASPECT: 1-4 = most2least restrictive (this is redstone strength, if its 0, the signal will be flashing red+yel)
]]

--[[ New Structure: ID, CMD, DATA; e.g. B2, 0, "" ]]

local RS = component.proxy( component.list("redstone")() )
local NC = component.proxy( component.list("modem")() )
local SI = component.proxy( component.list("sign")() )

local Sides = { bottom = 0, top = 1, back = 2, front = 3, right = 4, left = 5 }
local Aspects = { red = 4, yellow = 3, dyellow = 2, green = 1}
local Direction = { "Towards", "Away" } -- only used for sign stuffs

local Pat = "%x%x%x%x%x%x%x%x%-%x%x%x%x%-4%x%x%x%-[89abAB]%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x"
local OutP = 2223

local EEPROM = component.proxy( component.list("eeprom")() )
local ChkSum = EEPROM.getChecksum()
local EData = EEPROM.getData()
local ID

if #EData >= 2 then
    ID = EData:sub(1,2)
elseif SI.getValue() ~= nil then
    ID = SI.getValue():sub(1,2)
else
    error("No ID Stored and no Sign!", 0)
end

if string.match(ID, '^[A-D][1-9]]') == nil then
    error( "Uhoh, your ID should be like [A-D][1-9]", 0)
end

function decodeNetwork( e, l, r, p, d, ... )
    local I, C, D = table.unpack(arg)
    return l, r, p, d, I, C, D
end

local Mstr = string.match( EData:sub(3), "^"..Pat)
NC.open(2222)

if Mstr == nil then
    NC.broadcast(OutP, ID, 0, "")
    NC.broadcast(OutP, ID, 3, NC.address)
end
while true do
    local a = table.pack( computer.pullSignal() )
    if a[1] == "modem_message" then
        local l,r,p,d,I,C,D = decodeNetwork( table.unpack( a ) )
        if C == 2 then
            Mstr = tostring(r)
            EEPROM.setData( ID..Mstr )
            break
        end
    end
end

function updateSignal( D, S ) -- Direction (passed as a side from above) : Strength (passed as an aspect)
    RS.setOutput(D, S) 
end


