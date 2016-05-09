rs = component.proxy( component.list("redstone")() );
nc = component.proxy( component.list("modem")() );
si = component.proxy( component.list("sign")() )
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
      if dir == 1 then
        rs.setOutput(sides.right, asp )
      elseif dir == 0 then
        rs.setOutput(sides.left, asp )
      end
      si.setValue( string.format("%s\nLast Message\n%q\n%q", ID, direct[dir+1], aspects[asp] ) )
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
