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
