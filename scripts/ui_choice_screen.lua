-- Prvni obrazovka: "What do you want to do with the item?" + tlacitka UPGRADE / ? / DUPLICATE.
local ui = include("scripts.ui")
local duplication = include("scripts.duplication")

local screen = {}

local panel = ui.Load("vyber")

local BUTTONS = {
    { id = "upgrade",   sprite = ui.Load("upgrade-btn"),   x = -68, scale = 100 / 900 },
    { id = "help",      sprite = ui.Load("napoveda"),      x = 0,   scale = 24 / 200 },
    { id = "duplicate", sprite = ui.Load("duplicate-btn"), x = 68,  scale = 100 / 900 },
}
local BUTTON_Y = 62

local selected = 1
local helpOpen = false

local function chanceText(count)
    return string.format("%dx %.1f%%", count, duplication.GetChance(count) * 100)
end

local function helpLines()
    return {
        "UPGRADE",
        "Pick one of 9 offers. The holy beam picks one of its 3 items.",
        "Then spin the roulette - bigger quality jump = lower chance.",
        "Luck helps. If you lose, your item is gone!",
        "",
        "DUPLICATE",
        "A chance to double the item:",
        chanceText(2) .. "    " .. chanceText(4) .. "    " .. chanceText(8),
        "If it fails, nothing happens.",
        "",
        "[SPACE] / [E] close",
    }
end

function screen.Open()
    selected = 1
    helpOpen = false
end

-- vrati "upgrade", "duplicate", "back" nebo nil
function screen.Update(menu)
    local player = menu.player

    if helpOpen then
        if ui.Pressed(player, "confirm") or ui.Pressed(player, "back") then
            helpOpen = false
        end
        return nil
    end

    if ui.Pressed(player, "left") then
        selected = (selected - 2) % #BUTTONS + 1
    elseif ui.Pressed(player, "right") then
        selected = selected % #BUTTONS + 1
    elseif ui.Pressed(player, "back") then
        return "back"
    elseif ui.Pressed(player, "confirm") then
        local id = BUTTONS[selected].id
        if id == "help" then
            helpOpen = true
        else
            return id
        end
    end
    return nil
end

function screen.Render(menu)
    ui.DrawBlack(0.85)
    ui.DrawSprite(panel, 0, -72, 230 / 1024)
    ui.DrawItem(menu.sourceId, 0, 8)

    for i, button in ipairs(BUTTONS) do
        local isSelected = i == selected
        ui.DrawSprite(button.sprite, button.x, BUTTON_Y,
            button.scale * (isSelected and 1.1 or 1),
            not isSelected and ui.DIM or nil)
    end

    local id = BUTTONS[selected].id
    local info
    if id == "duplicate" then
        local count = duplication.GetCount(menu.player, menu.sourceId)
        local target = duplication.GetTargetCount(count)
        info = string.format("%dx -> %dx   chance %.1f%%", count, target, duplication.GetChance(target) * 100)
    elseif id == "upgrade" then
        info = "Trade this item for a different one"
    else
        info = "How does it work?"
    end
    ui.DrawText(info, 0, 100)
    ui.DrawText("[SPACE] select    [E] back", 0, 118, ui.GRAY)

    if helpOpen then
        ui.DrawBlack(0.8)
        for i, line in ipairs(helpLines()) do
            ui.DrawText(line, 0, -60 + (i - 1) * 13)
        end
    end
end

return screen
