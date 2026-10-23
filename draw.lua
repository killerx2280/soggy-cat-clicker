local background = nil
local backgroundChecked = false
local logo = nil
local logoChecked = false
local upgradesIcon = nil
local upgradesIconChecked = false
local fonts = nil

local STATS_FONT_SIZE = 20
local BUTTON_FONT_SIZE = 14
local CLICK_FONT_SIZE = 16
local OUTLINE_WIDTH = 1
local STATS_OFFSET = 58
local STATS_LINE_HEIGHT = 26
local BUTTON_TEXT_SPACING = 22
local LOGO_MAX_WIDTH = 320
local LOGO_MAX_HEIGHT = 140
local LOGO_GAP = 16
local BG_TINT_ALPHA = 0.45
local STATS_SIDE_MARGIN = 40

local MAX_PARTICLES = 1500
local PARTICLES_PER_CLICK = 5
local PARTICLE_LIFETIME_MIN = 0.45
local PARTICLE_LIFETIME_MAX = 0.9
local PARTICLE_SIZE_MIN = 24
local PARTICLE_SIZE_MAX = 64
local PARTICLE_SPEED_MIN = 140
local PARTICLE_SPEED_MAX = 460
local PARTICLE_GRAVITY = 900
local PARTICLE_SPIN = 4
local PARTICLE_UPWARD_BIAS = 120

local BUTTON_HOVER_SCALE = 0.03
local BUTTON_PRESS_SCALE = 0.15
local BUTTON_HOVER_SPEED = 11
local BUTTON_PRESS_DECAY = 6
local BUTTON_HOVER_BRIGHTNESS = 0.12

local PANEL_PADDING = 20
local PANEL_TITLE_HEIGHT = 36
local PANEL_CLOSE_SIZE = 28

local UPGRADES_BUTTON_SIZE = 72
local UPGRADES_BUTTON_MARGIN = 24

local particles = {}
local buttonAnimations = {}
local upgradesButton = { x = 0, y = 0, width = UPGRADES_BUTTON_SIZE, height = UPGRADES_BUTTON_SIZE }
local panelCloseButton = { x = 0, y = 0, width = 0, height = 0 }

local OUTLINE_DIRS = {
    {-1, -1}, {0, -1}, {1, -1},
    {-1, 0},           {1, 0},
    {-1, 1},  {0, 1},  {1, 1},
}

local function newFont(size)
    if love.filesystem.getInfo("assets/DejaVuSans-Bold.ttf") then
        return love.graphics.newFont("assets/DejaVuSans-Bold.ttf", size)
    end

    print("font not found")
    return love.graphics.newFont(size)
end

local function getFonts()
    if not fonts then
        fonts = {
            stats = newFont(STATS_FONT_SIZE),
            button = newFont(BUTTON_FONT_SIZE),
            click = newFont(CLICK_FONT_SIZE),
        }
    end

    return fonts
end

local function getBackground()
    if not backgroundChecked then
        backgroundChecked = true

        if love.filesystem.getInfo("assets/bg.png") then
            background = love.graphics.newImage("assets/bg.png")
            background:setFilter("linear", "linear")
        else
            print("assets/bg.png not found, skipping background")
        end
    end

    return background
end

local function getLogo()
    if not logoChecked then
        logoChecked = true

        if love.filesystem.getInfo("assets/logo.png") then
            local image = love.graphics.newImage("assets/logo.png")
            image:setFilter("linear", "linear")

            local scale = math.min(
                LOGO_MAX_WIDTH / image:getWidth(),
                LOGO_MAX_HEIGHT / image:getHeight()
            )

            logo = {
                image = image,
                scale = scale,
                width = math.floor(image:getWidth() * scale),
                height = math.floor(image:getHeight() * scale),
            }
        else
            print("assets/logo.png not found, skipping logo")
        end
    end

    return logo
end

