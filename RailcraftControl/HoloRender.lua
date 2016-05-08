local TSegments = { 
--[[ 
  Define the hologram segments for your sections here, the Keys should be the same as what your Signal boxes are called
]]
W2E = {{ x={21,22}, y=1, z={1 ,48} }}, -- W2E
E2W = {{ x={27,28}, y=1, z={1 ,48} }}, -- E2W
N2S = {{ x={1 ,48}, y=1, z={21,22} }}, -- S2N
S2N = {{ x={1 ,48}, y=1, z={27,28} }}, -- N2S

W2S = {{ x={39,40}, y=2, z={21,34} }, --[[ E2N V ]] { x={21,38}, y=2, z={35,36} } --[[ E2N H ]] },
N2W = {{ x={15,28}, y=2, z={39,40} }, --[[ S2E H ]] { x={13,14}, y=2, z={21,38} } --[[ S2E V ]] },
E2N = {{ x={11,28}, y=2, z={13,14} }, --[[ W2S V ]] { x={9 ,10}, y=2, z={15,28} } --[[ W2S H ]] },
S2E = {{ x={35,36}, y=2, z={11,28} }, --[[ N2W H ]] { x={21,34}, y=2, z={9 ,10} } --[[ N2W V ]] },
--N2E = {{ x={31,32}, y=2, z={27,30} }, --[[ N2E H ]] { x={27,30}, y=2, z={31,32} } --[[ N2E V ]] },
--E2S = {{ x={19,22}, y=2, z={31,32} }, --[[ E2S V ]] { x={17,18}, y=2, z={27,30} } --[[ E2S H ]] },
--S2W = {{ x={17,18}, y=2, z={19,22} }, --[[ S2W H ]] { x={19,22}, y=2, z={17,18} } --[[ S2W V ]] },
--W2N = {{ x={27,30}, y=2, z={17,18} }, --[[ E2N V ]] { x={31,32}, y=2, z={19,22} } --[[ E2N H ]] }
}

local h = require("component").hologram
function ReRender( Event, Addr, Signal, Aspect )
  local p = 0
  if Aspect == 1 then p=2 elseif Aspect == 3 then p=3 else p=1 end
  for n,v in pairs(TSegments[Signal]) do
    for i=v.x[1],v.x[2] do
      for k=v.z[1],v.z[2] do
        h.set(i,v.y,k,p) 
      end
    end
  end
end


h.clear()
h.setScale(0.33) -- Single block space 
os.sleep(1)

-- Initial Draw of the segments,
for kk,l in pairs(TSegments) do
  for k,v in pairs(l) do
    if type(v) == "table" then
      print( "attempting to draw "..kk)
      for i=v.x[1],v.x[2] do 
        for k=v.z[1],v.z[2] do 
          h.set(i,v.y,k,2) 
          --os.sleep(0.01) 
        end
      end
    end
  end
end
h.set(1,1,1,3)
h.set(48,1,48,2)
h.set(1,1,48,1)
local event = require("event")
event.listen( "aspect_changed", ReRender)
