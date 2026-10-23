B = require("bignum")

clicks = B.zero()
clickPower = B.one()
clickMultiplier = B.one()
clickExponent = 1
cps = 0
cpsTimer = 0
saveTimer = 0

CLICK_SOUND_VOLUME = 0.6
BUY_SOUND_VOLUME = 0.6
clickSound = nil
buySound = nil
upgradesOpen = false
upgradesWindowOffsetX = 0
upgradesWindowOffsetY = 0
upgradesDragging = false
dragStartX = 0
dragStartY = 0
dragOffsetX = 0
dragOffsetY = 0

COMBO_TIMEOUT = 0.1
COMBO_MAX_STACKS = 49
COMBO_BONUS_PER_STACK = 0.05
comboCount = 0
comboTimer = 0
comboPulse = 0

require("upgrades")
require("buttons")
require("draw")
require("format")

function saveGame()
    local buttonsData = ""

    for _, b in ipairs(buttons) do
        buttonsData = buttonsData .. b.level .. ":" .. B.serialize(b.price) .. ","
    end

    local data = B.serialize(clicks) .. "\n"
        .. B.serialize(clickPower) .. "\n"
        .. B.serialize(clickMultiplier) .. "\n"
        .. clickExponent .. "\n"
        .. cps .. "\n"
        .. buttonsData

    love.filesystem.write("save.txt", data)

    print("Game saved!")
end

function loadGame()
    print("Loading game...")

    local data = love.filesystem.read("save.txt")

    if data then
        print("Save file found!")

        local values = {}

        for value in data:gmatch("[^\r\n]+") do
            table.insert(values, value)
        end

        clicks = B.deserialize(values[1])
        clickPower = B.deserialize(values[2])
        clickMultiplier = B.deserialize(values[3])
        clickExponent = tonumber(values[4])
        cps = tonumber(values[5])

        local i = 1

        for buttonData in values[6]:gmatch("[^,]+") do
            local level, price = buttonData:match("([^:]+):([^:]+)")

            buttons[i].level = tonumber(level)
            buttons[i].price = B.deserialize(price)

            i = i + 1
        end

        print("Game loaded!")
    else
        print("No save file found. Starting new game.")
    end
end

function loadSound(path, volume)
    if not love.filesystem.getInfo(path) then
        print(path .. " not found, skipping sound")
        return nil
    end

    local source = love.audio.newSource(path, "static")
    source:setVolume(volume)
    return source
end

function playSound(source)
    if source then
        source:stop()
        source:play()
    end
end

function love.load()
    loadGame()

    clickSound = loadSound("assets/click.mp3", CLICK_SOUND_VOLUME)
    buySound = loadSound("assets/muhaha.mp3", BUY_SOUND_VOLUME)
end

function clickValue()
    return B.pow(B.mul(clickPower, clickMultiplier), clickExponent)
end

function comboMultiplier()
    local stacks = math.max(0, math.min(comboCount - 1, COMBO_MAX_STACKS))

    return 1 + stacks * COMBO_BONUS_PER_STACK
end

function registerClick()
    comboCount = math.min(comboCount + 1, COMBO_MAX_STACKS + 1)
    comboTimer = COMBO_TIMEOUT
    comboPulse = 1
end

function updateCombo(dt)
    if comboTimer > 0 then
        comboTimer = comboTimer - dt

        if comboTimer <= 0 then
            comboTimer = 0
            comboCount = 0
        end
    end

    comboPulse = math.max(0, comboPulse - dt * 6)
end

function love.update(dt)
    updateButtonAnimations(dt)
    updateParticles(dt)
    updateCombo(dt)

    cpsTimer = cpsTimer + dt

    if cpsTimer >= 1 / cps then
        clicks = B.add(clicks, clickValue())
        cpsTimer = cpsTimer - (1 / cps)
    end

    saveTimer = saveTimer + dt

    if saveTimer >= 3 then
        saveGame()
        saveTimer = 0
    end
end

function love.quit()
    saveGame()
end

function buyButton(b)
    local oldPrice = b.price
    local oldLevel = b.level

    if B.cmp(clicks, b.price) >= 0 and b.level < b.maxLevel then
        clicks = B.sub(clicks, b.price)

        b.effect()
        b.price = B.mul(b.price, b.priceMultiplier)
        b.level = b.level + 1

        playSound(buySound)

        print("================================")
        print("Button: " .. b.text)
        print("Price: " .. formatNumber(oldPrice) .. " > " .. formatNumber(b.price))
        print("Level: " .. oldLevel .. " > " .. b.level)
        print("================================")
    else
        print("Cannot buy " .. b.text)
    end
end

function love.mousepressed(x, y, button)
    local icon = getUpgradesButtonRect()

    if x > icon.x and x < icon.x + icon.width
    and y > icon.y and y < icon.y + icon.height then

        pressButton(icon)
        playSound(clickSound)
        upgradesOpen = not upgradesOpen

        if upgradesOpen then
            upgradesWindowOffsetX = 0
            upgradesWindowOffsetY = 0
        end

        return
    end

    if upgradesOpen then
        local close = getPanelCloseRect()

        if x > close.x and x < close.x + close.width
        and y > close.y and y < close.y + close.height then

            pressButton(close)
            upgradesOpen = false
            return
        end

        local titleX, titleY, titleWidth, titleHeight = getPanelTitleRect()

        if x >= titleX and x <= titleX + titleWidth
        and y >= titleY and y <= titleY + titleHeight then

            if button == 1 then
                upgradesDragging = true
                dragStartX = x
                dragStartY = y
                dragOffsetX = upgradesWindowOffsetX
                dragOffsetY = upgradesWindowOffsetY
            end

            return
        end

        local panelX, panelY, panelWidth, panelHeight = getPanelRect()

        if x >= panelX and x <= panelX + panelWidth
        and y >= panelY and y <= panelY + panelHeight then

            local panelXInLayout, panelYInLayout = screenToPanel(x, y)

            for _, b in ipairs(buttons) do
                if panelXInLayout > b.x and panelXInLayout < b.x + b.width
                and panelYInLayout > b.y and panelYInLayout < b.y + b.height then

                    pressButton(b)
                    buyButton(b)
                    return
                end
            end

            return
        end
    end

    local ox, oy = uiOffset()
    x, y = x - ox, y - oy

    if x > clickb.x and x < clickb.x + clickb.width
    and y > clickb.y and y < clickb.y + clickb.height then

        clicks = B.add(clicks, B.mul(clickValue(), comboMultiplier()))
        playSound(clickSound)
        pressButton(clickb)
        registerClick()

        spawnParticles(
            ox + clickb.x + clickb.width / 2,
            oy + clickb.y + clickb.height / 2
        )
    end
end

function love.mousemoved(x, y)
    if not upgradesDragging then
        return
    end

    local panelWidth, panelHeight = getPanelSize()
    local screenWidth, screenHeight = love.graphics.getDimensions()

    local limitX = math.max(0, (screenWidth - panelWidth) / 2)
    local limitY = math.max(0, (screenHeight - panelHeight) / 2)

    local newX = dragOffsetX + (x - dragStartX)
    local newY = dragOffsetY + (y - dragStartY)

    upgradesWindowOffsetX = math.max(-limitX, math.min(limitX, newX))
    upgradesWindowOffsetY = math.max(-limitY, math.min(limitY, newY))
end

function love.mousereleased(x, y, button)
    if button == 1 then
        upgradesDragging = false
    end
end

function love.draw()
    drawGame()
end