local function getUpgradesIcon()
    if not upgradesIconChecked then
        upgradesIconChecked = true

        if love.filesystem.getInfo("assets/upgrades.png") then
            local imageData = love.image.newImageData("assets/upgrades.png")

            imageData:mapPixel(function(x, y, r, g, b, a)
                return 1 - r, 1 - g, 1 - b, a
            end)

            local image = love.graphics.newImage(imageData)
            image:setFilter("linear", "linear")

            local maxSize = UPGRADES_BUTTON_SIZE - 14
            local scale = math.min(maxSize / image:getWidth(), maxSize / image:getHeight())

            upgradesIcon = {
                image = image,
                scale = scale,
                width = math.floor(image:getWidth() * scale),
                height = math.floor(image:getHeight() * scale),
            }
        else
            print("assets/upgrades.png not found, using text instead")
        end
    end

    return upgradesIcon
end

function spawnParticles(x, y)
    local bg = getBackground()
    if not bg then
        return
    end

    for _ = 1, PARTICLES_PER_CLICK do
        if #particles >= MAX_PARTICLES then
            table.remove(particles, 1)
        end

        local angle = love.math.random() * math.pi * 2
        local speed = PARTICLE_SPEED_MIN + love.math.random() * (PARTICLE_SPEED_MAX - PARTICLE_SPEED_MIN)
        local lifetime = PARTICLE_LIFETIME_MIN + love.math.random() * (PARTICLE_LIFETIME_MAX - PARTICLE_LIFETIME_MIN)
        local size = PARTICLE_SIZE_MIN + love.math.random() * (PARTICLE_SIZE_MAX - PARTICLE_SIZE_MIN)

        table.insert(particles, {
            x = x + love.math.random() * 8 - 4,
            y = y + love.math.random() * 8 - 4,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed - PARTICLE_UPWARD_BIAS,
            rotation = love.math.random() * math.pi * 2,
            spin = (love.math.random() * 2 - 1) * PARTICLE_SPIN,
            size = size,
            life = lifetime,
            maxLife = lifetime,
        })
    end
end

