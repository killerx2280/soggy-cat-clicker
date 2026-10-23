local B = {}

local LOG10 = math.log(10)
local MAX_EXPONENT = 1e15

local metaTable = {}

metaTable.__tostring = function(value)
    if value.m == 0 then
        return "0"
    end

    return string.format("%.3fE%.0f", value.m, value.e)
end

local function make(m, e)
    return setmetatable({ m = m, e = e }, metaTable)
end

local function normalize(m, e)
    if m == nil or e == nil or m ~= m or e ~= e then
        return make(0, 0)
    end

    if m == 0 then
        return make(0, 0)
    end

    if m < 0 then
        m = -m
    end

    while m >= 10 do
        m = m / 10
        e = e + 1
    end

    while m < 1 do
        m = m * 10
        e = e - 1
    end

    if e > MAX_EXPONENT then
        e = MAX_EXPONENT
    end

    m = math.floor(m * 1e12 + 0.5) / 1e12

    if m >= 10 then
        m = m / 10
        e = e + 1
    end

    return make(m, e)
end

function B.new(m, e)
    return normalize(m, e or 0)
end

function B.zero()
    return make(0, 0)
end

function B.one()
    return make(1, 0)
end

function B.fromNumber(value)
    if type(value) == "table" then
        return normalize(value.m, value.e)
    end

    if value == nil or value ~= value then
        return make(0, 0)
    end

    if value == math.huge then
        return make(1, MAX_EXPONENT)
    end

    if value == -math.huge then
        return make(0, 0)
    end

    return normalize(value, 0)
end

function B.clone(value)
    value = B.fromNumber(value)
    return make(value.m, value.e)
end

function B.cmp(a, b)
    a = B.fromNumber(a)
    b = B.fromNumber(b)

    if a.m == 0 and b.m == 0 then
        return 0
    end

    if a.m == 0 then
        return -1
    end

    if b.m == 0 then
        return 1
    end

    if a.e ~= b.e then
        return a.e < b.e and -1 or 1
    end

    if a.m == b.m then
        return 0
    end

    return a.m < b.m and -1 or 1
end

function B.add(a, b)
    a = B.fromNumber(a)
    b = B.fromNumber(b)

    if a.m == 0 then
        return b
    end

    if b.m == 0 then
        return a
    end

    local big, small = a, b

    if b.e > a.e then
        big, small = b, a
    end

    local difference = big.e - small.e

    if difference > 17 then
        return big
    end

    return normalize(big.m + small.m / 10 ^ difference, big.e)
end

function B.sub(a, b)
    a = B.fromNumber(a)
    b = B.fromNumber(b)

    if B.cmp(a, b) <= 0 then
        return make(0, 0)
    end

    local difference = a.e - b.e

    if difference > 17 then
        return a
    end

    return normalize(a.m - b.m / 10 ^ difference, a.e)
end

function B.mul(a, b)
    a = B.fromNumber(a)
    b = B.fromNumber(b)

    if a.m == 0 or b.m == 0 then
        return make(0, 0)
    end

    return normalize(a.m * b.m, a.e + b.e)
end

function B.div(a, b)
    a = B.fromNumber(a)
    b = B.fromNumber(b)

    if a.m == 0 or b.m == 0 then
        return make(0, 0)
    end

    return normalize(a.m / b.m, a.e - b.e)
end

function B.pow(a, power)
    a = B.fromNumber(a)

    if a.m == 0 then
        return make(0, 0)
    end

    if power == 0 then
        return make(1, 0)
    end

    local total = (a.e + math.log(a.m) / LOG10) * power

    if total ~= total then
        return make(0, 0)
    end

    if total == math.huge or total > MAX_EXPONENT then
        total = MAX_EXPONENT
    end

    local e = math.floor(total)
    local m = 10 ^ (total - e)

    return normalize(m, e)
end

function B.serialize(value)
    value = B.fromNumber(value)
    return string.format("%.17gE%.0f", value.m, value.e)
end

function B.deserialize(text)
    local m, e = text:match("^([^E]+)E([^E]+)$")

    if m then
        return normalize(tonumber(m), tonumber(e))
    end

    return B.fromNumber(tonumber(text) or 0)
end

return B
