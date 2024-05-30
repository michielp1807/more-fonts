-- More Fonts - Pine3D Edition
--
-- Changes compared to normal More Fonts
--  - Writes to pixel buffer such that it can be used by Pine3D
--  - Only has `writeOn`, no `print` or `write`
--  - `writeOn`'s x and y coordinates are in teletext pixels, not screen pixels'
--  - Does not fill background colors
--  - The text color is passed as an argument instead of using `term.getTextColor()`
--  - `drawTextOneLine` no longer returns last char row, as this is not needed when using a buffer

local expect = require("cc.expect")
local mf = {}                 -- exported table

local MAX_PIXELS_PER_CHAR = 6 -- for decoding font data
local DATA_START = 0x20       -- start of encoded charactes

-- Font data, exported via convert.py
---@class Font (generated with convert.py)
---@field data string encoded pixel information
---@field startX string position of the first column with pixels of every character
---@field lengthX string number of columns every character is wide
---@field charW integer max width of a character
---@field charH integer max height of a character
---@field sepWidth? integer number of empty pixels between characters horizontally when condensed
---@field spaceWidth? integer width of the space character when condensed
---@field lineSepHeight? integer additional spacing between lines vertically
---@field fontname? string
---@field author? string
---@field source? string
---@field license? string
---@field copyright? string
mf.ccfont = {
    data =
    [[         .1;151.  .?5?1;.   *???.$   $.?.$   $.$??$.   $.??$.    ,>>,   __SAAS__                    <86))&  .111.$.$           >2>"##   ^B^BSS   !'?'!    0<?<0   $.?$$?.$ 22222 2  >556444  >#-168/       >>  $.?$?.$? $.?$$$$  $$$$?.$   $,?,$    $&?&$       !!?    2_2     $$..?    ?..$$            $$$$$ $  44*      **?*?**  $>!.0/$  1)($"21  $*$6-)6  (($      8$"""$8  &(000(&    2,2     $$?$$        $$$    ?          $$  0(($""!  .19531.  $&$$$$?  .10,"1?  .10,01.  8421?00  ?!/001.  ,"!/11.  ?10($$$  .11.11.  .11>0(&   $$  $$   $$  $$$ 0($"$(0    ?  ?   "$(0($"  .10($ $  >AMM]!>  .1?1111  /1/111/  .1!!!1.  /11111/  ?!'!!!?  ?!'!!!!  >!9111.  11?1111  .$$$$$.  000001.  1)')111  !!!!!!?  1;51111  1359111  .11111.  /1/!!!!  .1111)6  /1/1111  >!.001.  ?$$$$$$  111111.  1111**$  11115;1  1*$*111  1*$$$$$  ?0($"!?  .""""".  !""$((0  .(((((.  $*1             ? $$(        .0>1>  !!-311/    .1!1.  006911>    .1?!>  8$>$$$$    >11>0/ !!-3111  $ $$$$$  0 00011. ""2*&*2  $$$$$$(    +5511    /1111    .111.    -31/!!   691>00   -3!!!    >!.0/  $$.$$$(    1111>    111*$    1155>    1*$*1    111>0/   ?($"?  8$$"$$8  $$$$$$$  &((0((&  F9       2)D2)D2)D         '''      XXX      ___         '''   ''''''   XXX'''   ___'''      XXX   '''XXX   XXXXXX   ___XXX      ___   '''___   XXX___   ______         ''''''   '''XXX   '''___   '''   '''''''''''''''XXX''''''___''''''   XXX''''''XXX'''XXXXXX'''___XXX'''   ___''''''___'''XXX___'''______'''         $ $$$$$   $.1!1.$ ,2"/""?   1.111.1 1*?$?$$  $$$ $$$  >#-168/  *         >IEEI>  &(.).      4*%*4     ?00      ?      >MMUA>  ?        &))&      $$?$$ ? !"#!#    #"#"#    "!         1111O!!>556444     ,,          ($ "#""'     .111.     %*4*%  1)($::1  1)($2*9  3*+$::1  $ $"!1.  # .1?11  8 .1?11  .1.1?11  *%.1?11  * .1?11  $ .1?11  >%%/%%=  .1!!1.($ # ?!/!?  8 ?!/!?  .1?!/!?  * ?!/!?  & .$$$.  , .$$$.  $*.$$$.  * .$$$.  /11311/  4*13591  #.1111.  8.1111.  .1.111.  *%.111.  *.1111.   1*$*1   .19531.  # 1111.  8 1111.  $* 111.  * 1111.  8 1*$$$  .$,4,$.  /1-111-! # .0>1>  8 .0>1>  .1.0>1>  *%.0>1>  * .0>1>  $ .0>1>    :E?%Z   .1!1.($ # .1?!>  8 .1?!>  .1.1?!>  * .1?!>  & $$$$$  , $$$$$  $*$$$$$  * $$$$$  $(>111.  *%/1111  # .111.  8 .111.  .1.111.  *%.111.  * .111.   $ ? $     .953.  # 1111>  8 1111>  $* 111>  * 1111>  8 111>0/ &$,4,$.  * 111>0/ ]],
    startX =
    [['!!!!!!"!''!!'!!!!!"!!"!!!!!!!!!'#"!!!!#"""!#!#!!!!!!!!!!!##"!"!!!!!!!!!!"!!!!!!!!!!!!!!!!!"!"!!#!!!!!"!!#!"#!!!!!!!"!!!!!!"#"!!'!$!!!!!$!$!!!!!!!!!!!!!!!!!!!!!'#!!!!#!"!!!!!!!!!!!!!!##!!!!!!!!!!!!!!!!!!!""""!!!!!!!!!!!!!!"!!!!!!!!!!!!!"#""!!!!!!!!!!!!!!"!]],
    lengthX =
    [[ %%%%%%$&  %% %&%%%$%%$%%%%%%&%% !$%%%%"$$$%!%!%%%%%%%%%%%!!$%$%&%%%%%%%%#%%%%%%%%%%%%%%%%%#%#%%"%%%%%$%%!%$"%%%%%%%#%%%%%%$!$&& ##&##&&#&#&&&&&##&&##&&&&&&&&&& !%%%%!%#&$%%%&%$%"""&%""#%%%%%%%%%%%%%%%%%%####%%%%%%%%%%%%%%$%%%%%%%&%%%%%""##%%%%%%%%%%%%%%$%]],
    charW = 6,
    charH = 9
}

---@class FontOptions
---@field font? Font | string the font to use or filename of font to load
---@field dx? integer horizontal text offset (in teletext pixels)
---@field dy? integer vertical text offset (in teletext pixels)
---@field scale? integer font scale (scaling will look weird with non-integer values)
---@field wrapWidth? integer | "nowrap" line width (in teletext pixels)
---@field condense? boolean if true, whitespace between characters will be condensed
---@field endOnNewLine? boolean if true, it will end on a new line (always the case when using print, might scroll if at bottom of terminal)
---@field sepWidth? integer number of empty pixels between characters horizontally when condensed
---@field spaceWidth? integer width of the space character when condensed
---@field lineSepHeight? integer additional spacing between lines vertically
---@field textAlign? "left" | "center" | "right" horizontal text alignment
---@field anchorHor? "left" | "center" | "right" horizontal anchor alignment
---@field anchorVer? "top" | "center" | "bottom" vertical anchor alignment

---@type FontOptions
local defaultOptions = {} -- default user font options
---@param fontOptions FontOptions
mf.setDefaultFontOptions = function(fontOptions)
    expect(1, fontOptions, "table")
    defaultOptions = fontOptions
end

---@param fontPath string
---@return Font
mf.loadFont = function(fontPath)
    expect(1, fontPath, "string")
    if not fs.exists(fontPath) then -- try download font from GitHub
        local fontName = fontPath:match("([^\\/]-)$")
        local fontURL = "https://raw.githubusercontent.com/MichielP1807/more-fonts/main/fonts/" .. fontName
        local res = http.get(fontURL)
        if not res then error("Could not find font \"" .. fontName .. "\" locally, or on GitHub...") end
        local data = res.readAll()
        res.close()
        local file = fs.open(fontPath, "w")
        if not file then error("Can't write to file " .. fontPath .. "...") end
        file.write(data)
        file.close()
    end
    local file, err = fs.open(fontPath, "r")
    if not file then error("Can't open font " .. fontPath .. (err and (": " .. err) or "")) end
    local str = file.readAll()
    file.close()
    if not str or #str < 1 then error("Can't read font " .. fontPath .. ": file is empty") end
    local fontData = textutils.unserialise(str)
    if not fontData then error("Can't unserialise font " .. fontPath .. ": is the file corrupt?") end
    if type(fontData) ~= "table" then error("Can't load font " .. fontPath .. ": file does not contain a table") end
    if not fontData.data or not fontData.startX or not fontData.lengthX or not fontData.charW or not fontData.charH then
        error("Can't load font " .. fontPath .. ": font is missing essential properties")
    end
    return fontData
end

---@type { [string]: Font }
local loaded_fonts = {}

---@param fontOptions FontOptions
---@param x? number x position (in terminal screen pixels) (if nil, text will be centered by default)
---@param y? number y position (in terminal screen pixels) (if nil, text will be centered by default)
---@return NonPartialFontOptions nonPartialFontOptions
local function fontOptionsFillDefaults(fontOptions, x, y)
    local font = fontOptions.font or defaultOptions.font
    if type(font) == "string" then ---@cast font string
        if not loaded_fonts[font] then loaded_fonts[font] = mf.loadFont(font) end
        font = loaded_fonts[font]
    end

    local condense = fontOptions.condense == nil and defaultOptions.condense or fontOptions.condense

    ---@cast font Font?
    ---@class NonPartialFont: Font
    local npFont = font or mf.ccfont
    local eWidth = string.byte(npFont.lengthX, 102) - DATA_START -- width of 'e' character
    npFont.sepWidth = fontOptions.sepWidth or defaultOptions.sepWidth or npFont.sepWidth or math.max(math.floor(npFont.charW / 6), 1)
    npFont.spaceWidth = fontOptions.spaceWidth or defaultOptions.spaceWidth or npFont.spaceWidth or (condense and eWidth or npFont.charW)
    npFont.lineSepHeight = fontOptions.lineSepHeight or defaultOptions.lineSepHeight or npFont.lineSepHeight or 0

    ---@class NonPartialFontOptions: FontOptions
    ---@field dx integer -- horizontal text offset (in teletext pixels)
    ---@field dy integer -- vertical text offset (in teletext pixels)
    local nonPartialFontOptions = {
        font = npFont,
        dx = fontOptions.dx or defaultOptions.dx or 0,
        dy = fontOptions.dy or defaultOptions.dy or 0,
        scale = fontOptions.scale or defaultOptions.scale or 1,
        wrapWidth = fontOptions.wrapWidth or defaultOptions.wrapWidth or "nowrap",
        condense = condense,
        endOnNewLine = fontOptions.endOnNewLine == nil and defaultOptions.endOnNewLine or fontOptions.endOnNewLine,
        textAlign = fontOptions.textAlign or defaultOptions.textAlign or (x and "left" or "center"),
        anchorHor = fontOptions.anchorHor or defaultOptions.anchorHor or (fontOptions.textAlign or (x and "left" or "center")),
        anchorVer = fontOptions.anchorVer or defaultOptions.anchorVer or (y and "top" or "center"),
    }

    if nonPartialFontOptions.scale <= 0 or nonPartialFontOptions.scale > 1000 then
        error("Font scale must be between 1 and 1000")
    end

    return nonPartialFontOptions
end

---Calculate text width and height in teletext pixels
---@param text string
---@param fontOptions NonPartialFontOptions
---@return integer width (in teletext pixels)
---@return integer height (in teletext pixels)
---@return string[] lines the text to print on everyline (based on newlines and automatic wrapping)
---@return integer[] lineWidths the width of every individual line (in teletext pixels)
local function calculateTextSize(text, fontOptions)
    local font = fontOptions.font
    local wrapWidth = fontOptions.wrapWidth
    local lineHeight = (font.charH + font.lineSepHeight) * fontOptions.scale
    local maxWidth = 0

    local lines = {}
    local lineWidths = {}

    ---Calculate width of a single line in teletext pixels
    ---@param line string
    ---@return integer width (in teletext pixels)
    local function calculateLineWidth(line)
        local font = fontOptions.font
        if fontOptions.condense then
            local byte = string.byte
            local width = 0
            local needCharSep = false
            for i = 1, #line do
                local currentChar = byte(line, i)
                local charWidth = byte(font.lengthX, currentChar + 1) - DATA_START
                if charWidth == 0 then -- empty space character
                    width = width + font.spaceWidth
                    needCharSep = false
                else
                    width = width + charWidth + (needCharSep and font.sepWidth or 0)
                    needCharSep = true
                end
            end
            return width * fontOptions.scale
        else
            return #line * math.ceil(font.charW * fontOptions.scale)
        end
    end

    if wrapWidth ~= "nowrap" then ---@cast wrapWidth integer
        maxWidth = wrapWidth
        local line = {}
        local lineWidth = 0
        local spaceBeforeNextWord = ""
        local function newLine()
            lines[#lines + 1] = table.concat(line)
            lineWidths[#lineWidths + 1] = lineWidth
            -- maxWidth = math.max(maxWidth, lineWidth)
            line = {}
            lineWidth = 0
            spaceBeforeNextWord = ""
        end
        local spaceWidth = font.spaceWidth

        -- Based on https://github.com/cc-tweaked/CC-Tweaked/blob/6656da58770887a30fc2617ceb236d3dadfc21c4/projects/core/src/main/resources/data/computercraft/lua/bios.lua#L105
        local sub = string.sub
        while #text > 0 do
            local whitespace = string.match(text, "^[ \t]+")
            if whitespace then
                text = sub(text, #whitespace + 1)
                spaceBeforeNextWord = whitespace
            end

            local newline = string.match(text, "^\n")
            if newline then
                text = sub(text, 2)
                newLine()
            end

            local word = string.match(text, "^[^ \t\n]+")
            if word then
                text = sub(text, #word + 1)
                local wordWidth = calculateLineWidth(word)
                while wordWidth > wrapWidth do
                    -- Print a multiline word
                    local wordPart = ""
                    local wordPartWidth = 0
                    -- TODO: this could be better optimized a whole lot
                    while lineWidth + #spaceBeforeNextWord * spaceWidth + wordPartWidth < wrapWidth and #wordPart < #word do
                        wordPart = sub(word, 1, #wordPart + 1)
                        wordPartWidth = calculateLineWidth(wordPart)
                    end
                    -- wordPart is one character too long to fit, shorten by 1 character
                    if lineWidth + #spaceBeforeNextWord * spaceWidth + wordPartWidth > wrapWidth then
                        if #wordPart <= 1 then
                            wordPart = ""
                            wordPartWidth = 0
                        else
                            wordPart = sub(word, 1, #wordPart - 1)
                            wordPartWidth = calculateLineWidth(wordPart)
                        end
                    end

                    if wordPartWidth > 0 then
                        line[#line + 1] = spaceBeforeNextWord
                        line[#line + 1] = wordPart
                        lineWidth = lineWidth + #spaceBeforeNextWord * spaceWidth + wordPartWidth
                    end
                    newLine()

                    word = sub(word, #wordPart + 1)
                    wordWidth = calculateLineWidth(word)
                end

                -- Print a word normally
                if lineWidth + #spaceBeforeNextWord * spaceWidth + wordWidth > wrapWidth then newLine() end
                line[#line + 1] = spaceBeforeNextWord
                line[#line + 1] = word
                lineWidth = lineWidth + #spaceBeforeNextWord * spaceWidth + wordWidth
            end
        end
        if #line > 0 then newLine() end
    else
        -- No automatic wrapping
        for line in string.gmatch(text .. "\n", "(.-)\n") do
            local width = calculateLineWidth(line)
            maxWidth = math.max(maxWidth, width)
            lines[#lines + 1] = line
            lineWidths[#lineWidths + 1] = width
        end
    end

    local totalHeight = math.ceil(#lines * lineHeight - font.lineSepHeight * fontOptions.scale)

    return maxWidth, totalHeight, lines, lineWidths
end

---Draw a single line of text
---@param buffer Buffer terminal to print text on
---@param text string text to print
---@param color integer the text color
---@param x number x position (in teletext pixels)
---@param y number y position (in teletext pixels)
---@param fontOptions NonPartialFontOptions to supply a custom font (e.g. hdfont)
local function drawTextOneLine(buffer, text, color, x, y, fontOptions)
    local byte = string.byte
    local ceil = math.ceil
    local floor = math.floor
    local brshift = bit.brshift
    local band = bit.band

    if #text == 0 then return end

    local font = fontOptions.font
    local BUFFER_WIDTH, BUFFER_HEIGHT = buffer.width, buffer.height

    local sCHAR_HEIGHT = font.charH
    local sFONT_DATA = font.data
    local BYTES_PER_ROW = ceil(font.charW / MAX_PIXELS_PER_CHAR)

    ---Get the pixel data for a specific row of a character
    ---@param c integer character code
    ---@param y integer which row to get (starting at 1)
    ---@return table pixel data (1s and 0s)
    local function getRowData(c, y)
        if y < 1 or y > sCHAR_HEIGHT then return {} end
        local rowPixels = {nil, nil, nil, nil, nil, nil}
        local rowStartIndex = (c * sCHAR_HEIGHT + y - 1) * BYTES_PER_ROW
        local rowIndex = 1
        for i = 1, BYTES_PER_ROW do
            local rowData = byte(sFONT_DATA, rowStartIndex + i) - DATA_START
            for _x = 1, MAX_PIXELS_PER_CHAR do
                local pixelValue = band(rowData, 1)
                rowPixels[rowIndex] = pixelValue
                rowIndex = rowIndex + 1
                rowData = brshift(rowData, 1)
            end
        end
        return rowPixels
    end

    local isCondensed = fontOptions.condense
    local scale = fontOptions.scale

    local currentChar
    local charWidth = font.charW
    local startX = 1
    local charXoffset = 0
    local needCharSep = false

    local colorValues = buffer.colorValues
    for textIndex = 1, #text do
        -- based on `getNextCharData` of the original more fonts
        currentChar = byte(text, textIndex)
        if isCondensed then
            charWidth = byte(font.lengthX, currentChar + 1) - DATA_START
            if charWidth == 0 then -- empty space character
                charWidth = font.spaceWidth
                startX = 1
                needCharSep = false
            else
                startX = byte(font.startX, currentChar + 1) - DATA_START
                if needCharSep then -- add space for separator
                    charXoffset = charXoffset + font.sepWidth
                end
                needCharSep = true
            end
        end

        for charY = 0, sCHAR_HEIGHT - 1 do
            local rowData = getRowData(currentChar, charY + 1)
            for dx = 0, charWidth - 1 do
                if rowData[startX + dx] == 1 then
                    for py = floor(y + charY * scale), floor(y + (charY + 1) * scale) - 1 do
                        for px = floor(x + (charXoffset + dx) * scale), floor(x + (charXoffset + dx + 1) * scale) - 1 do
                            if px > 0 and py > 0 and px <= BUFFER_WIDTH and py <= BUFFER_HEIGHT then
                                colorValues[py][px] = color
                            end
                        end
                    end
                end
            end
        end

        charXoffset = charXoffset + charWidth
    end
end

---Draw multi-line text (does not automatically wrap (yet?), but uses newlines '\n' in input text)
---@param buffer Buffer terminal to print text on
---@param text string text to print
---@param color integer the text color
---@param x? number x position (in teletext pixels)
---@param y? number y position (in teletext pixels)
---@param fontOptions? FontOptions to supply a custom font (e.g. hdfont)
---@return integer textWidth width of multiline text (in teletext pixels)
---@return integer textHeight height of multiline text (in teletext pixels)
local function drawMultiLineText(buffer, text, color, x, y, fontOptions)
    fontOptions = fontOptionsFillDefaults(fontOptions or {}, x, y)
    local font = fontOptions.font

    local BUFFER_WIDTH, BUFFER_HEIGHT = buffer.width, buffer.height
    local TEXT_WIDTH, TEXT_HEIGHT, lines, lineWidths = calculateTextSize(text, fontOptions)

    local function alignFactor(alignment)
        if alignment == "center" then return 0.5 end
        if alignment == "right" or alignment == "bottom" then return 1 end
        return 0
    end

    local textAlignFac = alignFactor(fontOptions.textAlign)
    local anchorHorFac = alignFactor(fontOptions.anchorHor)
    local anchorVerFac = alignFactor(fontOptions.anchorVer)

    -- Center text if no coordinates provided
    x = x or (BUFFER_WIDTH * 0.5 + 1)
    y = y or (BUFFER_HEIGHT * 0.5 + 1)

    -- Offset for anchor alignment
    x = x - anchorHorFac * TEXT_WIDTH
    y = y - anchorVerFac * TEXT_HEIGHT

    -- Add dx/dy (no conversion needed, as x/y are already teletext pixels) and round
    x = x + fontOptions.dx
    y = y + fontOptions.dy
    fontOptions.dx = 0
    fontOptions.dy = 0

    local lineHeight = (font.charH + font.lineSepHeight) * fontOptions.scale
    for i = 1, #lines do
        -- Offset for horizontal alignment per line
        local xOffset = textAlignFac * (TEXT_WIDTH - lineWidths[i])
        local yOffset = (i - 1) * lineHeight

        -- Convert to teletext pixels for rounding, then convert back
        local lx = math.floor(x + xOffset + 0.5)
        local ly = math.floor(y + yOffset + 0.5)

        if ly > BUFFER_HEIGHT then break end
        if ly + math.ceil(lineHeight) >= 1 then
            drawTextOneLine(buffer, lines[i], color, lx, ly, fontOptions)
        end
    end

    return TEXT_WIDTH, TEXT_HEIGHT
end

---@param frame ThreeDFrame
---@param text string | any
---@param color integer the text color
---@param x? integer x position (in teletext pixels) (leave nil to center on frame buffer)
---@param y? integer y position (in teletext pixels) (leave nil to center on frame buffer)
---@param fontOptions? FontOptions
mf.writeOn = function(frame, text, color, x, y, fontOptions)
    expect(1, frame, "table")
    expect(1, frame.buffer, "table")
    expect(1, frame.buffer.colorValues, "table")
    expect(3, x, "number", "nil")
    expect(4, y, "number", "nil")
    expect(5, fontOptions, "table", "nil")
    return drawMultiLineText(frame.buffer, tostring(text), color, x, y, fontOptions)
end

return mf