function updateParticles(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.life = p.life - dt

        if p.life <= 0 then
            table.remove(particles, i)
        else
            p.vy = p.vy + PARTICLE_GRAVITY * dt
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.rotation = p.rotation + p.spin * dt
        end
    end
end

local function drawParticles()
    local bg = getBackground()
    if not bg or #particles == 0 then
        return
    end

    local textureSize = math.max(bg:getWidth(), bg:getHeight())

    for _, p in ipairs(particles) do
        local lifeRatio = p.life / p.maxLife
        local scale = (p.size / textureSize) * (0.5 + 0.5 * lifeRatio)

        love.graphics.setColor(1, 1, 1, math.min(1, lifeRatio * 1.5))
        love.graphics.draw(bg, p.x, p.y, p.rotation, scale, scale, bg:getWidth() / 2, bg:getHeight() / 2)
    end
end

local function getAnimation(target)
    local animation = buttonAnimations[target]

    if not animation then
        animation = { hover = 0, press = 0 }
        buttonAnimations[target] = animation
    end

    return animation
end

function pressButton(target)
    getAnimation(target).press = 1
end

local function getUpgradeRowBounds()
    local left, top = math.huge, math.huge
    local right, bottom = -math.huge, -math.huge

    for _, b in ipairs(buttons) do
        left = math.min(left, b.x)
        top = math.min(top, b.y)
        right = math.max(right, b.x + b.width)
        bottom = math.max(bottom, b.y + b.height)
    end

    return left, top, right, bottom
end

function getPanelScale()
    local left, top, right, bottom = getUpgradeRowBounds()

    local panelWidth = (right - left) + PANEL_PADDING * 2
    local panelHeight = (bottom - top) + PANEL_PADDING * 2 + PANEL_TITLE_HEIGHT

    local width, height = love.graphics.getDimensions()

    return math.min(1, (width - 60) / panelWidth, (height - 60) / panelHeight)
end

function getPanelRect()
    local left, top, right, bottom = getUpgradeRowBounds()

    local panelWidth = (right - left) + PANEL_PADDING * 2
    local panelHeight = (bottom - top) + PANEL_PADDING * 2 + PANEL_TITLE_HEIGHT

    local scale = getPanelScale()
    local width, height = love.graphics.getDimensions()

    local scaledWidth = panelWidth * scale
    local scaledHeight = panelHeight * scale

    local x = math.floor((width - scaledWidth) / 2) + (upgradesWindowOffsetX or 0)
    local y = math.floor((height - scaledHeight) / 2) + (upgradesWindowOffsetY or 0)

    if scaledWidth <= width then
        x = math.max(0, math.min(x, width - scaledWidth))
    end

    if scaledHeight <= height then
        y = math.max(0, math.min(y, height - scaledHeight))
    end

    panelCloseButton.width = math.floor(PANEL_CLOSE_SIZE * scale)
    panelCloseButton.height = math.floor(PANEL_CLOSE_SIZE * scale)
    panelCloseButton.x = x + scaledWidth - PANEL_PADDING * scale - panelCloseButton.width
    panelCloseButton.y = y + math.floor((PANEL_TITLE_HEIGHT * scale - panelCloseButton.height) / 2)

    return x, y, scaledWidth, scaledHeight, scale
end

function getPanelSize()
    local left, top, right, bottom = getUpgradeRowBounds()
    local scale = getPanelScale()

    return ((right - left) + PANEL_PADDING * 2) * scale,
        ((bottom - top) + PANEL_PADDING * 2 + PANEL_TITLE_HEIGHT) * scale
end

function getPanelTitleRect()
    local panelX, panelY, panelWidth, _, scale = getPanelRect()

    return panelX, panelY, panelWidth, PANEL_TITLE_HEIGHT * scale
end

function getPanelCloseRect()
    return panelCloseButton
end

function screenToPanel(x, y)
    local panelX, panelY, _, _, scale = getPanelRect()
    local left, top = getUpgradeRowBounds()

    return (x - panelX) / scale + left - PANEL_PADDING,
        (y - panelY) / scale + top - PANEL_TITLE_HEIGHT - PANEL_PADDING
end

function panelToScreen(x, y)
    local panelX, panelY, _, _, scale = getPanelRect()
    local left, top = getUpgradeRowBounds()

    return panelX + (x - left + PANEL_PADDING) * scale,
        panelY + (y - top + PANEL_TITLE_HEIGHT + PANEL_PADDING) * scale
end

function getUpgradesButtonRect()
    local width, height = love.graphics.getDimensions()

    upgradesButton.x = width - UPGRADES_BUTTON_MARGIN - upgradesButton.width
    upgradesButton.y = height - UPGRADES_BUTTON_MARGIN - upgradesButton.height

    return upgradesButton
end

function updateButtonAnimations(dt)
    local mouseX, mouseY = love.mouse.getPosition()
    local uiX, uiY = uiOffset()
    local icon = getUpgradesButtonRect()

    local function updateAnimation(b, x, y)
        local animation = getAnimation(b)

        local hovered = x >= b.x and x <= b.x + b.width
            and y >= b.y and y <= b.y + b.height

        animation.hover = animation.hover
            + ((hovered and 1 or 0) - animation.hover) * math.min(1, dt * BUTTON_HOVER_SPEED)

        animation.press = math.max(0, animation.press - dt * BUTTON_PRESS_DECAY)
    end

    local icon = getUpgradesButtonRect()
    local close = panelCloseButton

    updateAnimation(clickb, mouseX - uiX, mouseY - uiY)
    updateAnimation(icon, mouseX, mouseY)

    if upgradesOpen then
        updateAnimation(close, mouseX, mouseY)
        local panelMouseX, panelMouseY = screenToPanel(mouseX, mouseY)

        for _, b in ipairs(buttons) do
            updateAnimation(b, panelMouseX, panelMouseY)
        end
    else
        updateAnimation(close, -math.huge, -math.huge)
        for _, b in ipairs(buttons) do
            updateAnimation(b, -math.huge, -math.huge)
        end
    end
end

local function drawButtonBody(b, drawContents)
    local animation = getAnimation(b)
    local scale = 1 + animation.hover * BUTTON_HOVER_SCALE - animation.press * BUTTON_PRESS_SCALE
    local centerX = b.x + b.width / 2
    local centerY = b.y + b.height / 2

    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.scale(scale, scale)
    love.graphics.translate(-centerX, -centerY)

    drawContents(animation)

    love.graphics.pop()
end

local function getUIBounds()
    local left = clickb.x
    local top = clickb.y - STATS_OFFSET
    local right = clickb.x + clickb.width
    local bottom = clickb.y + clickb.height

    local logoImage = getLogo()
    if logoImage then
        top = top - LOGO_GAP - logoImage.height
    end

    return left, top, right, bottom
end

function uiOffset()
    local left, top, right, bottom = getUIBounds()
    local width, height = love.graphics.getDimensions()

    local ox = math.floor((width - (right - left)) / 2 - left)
    local oy = math.floor((height - (bottom - top)) / 2 - top)

    return ox, oy
end

local function drawOutlined(text, x, y, font, scale, color)
    scale = scale or 1
    color = color or { 1, 1, 1 }

    love.graphics.setFont(font)
    love.graphics.setColor(0, 0, 0, 1)

    for radius = 1, OUTLINE_WIDTH do
        for _, dir in ipairs(OUTLINE_DIRS) do
            love.graphics.print(text, x + dir[1] * radius, y + dir[2] * radius, 0, scale, scale)
        end
    end

    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.print(text, x, y, 0, scale, scale)
end

local function drawCentered(text, centerX, y, font, maxWidth, color, textScale)
    local width = font:getWidth(text)
    local scale = textScale or 1

    if maxWidth and width * scale > maxWidth then
        scale = maxWidth / width
    end

    local x = math.floor(centerX - (width * scale) / 2)
    drawOutlined(text, x, math.floor(y), font, scale, color)
end

local function drawUpgradeButton(b, uiFonts)
    drawButtonBody(b, function(animation)
        local brightness = 1 - BUTTON_HOVER_BRIGHTNESS + BUTTON_HOVER_BRIGHTNESS * animation.hover

        love.graphics.setColor(brightness, brightness, brightness)
        love.graphics.rectangle("fill", b.x, b.y, b.width, b.height, 12)

        local buttonCenterX = b.x + b.width / 2
        local innerWidth = b.width - 20
        local textTop = b.y + 15

        drawCentered(b.text, buttonCenterX, textTop, uiFonts.button, innerWidth)
        drawCentered(
            "Level: " .. formatNumber(b.level) .. "/" .. formatNumber(b.maxLevel),
            buttonCenterX, textTop + BUTTON_TEXT_SPACING, uiFonts.button, innerWidth
        )

        if b.level >= b.maxLevel then
            drawCentered("MAX", buttonCenterX, textTop + BUTTON_TEXT_SPACING * 2, uiFonts.button, innerWidth)
        else
            drawCentered(
                "Price: " .. formatNumber(b.price),
                buttonCenterX, textTop + BUTTON_TEXT_SPACING * 2, uiFonts.button, innerWidth
            )
        end
    end)
end

local function drawUpgradesPanel()
    local uiFonts = getFonts()
    local panelX, panelY, panelWidth, panelHeight, scale = getPanelRect()
    local left, top, right = getUpgradeRowBounds()
    local close = panelCloseButton
    local titleHeight = PANEL_TITLE_HEIGHT * scale

    love.graphics.setColor(0.06, 0.06, 0.08, 0.97)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 16)

    love.graphics.setColor(0.15, 0.15, 0.19, 0.97)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, titleHeight + 16, 16)

    love.graphics.setColor(0.06, 0.06, 0.08, 0.97)
    love.graphics.rectangle("fill", panelX, panelY + titleHeight, panelWidth, 16)

    love.graphics.setColor(1, 1, 1, 0.12)
    love.graphics.rectangle("fill", panelX, panelY + titleHeight, panelWidth, 1)

    love.graphics.setColor(0.55, 0.55, 0.62, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 16)
    love.graphics.setLineWidth(1)

    drawCentered(
        "Upgrades",
        panelX + panelWidth / 2,
        panelY + (titleHeight - uiFonts.stats:getHeight()) / 2,
        uiFonts.stats,
        panelWidth - close.width - 24
    )

    love.graphics.push()
    love.graphics.translate(panelX, panelY)
    love.graphics.scale(scale)
    love.graphics.translate(PANEL_PADDING - left, PANEL_TITLE_HEIGHT + PANEL_PADDING - top)

    for _, b in ipairs(buttons) do
        drawUpgradeButton(b, uiFonts)
    end

    love.graphics.pop()

    local anim = getAnimation(close)
    local cscale = 1 + anim.hover * BUTTON_HOVER_SCALE - anim.press * BUTTON_PRESS_SCALE
    local ccx, ccy = close.x + close.width / 2, close.y + close.height / 2

    love.graphics.push()
    love.graphics.translate(ccx, ccy)
    love.graphics.scale(cscale)
    love.graphics.translate(-ccx, -ccy)

    local brightness = 0.16 - 0.06 * anim.hover
    love.graphics.setColor(brightness + 0.1, brightness, brightness, 0.95)
    love.graphics.rectangle("fill", close.x, close.y, close.width, close.height, 8)

    drawCentered("X", ccx, close.y + (close.height - uiFonts.button:getHeight()) / 2, uiFonts.button, close.width)

    love.graphics.pop()
