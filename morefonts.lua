local expect = require("cc.expect")
local mf = {} -- exported table

local colorChar = {}
for i = 1, 16 do colorChar[2 ^ (i - 1)] = ("0123456789abcdef"):sub(i, i) end

local pixelChars = {}
local char = string.char
for i = 128, 128 + 31 do pixelChars[i] = char(i) end

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
---@param term Redirect terminal to print text on
---@param text string text to print
---@param x number x position (in terminal screen pixels)
---@param y number y position (in terminal screen pixels)
---@param fontOptions NonPartialFontOptions to supply a custom font (e.g. hdfont)
---@param firstCharRow? string chars to update if line overlaps with previous line
---@param firstCharRowStart? number
---@return string? lastCharRow last row of chars drawn (should not have inverted colors if last teletext pixel row was not used)
---@return number? lastCharRowStart
local function drawTextOneLine(term, text, x, y, fontOptions, firstCharRow, firstCharRowStart)
    local byte = string.byte
    local ceil = math.ceil
    local concat = table.concat
    local brshift = bit.brshift
    local band = bit.band
    local bxor = bit.bxor
    local setCursorPos = term.setCursorPos
    local blit = term.blit

    if #text == 0 then return end

    local dx = fontOptions.dx
    local dy = fontOptions.dy

    local font = fontOptions.font
    local TERM_WIDTH, TERM_HEIGHT = term.getSize()
    local TEXT_HEIGHT = ceil((font.charH * fontOptions.scale + dy) / 3)

    local fg = colorChar[term.getTextColor()]
    local bg = colorChar[term.getBackgroundColor()]

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
    local scaleInv = 1 / scale

    local ttArray = {} -- teletext pixels
    local fgArray = {} -- foreground colors
    local bgArray = {} -- background colors
    local charString, fgString, bgString
    for row = math.max(1, -y), TEXT_HEIGHT do
        local yIndex1 = ceil((3 * (row - 1) + 1 - dy) * scaleInv) -- subtract y offset
        local yIndex2 = ceil((3 * (row - 1) + 2 - dy) * scaleInv)
        local yIndex3 = ceil((3 * (row - 1) + 3 - dy) * scaleInv)

        local arrayIndex = 1

        local textIndex = 0
        local currentChar, currentCharStart
        local currentCharEnd = 0
        local startX = 1     -- start of char in font bitmap
        local charX = 1 - dx -- subtract x offset
        local rowData1, rowData2, rowData3

        local needCharSep = false
        local function getNextCharData()
            textIndex = textIndex + 1
            currentChar = byte(text, textIndex)
            currentCharStart = currentCharEnd
            if isCondensed then
                local charWidth = byte(font.lengthX, currentChar + 1) - DATA_START
                if charWidth == 0 then -- empty space character
                    currentCharEnd = currentCharEnd + font.spaceWidth * scale
                    startX = 1
                    rowData1 = {}
                    rowData2 = {}
                    rowData3 = {}
                    needCharSep = false
                    return
                end
                startX = byte(font.startX, currentChar + 1) - DATA_START
                if needCharSep then -- add space for separator
                    currentCharEnd = currentCharEnd + font.sepWidth * scale
                    currentCharStart = currentCharEnd
                end
                currentCharEnd = currentCharEnd + charWidth * scale
                needCharSep = true
            else
                currentCharEnd = currentCharEnd + font.charW * scale
                -- charX = 1
            end

            rowData1 = getRowData(currentChar, yIndex1)
            rowData2 = yIndex2 == yIndex1 and rowData1 or getRowData(currentChar, yIndex2)
            rowData3 = yIndex3 == yIndex2 and rowData2 or getRowData(currentChar, yIndex3)
        end

        getNextCharData()

        local ttCharNr, xIndex
        repeat
            if charX > currentCharEnd then getNextCharData() end -- never end of text (because of loop condition)
            ttCharNr = 128
            if row == 1 and firstCharRow then
                -- Start with firstCharRow
                local i = x - firstCharRowStart + arrayIndex
                if i > 0 and i <= #firstCharRow then
                    ttCharNr = byte(firstCharRow, i) or ttCharNr
                end
            end

            -- Left column
            xIndex = ceil((charX - currentCharStart) * scaleInv) + startX - 1
            if rowData1[xIndex] == 1 then ttCharNr = ttCharNr + 1 end
            if rowData2[xIndex] == 1 then ttCharNr = ttCharNr + 4 end
            if rowData3[xIndex] == 1 then ttCharNr = ttCharNr + 16 end
            charX = charX + 1

            if charX > currentCharEnd then
                if textIndex >= #text then -- end of text, insert last char as is
                    ttArray[arrayIndex] = pixelChars[ttCharNr]
                    fgArray[arrayIndex] = fg
                    bgArray[arrayIndex] = bg
                    break
                end
                getNextCharData()
            end

            -- Right column
            xIndex = ceil((charX - currentCharStart) * scaleInv) + startX - 1
            if rowData1[xIndex] == 1 then ttCharNr = ttCharNr + 2 end
            if rowData2[xIndex] == 1 then ttCharNr = ttCharNr + 8 end
            if rowData3[xIndex] == 1 then
                -- Flip colors to activate final pixel
                ttArray[arrayIndex] = pixelChars[bxor(ttCharNr, 31)]
                fgArray[arrayIndex] = bg
                bgArray[arrayIndex] = fg
            else
                ttArray[arrayIndex] = pixelChars[ttCharNr]
                fgArray[arrayIndex] = fg
                bgArray[arrayIndex] = bg
            end
            arrayIndex = arrayIndex + 1
            charX = charX + 1
        until textIndex >= #text and charX > currentCharEnd

        -- Stop if at bottom of terminal
        local rowY = y + row - 1
        if rowY > TERM_HEIGHT then break end

        -- Print full line of pixel characters all at once
        setCursorPos(x, rowY)
        charString = concat(ttArray)
        fgString = concat(fgArray)
        bgString = concat(bgArray)
        blit(charString, fgString, bgString)
    end
    if y + TEXT_HEIGHT < 1 then -- to make sure next line starts at the right y level
        setCursorPos(x, y + TEXT_HEIGHT - 1)
    end
    return charString, x
