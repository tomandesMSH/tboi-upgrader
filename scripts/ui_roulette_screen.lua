-- Ruleta (kolo): rozhodne, jestli hrac vyhrany item opravdu dostane, nebo vsazeny item propadne.
-- Zelena vysec kola = sance na vyhru (od vrcholu po smeru hodinovych rucicek). Ukazatel nekolikrat
-- objede kolo, zpomaluje a zastavi se; vysledek je vylosovany predem (menu.rng), animace k nemu jen dojede.
local ui = include("scripts.ui")
local items = include("scripts.items")

local screen = {}

local wheelFrame = ui.Load("wheel_frame")
local wheelPointer = ui.Load("wheel_pointer")
local segment = ui.Load("white_center")

local WHEEL_X, WHEEL_Y = 0, 0
local RING_RADIUS = 53     -- stred prstence (musi sedet s wheel_frame.png)
local RING_THICKNESS = 15
local SEGMENTS = 120
local ITEM_DX = 150        -- vsazeny item vlevo, vyhrany vpravo

local SPIN_FRAMES = 240 -- delka toceni (render framy, 60 za sekundu)
local SPIN_TURNS = 4    -- kolik plnych otacek ukazatel udela
local TICK_DEGREES = 30 -- cvaknuti pri kazdem ryzku
local RESULT_HOLD = 100 -- jak dlouho zustane vysledek na obrazovce

local GREEN = Color(0.3, 0.85, 0.3, 1)
local RED = Color(0.75, 0.18, 0.18, 1)

local state = nil

function screen.Open(menu)
    local roll = menu.rng:RandomFloat()
    state = {
        roll = roll,
        win = roll < menu.bet.chance,
        startFrame = Isaac.GetFrameCount(),
        doneFrame = nil,
        lastTick = 0,
    }
end

-- uhel ukazatele ve stupnich (0 = nahore, po smeru hodinovych rucicek); na konci presne roll * 360
local function pointerAngle()
    local t = math.min((Isaac.GetFrameCount() - state.startFrame) / SPIN_FRAMES, 1)
    local eased = 1 - (1 - t) ^ 3
    return (SPIN_TURNS + state.roll) * 360 * eased
end

-- vrati { win = bool } po skonceni, jinak nil
function screen.Update(menu)
    local now = Isaac.GetFrameCount()
    if state.doneFrame then
        if now >= state.doneFrame then
            return { win = state.win }
        end
        return nil
    end

    local tick = math.floor(pointerAngle() / TICK_DEGREES)
    if tick ~= state.lastTick then
        state.lastTick = tick
        ui.Sound("SOUND_PLOP")
    end

    if now - state.startFrame >= SPIN_FRAMES then
        state.doneFrame = now + RESULT_HOLD
        if state.win then
            ui.Sound("SOUND_HOLY")
        else
            ui.Sound("SOUND_DEATH_CARD")
        end
    end
    return nil
end

local function renderRing(chance)
    -- prstenec slozeny z otocenych obdelniku (tecny ke kruznici)
    local _, _, u = ui.GetLayout()
    local segLength = 2 * math.pi * RING_RADIUS / SEGMENTS + 1.5
    segment.Scale = Vector(segLength * u / 16, RING_THICKNESS * u / 16)
    for i = 0, SEGMENTS - 1 do
        local fraction = (i + 0.5) / SEGMENTS
        local angle = fraction * 360
        local rad = math.rad(angle)
        segment.Rotation = angle
        segment.Color = fraction < chance and GREEN or RED
        segment:Render(ui.Pos(WHEEL_X + RING_RADIUS * math.sin(rad), WHEEL_Y - RING_RADIUS * math.cos(rad)))
    end
end

local function renderItem(id, x, label)
    ui.DrawText(label, x, WHEEL_Y - 34, ui.GRAY)
    ui.DrawItem(id, x, WHEEL_Y, 1.5)
    ui.DrawQuality(items.GetQuality(id), x + 22, WHEEL_Y + 20, 2)
end

function screen.Render(menu)
    local bet = menu.bet
    ui.DrawBlack(0.85)
    ui.DrawText("UPGRADE", 0, -105, ui.WHITE, 2)

    renderItem(menu.sourceId, WHEEL_X - ITEM_DX, "YOUR BET")
    renderItem(bet.targetId, WHEEL_X + ITEM_DX, "TARGET")

    renderRing(bet.chance)
    ui.DrawSprite(wheelFrame, WHEEL_X, WHEEL_Y)

    wheelPointer.Rotation = pointerAngle()
    ui.DrawSprite(wheelPointer, WHEEL_X, WHEEL_Y)

    -- stred kola: sance, po dotoceni vysledek
    if state.doneFrame then
        if state.win then
            ui.DrawText("WIN!", WHEEL_X, WHEEL_Y, ui.GREEN, 2.5)
        else
            ui.DrawText("LOST", WHEEL_X, WHEEL_Y, ui.RED, 2.5)
        end
    else
        ui.DrawText(string.format("%d%%", math.floor(bet.chance * 100 + 0.5)), WHEEL_X, WHEEL_Y - 4, ui.WHITE, 2.5)
        ui.DrawText("chance", WHEEL_X, WHEEL_Y + 16, ui.GRAY)
    end

    ui.DrawText(string.format("Quality jump %+d: %d%%    Luck: %+d%%",
        bet.jump, math.floor(bet.base * 100 + 0.5), math.floor(bet.luck * 100 + 0.5)), 0, 82, ui.GRAY)

    if state.doneFrame then
        if state.win then
            ui.DrawText("YOU WIN!", 0, 104, ui.GREEN, 2)
        else
            ui.DrawText("YOU LOSE... the item is gone", 0, 104, ui.RED, 2)
        end
    end
end

return screen