end

local function drawUpgradesButton()
    local b = getUpgradesButtonRect()
    local icon = getUpgradesIcon()
    local uiFonts = getFonts()

    drawButtonBody(b, function(animation)
        local brightness = 1 - BUTTON_HOVER_BRIGHTNESS + BUTTON_HOVER_BRIGHTNESS * animation.hover

        love.graphics.setColor(0.05, 0.05, 0.07, 0.75)
        love.graphics.rectangle("fill", b.x, b.y, b.width, b.height, 14)

        if icon then
            love.graphics.setColor(brightness, brightness, brightness, 1)
            love.graphics.draw(
                icon.image,
                math.floor(b.x + (b.width - icon.width) / 2),
                math.floor(b.y + (b.height - icon.height) / 2),
                0, icon.scale, icon.scale
            )
        else
            drawCentered(
                "Upgrades",
                b.x + b.width / 2,
                b.y + (b.height - uiFonts.button:getHeight()) / 2,
                uiFonts.button,
                b.width - 8
            )
        end
    end)
end

function drawGame()
    local width, height = love.graphics.getDimensions()

    local bg = getBackground()
    if bg then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(bg, 0, 0, 0, width / bg:getWidth(), height / bg:getHeight())

        love.graphics.setColor(0, 0, 0, BG_TINT_ALPHA)
        love.graphics.rectangle("fill", 0, 0, width, height)
    end

    local uiFonts = getFonts()
    local logoImage = getLogo()
    local ox, oy = uiOffset()
    local left, top, right = getUIBounds()
    local centerX = (left + right) / 2
    local statsTop = clickb.y - STATS_OFFSET
    local statsMaxWidth = width - STATS_SIDE_MARGIN * 2

    love.graphics.push()
    love.graphics.translate(ox, oy)

    if logoImage then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            logoImage.image,
            math.floor(centerX - logoImage.width / 2),
            statsTop - LOGO_GAP - logoImage.height,
            0, logoImage.scale, logoImage.scale
        )
    end

    drawCentered("Clicks: " .. formatNumber(clicks), centerX, statsTop, uiFonts.stats, statsMaxWidth)
    drawCentered("Click power: " .. formatNumber(clickValue()), centerX, statsTop + STATS_LINE_HEIGHT, uiFonts.stats, statsMaxWidth)

    drawButtonBody(clickb, function(animation)
        local brightness = 1 - BUTTON_HOVER_BRIGHTNESS + BUTTON_HOVER_BRIGHTNESS * animation.hover

        love.graphics.setColor(brightness, brightness, brightness)
        love.graphics.rectangle("fill", clickb.x, clickb.y, clickb.width, clickb.height, 12)

        drawCentered(
            clickb.text,
            clickb.x + clickb.width / 2,
            clickb.y + (clickb.height - uiFonts.click:getHeight()) / 2,
            uiFonts.click,
            clickb.width - 12
        )
    end)

    if comboCount >= 2 then
        drawCentered(
            "Combo x" .. string.format("%.2f", comboMultiplier()) .. "  (" .. comboCount .. ")",
            centerX,
            clickb.y + clickb.height + 12,
            uiFonts.click,
            statsMaxWidth,
            { 1, 0.85, 0.3 },
            1 + comboPulse * 0.25
        )
    end

    love.graphics.pop()

    drawParticles()

    if upgradesOpen then
        drawUpgradesPanel()
    end

    drawUpgradesButton()
end
