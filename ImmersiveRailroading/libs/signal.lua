local component = require("component")
local event = require("event")
local computer = require("computer")
local os = require("os")
local s = require("serialization").serialize

local rs = component.redstone

function d (message)
    component.modem.broadcast(123, message)
end

local misc = {}

function misc.stringSplit(inputstr, sep) -- stolen from stack overflow, will move to own file later
    -- text.split 
    if sep == nil then
            sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            t[i] = str
            i = i + 1
    end
    return t
end

function misc.uuid() -- require("uuid")
    local r = math.random
    return string.format("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
    r(0,255),r(0,255),r(0,255),r(0,255),
    r(0,255),r(0,255),
    r(64,79),r(0,255),
    r(128,191),r(0,255),
    r(0,255),r(0,255),r(0,255),r(0,255),r(0,255),r(0,255))
end

--#####################--
-- END OF LIBS SECTION --
--#####################--

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

local api = {
    aspects = aspects,
    misc = misc
}

-- local side = 1

-- api.setAspect = function(num)
--     if num == aspects.DANGER then
--         rs.setBundledOutput(side, {[0] = 255, 0, 0, 0} )
--     elseif num == aspects.CAUTION then
--         rs.setBundledOutput(side, {[0] = 0, 255, 0, 0} )
--     elseif num == aspects.PRE_CAUTION then
--         rs.setBundledOutput(side, {[0] = 0, 255, 255, 0})
--     elseif num == aspects.CLEAR then
--         rs.setBundledOutput(side, {[0] = 0, 0, 0, 255})
--     end
-- end

local BLOCK_UPDATE_SIGNAL = "X-BlockUpdate"
local ASPECT_UPDATE_SIGNAL = "X-AspectChanged"

d(BLOCK_UPDATE_SIGNAL)
d(ASPECT_UPDATE_SIGNAL)

local signal = {aspects = aspects}

d(s(signal))

function signal.getRedVals (aspect) -- maybe convert these into an addressable form?
    local sig = {
        {[0]=255, 0, 0, 0}, {[0]=0, 255, 0, 0}, {[0]=0, 255, 255, 0}, {[0]=0, 0, 0, 255},
        DANGER={[0]=255, 0, 0, 0}, 
        CAUTION={[0]=0, 255, 0, 0},PRE_CAUTION={[0]=0, 255, 255, 0}, 
        CLEAR={[0]=0, 0, 0, 255}
        }
    return sig[aspect]
end

-- function signal:updateAspect ()
--     -- local as 
--     -- if type(aspect) == "string" then
--     --  if self.aspects[string.upper(aspect)] == nil then
--     --      error("Invalid parameter: "..string.upper(aspect)..", expected 'dyffu;")
--     --  else 
--     --      as = self.aspects[string.upper(aspect)]
--     --  end
--     -- elseif type(aspect) == "number" then
--     --  if not (aspect >=1 and aspect <= 4) then
--     --      error("Invalid parameter: "..aspect..", expected range 1-4")
--     --  else
--     --      as = aspect
--     --  end
--     -- else
--     --  error("Expected number or string, got "..type(aspect))
--     -- end
--     d( s({OR=self.override, Si=self.rSide, GG=self.getRedVals(self.state)}) )
--     if self.override then self.redstone.setBundledOutput(self.rSide, self.getRedVals(self.aspects.DANGER)) return end

--     -- if as == self.state then return end -- if we get told the same state as we already were, we don't need to change
    
--     -------------------------

--     d( s(rs.setBundledOutput(self.rSide, self.getRedVals(self.state))) )
--     computer.pushSignal("X-AspectChanged", self.id, self.state, true) -- notify other signals we changed
-- end

