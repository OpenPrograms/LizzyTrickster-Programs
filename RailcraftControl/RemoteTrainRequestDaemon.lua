--[[

"minecart" DigitalDetectorAddress CartType Name PrimaryC SecondaryC Dest Owner

]]

local component = require("component")
local table = require("table")
local DigitalReceiver = component.digital_receiver_box
local DigitalController = component.digital_controller_box
local Lanes = {
    S1  = { DigitDetect = component.get("3724"), NameOfLoco = "", Occupied = false, StorageCarts = 0 },
    S2  = { DigitDetect = component.get("3589"), NameOfLoco = "", Occupied = false, StorageCarts = 0 },
    S3  = { DigitDetect = component.get("ffd1"), NameOfLoco = "", Occupied = false, StorageCarts = 0 },
    S4  = { DigitDetect = component.get("e274"), NameOfLoco = "", Occupied = false, StorageCarts = 0 },
    S5  = { DigitDetect = component.get("6890"), NameOfLoco = "", Occupied = false, StorageCarts = 0 },
    S6  = { DigitDetect = component.get("aca9"), NameOfLoco = "", Occupied = false, StorageCarts = 0 },
    S7  = { DigitDetect = component.get("5805"), NameOfLoco = "", Occupied = false, StorageCarts = 0 },
    S8  = { DigitDetect = component.get("27d1"), NameOfLoco = "", Occupied = false, StorageCarts = 0 },
    S9  = { DigitDetect = component.get("a135"), NameOfLoco = "", Occupied = false, StorageCarts = 0 },
    S10 = { DigitDetect = component.get("f228"), NameOfLoco = "", Occupied = false, StorageCarts = 0 },
}
local OutDetect = component.proxy( component.get("71bf") )
local RouteTrack = component.routing_track
local ReleasingTrain = ""


function LocateOccupiedLanes()
    local t = {}
    for i,v in pairs(Lanes) do
        if Lanes[i].Occupied then
            table.insert(t, i)
        end
    end
    if #t >0 then
        return true, t
    else
        return false, "No trains!"
    end
end

function LocateTrainWithStorageAmmountOf( Carts )
    local n = "No"
    local Stat, Ln = LocateOccupiedLanes()
    if Stat then
        for i,v in pairs(Ln) do
            if Lanes[v].StorageCarts >= Carts then
                n = v
                break
            end
        end
    end
    return n
end


function SendTrainTo( Lane, Dest )
    if #ReleasingTrain == 0 then
        RouteTrack.setDestination( Dest )
        DigitalController.setAspect("RouteTrack", 1)
        DigitalController.setAspect( Lane, 1 )
        ReleasingTrain = Lanes[ Lane ].NameOfLoco
        return true, Lane.." release sequence initiated"
    else
        return false, "There is currently a train going out"
    end
end

function minecart( EventName, Address, Type, Name, Pc, Sc, Dest, Owner )
    if EventName ~= "minecart" then return end
    for i,v in pairs(Lanes) do
end

-- releasing train should be set to the name of the train ebing released
