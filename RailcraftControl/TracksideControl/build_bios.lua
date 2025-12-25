local pp = require "preprocess" -- This may not be on the path, work out how to add it to the path for the runner

lzss = require "lzss"

print("Minifying code!")
-- do minification stuff here

print("Assembling code")
local info, err = pp.processFile{
    pathIn = "trackside_bios_skel.lua",
    pathOut = "trackside_bios.lua",
}

if err then error(err) end


print("Compressing!")
-- do compressy things here
local info, err = pp.processFile{
    pathIn = "trackside_bios_comp_skel.lua",
    pathOut = "trackside_bios_comp.lua",
}

if err then error(err) end
