-- Font browser for MORE FONTS
local function downloadFile(filename, url)
    local res = http.get(url)
    if not res then error("Error downloading font from " .. url) end
    local data = res.readAll()
    res.close()
    local file = fs.open(filename, "w")
    if not file then error("Can't write to file " .. filename .. "...") end
    file.write(data)
    file.close()
end

if not fs.exists("morefonts.lua") then
    downloadFile("morefonts.lua", "https://raw.githubusercontent.com/MichielP1807/more-fonts/main/morefonts.lua")
end
local mf = require("morefonts")

-- Configuration file with all currently downloaded fonts
local CONF_FILE = "fonts.conf"
local conf_data = {}
if fs.exists(CONF_FILE) then
    local file = fs.open(CONF_FILE, "r")
    if not file then error("Can't read file " .. CONF_FILE .. "...") end
    local str = file.readAll()
    file.close()
    conf_data = textutils.unserialise(str or "") or {}
end
local function saveConfigToFile()
    local str = textutils.serialise(conf_data)
    local file = fs.open(CONF_FILE, "w")
    if not file then error("Can't write to file " .. CONF_FILE .. "...") end
    file.write(str)
    file.close()
end

local fontFolder = "fonts"
if not fs.exists(fontFolder) then
    fs.makeDir(fontFolder)
end

local FONT_LIST_API = "https://api.github.com/repos/MichielP1807/more-fonts/contents/fonts"
local function checkForFontUpdates()
    print("Loading font data...")
    local res = http.get(FONT_LIST_API, {["If-None-Match"] = conf_data.etag})
    if not res then
        error("Could not load fonts from GitHub...")
        return
    end
    local resCode, message = res.getResponseCode()
    if resCode == 304 then
        print("No font updates")
        return
    end
    local resHeaders = res.getResponseHeaders()
    conf_data.etag = resHeaders.ETag

    conf_data.hashes = conf_data.hashes or {}
    local data = res.readAll()
    res.close()
    data = textutils.unserialiseJSON(data)
    for i = 1, #data do
        local d = data[i]
        if d.type == "file" and d.name:sub(-3) ~= ".py" then
            if conf_data.hashes[d.name] ~= d.sha then
                print("Downloading new/updated font: " .. d.name)
                downloadFile(fontFolder .. "/" .. d.name, d.download_url)
                conf_data.hashes[d.name] = d.sha
            end
        end
    end
    saveConfigToFile()
    sleep(1)
end

checkForFontUpdates()

---@class FontWithFilename: Font
local defaultFont = mf.ccfont
defaultFont.filename = "Default CC font"

-- Get list of locally available fonts
---@type FontWithFilename[]
local fonts = {defaultFont}
local files = fs.list(fontFolder)
for i = 1, #files do
    local filename = fontFolder .. "/" .. files[i]
    if not fs.isDir(filename) and filename:sub(-3) ~= ".py" then
        ---@class FontWithFilename: Font
        local font = mf.loadFont(filename)
        font.filename = files[i]
        fonts[#fonts + 1] = font
    end
end

local currentFontIndex = 1

---@type string?
local previewText = table.concat(arg, " ")
if #previewText < 1 then previewText = nil end

local TERM_WIDTH, TERM_HEIGHT = term.getSize()
local myWindow = window.create(term.current(), 1, 1, TERM_WIDTH, TERM_HEIGHT, false)

local function center(text)
    while #text < TERM_WIDTH do text = " " .. text .. " " end
    return text:sub(1, TERM_WIDTH)
end

local function render()
    -- Draw main text using MORE FONTS
    local font = fonts[currentFontIndex]
    myWindow.setTextColor(colors.white)
    myWindow.setBackgroundColor(colors.black)
    myWindow.clear()
    mf.writeOn(myWindow, previewText or font.filename, nil, nil, {
        font = font,
        condense = true,
        wrapWidth = TERM_WIDTH * 2 - 4
    })

    -- Draw font name and author (if known)
    myWindow.setCursorPos(1, 1)
    myWindow.setTextColor(colors.white)
    myWindow.setBackgroundColor(colors.blue)
    local header = font.filename .. (font.author and " by " .. font.author or "")
    myWindow.write(center(header))

    -- Draw copyright info (if known)
    if font.copyright then
        myWindow.setCursorPos(1, TERM_HEIGHT - 1)
        myWindow.setTextColor(colors.gray)
        myWindow.setBackgroundColor(colors.black)
        myWindow.write(center(font.copyright))
    end

    -- Draw license info
    myWindow.setCursorPos(1, TERM_HEIGHT)
    myWindow.setTextColor(colors.white)
    myWindow.setBackgroundColor(colors.gray)
    myWindow.write(center(font.license or ""))

    myWindow.setVisible(true) -- prevent flashing
    myWindow.setVisible(false)
end

while true do
    local event, which, x, y = os.pullEventRaw()
    if event == "key" then
        if which == keys.left or which == keys.a then
            currentFontIndex = ((currentFontIndex - 2) % #fonts) + 1
        elseif which == keys.right or which == keys.d then
            currentFontIndex = (currentFontIndex % #fonts) + 1
        end
    elseif event == "term_resize" then
        TERM_WIDTH, TERM_HEIGHT = term.getSize()
        myWindow.reposition(1, 1, TERM_WIDTH, TERM_HEIGHT)
    elseif event == "terminate" then
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1, 1)
        return
    end

    render()
end
