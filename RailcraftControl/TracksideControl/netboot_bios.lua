_G.net={}
do
local M,pQ,pC,rC,C,Y={},{},{},{},computer,table.unpack
net.port,net.hostname,net.route,net.hook,U,Cl,Cp=4096,C.address():sub(1,8),true,{},C.uptime,component.list,component.proxy
for a in Cl("modem") do
M[a]=Cp(a)
M[a].open(net.port)
end
for a in Cl("tunnel") do
M[a]=Cp(a)
end
local function gP()
local pID=""
for i=1,16 do
pID=pID .. string.char(math.random(32,126))
end
return pID
end
local function rS(pID,pT,T,from,vP,D)
if rC[T] then
if M[rC[T][1]].type=="tunnel" then
M[rC[T][1]].send(pID,pT,T,from,vP,D)
else
M[rC[T][1]].send(rC[T][2],net.port,pID,pT,T,from,vP,D)
end
else
for k,v in pairs(M) do
if v.type=="tunnel" then
v.send(pID,pT,T,from,vP,D)
else
v.broadcast(net.port,pID,pT,T,from,vP,D)
end
end
end
end
local function sP(pID,pT,T,vP,D)
pC[pID]=U()
rS(pID,pT,T,net.hostname,vP,D)
end
function net.send(T,vP,D,pT,pID)
pT,pID=pT or 1,pID or gP()
if pT == 1 then pQ[pID]={pT,T,vP,D,0} end
sP(pID,pT,T,vP,D)
end
local function cC(pID)
for k,v in pairs(pC) do
if k==pID then
return false
end
end
return true
end
local rCPE=C.pullSignal
function C.pullSignal(t)
local Z={rCPE(t)}
for k,v in pairs(net.hook) do
pcall(v,Y(Z))
end
for k,v in pairs(pC) do
if U()>v+30 then
pC[k]=nil
end
end
for k,v in pairs(rC) do
if U()>v[3]+30 then
rC[k]=nil
end
end
if Z[1]=="modem_message" and (Z[4]==net.port or Z[4]==0) and cC(Z[6]) then
rC[Z[9]]={Z[2],Z[3],U()}
if Z[8]==net.hostname then
if Z[7]~=2 then
C.pushSignal("net_msg",Z[9],Z[10],Z[11])
if Z[7]==1 then
sP(gP(),2,Z[9],Z[10],Z[6])
end
else
pQ[Z[11]]=nil
end
elseif net.route and cC(Z[6]) then
rS(Z[6],Z[7],Z[8],Z[9],Z[10],Z[11])
end
pC[Z[6]]=U()
end
for k,v in pairs(pQ) do
if U()>v[5] then
sP(k,Y(v))
v[5]=U()+30
end
end
return Y(Z)
end
end
net.mtu=8192 --4096
function net.lsend(T,P,L)
local D={}
for i=1,L:len(),net.mtu do
D[#D+1]=L:sub(1,net.mtu)
L=L:sub(net.mtu+1)
end
for k,v in ipairs(D) do
net.send(T,P,v)
end
end
function net.socket(A,P,S)
local C,rb={},""
C.s,C.b,C.P,C.A="o","",tonumber(P),A
function C.r(s,l)
rb=s.b:sub(1,l)
s.b=s.b:sub(l+1)
return rb
end
function C.w(s,D)
net.lsend(s.A,s.P,D)
end
function C.c(s)
net.send(C.A,C.P,S)
end
function h(E,F,P,D)
if F==C.A and P==C.P then
if D==S then
net.hook[S]=nil
C.s="c"
return
end
C.b=C.b..D
end
end
net.hook[S]=h
return C
end
net.timeout=60
function net.open(A,V)
local st,F,P,D=computer.uptime()
net.send(A,V,"openstream")
repeat
_,F,P,D=computer.pullSignal(0.5)
if computer.uptime()>st+net.timeout then return false end
until F==A and P==V and tonumber(D)
V=tonumber(D)
repeat
_,F,P,D=computer.pullSignal(0.5)
until F==A and P==V
return net.socket(A,V,D)
end
function fget(A,P,V)
 local b,tb,s="","",net.open(A,V or 70)
 s:w("t"..P.."\n")
 repeat
  computer.pullSignal(1)
  tb=s:r(net.mtu)
  b=b..tb
 until tb == "" and s.s == "c"
 return b:sub(2),b:sub(1,1)
end
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
