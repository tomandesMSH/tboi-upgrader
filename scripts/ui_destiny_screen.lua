-- Obrazovka "Choose Your Destiny": mrizka 3x3 slotu, kazdy se 3 itemy stejne kvality (viz mockup).
-- Ovladani: sipkami vyber slot, mezernikem/enterem spust loterii. Holy beam prejizdi pres itemy
-- ve slotu, postupne zpomaluje a zastavi se na itemu, o ktery se pak hraje v rulete.
local ui = include("scripts.ui")
local pricing = include("scripts.pricing")
local change = include("scripts.item_change")

local screen = {}

local banner = ui.Load("banner_destiny")
local frameEmpty = ui.Load("slot_frame_empty")
local frameSelected = ui.Load("slot_frame_selected")
local beam = ui.Load("holy_beam")
beam:ReplaceSpritesheet(0, "gfx/effects/crackthesky.png")
beam:LoadGraphics()

local COL_X = { -140, 0, 140 }
local ROW_Y = { -58, 6, 70 }
local ITEM_DX = { -38, 0, 38 }
local ITEM_DY = -2
local QUALITY_DX, QUALITY_DY = 58, 22
local BEAM_DY = 12 -- spodek paprsku na spodku itemu

-- loterie (vse v render framech, 60 za sekundu)
local LOTTERY_LAPS = 4          -- kolik plnych kol paprsek objede pred zastavenim
local LOTTERY_FIRST_STEP = 4    -- delka prvniho kroku
local LOTTERY_SLOWDOWN = 1.12   -- kazdy dalsi krok je o tolik delsi
local LOTTERY_HOLD = 70         -- jak dlouho paprsek sviti na vyherci pred predanim itemu

local MESSAGE_FRAMES = 90

local cursor = 1
local message = nil
local messageUntil = 0
local lottery = nil -- { slot, winner, steps, step, nextStepFrame, doneFrame }

local function showMessage(text)
    message = text
    messageUntil = Isaac.GetFrameCount() + MESSAGE_FRAMES
    ui.Sound("SOUND_BOSS2INTRO_ERRORBUZZ")
end

local function slotPos(index)
    local col = (index - 1) % 3 + 1
    local row = (index - 1) // 3 + 1
    return COL_X[col], ROW_Y[row]
end

-- index itemu, nad kterym je prave paprsek
local function lotteryIndex()
    local count = #lottery.slot.items
    return lottery.step % count + 1
end

local function startLottery(menu, slotIndex)
    local slot = menu.offers[slotIndex]
    local winner = change.RollWinner(slot, menu.rng)
    lottery = {
        slotIndex = slotIndex,
        slot = slot,
        winner = winner,
        -- po "steps" krocich od itemu 1 skonci paprsek na vyherci
        steps = LOTTERY_LAPS * #slot.items + (winner - 1),
        step = 0,
        nextStepFrame = Isaac.GetFrameCount() + LOTTERY_FIRST_STEP,
        doneFrame = nil,
    }
end

-- vrati true, kdyz loterie skoncila
local function updateLottery()
    local now = Isaac.GetFrameCount()
    if lottery.doneFrame then
        return now >= lottery.doneFrame
    end
    if now >= lottery.nextStepFrame then
        lottery.step = lottery.step + 1
        if lottery.step >= lottery.steps then
            lottery.doneFrame = now + LOTTERY_HOLD
            ui.Sound("SOUND_HOLY")
        else
            local length = LOTTERY_FIRST_STEP * LOTTERY_SLOWDOWN ^ lottery.step
            lottery.nextStepFrame = now + math.floor(length)
            ui.Sound("SOUND_PLOP")
        end
    end
    return false
end

function screen.Open()
    cursor = 1
    message = nil
    lottery = nil
end

-- vrati "back", { slot = index, item = id } po dobehnuti loterie, nebo nil
function screen.Update(menu)
    if lottery then
        if updateLottery() then
            local result = { slot = lottery.slotIndex, item = lottery.slot.items[lottery.winner] }
            lottery = nil
            return result
        end
        return nil
    end

    local player = menu.player
    local col = (cursor - 1) % 3
    local row = (cursor - 1) // 3
    if ui.Pressed(player, "left") then
        col = (col - 1) % 3
    elseif ui.Pressed(player, "right") then
        col = (col + 1) % 3
    elseif ui.Pressed(player, "up") then
        row = (row - 1) % 3
    elseif ui.Pressed(player, "down") then
        row = (row + 1) % 3
    elseif ui.Pressed(player, "back") then
        return "back"
    elseif ui.Pressed(player, "confirm") then
        local slot = menu.offers[cursor]
        if #slot.items == 0 then
            showMessage("This slot is empty")
        elseif not pricing.CanAfford(player, slot.tier) then
            showMessage("Not enough " .. pricing.GetTier(slot.tier).currency .. "!")
        else
            startLottery(menu, cursor)
        end
    end
    cursor = row * 3 + col + 1
    return nil
end

local function renderBeam(x, y, winnerGlow)
    beam:SetFrame("Idle", (Isaac.GetFrameCount() // 4) % 2)
    local alpha = 0.75
    if winnerGlow then
        alpha = 0.75 + 0.25 * math.sin(Isaac.GetFrameCount() * 0.3)
    end
    ui.DrawSprite(beam, x, y + BEAM_DY, 1, Color(1, 1, 1, alpha))
end

function screen.Render(menu)
    ui.DrawBlack(0.85)
    ui.DrawSprite(banner, 0, -112)
    ui.DrawItem(menu.sourceId, -190, -112, 0.75)

    for index, slot in ipairs(menu.offers) do
        local x, y = slotPos(index)
        local isCursor = index == cursor
        local inLottery = lottery and lottery.slotIndex == index
        ui.DrawSprite(isCursor and frameSelected or frameEmpty, x, y)

        if #slot.items == 0 then
            ui.DrawText("-    -    -", x, y, ui.DARK, 1.5)
        end

        local beamIndex = inLottery and lotteryIndex() or nil
        for i, id in ipairs(slot.items) do
            local dim = inLottery and lottery.doneFrame and i ~= beamIndex
            ui.DrawItem(id, x + ITEM_DX[i], y + ITEM_DY, 1, dim and ui.DIM or nil)
        end
        if beamIndex then
            renderBeam(x + ITEM_DX[beamIndex], y + ITEM_DY, lottery.doneFrame ~= nil)
        end

        if slot.quality then
            ui.DrawQuality(slot.quality, x + QUALITY_DX, y + QUALITY_DY, 2)
        end
    end

    if message and Isaac.GetFrameCount() < messageUntil then
        ui.DrawText(message, 0, 108, ui.RED)
    end

    if not lottery then
        local tier = pricing.GetTier(menu.offers[cursor].tier)
        local hint = string.format("[ARROWS] move    [SPACE] bet for %d %s    [E] back", tier.amount, tier.currency)
        ui.DrawText(hint, 0, 121, ui.GRAY)
    end
end

return screen
