local larcs_common = require("larcs/common")
local event = require("event")
local serial = require("serialization")
local component = require("component")
local computer = require("computer")

local detectors = dofile("/etc/larcs/detectors") -- do we actually need this?

local modem = require("component").modem

local function sendTrainDetails (aug_address, data1, data2)

    local dt =  { [aug_address]=detectors[aug_address] or {Pos={-0, -0}} }
    local detector_details = serial.serialize( dt )
    modem.broadcast(larcs_common.NetworkPort, larcs_common.TrainNetworkID, detector_details, data1, data2)
    -- sends something like this:
    -- "{['long-UUID-here']={-42,-42}}", "theUUID-of-the-train-here", "{Stuff from data table in getTrainDetails or EOT}"
end

local function handleTrainOverhead (event_name, augment_address, stock_uuid, data) 
    if event_name ~= "ir_train_details" then return end
    --local dt = serial.serialize(data)
    if stock_uuid == "NONE" then
        sendTrainDetails(augment_address, nil, "EOT") -- End Of Train
    else
        sendTrainDetails(augment_address, stock_uuid, data)
    end
end




local function getTrainDetails ( event_name, augment_address, augment_type, stock_uuid )
    if augment_type == "DETECTOR" then 
        if stock_uuid == nil then 
            computer.pushSignal("ir_train_details", augment_address, "NONE", {})
        else
            local inf   = component.proxy(augment_address).info()
            local const = component.proxy(augment_address).consist()
            --directiom, cars, weight_kg, speed_km. from consist()
            --ag, speed, name from info()
            -- {stock_uuid, info.direction, speed, tag, {throttle=throttle or -42, brake = brake or -42}}
            local data = {
                            tag=inf.tag,
                            throttle=inf.throttle or false, 
                            brake=inf.brake or false, 
                            cars=const.cars, 
                            name=inf.name,
                            speed=math.floor(inf.speed),
                            direction=inf.direction
                        }
            computer.pushSignal("ir_train_details", augment_address, stock_uuid, serial.serialize(data) )
        end
    end
end



print("getTrainDetails() added as listener for ir_train_overhead, event ID: "..event.listen("ir_train_overhead", getTrainDetails))
print("handleTrainOverhead() added as a listener for ir_train_details, event ID: "..event.listen("ir_train_details", handleTrainOverhead))
