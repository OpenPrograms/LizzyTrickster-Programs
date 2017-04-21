-- Example Config File
-- This is incomplete, not sure if i'll ever bother completing it

local config = {
	staticRoutes = {
		South = {""},
		North = {""},
		East = {""},
		West = {"Liz/"},
	},
	North = {
		NC = component.get("UUID"), 
		RT={}
	},
	South = {
		NC = component.get("UUID"), 
		RT={}
	},
	West = {NC = component.get("UUID"), RT={}},
	East =  {NC = component.get("UUID"), RT={}}
}

for addr, comp in component.list("routing_switch") do
	if component.proxy(addr).getRoutingTableTitle():find("2N") then
		table.insert( config.North.RT, component.proxy(addr) )
	elif component.proxy(addr).getRoutingTableTitle():find("2S") then
		table.insert( config.South.RT, component.proxy(addr) )
	elif component.proxy(addr).getRoutingTableTitle():find("2E") then
		table.insert( config.East.RT, component.proxy(addr) )
	elif component.proxy(addr).getRoutingTableTitle():find("2W") then
		table.insert( config.West.RT, component.proxy(addr) )
	end
end

return config
