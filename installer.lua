local NAME = "More Fonts Installer"
local REPO_LINK = "https://raw.githubusercontent.com/MichielP1807/more-fonts/main/"

local DOWNLOADS = {}
local argStr = table.concat({...}, " ")
if argStr:lower():find("pine3d") then
    NAME = "More Fonts [Pine3D Edition] Installer"
    DOWNLOADS[#DOWNLOADS + 1] = "pine3d/morefonts-pe.lua"
else
    DOWNLOADS[#DOWNLOADS + 1] = "morefonts.lua"
    DOWNLOADS[#DOWNLOADS + 1] = "fontbrowser.lua"
end

local width, height = term.getSize()
local totalDownloaded = 0

local function update(text)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 9)
    term.clearLine()
    term.setCursorPos(math.floor(width / 2 - string.len(text) / 2 + 0.5), 9)
    write(text)
end

local function bar(ratio)
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.lime)
    term.setCursorPos(1, 11)
    for i = 1, width do
        if (i / width < ratio) then write("]") else write(" ") end
    end
end

local function download(path, attempt)
    local rawData = http.get(REPO_LINK .. path)
    update("Downloaded " .. path .. "!")
    if not rawData then
        if attempt == 3 then error("Failed to download " .. path .. " after 3 attempts!") end
        update("Failed to download " .. path .. ". Trying again (attempt " .. (attempt + 1) .. "/3)")
        return download(path, attempt + 1)
    end
    local data = rawData.readAll()

    local filename = path:sub((path:find("/") or 0) + 1) -- remove folder from path
    local file = fs.open(filename, "w")
    file.write(data)
    file.close()
end

local function downloadAll(downloads, total)
    local nextFile = table.remove(downloads, 1)
    if nextFile then
        sleep(0.1)
        parallel.waitForAll(function() downloadAll(downloads, total) end, function()
            download(nextFile, 1)
            totalDownloaded = totalDownloaded + 1
            bar(totalDownloaded / total)
        end)
    end
end

local function install()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.yellow)
    term.clear()

    term.setCursorPos(math.floor(width / 2 - #NAME / 2 + 0.5), 2)
    write(NAME)
    update("Installing...")
    bar(0)

    totalDownloaded = 0
    downloadAll(DOWNLOADS, #DOWNLOADS)

    update("Installation finished!")

    sleep(1)

    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()

    term.setCursorPos(1, 1)
    write("Finished installation!\nPress any key to close...")

    os.pullEventRaw()

    term.clear()
    term.setCursorPos(1, 1)
end

install()
