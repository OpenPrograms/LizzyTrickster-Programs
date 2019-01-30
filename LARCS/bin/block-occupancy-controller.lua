local larcs_common = require("larcs/common")

local internet = require("internet")

-- gets latest shiz
local s = ""
for chunk in internet.request("https://raw.githubusercontent.com/LizzyTrickster/TechycraftCrap/master/creative/MainlineEquipment.lua") do
	s = s + chunk
end
local dd = load(s)() -- TODO load / write to file
-- curl https://raw.githubusercontent.com/LizzyTrickster/TechycraftCrap/master/creative/MainlineEquipment.lua -v -H 'If-None-Match: "29eb4e57f1d9631d5f953b7ec9ebe8ea0aa848ae"'
-- can use ETAG to check if it's newer or not, may need to use base internet component cause the internet library seems crap

local GLOBAL_STATE = {}

function handleIncomingNetwork (event_name, l_addr, r_addr, port, dist, ...)
	if event_name ~= "modem_message" then return end
	
	local args = {...} -- todo split these out into separate variables?
	if args[1] ~= "LARCS" then return end -- Not our message...
	-- larcs_common.TrainNetworkID, detector_details, data
	
	if args[2] ~= larcs_common.TrainNetworkID then return end -- not a message we need to worry about
	
	local detector_details = args[3]
	if type(detector_details) == "string" then
		local success, result = pcall(serial.unserialize, detector_details)
		if success then
			if result ~= nil then 
				detector_details = result
			end
		end
	end

	if args[3] ~= nil then
		