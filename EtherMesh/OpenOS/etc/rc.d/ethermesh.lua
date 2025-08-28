local vcomponent = require "vcomponent"
local serial = require "serialization"
local component = require "component"
local computer = require "computer"
local event = require "event"
local json = require "json"

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
    function proxy.connect()
        if proxy.socket then
            proxy.socket.close()
        end
        proxy.socket = component.internet.connect(host,port)
        local st = computer.uptime()
        repeat
            coroutine.yield()
        until proxy.socket.finishConnect() or computer.uptime() > st+5
        proxy.socket.write(json.encode({type="HELLO", s=proxy.address, op=proxy._openports}).."\n")
    end
    function proxy.send(dest, port, d1,d2,d3,d4,d5,d6,d7,d8)
        rt = 0
        data_to_send = {type="DATA", s=proxy.address, d=dest, p=port, D={d1=d1,d2=d2,d3=d3,d4=d4,d5=d5,d6=d6,d7=d7,d8=d8} } -- stupid table.pack / serialization issues
        while not proxy.socket.write(json.encode(data_to_send).."\n") and rt < 10 do
            proxy.connect()
            rt = rt + 1
        end
        proxy.last = computer.uptime()
    end
    function proxy.broadcast(port, ...)
        proxy.send("BROADCAST", port, ...)
    end

    function proxy.read(event, cardId, connectionId)
        local rb, r
        local buffer = ""
        while true do
            rb,r = proxy.socket.read(4096)
            if type(rb) == "nil" then
                proxy.connect()
            end
            if #rb == 0 and #buffer == 0 then
                -- Buffer empty and no actual data, return early
                return
            end
            buffer = buffer..rb
            if #buffer > 0 and #rb == 0 then
                break
            end
        end
        if #buffer > 0 then
            for dataline in string.gmatch(buffer, '([^'.."\n"..']+)') do
                data = json.decode(dataline)
                if data['type'] == "DATA" then
                    computer.pushSignal("modem_message", addr, data['s'], data['p'], 0, data['D']['d1'], data['D']['d2'], data['D']['d3'], data['D']['d4'], data['D']['d5'], data['D']['d6'], data['D']['d7'], data['D']['d8'])
                end
                proxy.last = computer.uptime()
            end
        end
        if computer.uptime() > proxy.last + cfg.katimer then
            proxy.socket.write(json.encode({type="KA", s=addr}).."\n" )
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
        proxy.socket.write(json.encode({type="POPEN", port=port}).."\n")
        -- TODO: note open ports in proxy._openports in the event that we reconnect
        return true
    end
    function proxy.close(port)
        proxy.socket.write(json.encode({type="PCLOSE", port=port}).."\n")
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
