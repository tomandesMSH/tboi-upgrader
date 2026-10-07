local mod = RegisterMod("Item Upgrader", 1)

local ITEM_UPGRADER = Isaac.GetItemIdByName("Item Upgrader")

local items = include("scripts.items")
local duplication = include("scripts.duplication")
local change = include("scripts.item_change")
local pricing = include("scripts.pricing")
local save = include("scripts.save")
local ui = include("scripts.ui")
local pickerScreen = include("scripts.ui_item_picker")
local choiceScreen = include("scripts.ui_choice_screen")
local destinyScreen = include("scripts.ui_destiny_screen")
local rouletteScreen = include("scripts.ui_roulette_screen")
local menuSwitch = include("scripts.menu_switch")

save.Init(mod)
menuSwitch.Init(mod, save)

local OPEN_DELAY = 10 -- pocet framu po otevreni / prepnuti obrazovky, kdy se ignoruje vstup

-- stav nabidky
local menu = {
    screen = nil,      -- picker -> choice -> destiny -> roulette; nil = zavreno
    player = nil,
    ownedItems = nil,  -- itemy, ktere muze hrac vsadit
    sourceId = nil,    -- vsazeny item
    bet = nil,         -- o co se hraje v rulete: { slotIndex, targetId, chance, base, luck, jump }
    activeSlot = -1,   -- slot aktivniho itemu, ze ktereho se menu otevrelo
    rng = nil,
    offers = nil,
    switchedFrame = 0,
    closedFrame = -100,
}

local function setScreen(screen)
    menu.screen = screen
    menu.switchedFrame = Isaac.GetFrameCount()
    screen.Open(menu)
end

local function openMenu(player, ownedItems, activeSlot)
    menu.player = player
    menu.ownedItems = ownedItems
    menu.sourceId = nil
    menu.activeSlot = activeSlot
    menu.rng = player:GetCollectibleRNG(ITEM_UPGRADER)
    player.ControlsEnabled = false
    setScreen(pickerScreen)
    ui.Sound("SOUND_PAPER_IN")
end

local function closeMenu()
    if menu.player and menu.player:Exists() then
        menu.player.ControlsEnabled = true
    end
    menu.screen = nil
    menu.player = nil
    menu.offers = nil
    menu.bet = nil
    menu.closedFrame = Isaac.GetFrameCount()
end

-- akce probehla: zavrit menu a spotrebovat naboj aktivniho itemu
local function finishAction()
    local player, activeSlot = menu.player, menu.activeSlot
    closeMenu()
    if activeSlot >= 0 then
        player:DischargeActiveItem(activeSlot)
    end
    return player
end

local function doDuplicate()
    local success = duplication.Try(menu.player, menu.sourceId, menu.rng)
    local player = finishAction()
    if success then
        ui.Sound("SOUND_THUMBSUP")
        player:AnimateHappy()
        ui.ShowPaper("double trouble", "your item", "has a twin")
    else
        ui.Sound("SOUND_THUMBS_DOWN")
        player:AnimateSad()
        ui.ShowPaper("not this time", "the item", "stays alone")
    end
end

local function openDestiny()
    local offers = save.GetOffers(menu.sourceId)
    if not offers then
        offers = change.GenerateOffers(menu.sourceId, menu.rng)
        save.SetOffers(menu.sourceId, offers)
    end
    menu.offers = offers
    setScreen(destinyScreen)
end

local function startRoulette(slotIndex, targetId)
    local chance, base, luck, jump = change.GetWinChance(menu.player, menu.sourceId, targetId)
    menu.bet = { slotIndex = slotIndex, targetId = targetId, chance = chance, base = base, luck = luck, jump = jump }
    setScreen(rouletteScreen)
end

-- vysledek rulety: vyhra = vymena itemu, prohra = vsazeny item propada; cena se plati vzdy
local function resolveRoulette(win)
    local player, sourceId, bet = menu.player, menu.sourceId, menu.bet
    pricing.Pay(player, menu.offers[bet.slotIndex].tier)
    if win then
        change.Apply(player, sourceId, bet.targetId)
    else
        change.Forfeit(player, sourceId)
    end
    save.SetOffers(sourceId, nil)
    finishAction()
    if win then
        ui.Sound("SOUND_POWERUP1")
        player:AnimateHappy()
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, player.Position, Vector.Zero, player)
        ui.ShowPaper("fortune favors", math.random() < 0.1 and "the bald" or "the bold")
    else
        player:AnimateSad()
        ui.ShowPaper("the house", "always wins", "your item is gone")
    end
