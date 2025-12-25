local function decompress(i)
local of,ou,w=1,{},''
while of<=#i do
local f=string.byte(i,of)
of=of+1
for i=1,8 do
local str=nil
if (f&1)~=0 then
if of<=#i then
str=string.sub(i,of,of)
of=of+1
end
else
if of+1<=#i then
local t=string.unpack('>I2',i,of)
of=of+2
local p,l=(t>>4)+1,(t&(16-1))+3
str=string.sub(w,p,p+l-1)
end
end
f=f>>1
if str then
ou[#ou+1]=str
w=string.sub(w..str,-4096)
end
end
end
return table.concat(ou)
end
