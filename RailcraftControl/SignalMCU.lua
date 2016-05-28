--[[ 
  New Structure: ID, CMD, DATA; e.g. B2, 0, "" 
  See SignalMaster.lua for IDs  
]]

local CPr = component.proxy
local RS = CPr( component.list("redstone")() )
local NC = CPr( component.list("modem")() )
local SI = CPr( component.list("sign")() )
local Sides = { bottom = 0, top = 1, back = 2, front = 3, right = 4, left = 5 }
local Aspects = { red = 4, yellow = 3, dyellow = 2, green = 1}
local Direction = { "Towards", "Away" } -- only used for sign stuffs
local Pat = "%x%x%x%x%x%x%x%x%-%x%x%x%x%-4%x%x%x%-[89abAB]%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x"
local OutP = 2223
local EEPROM = CPr( component.list("eeprom")() )
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
-- TODO Optimize the above and below
if string.match(ID, '^[A-D][1-9]') == nil then
    error( "Uhoh, your ID should be like [A-D][1-9]", 0)
end

function decodeNetwork( e, l, r, p, d, ... )
    local I, C, D = ... 
    return l, r, p, I, C, D
end

local Mstr = string.match( EData:sub(3), "^"..Pat)
NC.open(2222)
NC.broadcast(OutP, ID, 0, "")
if Mstr == nil then
    NC.broadcast(OutP, ID, 3, NC.address)
    while true do
        local a = table.pack( computer.pullSignal() )
        if a[1] == "modem_message" then
            local l,r,p,I,C,D = decodeNetwork( table.unpack( a ) )
            if C == 2 then
                Mstr = tostring(r)
                EEPROM.setData( ID..Mstr )
                break
            end
        end
    end
end
function updateSignal( D, S ) -- Direction (passed as a side from above) : Strength (passed as an aspect)
    if D=="T" then
        RS.setOutput(Sides.left, tonumber(S)) 
    elseif D=="A" then
        RS.setOutput(Sides.right, tonumber(S))
    end
end
local running = true
while running do
    local a = table.pack( computer.pullSignal() )
    if a[1] == "modem_message" then
        l, r, p, I, C, D = decodeNetwork( table.unpack( a ) )
        if C == 1 then
            updateSignal( D:sub(1,1), D:sub(2,2) )
        end
    end
end
