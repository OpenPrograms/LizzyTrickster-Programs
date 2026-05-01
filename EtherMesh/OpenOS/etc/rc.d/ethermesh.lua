local vcomponent = require "vcomponent"
local serial = require "serialization"
local component = require "component"
local computer = require "computer"
local event = require "event"

local cfg = {}
cfg.peers = {}
cfg.rtimer = 15
cfg.katimer = 50
local listeners = {}
local timers = {}
local proxies = {}


local function loadcfg()
    local f = io.open("/etc/ethermesh.cfg","rb")
    if not f then return false end
    for k,v in pairs(serial.unserialize(f:read("*a")) or {}) do
        cfg[k] = v
    end
    f:close()
end
local function savecfg()
    local f = io.open("/etc/ethermesh.cfg","wb")
    if not f then 
        print("Warning: unable to save configuration.")
        return false
    end
    f:write(serial.serialize(cfg))
    f:close()
end

local function createMesh(host,port,addr)
    local proxy = {address=addr,buffer="", _openports={}}
    function proxy._sendToBridge(data)
        return proxy.socket.write( string.pack("<H", #data)..data )
    end
    function proxy.connect()
        print("DEBUG: CONNECT STARTING")
        if proxy.socket then
            proxy.socket.close()
            print("DEBUG: existing connection close")
        end
        proxy.socket = component.internet.connect(host,port)
        local st = computer.uptime()
        repeat
            os.sleep()
        until proxy.socket.finishConnect() or computer.uptime() > st+5
        local finalstr = string.pack("< B c36", 2, proxy.address)
        proxy._sendToBridge( finalstr )
    end
    function proxy.send(dest, port, ...)
        local args = {...}
        rt = 0
        local finalstr, argstr, argCount = "", "", #args
        for i=1,argCount do
            local arg = args[i] -- Why am i setting it local here? Maybe to make the code more readable?
            local argType = type(arg)
            if argType == "string" then -- type 1
                argstr = argstr..string.pack("< B s2", 1, arg) -- Use 2 bytes for string length as most string args will be less than 8192 chars, 1 is too small
            elseif argType == "number" then -- type 2
                argstr = argstr..string.pack("< B n", 2, arg)
            elseif argType == "boolean" then -- type 3
                argstr = argstr..string.pack("< B B", 3, (arg and 1 or 0))
            elseif argType == "nil" then -- type 4
                argstr = argstr..string.pack("<B x", 4)
            end
        end
        local finalstr = string.pack("< B c36 c36 H H B ", 5, proxy.address, dest, port, #argstr, argCount)..argstr
        while not proxy._sendToBridge(finalstr) and rt < 10 do
            proxy.connect()
            rt = rt + 1
        end
        proxy.last = computer.uptime()
    end
    function proxy.broadcast(port, ...)
        proxy.send("BROADCAST", port, ...)
    end

    function proxy.read(event, cardId, connectionId)
        if connectionId ~= proxy.socket.id() then return end -- not our socket, we don't care

        local readbuffer, result
        while true do
            readbuffer, result = proxy.socket.read(4096) -- what is result?
            if type(readbuffer) == "nil" then
                proxy.connect()
            end
            if #readbuffer == 0 and #proxy.buffer == 0 then -- this probably shouldn't ever happen
                -- Buffer empty and no actual data, return early
                return
            end
            proxy.buffer = proxy.buffer..readbuffer -- append the acquired data to the main buffer
            if #proxy.buffer > 0 and #readbuffer == 0 then
                -- no more data left in the socket, lets break out of the while loop and continue on
                break
            end
            -- maybe put an os.sleep() here?
        end
        while true do
            if #proxy.buffer == 0 then break end -- early bail out if we've looped back up here and emptieid the buffer entirely
            local packetLen, bufferOffset = string.unpack("< H", proxy.buffer)
            if #proxy.buffer < packetLen then
                -- buffer doesn't have at least 1 full packet. bail out early cause the data will probably come in soon
                break
            elseif #proxy.buffer >= packetLen then -- we have enough to decode at least one packet
                local bufferLine = proxy.buffer:sub(bufferOffset, packetLen + bufferOffset - 1 )
                proxy.buffer = proxy.buffer:sub(packetLen + bufferOffset) -- remove the current packet from the buffer
                local pType, data, saddr, port, lenArgs, countArgs, args
                local nextOffset = 0
                pType, nextOffset = string.unpack("< B", bufferLine)
                if pType == 1 then -- KA
                    proxy._sendToBridge( string.pack("<Bx", 1) )
                elseif pType == 2 then -- HELLO -- technically not HELLO in this direction, but EtherMesh inquiring who this is (if it didn't yet get sent)
                    proxy._sendToBridge( string.pack("< B c36", 2, proxy.address) ) -- same as in proxy.connect() above
                elseif pType == 3 then -- POPEN -- shouldn't ever actually arrive here
                    print()
                elseif pType == 4 then -- PCLOSE -- same as POPEN
                    print()
                elseif pType == 5 then -- DATA
                    saddr, daddr, port, lenArgs, countArgs, nextOffset = string.unpack("< c36 c36 H H B", bufferLine, nextOffset)
                    args = {}
                    for i=1,countArgs do
                        local argType
                        argType, nextOffset = string.unpack("<B", bufferLine, nextOffset)
                        if argType == 1 then -- string
                            data, nextOffset = string.unpack("<s2", bufferLine, nextOffset)
                            args[#args+1] = data
                        elseif argType == 2 then -- number
                            data, nextOffset = string.unpack("<n", bufferLine, nextOffset)
                            args[#args+1] = data
                        elseif argType == 3 then -- boolean
                            data, nextOffset = string.unpack("<B", bufferLine, nextOffset)
                            args[#args+1] = (data==1 and true or false)
                        elseif argType == 4 then -- nil
                            nextOffset = string.unpack("<x", bufferLine, nextOffset)
                            args[#args+1] = nil
                        end
                    end
                    computer.pushSignal("modem_message", addr, saddr, port, 0, table.unpack(args))
                end
            end
            proxy.last = computer.uptime()
        end
        if computer.uptime() > proxy.last + cfg.katimer then
            proxy._sendToBridge( string.pack("<Bx", 1).."\r\n" )
            proxy.last = computer.uptime()
        end
    end
    function proxy.isWired()
        return true
    end
    function proxy.isWireless()
        return false
    end
    function proxy.getWakeMessage()
        return false
    end
    proxy.setWakeMessage = proxy.getWakeMessage
    function proxy.maxPacketSize()
        return 8192
    end
    function proxy.open(port)
        proxy._sendToBridge( string.pack("< B H", 3, port) )
        -- TODO: note open ports in proxy._openports in the event that we reconnect
        return true
    end
    function proxy.close(port)
        proxy._sendToBridge( string.pack("< B H", 4, port) )
        return true
    end
    event.listen("internet_ready",proxy.read)
    listeners[addr] = {"internet_ready",proxy.read}
    timers[addr] = event.timer(cfg.rtimer, proxy.read, math.huge)
    proxy.connect()
    proxy.last = computer.uptime()
    return proxy
end

function start()
    loadcfg()
    for k,v in pairs(cfg.peers) do
        print(string.format("Connecting to %s:%d",v.host,v.port))
        v.addr = v.addr or vcomponent.uuid()
        local px = createMesh(v.host, v.port, v.addr)
        vcomponent.register(v.addr, "modem", px)
        proxies[v.addr] = px
    end
end

function stop()
    for k,v in pairs(listeners) do
        event.ignore(v[1],v[2])
    end
    for k,v in pairs(timers) do
        event.cancel(v)
    end
    for k,v in pairs(proxies) do
        vcomponent.unregister(k)
    end
end

function settimer(time)
    time = tonumber(time)
    if not time then
        print("Timer must be a number.")
        return false
    end
    cfg.rtime = time
    savecfg()
end

function listpeers()
    for k,v in pairs(cfg.peers) do
        print(string.format("#%d (%s:%d)\n Local address: %s\n Remote address: %s",k,v.host,v.port,v.addr,v.raddr))
    end
end
function addpeer(host,port)
    port = tonumber(port) or 4096
    local t = {}
    t.host = host
    t.port = port
    t.addr = vcomponent.uuid()
    cfg.peers[#cfg.peers+1] = t
    print(string.format("Added peer #%d (%s:%d) to the configuration.\nRestart to apply changes.",#cfg.peers,host,port))
    savecfg()
end

function delpeer(n)
    n=tonumber(n)
    if not n then
        print("delpeer requires a number, representing the peer number, as an argument.")
        return false
    end
    local dp = table.remove(cfg.peers, n)
    savecfg()
    print(string.format("Removed peer %s:%d",dp.host, dp.port))
end
