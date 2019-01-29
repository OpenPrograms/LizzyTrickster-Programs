local larcs_common = require("larcs/common")

local internet = require("internet")

-- gets latest shiz
local s = ""
for chunk in internet.request("https://raw.githubusercontent.com/LizzyTrickster/TechycraftCrap/master/creative/MainlineEquipment.lua") do
	s = s + chunk
end
local dd = load(s)() -- TODO load / write to file
-- curl https://raw.githubusercontent.com/LizzyTrickster/TechycraftCrap/master/creative/MainlineEquipment.lua -v -H 'If-None-Match: "29eb4e57f1d9631d5f953b7ec9ebe8ea0aa848ae"'
-- can use ETAG to check if it's newer or not