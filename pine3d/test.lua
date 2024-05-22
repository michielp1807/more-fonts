local mf = require(".morefonts")
local mfpe = require("morefonts-pe")
local betterblittle = require("betterblittle")

-- Unit tests to verify that mfpe and mf produce the same results

local textColor, backgroundColor = colors.white, colors.black
local cursorX, cursorY = 1, 1
local textBuffer, fgBuffer, bgBuffer = {}, {}, {}
local width, height = term.getSize()
local textStr, fgStr, bgStr = "", "", ""
for _ = 1, width do
    textStr = textStr .. " "
    fgStr = fgStr .. "f" -- black
    bgStr = bgStr .. "f"
end

local fakeWindow = {
    getTextColor = function() return textColor end,
    setTextColor = function(color) textColor = color end,
    getBackgroundColor = function() return backgroundColor end,
    setBackgroundColor = function(color) backgroundColor = color end,
    getCursorPos = function() return cursorX, cursorY end,
    setCursorPos = function(x, y) cursorX, cursorY = x, y end,
    getSize = function() return width, height end
}

---Reset the fake window parameters and buffers
function fakeWindow.reset()
    textColor, backgroundColor = colors.white, colors.black
    cursorX, cursorY = 1, 1
    textBuffer, fgBuffer, bgBuffer = {}, {}, {}
    for i = 1, height do
        textBuffer[i] = textStr
        fgBuffer[i] = fgStr
        bgBuffer[i] = bgStr
    end
end

