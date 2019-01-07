local component = require("component")
local event = require("event")

local aspects = {
    "DANGER",
    "CAUTION",
    "PRE_CAUTION",
    "CLEAR",
    DANGER = 1,
    CAUTION = 2,
    PRE_CAUTION = 3,
    CLEAR = 4
}

local BLOCK_UPDATE_SIGNAL = "X-BlockUpdate"
local ASPECT_UPDATE_SIGNAL = "X-AspectChanged"

local signal = {aspects = aspects}

function signal.getRedVals (aspect) -- maybe convert these into an addressable form?
    local sig = {
        {[0]=255, 0, 0, 0}, {[0]=0, 255, 0, 0}, {[0]=0, 255, 255, 0}, {[0]=0, 0, 0, 255},
        DANGER={[0]=255, 0, 0, 0}, 
        CAUTION={[0]=0, 255, 0, 0},PRE_CAUTION={[0]=0, 255, 255, 0}, 
        CLEAR={[0]=0, 0, 0, 255}
        }
    return sig[aspect]
end

function signal.new (signal_id, redstone_comp, side, upstream_signal_id, block_id)
    local o = {}
    setmetatable(o, signal)
    signal.__index = signal
    o.id = signal_id
    o.redstone = component.proxy(redstone_comp)
    o.rSide = side
    o.upstream = upstream_signal_id
    o.state = 4
    o.override=false
    o.block = block_id

    o.updateAspect = function() 
        if o.override then 
            o.redstone.setBundledOutput(o.rSide, o.getRedVals(o.aspects.DANGER)) 
            event.push("X-AspectChanged", o.id, o.aspects.DANGER, true)
        else
            o.redstone.setBundledOutput(o.rSide, o.getRedVals(o.state))
            event.push("X-AspectChanged", o.id, o.state, true)
        end
    end

    o.handleAspect = function(event_name, signal_id, aspect, is_local)
        if event_name ~= ASPECT_UPDATE_SIGNAL then d("WRONG EVENT SIGNAL") return end
        if signal_id == o.id then d("it's me") return end -- don't need to update for ourselves
        if signal_id ~= o.upstream then d("NOTMYUPSTREM") return end -- if it's not our upstream, we dont care
        if signal_id == o.upstream then -- sanity check
            if aspect == 4 then -- if it's already CLEAR upstream, we don't need to do any math
                o.state = 4
                o.updateAspect()
            elseif aspect >= 1 and aspect <= 3 then -- this could be simpler, but sanity checking
                o.state = aspect + 1
                o.updateAspect()
            end
        end
    end

    o.handleBlockUpdate = function(event_name, block_id, occupied, is_local)
        if event_name ~= BLOCK_UPDATE_SIGNAL then d("WRONG EVENT BLOCK") return end
        if block_id ~= o.block then d("NOTMYBLOCK") return end
        if occupied then
            o.override = true
        else
            o.override = false
        end
        o.updateAspect()
    end
    o._blockEvent = event.listen(BLOCK_UPDATE_SIGNAL, o.handleBlockUpdate)
    o._aspectEvent = event.listen(ASPECT_UPDATE_SIGNAL, o.handleAspect)
    -- should set up other variables here, also event handler functions
    o.updateAspect()
    return o
end

return signal