local API = {
  ["zone"] = 0xA1
  ["direction"] = {
    ["E"] = {
      0, -- Aspect
      0xA2, -- Next zone ID
      0xA0, -- Prev zone ID
      "" -- Component ID for this Zone
    },
    ["W"] = {
      0,
      0xA0,
      0xA2
    }
  },
  }, 
  ["a2d"] = "4", 
  ["occ"]=false, 
}


local component = require( "component" )
local event = require("event")

API.regID2Side = function( boxAddr, side )
  self.a2s[boxAddr] = side
end

API.getRsSide = function( boxAddr )
  local status, out = pcall( function(boxAddr) return API.a2s[boxAddr] end)
  if status then
    return out
  elseif not status then
    return 6
  end
end


API.localAspectChange = function( eventName, Address, Aspect )
  if self.getRsSide( Address ) ~= 6 then
    si = self.getRsSide( Address )
  else
    return
  end
  if Aspect == 0 then 
    self.occ = false
  elseif Aspect > 0 then
    self.occ = true
  end
  computer.pushSignal( "aspect_primary" )
end

API.remoteAspectChange = function( eventName, la, ra, p, d, ...)
  if eventName ~= "modem_message" then return end
  
end


component.modem.open( 6678 )
event.listen( "modem_message", API.remoteAspectChange )



_G["AspectAPI"] = API