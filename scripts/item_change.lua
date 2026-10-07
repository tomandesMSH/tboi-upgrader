-- Logika zmeny itemu / upgradu kvality (kapitola 1.3 design dokumentu).
-- Vygeneruje 9 slotu po 3 itemech; kvalita slotu se losuje podle rozdilu oproti kvalite
-- zdrojoveho itemu, takze velke skoky (Q1 -> Q4) jsou vzacne. Item ze slotu vybere loterie.
local items = include("scripts.items")
local pricing = include("scripts.pricing")

local change = {}

change.SLOT_COUNT = 9
change.ITEMS_PER_SLOT = 3

-- vaha podle rozdilu kvality (cil - zdroj); co tu neni, nemuze padnout
change.DELTA_WEIGHTS = {
    [-1] = 15,
    [0] = 40,
    [1] = 30,
    [2] = 10,
    [3] = 4,
    [4] = 1,
}

local function rollQuality(sourceQuality, rng)
    local options, total = {}, 0
    for q = 0, 4 do
        local weight = change.DELTA_WEIGHTS[q - sourceQuality] or 0
        if weight > 0 and #items.GetByQuality(q) > 0 then
            options[#options + 1] = { quality = q, weight = weight }
            total = total + weight
        end
    end
    if total == 0 then return nil end

    local roll = rng:RandomFloat() * total
    for _, option in ipairs(options) do
        roll = roll - option.weight
        if roll < 0 then return option.quality end
    end
    return options[#options].quality
end

local function rollItem(quality, rng, used)
    local list = items.GetByQuality(quality)
    for _ = 1, 20 do
        local id = list[rng:RandomInt(#list) + 1]
        if not used[id] then return id end
    end
    return nil
end

-- Vrati pole slotu: { quality = q, items = {id, id, id}, tier = "normal" | "rare" }
-- Kazdy slot ma jednu kvalitu (zobrazenou ikonou v rohu) a vsechny jeho itemy jsou te kvality.
function change.GenerateOffers(sourceId, rng)
    local sourceQuality = items.GetQuality(sourceId)
    local used = { [sourceId] = true }
    local slots = {}

    for s = 1, change.SLOT_COUNT do
        local quality = rollQuality(sourceQuality, rng)
        local slotItems = {}
        if quality then
            for _ = 1, change.ITEMS_PER_SLOT do
                local id = rollItem(quality, rng, used)
                if id then
                    used[id] = true
                    slotItems[#slotItems + 1] = id
                end
            end
        end
        slots[s] = {
            quality = quality,
            items = slotItems,
            tier = pricing.GetTierName(sourceQuality, { quality }),
        }
    end

    return slots
end

-- Loterie: ktery item ze slotu hrac dostane.
function change.RollWinner(slot, rng)
    return rng:RandomInt(#slot.items) + 1
end

-- Ruleta: zakladni sance podle kvality vsazeneho itemu (radek) a ciloveho itemu (sloupec) + bonus za Luck.
-- Skoky do Q4 jsou schvalne hodne vzacne, Q4 itemy jsou oproti Q3 brutalni.
change.WIN_CHANCE = {
    --       Q0    Q1    Q2    Q3    Q4
    [0] = { 0.70, 0.45, 0.20, 0.08, 0.01 },
    [1] = { 0.85, 0.70, 0.45, 0.20, 0.03 },
    [2] = { 0.90, 0.85, 0.70, 0.45, 0.06 },
    [3] = { 0.95, 0.90, 0.85, 0.70, 0.12 },
    [4] = { 0.95, 0.95, 0.90, 0.85, 0.70 },
}
change.LUCK_PER_POINT = 0.02 -- +2 % za kazdy bod Lucku (zaporny Luck sanci snizuje)
change.MIN_CHANCE = 0.01
change.MAX_CHANCE = 0.95

-- vrati: celkova sance, zakladni sance, bonus za luck, skok kvality
function change.GetWinChance(player, sourceId, targetId)
    local sourceQuality, targetQuality = items.GetQuality(sourceId), items.GetQuality(targetId)
    local jump = targetQuality - sourceQuality
    local row = change.WIN_CHANCE[sourceQuality]
    local base = row and row[targetQuality + 1] or 0.5
    local luck = player.Luck * change.LUCK_PER_POINT
    local chance = math.max(change.MIN_CHANCE, math.min(change.MAX_CHANCE, base + luck))
    return chance, base, luck, jump
end

-- prohra v rulete: vsazeny item propada
function change.Forfeit(player, sourceId)
    player:RemoveCollectible(sourceId)
end

function change.Apply(player, sourceId, targetId)
    player:RemoveCollectible(sourceId)
    player:AddCollectible(targetId, 0, true)
    Game():GetItemPool():RemoveCollectible(targetId)
end

return change
