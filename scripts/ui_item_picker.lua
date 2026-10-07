-- Prvni obrazovka: hrac vybere, ktery ze svych itemu chce vsadit.
local ui = include("scripts.ui")
local items = include("scripts.items")

local screen = {}

local itemCursor = ui.Load("item_cursor")

local COLS = 10
local ROWS_VISIBLE = 4
local CELL = 40
local GRID_TOP = -60

local cursor = 1
local scroll = 0

local function clampScroll()
    local row = (cursor - 1) // COLS
    if row < scroll then
        scroll = row
    elseif row >= scroll + ROWS_VISIBLE then
        scroll = row - ROWS_VISIBLE + 1
    end
end

function screen.Open(menu)
    cursor = 1
    scroll = 0
    for i, id in ipairs(menu.ownedItems) do
        if id == menu.sourceId then cursor = i end
    end
    clampScroll()
end

-- vrati "close", { item = id } nebo nil
function screen.Update(menu)
    local player = menu.player
    local count = #menu.ownedItems

    if ui.Pressed(player, "left") then
        cursor = math.max(1, cursor - 1)
    elseif ui.Pressed(player, "right") then
        cursor = math.min(count, cursor + 1)
    elseif ui.Pressed(player, "up") then
        if cursor > COLS then cursor = cursor - COLS end
    elseif ui.Pressed(player, "down") then
        cursor = math.min(count, cursor + COLS)
    elseif ui.Pressed(player, "back") then
        return "close"
    elseif ui.Pressed(player, "confirm") then
        return { item = menu.ownedItems[cursor] }
    end
    clampScroll()
    return nil
end

function screen.Render(menu)
    ui.DrawBlack(0.85)
    ui.DrawText("CHOOSE AN ITEM TO BET", 0, -100, ui.WHITE, 2)

    local list = menu.ownedItems
    local cols = math.min(#list, COLS)
    local startX = -(cols - 1) * CELL / 2

    for i, id in ipairs(list) do
        local row = (i - 1) // COLS - scroll
        if row >= 0 and row < ROWS_VISIBLE then
            local x = startX + ((i - 1) % COLS) * CELL
            local y = GRID_TOP + row * CELL
            local selected = i == cursor
            ui.DrawItem(id, x, y, selected and 1.15 or 1, not selected and ui.DIM or nil)
            if selected then
                ui.DrawSprite(itemCursor, x, y)
            end
            ui.DrawQuality(items.GetQuality(id), x + 13, y + 13)
            local owned = menu.player:GetCollectibleNum(id, true)
            if owned > 1 then
                ui.DrawText("x" .. owned, x - 12, y + 13)
            end
        end
    end

    if scroll > 0 then
        ui.DrawText("^", 0, GRID_TOP - 26, ui.GRAY)
    end
    if ((#list - 1) // COLS) >= scroll + ROWS_VISIBLE then
        ui.DrawText("v", 0, GRID_TOP + ROWS_VISIBLE * CELL - 14, ui.GRAY)
    end

    ui.DrawText("[ARROWS] move    [SPACE] choose    [E] close", 0, 121, ui.GRAY)
end

return screen
