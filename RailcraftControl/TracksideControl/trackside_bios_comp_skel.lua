@insert "bios_src/decompressor.lua"
!(
    lzss = require "lzss"
    bios_code = readFile("trackside_bios.lua")
)
local code = !( lzss.compress(bios_code) )
load(decompress(code))()
