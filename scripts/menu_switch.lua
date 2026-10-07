-- Prepinac modu v hlavnim menu, na obrazovce vyberu postavy (vlevo dole pod Win Streak), po vzoru
-- "Completion Marks Recap Screen". Otevrena truhla = mod zapnuty, zavrena = vypnuty.
-- Vyzaduje REPENTOGON (MC_MAIN_MENU_RENDER, MenuManager).
local menuSwitch = {}

local TOGGLE_KEY = Keyboard.KEY_U   -- T a Y pouziva Completion Marks Recap Screen
local TOGGLE_LABEL = "U"
local WIDGET_POS = Vector(40, 210)  -- souradnice stranky vyberu postavy; vlevo dole je volne misto pod Win Streak

local sprite = Sprite()
sprite:Load("gfx/ui/main menu/switch.anm2", true)
sprite:Play("Off", true)

local font = Font()
font:Load("font/pftempestasevencondensed.fnt")

local sfx = SFXManager()
local inCharacterMenu = false

local function playSound(name)
    local id = SoundEffect[name]
    if id then sfx:Play(id) end
end

function menuSwitch.Init(mod, save)
    if not REPENTOGON then return end

    mod:AddCallback(ModCallbacks.MC_MAIN_MENU_RENDER, function()
        if MenuManager.GetActiveMenu() ~= MainMenuType.CHARACTER then
            inCharacterMenu = false
            return
        end

        -- pri vstupu do vyberu postavy nacist nastaveni (save slot uz je vybrany)
        if not inCharacterMenu then
            inCharacterMenu = true
            save.LoadAll()
        end

        if Input.IsButtonTriggered(TOGGLE_KEY, 0) then
            save.SetEnabled(not save.IsEnabled())
            playSound(save.IsEnabled() and "SOUND_CHEST_OPEN" or "SOUND_CHEST_DROP")
        end

        local enabled = save.IsEnabled()
        local pos = Isaac.WorldToMenuPosition(MainMenuType.CHARACTER, WIDGET_POS)
        sprite:Play(enabled and "On" or "Off", true)
        sprite:Render(pos)

        -- pismeno klavesy do prazdneho tlacitka (vrstva Button je na -12, -1)
        local keyPos = pos + Vector(-12, -1)
        font:DrawString(TOGGLE_LABEL, keyPos.X - font:GetStringWidth(TOGGLE_LABEL) / 2,
            keyPos.Y - font:GetLineHeight() / 2, KColor(0.21, 0.16, 0.16, 1), 0, false)

        local label = enabled and "Upgrader: ON" or "Upgrader: OFF"
        font:DrawString(label, pos.X - font:GetStringWidth(label) / 2, pos.Y + 26,
            enabled and KColor(0.2, 0.55, 0.2, 1) or KColor(0.35, 0.25, 0.25, 1), 0, false)
    end)
end

return menuSwitch
