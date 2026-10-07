-- Spolecne veci pro vykreslovani a ovladani obrazovek modu.
-- Vsechny pozice jsou v "design" souradnicich: obrazovka 480x270, (0, 0) = stred.
-- Prepocet na skutecnou velikost obrazovky dela ui.Pos / ui.DrawSprite.
local ui = {}

ui.DESIGN_W = 480
ui.DESIGN_H = 270

ui.WHITE = KColor(1, 1, 1, 1)
ui.GRAY = KColor(0.7, 0.7, 0.7, 1)
ui.RED = KColor(1, 0.35, 0.35, 1)
ui.GREEN = KColor(0.45, 1, 0.35, 1)
ui.DARK = KColor(0.08, 0.05, 0.05, 1)
ui.DIM = Color(0.55, 0.55, 0.55, 1)

function ui.Load(name)
    local sprite = Sprite()
    sprite:Load("gfx/ui/upgrader/" .. name .. ".anm2", true)
    sprite:Play("Idle", true)
    return sprite
end

local font = Font()
font:Load("font/pftempestasevencondensed.fnt")

local black = ui.Load("black")
local qualityIcons = ui.Load("quality_icons")
local itemSprites = {}
local sfx = SFXManager()

function ui.GetLayout()
    local sw, sh = Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
    return sw / 2, sh / 2, math.min(sw / ui.DESIGN_W, sh / ui.DESIGN_H)
end

function ui.Pos(x, y)
    local cx, cy, u = ui.GetLayout()
    return Vector(cx + x * u, cy + y * u)
end

function ui.DrawSprite(sprite, x, y, scale, color)
    local _, _, u = ui.GetLayout()
    local s = (scale or 1) * u
    sprite.Scale = Vector(s, s)
    sprite.Color = color or Color(1, 1, 1, 1)
    sprite:Render(ui.Pos(x, y))
end

function ui.DrawBlack(alpha)
    local sw, sh = Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
    black.Scale = Vector(sw / 16 + 1, sh / 16 + 1)
    black.Color = Color(1, 1, 1, alpha)
    black:Render(Vector(0, 0))
end

-- ikona kvality 0-4 ve stylu EID
-- Pixel art se kresli jen v celociselnem zvetseni a na cele pixely, jinak ma pixely ruzne siroke
-- a ikona pusobi rozmazane / mimo stred.
-- V quality_icons.png je kazda ikona 9x9 v bunce 12x12 od pixelu (1, 1), jeji stred je tedy 5.5,
-- ale pivot v anm2 je 6 -> posuneme o rozdil, aby byla ikona presne na (x, y).
local QUALITY_ICON_CENTER = 5.5
local QUALITY_ANM2_PIVOT = 6

function ui.DrawQuality(quality, x, y, scale)
    local _, _, u = ui.GetLayout()
    local s = math.max(1, math.floor((scale or 1) * u + 0.5))
    local pos = ui.Pos(x, y)
    local fix = (QUALITY_ANM2_PIVOT - QUALITY_ICON_CENTER) * s
    qualityIcons:SetFrame("Idle", quality)
    qualityIcons.Scale = Vector(s, s)
    qualityIcons.Color = Color(1, 1, 1, 1)
    qualityIcons:Render(Vector(math.floor(pos.X + fix + 0.5), math.floor(pos.Y + fix + 0.5)))
end

-- text vycentrovany na (x, y)
function ui.DrawText(text, x, y, color, scale)
    local _, _, u = ui.GetLayout()
    local s = (scale or 1) * u
    local pos = ui.Pos(x, y)
    local w = font:GetStringWidth(text) * s
    local h = font:GetLineHeight() * s
    font:DrawStringScaled(text, pos.X - w / 2, pos.Y - h / 2, s, s, color or ui.WHITE, 0, false)
end

-- ikona collectiblu (32x32, stred na x, y)
function ui.DrawItem(id, x, y, scale, color)
    local sprite = itemSprites[id]
    if not sprite then
        local config = Isaac.GetItemConfig():GetCollectible(id)
        if not config then return end
        sprite = ui.Load("item_icon")
        sprite:ReplaceSpritesheet(0, config.GfxFileName)
        sprite:LoadGraphics()
        itemSprites[id] = sprite
    end
    ui.DrawSprite(sprite, x, y, scale, color)
end

local ACTIONS = {
    left    = { ButtonAction.ACTION_LEFT, ButtonAction.ACTION_SHOOTLEFT },
    right   = { ButtonAction.ACTION_RIGHT, ButtonAction.ACTION_SHOOTRIGHT },
    up      = { ButtonAction.ACTION_UP, ButtonAction.ACTION_SHOOTUP },
    down    = { ButtonAction.ACTION_DOWN, ButtonAction.ACTION_SHOOTDOWN },
    confirm = { ButtonAction.ACTION_ITEM, ButtonAction.ACTION_MENUCONFIRM },
    back    = { ButtonAction.ACTION_BOMB, ButtonAction.ACTION_DROP },
}

function ui.Pressed(player, name)
    for _, action in ipairs(ACTIONS[name]) do
        if Input.IsActionTriggered(action, player.ControllerIndex) then
            return true
        end
    end
    return false
end

-- prehraje zvuk podle jmena z SoundEffect, pokud existuje
function ui.Sound(name)
    local id = SoundEffect[name]
    if id then sfx:Play(id) end
end

return ui