---Redirect.blit
---@param text string
---@param textColor string
---@param backgroundColor string
function fakeWindow.blit(text, textColor, backgroundColor)
    if #text ~= #textColor or #textColor ~= #backgroundColor then
        error("Arguments must be the same length")
    end

    if cursorY < 1 or cursorY > height then return end

    local function updateBuffer(buffer, newData)
        local prev = buffer[cursorY]
        newData = newData:sub(math.max(2 - cursorX, 0)) -- cutoff newData if out of screen on left side
        newData = prev:sub(0, math.max(cursorX - 1, 0)) .. newData .. prev:sub(math.max(cursorX, 1) + #newData)
        buffer[cursorY] = newData:sub(0, width)         -- cutoff buffer if out of screen on right side
    end

    text = text:gsub("\128", " ") -- replace empty space by real space (betterblittle may use both mixed)
    updateBuffer(textBuffer, text)

    for i = 1, #text do
        if text:sub(i, i) == " " then
            -- foreground color does not, matter so set foreground equal to background color
            textColor = textColor:sub(1, i - 1) .. backgroundColor:sub(i, i) .. textColor:sub(i + 1)
        end
    end

    updateBuffer(fgBuffer, textColor)
    updateBuffer(bgBuffer, backgroundColor)
    cursorX = cursorX + #text
end

---Show fake window in terminal
function fakeWindow:show()
    for i = 1, height do
        term.setCursorPos(1, i)
        term.blit(textBuffer[i] or "", fgBuffer[i] or "", bgBuffer[i] or "")
    end
end

---@param text string
---@param color integer the text color
---@param x? integer x position (in teletext pixels) (leave nil to center on frame buffer)
---@param y? integer y position (in teletext pixels) (leave nil to center on frame buffer)
---@param fontOptions? FontOptions
local function mfpeWriteOn(text, color, x, y, fontOptions)
    local frame = {}
    local buffer = {colorValues = {}, width = width * 2, height = height * 3, backgroundColor = backgroundColor}
    for py = 1, buffer.height do -- fill buffer with background color
        buffer.colorValues[py] = {}
        local colorsY = buffer.colorValues[py]
        for px = 1, buffer.width do colorsY[px] = backgroundColor end
    end
    frame.buffer = buffer

    if x then x = (x - 1) * 2 + 1 end
    if y then y = (y - 1) * 3 + 1 end

    mfpe.writeOn(frame, text, color, x, y, fontOptions)
    betterblittle.drawBuffer(frame.buffer.colorValues, fakeWindow)
end

---@param text string
---@param color integer the text color
---@param x? integer x position (in teletext pixels) (leave nil to center on frame buffer)
---@param y? integer y position (in teletext pixels) (leave nil to center on frame buffer)
---@param fontOptions? FontOptions
local function mfWriteOn(text, color, x, y, fontOptions)
    fakeWindow.setTextColor(color)
    mf.writeOn(fakeWindow, text, x, y, fontOptions)
end

local totalTests = 0
local passedTests = 0
local showAll = false

---@param text string
---@param color integer the text color
---@param x? integer x position (in teletext pixels) (leave nil to center on frame buffer)
---@param y? integer y position (in teletext pixels) (leave nil to center on frame buffer)
---@param fontOptions? FontOptions
---@param forceShow? boolean always show the results, event if they are the same
local function test(text, color, x, y, fontOptions, forceShow)
    totalTests = totalTests + 1

    fakeWindow.reset()
    mfWriteOn(text, color, x, y, fontOptions)
    local tb1, fb1, bb1 = textBuffer, fgBuffer, bgBuffer

    fakeWindow.reset()
    mfpeWriteOn(text, color, x, y, fontOptions)
    local tb2, fb2, bb2 = textBuffer, fgBuffer, bgBuffer

    local lines = {}
    local theSame = true
    for i = 1, height do
        if tb1[i] ~= tb2[i] or fb1[i] ~= fb2[i] or bb1[i] ~= bb2[i] then
            theSame = false
            lines[#lines + 1] = i
        end
    end

    local testLine = debug.getinfo(2).currentline
    local name = "test@" .. testLine
    if theSame then
        print(name .. " passed")
        passedTests = passedTests + 1
    end

    if not theSame or forceShow or showAll then
        -- show visual difference
        local escape = false
        local showB1 = true
        while not escape do
            term.clear()
            if showB1 then
                textBuffer, fgBuffer, bgBuffer = tb1, fb1, bb1
                fakeWindow:show()
            else
                textBuffer, fgBuffer, bgBuffer = tb2, fb2, bb2
                fakeWindow:show()
            end

            -- find empty line to print debug info on
            for i = 1, height do
                if textBuffer[i] == textStr then
                    term.setTextColor(theSame and colors.lime or colors.red)
                    term.setCursorPos(1, i)
                    term.write(name)
                    term.setTextColor(colors.white)
                    term.write(" - " .. (showB1 and "classic" or "Pine3D"))
                    break
                end
            end

            local event, key, is_held = os.pullEvent("key")
            if key == keys.grave then
                escape = true
                os.pullEvent("char") -- otherwise it puts a '`' in the terminal after exiting the program
                term.clear()
                term.setTextColor(colors.white)
                term.setCursorPos(1, 1)
            else
                showB1 = not showB1
            end
        end
    end
end

-- test basic positioning
test("testing", colors.red, nil, nil, nil)
test("testing", colors.red, 1, 1, nil)
test("testing", colors.red, -1, nil, nil)
test("testing", colors.red, nil, -1, nil)
test("testing", colors.red, -5, -5, nil)
test("testing", colors.red, width, height, nil)
test("testing", colors.red, width + 5, height + 5, nil)
test("testing", colors.red, nil, nil, {dx = 5, dy = 4})
test("testing", colors.red, nil, nil, {dx = -5})
test("testing", colors.red, nil, nil, {dy = -4})

-- test advanced positioning with anchor points and text alignment
test("testing", colors.blue, nil, nil, {textAlign = "left"})
test("testing", colors.blue, nil, nil, {textAlign = "right"})
test("testing", colors.blue, nil, nil, {anchorHor = "left", anchorVer = "top"})
test("testing", colors.blue, nil, nil, {anchorHor = "right", anchorVer = "bottom"})
test("testing", colors.blue, width, 1, {textAlign = "right"})
test("testing", colors.blue, width, height, {anchorHor = "right", anchorVer = "bottom"})

-- test long text running off screen
test("long text running off screen", colors.purple, nil, nil)
test("long text running off screen", colors.purple, nil, nil, {condense = true})
test("long text running off screen", colors.purple, nil, nil, {textAlign = "left"})
test("long text running off screen", colors.purple, nil, nil, {textAlign = "right"})
test("long text running off screen", colors.purple, nil, nil, {anchorHor = "left", anchorVer = "top"})
test("long text running off screen", colors.purple, nil, nil, {anchorHor = "right", anchorVer = "bottom"})

-- test scale
test("big!", colors.lime, nil, nil, {scale = 2})
test("big!", colors.lime, nil, nil, {scale = 3})
test("smol??", colors.lime, nil, nil, {scale = 0.5})
test("little big", colors.lime, nil, nil, {scale = 1.5})
test("little big", colors.lime, nil, nil, {scale = 1.5, textAlign = "left"})
test("big!", colors.lime, nil, nil, {scale = 2, condense = true})
test("little big", colors.lime, nil, nil, {scale = 1.5, condense = true})

-- test multiple words and new lines
test("haha yes!", colors.pink, nil, nil, nil)
test("haha\nyes", colors.pink, nil, nil, nil)
test("haha\nyes", colors.pink, nil, nil, {textAlign = "left"})
test("haha\nyes", colors.pink, nil, nil, {textAlign = "right"})
test("haha\nyes", colors.pink, nil, nil, {anchorHor = "left", anchorVer = "top"})
test("haha\nyes", colors.pink, nil, nil, {anchorHor = "right", anchorVer = "bottom"})

-- test condensed text
test("Hi! :)", colors.yellow, nil, nil, {condense = true})
test("Hi! :)", colors.yellow, nil, nil, {condense = true, textAlign = "left"})
test("Hi! :)", colors.yellow, nil, nil, {condense = true, textAlign = "right"})
test("Hi! :)", colors.yellow, nil, nil, {condense = true, anchorHor = "left", anchorVer = "top"})
test("Hi! :)", colors.yellow, nil, nil, {condense = true, anchorHor = "right", anchorVer = "bottom"})
test("Hi! :)", colors.yellow, nil, nil, {condense = true, sepWidth = 3})
test("Hi! :)", colors.yellow, nil, nil, {condense = true, spaceWidth = 7})

-- test text wrapping
test("Hey there! Hello, world. How are you? What's up?", colors.orange, nil, nil, {wrapWidth = 60})
test("Hey there! Hello, world. How are you? What's up?", colors.orange, nil, nil, {wrapWidth = 60, condense = true})
test("Hey there! Hello, world. How are you? What's up?", colors.orange, nil, nil, {wrapWidth = 60, textAlign = "left"})
test("Hey there! Hello, world. How are you? What's up?", colors.orange, nil, nil, {wrapWidth = 60, condense = true, textAlign = "left"})
-- TODO: these three test also fail, likely because of build up in rounding error vertically
test("Hey there! Hello, world. How are you? What's up?", colors.orange, nil, nil, {wrapWidth = 60, condense = true, lineSepHeight = 4})
test("Hey there! Hello, world. How are you? What's up?", colors.orange, nil, nil, {wrapWidth = 60, condense = true, spaceWidth = 3})
test("Hey there! Hello, world. How are you? What's up?", colors.orange, nil, nil, {wrapWidth = 60, condense = true, sepWidth = 5})

-- test using fonts
test("testing", colors.cyan, nil, nil, {font = "fonts/PixelPlace"})
test("testing", colors.cyan, 1, 1, {font = "fonts/PublicPixel"})
test("testing", colors.cyan, nil, nil, {font = "fonts/QuinqueFive", anchorHor = "right", anchorVer = "bottom"})
test("testing", colors.cyan, nil, nil, {font = "fonts/Scientifica", scale = 2})
test("testing", colors.cyan, nil, nil, {font = "fonts/Scientifica-Italic", scale = 1.5})
test("testing", colors.cyan, nil, nil, {font = "fonts/Silkscreen", condense = true})
test("testing testing testing testing testing testing", colors.cyan, 2, 2, {font = "fonts/Times9k", wrapWidth = 60, condense = true})

print("Passed " .. passedTests .. " out of " .. totalTests .. " tests (" .. (passedTests / totalTests * 100) .. "%)")