end

---Draw multi-line text (does not automatically wrap (yet?), but uses newlines '\n' in input text)
---@param term Redirect terminal to print text on
---@param text string text to print
---@param x? number x position (in terminal screen pixels)
---@param y? number y position (in terminal screen pixels)
---@param fontOptions? FontOptions to supply a custom font (e.g. hdfont)
---@param noScroll? boolean set to true if the terminal should not scroll if the text goes off of the bottom of the screen
---@return integer textWidth width of multiline text (in teletext pixels)
---@return integer textHeight height of multiline text (in teletext pixels)
local function drawMultiLineText(term, text, x, y, fontOptions, noScroll)
    fontOptions = fontOptionsFillDefaults(fontOptions or {}, x, y)
    local font = fontOptions.font

    local TERM_WIDTH, TERM_HEIGHT = term.getSize()
    local TEXT_WIDTH, TEXT_HEIGHT, lines, lineWidths = calculateTextSize(text, fontOptions)

    local function alignFactor(alignment)
        if alignment == "center" then return 0.5 end
        if alignment == "right" or alignment == "bottom" then return 1 end
        return 0
    end

    local textAlignFac = alignFactor(fontOptions.textAlign)
    local anchorHorFac = alignFactor(fontOptions.anchorHor)
    local anchorVerFac = alignFactor(fontOptions.anchorVer)

    -- Center text if no coordinates provided, and convert to teletext pixels
    x = (x or (TERM_WIDTH * 0.5 + 1)) * 2
    y = (y or (TERM_HEIGHT * 0.5 + 1)) * 3

    -- Offset for anchor alignment
    x = x - anchorHorFac * TEXT_WIDTH
    y = y - anchorVerFac * TEXT_HEIGHT

    local dx = fontOptions.dx
    local dy = fontOptions.dy

    local lineHeight = (font.charH + font.lineSepHeight) * fontOptions.scale
    local lastCharRow, lastCharRowStart
    for i = 1, #lines do
        -- Offset for horizontal alignment per line
        local xOffset = textAlignFac * (TEXT_WIDTH - lineWidths[i])
        local yOffset = (i - 1) * lineHeight

        -- Round with offsets, then convert back screen pixels
        local lx = math.floor(x + dx + xOffset + 0.5)
        local ly = math.floor(y + dy + yOffset + 0.5)
        fontOptions.dx = lx % 2
        fontOptions.dy = ly % 3
        lx = math.floor(lx / 2)
        ly = math.floor(ly / 3)

        if fontOptions.dy <= font.lineSepHeight then lastCharRow = nil end -- no overlapping chars

        if noScroll then
            if ly > TERM_HEIGHT then break end
        else
            local rowsShort = ly + math.ceil(font.charH * fontOptions.scale / 3) - TERM_HEIGHT
            if rowsShort > 0 then -- scroll if needed
                term.scroll(rowsShort)
                y = y - rowsShort
                ly = ly - rowsShort
            end
        end

        lastCharRow, lastCharRowStart = drawTextOneLine(term, lines[i], lx, ly, fontOptions, lastCharRow, lastCharRowStart)
    end
    if fontOptions.endOnNewLine then
        print()
    else
        local endX, endY = term.getCursorPos()
        term.setCursorPos(endX, endY - math.ceil(lineHeight / 3) + 1)
    end

    return TEXT_WIDTH, TEXT_HEIGHT
end

---@param text string | any
---@param fontOptions? FontOptions
mf.print = function(text, fontOptions)
    expect(2, fontOptions, "table", "nil")
    local x, y = term.getCursorPos()
    fontOptions = fontOptions or {}
    fontOptions.endOnNewLine = true
    return drawMultiLineText(term, tostring(text), x, y, fontOptions)
end

---@param text string | any
---@param fontOptions? FontOptions
mf.write = function(text, fontOptions)
    expect(2, fontOptions, "table", "nil")
    local x, y = term.getCursorPos()
    return drawMultiLineText(term, tostring(text), x, y, fontOptions)
end

---@param term Redirect
---@param text string | any
---@param x? integer x position (in terminal screen pixels) (leave nil to center on terminal)
---@param y? integer y position (in terminal screen pixels) (leave nil to center on terminal)
---@param fontOptions? FontOptions
mf.writeOn = function(term, text, x, y, fontOptions)
    expect(1, term, "table")
    expect(3, x, "number", "nil")
    expect(4, y, "number", "nil")
    expect(5, fontOptions, "table", "nil")
    return drawMultiLineText(term, tostring(text), x, y, fontOptions, true)
end

return mf
