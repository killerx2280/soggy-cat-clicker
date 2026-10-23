clickb = {x=50,y=100,width=110,height=40,text="Click"}
b1 = {x=50,y=160,width=240,height=90,price=B.new(10),text="+1 Click",effect=buyClickPower,priceMultiplier=1.5,maxLevel=100000000,level=0}
b2 = {x=310,y=160,width=240,height=90,price=B.new(50),text="x2 Multiplier",effect=buyMultiplier,priceMultiplier=2.5,maxLevel=100000000,level=0}
b3 = {x=570,y=160,width=240,height=90,price=B.new(100),text="+1 CPS",effect=buyCPS,priceMultiplier=4,maxLevel=12,level=0}

buttons = {b1,b2,b3}

local left, right = math.huge, -math.huge

for _, b in ipairs(buttons) do
    left = math.min(left, b.x)
    right = math.max(right, b.x + b.width)
end

clickb.x = math.floor(left + (right - left - clickb.width) / 2)

print(clicks)
print(clickPower)
print(clickExponent)
print(cps)

print(b1.effect)
print(b2.effect)
print(b3.effect)
