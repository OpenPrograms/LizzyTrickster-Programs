-- TODO list
-- handle local events and convert remote events
-- Possibly have some form of state information so that each 'node' knows who it needs to be sending updates to?


local event = require("event")
local serial = require("serialization")

local modem = require("component").modem -- should probably load a config to decide which to use

local larcs_common = require("larcs/common")

local function broad (message_id, data, ext_data)
	checkArg(1, message_id, "string")
	checkArg(2, data, "table", "string")
	checkArg(3, ext_data, "table", "string", "nil")
	if type(data) == "table" then data = serial.serialize(data) end
	if ext_data ~= "string" then  ext_data = serial.serialize(ext_data) end
	return modem.broadcast(larcs_common.NetworkPort, "LARCS", message_id, data, ext_data)
end

local function handleNetworkMessages (event_name, l_addr, r_addr, port, dist, ...)
	if event_name ~= "modem_message" then return end
	if port ~= larcs_common.NetworkPort then return end
	-- {"LARCS", "**_UPDATE", "{{DATA}}", "_extData"}
	local args = {...}
	if args[1] ~= "LARCS" then return end -- not a LARCS message? Don't care
	local message_id = args[2]
	local net_args = serial.unserialize(args[3])

	if message_id == larcs_common.AspectNetworkID then
		for signal_id, aspect in pairs(net_args) do
			if aspect >=1 and aspect <=4 then
				event.push(larcs_common.AspectEventName, signal_id, aspect, false)
			end
		end
	elseif message_id == larcs_common.BlockNetworkID then
		for block, occupied in pairs(net_args) do
			if type(occupied) == "boolean" then
				event.push(larcs_common.BlockEventName, block, occupied, false)
			end
		end
	end
end


local function handleAspectUpdates (event_name, signal_id, aspect, is_local)
	if event_name ~= larcs_common.AspectEventName then return end
	if not is_local then return end -- Non-local updates get generated by this script, don't need no loops
	broad( larcs_common.AspectNetworkID, {[signal_id]=aspect} )
end

local function handleBlockUpdates (event_name, block_id, occupied, is_local)
	if event_name ~= larcs_common.BlockEventName then return end
	if not is_local then return end
	broad( larcs_common.BlockNetworkID, {[block_id]=occupied} )
end

print(event.listen(larcs_common.BlockEventName, handleBlockUpdates))
print(event.listen(larcs_common.AspectEventName, handleAspectUpdates))
print(event.listen("modem_message", handleNetworkMessages))
modem.open(larcs_common.NetworkPort)