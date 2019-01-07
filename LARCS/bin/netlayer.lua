-- TODO list
-- handle local events and convert remote events



local event = require("event")

local port = 564

local function handleNetworkMessages (event_name, l_addr, r_addr, port, dist, ...)
	if event_name ~= "network_message" then return end


end


local function handleAspectUpdates (event_name, signal_id, aspect, is_local)
	return
end

local function handleBlockUpdates (event_name, block_id, occupied, is_local)
	return
end

