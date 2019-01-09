local larcs_common = require("larcs/common")
local event = require("event")

local function sendTrainDetails () return end

local function handleTrainOverhead () return end




local function getTrainDetails ( event_name, augment_address, augment_type, stock_uuid )
    if augment_type == "DETECTOR" then 
        if stock_uuid == nil then 
            computer.pushSignal("ir_train_details", augment_address, "NONE", {})
        else
            local inf   = component.ir_augment_detector.info()
            local const = component.ir_augment_detector.consist()
            --directiom, cars, weight_kg, speed_km. from consist()
            --ag, speed, name from info()
            -- {stock_uuid, info.direction, speed, tag, {throttle=throttle or -42, brake = brake or -42}}
            local data = {
            				tag=inf.tag, 
            				throttle=inf.throttle or false, 
            				brake=inf.brake or false, 
            				cars=const.cars, 
            				name=inf.name,
            				speed=inf.speed,
            				direction=inf.direction
            			}
            computer.pushSignal("ir_train_details", augment_address, stock_uuid, data )
        end
    end
end



print("getTrainDetails() added as listener for ir_train_overhead, event ID: "..event.listen("ir_train_overhead", getTrainDetails))
print("handleTrainOverhead() added as a listener for ir_train_details, event ID: "..event.listen("ir_train_details", handleTrainOverhead))