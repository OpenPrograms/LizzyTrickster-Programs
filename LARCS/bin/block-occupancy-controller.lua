local larcs_common = require("larcs/common")
local event = require("event")
local serialization = require("serialization")
local internet = require("internet")

-- gets latest shiz
local s = ""
for chunk in internet.request("https://raw.githubusercontent.com/LizzyTrickster/TechycraftCrap/master/creative/MainlineEquipment.lua") do
    s = s .. chunk
end
local dd = load(s)() -- TODO load / write to file

local new_fifo = require("fifo")

-- curl https://raw.githubusercontent.com/LizzyTrickster/TechycraftCrap/master/creative/MainlineEquipment.lua -v -H 'If-None-Match: "29eb4e57f1d9631d5f953b7ec9ebe8ea0aa848ae"'
-- can use ETAG to check if it's newer or not, may need to use base internet component cause the internet library seems crap

function log (level, message)
    --print(level, message)
    return
end

local GLOBAL_STATE = {}

function getBlock (detector_id) -- returns block ID and entry (true) or exit (false)
    for block_id, data in pairs( dd.BLOCKS ) do 
        for _, detector in pairs( dd.BLOCKS[block_id].ENTRY_DETECTORS ) do
            if detector == detector_id then return block_id, true end
        end
        for _, detector in pairs( dd.BLOCKS[block_id].EXIT_DETECTORS ) do
            if detector == detector_id then return block_id, false end
        end
    end
    return "NANA", false
end

function sendBlockUpdate (block, occupied)
    event.push(larcs_common.BlockEventName, block, occupied, true) 
end

function handleIncomingNetwork (event_name, l_addr, r_addr, port, dist, ...)
    if event_name ~= "modem_message" then return end
    
    local args = {...} -- todo split these out into separate variables?
    if args[1] ~= "LARCS" then return end -- Not our message...
    -- larcs_common.TrainNetworkID, detector_details, train_data
    
    if args[2] ~= larcs_common.TrainNetworkID then return end -- not a message we need to worry about
    
    local detector = args[3]
    if dd.DETECTORS[detector] ~= nil then
        detector_details = dd.DETECTORS[detector]
    else
        detector_details = {POS={0,0},INFO="No Data"}
    end

    local block_id, entering = getBlock( detector )
    if block_id == "NANA" and entering == false then return end

    if GLOBAL_STATE[block_id] == nil then 
        GLOBAL_STATE[block_id] = {trains_in_block=new_fifo():setempty(function() return nil end), state=0} 
    end

    if args[4] == nil then 
        return -- shouldn't be nil, may put some better error handling here later
    elseif args[4] == "EOT" then
        if entering then
            GLOBAL_STATE[block_id].trains_in_block:push( "EOT" )
        else
            local value, exists = GLOBAL_STATE[block_id].trains_in_block:peek()
            if exists then
                if value ~= "EOT" then
                    log("WARN", "Expected to pull EOT from "..block_id.."'s queue but I got "..value.."!")
                else
                    GLOBAL_STATE[block_id].trains_in_block:pop()
                end
            else
                log("WARN", "Received EOT but there was no more entries to pull!")
            end
        end
    else
        local stock_data = serialization.unserialize( args[4] ) -- should put some error handling on this
        if entering then
            GLOBAL_STATE[block_id].trains_in_block:push( stock_data.ID )
            log("INFO", stock_data.ID.." entered "..block_id.."!")
        else --exiting
            local value, exists = GLOBAL_STATE[block_id].trains_in_block:peek()
            if exists then
                if value ~= stock_data.ID then
                    log("WARN", stock_data.ID.." unexectedly left "..block_id..".. Did the order change?")
                else
                    GLOBAL_STATE[block_id].trains_in_block:pop()
                    log("INFO", value.." left block "..block_id)
                end
            else
                log("WARN", "Ran out of values to extract from "..block_id.."'s FIFO queue?")
            end
        end
    end

    if #GLOBAL_STATE[block_id].trains_in_block > 0 and GLOBAL_STATE[block_id].state == 0 then
        GLOBAL_STATE[block_id].state = 1
        sendBlockUpdate(block_id, true)
    elseif #GLOBAL_STATE[block_id].trains_in_block == 0 and GLOBAL_STATE[block_id].state == 1 then
        GLOBAL_STATE[block_id].state = 0
        sendBlockUpdate(block_id, false)
    end
end

print("network event listener registered!: "..event.listen("modem_message", handleIncomingNetwork))
