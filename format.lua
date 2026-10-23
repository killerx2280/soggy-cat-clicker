local names = {
    "thousand",
    "million",
    "billion",
    "trillion",
    "quadrillion",
    "quintillion",
    "sextillion",
    "septillion",
    "octillion",
    "nonillion",
    "decillion",
    "undecillion",
    "duodecillion",
    "tredecillion",
    "quattuordecillion",
    "quindecillion",
    "sexdecillion",
    "septendecillion",
    "octodecillion",
    "novemdecillion",
    "vigintillion",
    "unvigintillion",
    "duovigintillion",
    "tresvigintillion",
    "quattuorvigintillion",
    "quinvigintillion",
    "sexvigintillion",
    "septenvigintillion",
    "octovigintillion",
    "novemvigintillion",
    "trigintillion",
    "untrigintillion",
    "duotrigintillion",
    "trestrigintillion",
    "quattuortrigintillion",
    "quintrigintillion",
    "sextrigintillion",
    "septentrigintillion",
    "octotrigintillion",
    "novemtrigintillion",
    "quadragintillion",
    "unquadragintillion",
    "duoquadragintillion",
    "tresquadragintillion",
    "quattuorquadragintillion",
    "quinquadragintillion",
    "sexquadragintillion",
    "septenquadragintillion",
    "octoquadragintillion",
    "novemquadragintillion",
    "quagintillion",
    "unquagintillion",
    "duoquagintillion",
    "tresquagintillion",
    "quattuorquagintillion",
    "quinquagintillion",
    "sexquagintillion",
    "septenquagintillion",
    "octoquagintillion",
    "novemquagintillion",
    "sexagintillion",
    "unsexagintillion",
    "duosexagintillion",
    "tressexagintillion",
    "quattuorsexagintillion",
    "quinsexagintillion",
    "sexsexagintillion",
    "septensexagintillion",
    "octosexagintillion",
    "novemsexagintillion",
    "septuagintillion",
    "unseptuagintillion",
    "duoseptuagintillion",
    "tresseptuagintillion",
    "quattuorseptuagintillion",
    "quinseptuagintillion",
    "sexseptuagintillion",
    "septenseptuagintillion",
    "octoseptuagintillion",
    "novemseptuagintillion",
    "octogintillion",
    "unoctogintillion",
    "duooctogintillion",
    "tresoctogintillion",
    "quattuoroctogintillion",
    "quinoctogintillion",
    "sexoctogintillion",
    "septenoctogintillion",
    "octooctogintillion",
    "novemoctogintillion",
    "nonagintillion",
    "unnonagintillion",
    "duononagintillion",
    "tresnonagintillion",
    "quattuornonagintillion",
    "quinnonagintillion",
    "sexnonagintillion",
    "septennonagintillion",
    "octononagintillion",
    "novemnonagintillion",
    "centillion"
}

local function splitNumber(value)
    if type(value) == "table" then
        return value.m, value.e
    end

    if value ~= value then
        return 0, 0
    end

    if value == math.huge or value == -math.huge then
        return 1, 1e15
    end

    if value == 0 then
        return 0, 0
    end

    local magnitude = math.abs(value)
    local e = math.floor(math.log(magnitude) / math.log(10))
    local m = magnitude / 10 ^ e

    if m >= 10 then
        m = m / 10
        e = e + 1
    elseif m < 1 then
        m = m * 10
        e = e - 1
    end

    return m, e
end

function formatNumber(value)
    local m, e = splitNumber(value)

    if m == 0 then
        return "0"
    end

    if e < 3 then
        return tostring(math.floor(m * 10 ^ e + 1e-9))
    end

    local group = math.floor(e / 3)
    local scaled = m * 10 ^ (e - group * 3)

    if names[group] then
        return string.format("%.3f %s", scaled, names[group])
    end

    return string.format("%.3fe%.0f", m, e)
end
