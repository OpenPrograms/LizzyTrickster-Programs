--[[


]]

local component = require("component")
local table = require("table")
local DigitalReceiver = component.digital_receiver_box
local DigitalController = component.digital_controller_box
local Lanes = {
    S1  = { DigitDetect = component.get("3724"), NameOfLoco = "", Occupied = false },
    S2  = { DigitDetect = component.get("3589"), NameOfLoco = "", Occupied = false },
    S3  = { DigitDetect = component.get("ffd1"), NameOfLoco = "", Occupied = false },
    S4  = { DigitDetect = component.get("e274"), NameOfLoco = "", Occupied = false },
    S5  = { DigitDetect = component.get("6890"), NameOfLoco = "", Occupied = false },
    S6  = { DigitDetect = component.get("aca9"), NameOfLoco = "", Occupied = false },
    S7  = { DigitDetect = component.get("5805"), NameOfLoco = "", Occupied = false },
    S8  = { DigitDetect = component.get("27d1"), NameOfLoco = "", Occupied = false },
    S9  = { DigitDetect = component.get("a135"), NameOfLoco = "", Occupied = false },
    S10 = { DigitDetect = component.get("f228"), NameOfLoco = "", Occupied = false },
}
local OutDetect = component.proxy( component.get("71bf") )
local RouteTrack = component.routing_track

function LocateOccupiedLanes()
    for i,v in pairs(Lanes) do
        Lanes[]
    end
end

function SendTrainTo( Dest )
    RouteTrack.setDestination( Dest )
    DigitalController.setAspect("RouteTrack", 1)
end