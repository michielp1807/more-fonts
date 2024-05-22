local Pine3D = require("Pine3D")
local mf = require("morefonts-pe")

local FONT_TITLE = mf.loadFont("fonts/PixelOperator-Bold")
local FONT_SUBTITLE = mf.loadFont("fonts/Silkscreen-Bold")

mf.setDefaultFontOptions({
    condense = true,
    font = FONT_TITLE,
})

local frame = Pine3D.newFrame()
frame:setCamera(0, 0.6, 0)
frame:setFoV(60)

local pineapple = frame:newObject("pine3d/pineapple.stab", 2, 0, 0, nil, math.pi * 0.25, nil)
local objects = {pineapple}

local animateConfetti, initConfetti
local sin = math.sin
local cos = math.cos

local function gameLoop()
    local lastTime = os.clock()

    local confettiState = "waiting"

    while true do
        -- compute the time passed since last step
        local currentTime = os.clock()
        local dt = currentTime - lastTime
        lastTime = currentTime

        -- animate all the things that need to be animated
        pineapple:setRot(0, currentTime, 0)
        animateConfetti(currentTime, dt)

        -- render frame
        frame:drawObjects(objects)

        -- draw text
        local scale = 1 - cos(0.5 * currentTime) ^ 32
        if scale > 0.99 then scale = 1 end
        mf.writeOn(frame, "Pine3D Edition", colors.red, nil, nil, {font = FONT_SUBTITLE, scale = scale, dy = 5})
        mf.writeOn(frame, "More Fonts", colors.blue, nil, nil, {scale = 1, dy = -6 * scale, spaceWidth = 9})

        frame:drawBuffer()

        if confettiState == "waiting" and scale == 1 then
            initConfetti()
            confettiState = "done"
        elseif confettiState == "done" and scale ~= 1 then
            confettiState = "waiting"
        end

        os.queueEvent("render-pls")
        ---@diagnostic disable-next-line: param-type-mismatch
        os.pullEvent("render-pls")
    end
end

-- Confetti stuff
local NUM_PARTICLES = 300
local CONFETTI_COLORS = {
    colors.blue, colors.red, colors.green, colors.yellow, colors.orange, colors.lime
}

---@type Model
local confetti = {{
    x1 = 0,
    y1 = 0,
    z1 = 0,
    x2 = 0.1,
    y2 = 0,
    z2 = 0,
    x3 = 0.05,
    y3 = 0.075,
    z3 = 0,
    c = colors.white,
    forceRender = true
}}

function initConfetti()
    for i = 1, NUM_PARTICLES do
        local r = sin(i * 140)
        confetti[1].c = CONFETTI_COLORS[(i % #CONFETTI_COLORS) + 1]
        local particle = frame:newObject(confetti, 0, 5 + 2 * r, 0, 0, 0, 0)
        ---@diagnostic disable-next-line: inject-field
        particle.ty = "confetti"
        ---@diagnostic disable-next-line: inject-field
        particle.ind = i
        objects[#objects + 1] = particle
    end
end

function animateConfetti(time, dt)
    for i = #objects, 1, -1 do
        local obj = objects[i]
        ---@diagnostic disable-next-line: undefined-field
        if obj.ty == "confetti" then
            ---@diagnostic disable-next-line: undefined-field
            local offset = 51 * obj.ind / NUM_PARTICLES
            local d = (5.45 * offset) % 6 + 0.5
            ---@diagnostic disable-next-line: undefined-field
            local a = (0.4532378 * obj.ind) % 1 + 1
            obj[1] = d * sin(time * 0.2 * a + offset) -- x
            obj[2] = obj[2] - a * dt                  -- y
            obj[3] = d * cos(time * 0.2 * a + offset) -- z
            if obj[2] < -3 then
                table.remove(objects, i)
            end
        end
    end
end

gameLoop()