end

function mod:onUseUpgrader(_, _, player, _, activeSlot)
    local noUse = { Discharge = false, Remove = false, ShowAnim = false }
    if menu.screen or Isaac.GetFrameCount() - menu.closedFrame < OPEN_DELAY then
        return noUse
    end

    local ownedItems = items.GetOwnedItems(player)
    if #ownedItems == 0 then
        ui.Sound("SOUND_BOSS2INTRO_ERRORBUZZ")
        ui.ShowPaper("nothing to bet", "pick up an item", "and come back")
        return noUse
    end

    -- naboj se spotrebuje az po provedeni akce (finishAction), zavreni menu je zadarmo
    openMenu(player, ownedItems, activeSlot or -1)
    return noUse
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.onUseUpgrader, ITEM_UPGRADER)

function mod:onInput()
    if not menu.screen or Game():IsPaused() then return end

    local player = menu.player
    if not player or not player:Exists() then
        closeMenu()
        return
    end

    -- hra mohla ovladani znovu zapnout (napr. animace), drzime ho vypnute
    player.ControlsEnabled = false

    if Isaac.GetFrameCount() - menu.switchedFrame < OPEN_DELAY then return end

    local result = menu.screen.Update(menu)
    if not result then return end

    if menu.screen == pickerScreen then
        if result == "close" then
            closeMenu()
            ui.Sound("SOUND_PAPER_OUT")
        else
            menu.sourceId = result.item
            setScreen(choiceScreen)
        end
    elseif menu.screen == choiceScreen then
        if result == "back" then
            setScreen(pickerScreen)
        elseif result == "duplicate" then
            doDuplicate()
        elseif result == "upgrade" then
            openDestiny()
        end
    elseif menu.screen == destinyScreen then
        if result == "back" then
            setScreen(choiceScreen)
        else
            startRoulette(result.slot, result.item)
        end
    elseif menu.screen == rouletteScreen then
        resolveRoulette(result.win)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onInput)

function mod:onRender()
    if menu.screen then
        menu.screen.Render(menu)
    end
end
-- s Repentogonem kreslime az nad HUD, jinak v beznem renderu
if REPENTOGON then
    mod:AddCallback(ModCallbacks.MC_POST_HUD_RENDER, mod.onRender)
else
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)
end

-- Upgrader do pocket slotu; postavy, ktere uz pocket item maji (napr. T.Cain), ho dostanou
-- do hlavniho slotu, a kdyz je i ten plny, objevi se na podstavci vedle hrace.
local function grantUpgrader(player)
    if player:GetActiveItem(ActiveSlot.SLOT_POCKET) == ITEM_UPGRADER
        or player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) == ITEM_UPGRADER then
        return
    end
    if player:GetActiveItem(ActiveSlot.SLOT_POCKET) == 0 then
        player:SetPocketActiveItem(ITEM_UPGRADER, ActiveSlot.SLOT_POCKET, false)
    elseif player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) == 0 then
        player:AddCollectible(ITEM_UPGRADER, 0, false, ActiveSlot.SLOT_PRIMARY)
    else
        local pos = Game():GetRoom():FindFreePickupSpawnPosition(player.Position, 40, true)
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, ITEM_UPGRADER, pos, Vector.Zero, nil)
    end
end

function mod:onGameStarted(isContinued)
    closeMenu()
    save.Load(isContinued)
    if not isContinued and save.IsEnabled() then
        for i = 0, Game():GetNumPlayers() - 1 do
            grantUpgrader(Isaac.GetPlayer(i))
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.onGameStarted)

-- Mod vypnuty v menu: Upgrader nesmi jit ziskat vubec (konzole, Eden, Death Certificate, rerolly...).
if REPENTOGON then
    mod:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, function()
        if not save.IsEnabled() then return false end
    end, ITEM_UPGRADER)
end

function mod:onPickupInit(pickup)
    if pickup.SubType == ITEM_UPGRADER and not save.IsEnabled() then
        pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 0, true)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.onPickupInit, PickupVariant.PICKUP_COLLECTIBLE)

function mod:onGameExit(shouldSave)
    closeMenu()
    if shouldSave then save.Save() end
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.onGameExit)
