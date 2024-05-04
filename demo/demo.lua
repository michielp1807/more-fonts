local mf = require(".morefonts")
local blittle = require("betterblittle")
local Pine3D = require("Pine3D")
local nbsTunes = require("nbsTunes")

local introMusic = nbsTunes.load("/demo/20th-century-fox.nbs")
local mainMusic = nbsTunes.load("/demo/star-wars-intro.nbs")

term.clear()
local TERM_WIDTH, TERM_HEIGHT = term.getSize()

local BLACK = 0.0667

mf.setDefaultFontOptions({condense = true})

---Fade palette colors to black
---@param duration number
---@param reverse? boolean
local function fadeToBlack(duration, reverse)
    local startTime = os.clock()

    while true do
        local fadeProgress = math.min((os.clock() - startTime) / duration, 1) -- 0 to 1
        local fadeAmount = reverse and fadeProgress or (1 - fadeProgress)
        for i = 1, 16 do
            local c = 2 ^ (i - 1)
            local r, g, b = term.nativePaletteColor(c)
            term.setPaletteColor(c,
                (r - BLACK) * fadeAmount + BLACK,
                (g - BLACK) * fadeAmount + BLACK,
                (b - BLACK) * fadeAmount + BLACK)
        end
        if fadeProgress == 1 then return end
        os.queueEvent("fade")
        ---@diagnostic disable-next-line: param-type-mismatch
        os.pullEventRaw("fade")
    end
end

---Set all palette colors to black
local function allBlack()
    for i = 1, 16 do
        term.setPaletteColor(2 ^ (i - 1), BLACK, BLACK, BLACK)
    end
end

---Reset all palette colors to their default values
local function resetColors()
    for i = 1, 16 do
        local c = 2 ^ (i - 1)
        local r, g, b = term.nativePaletteColor(c)
        term.setPaletteColor(c, r, g, b)
    end
end

local function playIntroMusic()
    introMusic:play()
end

local frame = Pine3D.newFrame()
frame:setCamera(-11, 0, -20, 0, 60, 10)
frame:setFoV(50)
frame:setBackgroundColor(colors.blue)
local function createLightBeam(x, y, z, color)
    return frame:newObject({{
        x1 = 0,
        y1 = 0,
        z1 = 0,
        x2 = -1.522306,
        y2 = 21.932735,
        z2 = 0.878904,
        x3 = 1.522306,
        y3 = 21.932735,
        z3 = -0.878904,
        c = color or colors.yellow
    }}, x, y, z)
end
local lightBeams = {
    createLightBeam(6, -2.5, -5),
    createLightBeam(-7, -2.5, -5),
    createLightBeam(7, -2.5, 5, colors.orange),
    createLightBeam(-7, -2.5, 5, colors.orange),
}
local objects = {
    frame:newObject("demo/cc-intro.stab", 0, 0, 0),
    frame:newObject({{ -- light blue background
        x1 = 0,
        y1 = -40,
        z1 = 100,
        x2 = -100,
        y2 = 8,
        z2 = 100,
        x3 = 100,
        y3 = 8,
        z3 = 100,
        c = colors.lightBlue
    }}, nil, nil, nil, 0, math.rad(30)),
    frame:newObject(Pine3D.models:mountains({
        color = colors.lightGray,
        y = -10,
        res = 12,
        scale = 100,
        randomHeight = 0.5,
        randomOffset = 0.5,
        snow = 0.5,
        snowHeight = 0.6,
    })),
    frame:newObject(Pine3D.models:mountains({
        color = colors.brown,
        y = -10,
        res = 18,
        scale = 75,
        randomHeight = 0.5,
        randomOffset = 0.25,
    })),
    frame:newObject(Pine3D.models:plane({
        color = colors.gray,
        size = 200,
        y = -12,
    }))
}
for i = 1, #lightBeams do
    objects[#objects + 1] = lightBeams[i]
end

local function renderIntro()
    -- Black screen
    term.blit("PleaseDontFlash!", "0123456789ABCDEF", "123456789ABCDEF0")
    allBlack()
    term.blit("PleaseDontFlash!", "0123456789ABCDEF", "123456789ABCDEF0")
    sleep(2)

    -- CC Intro
    frame:drawObjects(objects)
    frame:drawBuffer()
    local startTime = os.clock()
    local timeSinceStart = 0
    while timeSinceStart < 8 do
        timeSinceStart = os.clock() - startTime

        local fadeAmount = 1
        if timeSinceStart < 2 then fadeAmount = timeSinceStart / 2 end
        if timeSinceStart > 6 then fadeAmount = 1 - (timeSinceStart - 6) / 2 end
        fadeAmount = math.min(math.max(fadeAmount, 0), 1)
        for i = 1, 16 do
            local c = 2 ^ (i - 1)
            local r, g, b = term.nativePaletteColor(c)
            frame.buffer.blittleWindow.setPaletteColor(c,
                (r - BLACK) * fadeAmount + BLACK,
                (g - BLACK) * fadeAmount + BLACK,
                (b - BLACK) * fadeAmount + BLACK)
        end

        -- Animate light beams
        for i = 1, #lightBeams do
            lightBeams[i]:setRot(0, 0, math.rad(15 * math.sin(timeSinceStart + math.pi * 0.25 * i)))
        end

        frame:drawObjects(objects)
        frame:drawBuffer()

        os.queueEvent("render-pls")
        ---@diagnostic disable-next-line: param-type-mismatch
        os.pullEvent("render-pls")
    end

    -- A MICHIEL Project
    allBlack()
    term.clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.green)
    mf.writeOn(term, "A", nil, nil, {dy = -14})
    mf.writeOn(term, "MICHIEL", nil, nil, {font = "fonts/hdfont", dy = 1})
    mf.writeOn(term, "Project", nil, nil, {dy = 15})
    fadeToBlack(1, true)
    sleep(5)
    fadeToBlack(1)
