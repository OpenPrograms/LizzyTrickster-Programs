-- Newer versioon of the MCU script designed to be used on T1 cases to make use of a digtal controller box
-- also changing signals arround, going from dual-heads to single heads
-- this is designed to be used in an EEPROM env, it will most likely cause issues on openos or plan9k

local component = component
local DigiBox = component.proxy( component.list("digital_controller_box")() )
local Nic = component.proxy( component.list("modem")() )
local Status = { A = {[1]=false, [2]=false}, T = {[1]=false, [2]=false} }
local Line, Gate = DigiBox.getSignalNames()[1]:sub(1,1), tonumber(DigiBox.getSignalNames()[1]:sub(3,3) )
Nic.open(2345)
function NetMessage( Event, LAddr, RAddr, Port, Dist, ... )
    -- the extra data should be two paramiters which is the zone and it's occupance
    if Event == "modem_message" then
        local z, o = ...
        UpdateAspect( z,o )
    end
end
function SetAspects()
    for i,v in pairs( DigiBox.getSignalNames() ) do
        local Zone,Dir,GateNum = v:sub(1,1), string.upper(v:sub(2,2)), v:sub(3,3)
        if Status[Dir][1] then
            DigiBox.setAspect(v, 5)
        elseif Status[Dir][2] then
            DigiBox.setAspect(v, 3)
        else
            DigiBox.setAspect(v, 1)
        end
    end
end
function UpdateAspect( Zone, Occ )
    local I,D,N = Zone:sub(1,1), Zone:sub(2,2), tonumber(Zone:sub(3,3))
    if I == Line then
        if string.upper(D) == "A" and (N >= Gate and N < Gate+2) then
            Status[string.upper(D)][N-Gate+1] = Occ
        elseif string.upper(D) == "T" and (N <= Gate and N > Gate-2)then
            Status[string.upper(D)][Gate-N+1] = Occ
        end
        SetAspects()
    end
end

while true do
    NetMessage( computer.pullSignal() )
end
