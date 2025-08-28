local os = require("os")
local event = require("event")
local comp = require("component")
local sb = comp.switch_board

local lb_u = comp.proxy(comp.get("fede"))
local lb_m = comp.proxy(comp.get("fa1e"))
local lb_l = comp.proxy(comp.get("cc5e"))

local drb = comp.digital_receiver_box
local dcb = comp.digital_controller_box

local aspects = drb.aspects
local lights = {
    ready=0x00FF00,
    releasing=0xFFFF00,
    empty=0xFF0000,
    occupied=0x00FFFF,
    unknown=0xFF00FF
}

for i=1,4 do
    lb_u.setActive(i, true)
    lb_u.setColor(i, lights.unknown)
    os.sleep(0.1)
    lb_l.setActive(i, true)
    lb_l.setColor(i, lights.unknown)
    os.sleep(0.1)
end

function StringExplode( str, pat )
    -- 'Borrowed' from Person8880 for Starfall on GMod many years ago
    local t = {}
    local fpat = "(.-)" .. pat
    local last_end = 1
    local s, e, cap = str:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            t[ #t + 1 ] = cap
        end
        last_end = e+1
        s, e, cap = str:find(fpat, last_end)
    end
    if last_end <= #str then
        cap = str:sub(last_end)
        t[ #t + 1 ] = cap
    end
    return t
end


local lane_status = {
    {inbound_detector="8fe79ab7-99a1-46f2-932c-5b2ca9900be1", train_ready=False, releasing=false, occupied=false},
    {inbound_detector="6fe92e0d-3817-4d6f-894d-3a4bc258a9f6", train_ready=False, releasing=false, occupied=false},
    {inbound_detector="ff151519-9c0f-4088-bd50-84ca219b5e00", train_ready=False, releasing=false, occupied=false},
    {inbound_detector="13d33d95-054e-4c8d-a59e-dca9b0e38758", train_ready=False, releasing=false, occupied=false},
}

local signals = {
    {"Depot-TR-1", "Depot-IL-1", "Depot-SH-1", "Depot-LO-1"},
    {"Depot-TR-2", "Depot-IL-2", "Depot-SH-2", "Depot-LO-2"},
    {"Depot-TR-3", "Depot-IL-3", "Depot-SH-3", "Depot-LO-3"},
    {"Depot-TR-4", "Depot-IL-4", "Depot-SH-4", "Depot-LO-4"},
}

for k, signal in pairs(signals) do
    lb_u.setActive(k, true)
    aspect = drb.getAspect(signal[1])
    if aspect == aspects.green then
        lb_u.setColor(k, lights.ready)
    else
        lb_u.setColor(k, lights.empty)
    end

end

function updateLights()
    for k,lane in pairs(lane_status) do
        if lane['train_ready'] and not lane['releasing'] then
            lb_u.setColor(k, lights.ready)
        elseif lane['train_ready'] and lane['releasing'] then
            lb_u.setColor(k, lights.releasing)
        elseif not lane['train_ready'] and lane['occupied'] then
            lb_u.setColor(k, lights.occupied)
        else
            lb_u.setColor(k, lights.empty)
        end
    end
end

function release_lane(lane)
    --checkarg(1, lane, "number")
    if not lane_status[lane]['train_ready'] then
        return false, "Lane not ready!"
    else
        lane_status[lane]['releasing'] = true
        dcb.setAspect(signals[lane][2], aspects.green)
        return true
    end
    if switch_board.isActive(lane) then
        switch_board.setActive(lane, false)
    end
    updateLights()
end

function handle_switch_flip(event, boardId, index, state)
    if not state then return end
    lb_l.setActive(index, state)
    local didRelease, reason = release_lane(index)
    if didRelease then
        print("Lane "..index.." released!")
    else
        print("Lane "..index.." not released: "..reason)
    end
    os.sleep(0.1)
    switch_board.setActive(index, false)
    --comp.proxy(boardId).setActive(index, false)
end

function handle_aspect_changed(event, recvBoxId, signalName, aspect)
    if signalName == "nil" then return end
    local area, ty, lane = table.unpack(StringExplode(signalName, "-"))
    lane = tonumber(lane)
    if area == "Depot" then
        if ty == "TR" then
            if aspect == aspects.green then
                lane_status[lane]['train_ready'] = true
                print("Lane "..lane.." is ready!")
            else
                lane_status[lane]['train_ready'] = false
                print("Lane "..lane.." is not ready...")
            end
        elseif ty == "LO" then
            if aspect == aspects.green then
                lane_status[lane]['occupied'] = false
                print("Lane "..lane.." is now free")                
                if lane_status[lane]['releasing'] then
                    lane_status[lane]['releasing'] = false
                    dcb.setAspect(signals[lane][2], aspects.red)
                    switch_board.setActive(lane, false)
                    print("Lane "..lane.." completed release!")
                end
            else
                lane_status[lane]['occupied'] = true
                print("Lane "..lane.." occupied")
            end
        end
    end
    updateLights()
end

event.listen("switch_flipped", handle_switch_flip)
event.listen("aspect_changed", handle_aspect_changed)

for k,signal in pairs(signals) do
    dcb.setAspect(signal[2], aspects.red)
    dcb.setAspect(signal[3], aspects.red)
    if drb.getAspect(signal[1]) == aspects.green then
        lane_status[k]['train_ready'] = true
    else
        lane_status[k]['train_ready'] = false
    end
    if drb.getAspect(signal[4]) == aspects.green then 
        lane_status[k]['occupied'] = false
    else
        lane_status[k]['occupied'] = true
    end
end
updateLights()

while true do
    for k,color in pairs({0xFF0000, 0x00FF00, 0x0000FF}) do
        for i=1,4 do
            lb_m.setColor(i, color)
            lb_m.setActive(i, true)
            os.sleep(0.2)
            lb_m.setActive(i, false)
        end
    end
end

event.ignore("switch_flipped", handle_switch_flip)

