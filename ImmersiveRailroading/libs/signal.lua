local component = require("component")
local event = require("event")

local rs = component.redstone

local misc = {}

function misc.stringSplit(inputstr, sep) -- stolen from stack overflow, will move to own file later
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
	aspects = aspects
}

local side = 1

api.setAspect = function(num)
	if num == aspects.DANGER then
		rs.setBundledOutput(side, {[0] = 255, 0, 0, 0} )
	elseif num == aspects.CAUTION then
		rs.setBundledOutput(side, {[0] = 0, 255, 0, 0} )
	elseif num == aspects.PRE_CAUTION then
		rs.setBundledOutput(side, {[0] = 0, 255, 255, 0})
	elseif num == aspects.CLEAR then
		rs.setBundledOutput(side, {[0] = 0, 0, 0, 255})
	end
end


local signal = {aspects = aspects, state = 0}

function signal.getRedVals (aspect)
	local sig = {
		{[0]=255, 0, 0, 0}, {[0]=0, 255, 0, 0}, {[0]=0, 255, 255, 0}, {[0]=0, 0, 0, 255},
		DANGER={[0]=255, 0, 0, 0}, 
		CAUTION={[0]=0, 255, 0, 0},PRE_CAUTION={[0]=0, 255, 255, 0}, 
		CLEAR={[0]=0, 0, 0, 255}
		}
	return sig[aspect]
end

function signal:setAspect (aspect)
	local as 
	if type(aspect) == "string" then
		if self.aspects[string.upper(aspect)] == nil then
			error("Invalid parameter: "..string.upper(aspect)..", expected 'dyffu;")
		else 
			as = self.aspects[string.upper(aspect)]
		end
	elseif type(aspect) == "number" then
		if not (aspect >=1 and aspect <= 4) then
			error("Invalid parameter: "..aspect..", expected range 1-4")
		else
			as = aspect
		end
	else
		error("Expected number or string, got "..type(aspect))
	end

	if as == self.state then return end -- if we get told the same state as we already were, we don't need to change
	
	-------------------------

	rs.setBundledOutput(self.side, self.getRedVals(as))

end

function signal:new (id, redstone, side, upstream_sig)
	o = {}
	setmetatable(o, self)
	self.__index = self
	-- should set up other variables here, also event handler functions
	return o
end

api.signal = signal

return api