end

parallel.waitForAll(playIntroMusic, renderIntro)
sleep(1)
term.clear()

-- A long time ago in a galaxy far, far away...
allBlack()
term.setTextColor(colors.blue)
mf.writeOn(term, "A long time ago in a galaxy far, far away", nil, nil,
    {font = "fonts/PixelPlace", textAlign = "left", anchorHor = "center", wrapWidth = TERM_WIDTH * 2 - 13})
fadeToBlack(1, true)
sleep(4)
fadeToBlack(1)
term.clear()
resetColors()
sleep(1)

local function playMainMusic()
    mainMusic:play()
end

local function renderMain()
    -- Main logo
    local window = window.create(term.current(), 1, 1, TERM_WIDTH, TERM_HEIGHT, false)
    window.setTextColor(colors.yellow)
    local scale = 5
    local lastTime = os.clock()
    while scale > 1 do
        local newTime = os.clock()
        local dt = newTime - lastTime
        lastTime = newTime
        window.clear()
        scale = math.max(scale - scale * 0.5 * dt, 1)
        mf.writeOn(window, "MORE", nil, nil, {font = "fonts/hdfont-outline", dy = -10 * scale + 2, scale = scale})
        mf.writeOn(window, "FONTS", nil, nil, {font = "fonts/hdfont-outline", dy = 10 * scale + 2, scale = scale})

        window.setVisible(true) -- prevent flashing
        window.setVisible(false)
        os.queueEvent("render-pls")
        ---@diagnostic disable-next-line: param-type-mismatch
        os.pullEvent("render-pls")
    end
    sleep(1)

    -- Text scroll
    mf.setDefaultFontOptions({
        condense = true,
        font = "fonts/PixelPlace",
        textAlign = "left",
        anchorHor = "center",
        anchorVer = "top",
        wrapWidth = math.min(TERM_WIDTH * 2 - 20, 51 * 2 + 10)
    })
    local dy = 0
    lastTime = os.clock()
    while true do
        local newTime = os.clock()
        local dt = newTime - lastTime
        lastTime = newTime
        dy = dy + 6 * dt
        window.clear()

        mf.writeOn(window, "MORE", nil, nil,
            {font = "fonts/hdfont-outline", dy = -8 - dy, scale = scale, textAlign = "center", anchorVer = "center"})
        mf.writeOn(window, "FONTS", nil, nil,
            {font = "fonts/hdfont-outline", dy = 12 - dy, scale = scale, textAlign = "center", anchorVer = "center"})

        local y = math.floor(TERM_HEIGHT * 1.5) - 1
        local w, h
        w, h = mf.writeOn(window, "In the beginning there was Bigfont, a great library to write big text in ComputerCraft.", nil, nil,
            {dy = y - dy})
        y = y + h + 5
        w, h = mf.writeOn(window, "However, Bigfont only has a few font sizes and only 1 font...", nil, nil,
            {dy = y - dy})
        y = y + h + 5
        w, h = mf.writeOn(window, "With MORE FONTS, you have more font sizes, improved alignment, and most importantly...", nil, nil,
            {dy = y - dy})
        y = y + h + 2
        w, h = mf.writeOn(window, "MORE FONTS!", nil, nil,
            {dy = y - dy, textAlign = "center", font = "fonts/PixeloidSans-Bold"})
        y = y + h + 2
        w, h = mf.writeOn(window,
            "This text is displayed in the \"PixelPlace\" font, a compact font that I drew myself.",
            nil, nil, {dy = y - dy})
        y = y + h + 5
        w, h = mf.writeOn(window,
            "Some other fonts were converted from TTF or OTF formats (licensing information is included with the fonts)",
            nil, nil, {dy = y - dy})
        y = y + h + 5
        w, h = mf.writeOn(window,
            "Thanks for watching, and let me know if you create anything cool with this library! :D",
            nil, nil, {dy = y - dy})

        window.setVisible(true) -- prevent flashing
        window.setVisible(false)
        os.queueEvent("render-pls")
        ---@diagnostic disable-next-line: param-type-mismatch
        os.pullEvent("render-pls")
    end
end

parallel.waitForAny(playMainMusic, renderMain)

-- Outro
local pinestore_logo = paintutils.loadImage("demo/pinestore-logo.nfp")
local logo_window = window.create(term.current(), math.floor(TERM_WIDTH / 2 - 18), math.floor(TERM_HEIGHT / 2 - 2), 9, 7)
term.clear()
blittle.drawBuffer(pinestore_logo, logo_window)

term.setTextColor(colors.white)
mf.setDefaultFontOptions({condense = true})
mf.writeOn(term, "PineStore", nil, nil, {font = "fonts/PixeloidSans-Bold", dx = 10, dy = 4})
mf.writeOn(term, "GET IT ON", nil, nil, {font = "fonts/PixelPlace", dx = -3, dy = -5})

sleep(5)
term.setCursorPos(1, TERM_HEIGHT)