-- function signal:handleBlockUpdate (event_name, block_id, occupied, is_local) -- remove this and set it up to be created in :new()
--     -- need look into why the parameters are to the left by 1
--     d( s({event_name, block_id, occupied, is_local}))
--     if event_name ~= BLOCK_UPDATE_SIGNAL then d("WRONG EVENT BLOCK") return end
--     os.sleep(0.2)
--     --if block_id ~= self.block then d("NOTMYBLOCK") return end
--     d(s({self.override, occupied}))
--     if occupied then 
--         self.override = true
--     else
--         self.override = false
--     end
--     d(s({self.override, occupied}))
--     self:updateAspect()
-- end

-- function signal:handleAspect (event_name, signal_id, aspect, is_local) -- remove this and set it up to be created in :new()
--     d( s({event_name, signal_id, aspect, is_local}))
--     if event_name ~= ASPECT_UPDATE_SIGNAL then d("WRONG EVENT SIGNAL") return end
--     if signal_id == self.id then d("it's me@") return end -- don't need to update for ourselves
--     if signal_id ~= self.upstream then d("NOTMYUPSTREM") return end -- if it's not our upstream, we dont care
--     if signal_id == self.upstream then -- sanity check
--         d(s({aspect, self.state}))
--         if aspect == 4 then -- if it's already CLEAR upstream, we don't need to do any math
--             self.state = 4
--             self:updateAspect()
--         elseif aspect >= 1 and aspect <= 3 then -- this could be simpler, but sanity checking
--             self.state = aspect + 1
--             d("state is now "..self.state)
--             self:updateAspect()
--         end
--     end
-- end


-- function signal:setupEventHandlers () -- todo remove, combine in :new()
--     print("BLOCK", event.listen(BLOCK_UPDATE_SIGNAL, self.handleBlockUpdate)) -- event name pending
--     print("SIGNA", event.listen(ASPECT_UPDATE_SIGNAL, self.handleAspect)) --handle both local and remote aspect in single func for now
--     --event.listen("")
-- end


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
    --o:setupEventHandlers()

    o.updateAspect = function() 
        d( s({OR=o.override, Si=o.rSide, GG=o.getRedVals(o.state)}) )
        if o.override then 
            o.redstone.setBundledOutput(o.rSide, o.getRedVals(o.aspects.DANGER)) 
        else
            d( s(o.redstone.setBundledOutput(o.rSide, o.getRedVals(o.state))) )
        end
        computer.pushSignal("X-AspectChanged", o.id, o.state, true) -- notify other signals we changed
    end

    o.handleAspect = function(event_name, signal_id, aspect, is_local)
        d( s({event_name, signal_id, aspect, is_local}))
        if event_name ~= ASPECT_UPDATE_SIGNAL then d("WRONG EVENT SIGNAL") return end
        if signal_id == o.id then d("it's me") return end -- don't need to update for ourselves
        if signal_id ~= o.upstream then d("NOTMYUPSTREM") return end -- if it's not our upstream, we dont care
        if signal_id == o.upstream then -- sanity check
            d(s({aspect, o.state}))
            if aspect == 4 then -- if it's already CLEAR upstream, we don't need to do any math
                o.state = 4
                o.updateAspect()
            elseif aspect >= 1 and aspect <= 3 then -- this could be simpler, but sanity checking
                o.state = aspect + 1
                d("state is now "..o.state)
                o.updateAspect()
            end
        end
    end

    o.handleBlockUpdate = function(event_name, block_id, occupied, is_local)
        d( s({event_name, block_id, occupied, is_local}))
        if event_name ~= BLOCK_UPDATE_SIGNAL then d("WRONG EVENT BLOCK") return end
        os.sleep(0.2)
        if block_id ~= o.block then d("NOTMYBLOCK") return end
        d(s({o.override, occupied}))
        if occupied then
            o.override = true
        else
            o.override = false
        end
        d(s({o.override, occupied}))
        o.updateAspect()
    end

    o._blockEvent = event.listen(BLOCK_UPDATE_SIGNAL, o.handleBlockUpdate)
    o._aspectEvent = event.listen(ASPECT_UPDATE_SIGNAL, o.handleAspect)

    -- should set up other variables here, also event handler functions
    o.updateAspect()
    return o
end

api.signal = signal

return api