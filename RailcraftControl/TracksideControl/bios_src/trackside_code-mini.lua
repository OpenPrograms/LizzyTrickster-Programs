local tfs = Cp(computer.tmpAddress())
--local tfs = Cp(Cl("filesystem")())

local function tryTmpFS()
  local handle, reason = tfs.open("/init.lua")
  if not handle then
    return nil, reason
  end
  local buffer = ""
  repeat
    local data, reason = tfs.read(handle, math.maxinteger or math.huge)
    if not data and reason then
      return nil, reason
    end
    buffer = buffer .. (data or "")
  until not data
  tfs.close(handle)
  return load(buffer, "=init")
end

init, reason = tryTmpFS()
if init then
    return init()
else
    BOOTSRV=""
    while true do
        net.send("~RAILBOOT", 67, "RAIL_BOOTPLS", 0)
        i = 0
        repeat
            local e = {computer.pullSignal(1)}
            if e[1] == "net_msg" and e[3] == 68 then 
                BOOTSRV=e[4]
            end
            i = i + 1
        until i == 5
        if BOOTSRV~="" then
            break
        end
    end
    load(fget(BOOTSRV, "/boot.lua"))()
end
