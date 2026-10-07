-- Spolecne pomocne funkce pro praci s itemy (vyber zdrojoveho itemu, filtrovani poolu).
local items = {}

local itemConfig = Isaac.GetItemConfig()
local upgraderId = Isaac.GetItemIdByName("Item Upgrader")
local byQuality = nil

function items.GetConfig(id)
    return itemConfig:GetCollectible(id)
end

function items.GetQuality(id)
    local config = itemConfig:GetCollectible(id)
    return config and config.Quality or 0
end

-- Muze byt item cilem duplikace / zmeny? Jen pasivni itemy a familiari, bez quest itemu.
function items.IsEligible(id)
    if id == upgraderId then return false end
    local config = itemConfig:GetCollectible(id)
    if not config or config.Hidden then return false end
    if config.Type ~= ItemType.ITEM_PASSIVE and config.Type ~= ItemType.ITEM_FAMILIAR then return false end
    if config:HasTags(ItemConfig.TAG_QUEST) then return false end
    return true
end

-- Itemy, ktere muze hrac vsadit: vsechny vlastnene vhodne itemy, nejnovejsi prvni.
function items.GetOwnedItems(player)
    local result, seen = {}, {}
    local function add(id)
        if not seen[id] and items.IsEligible(id) and player:HasCollectible(id, true) then
            seen[id] = true
            result[#result + 1] = id
        end
    end

    if player.GetHistory then -- REPENTOGON: poradi podle historie sebrani
        local history = player:GetHistory():GetCollectiblesHistory()
        for i = #history, 1, -1 do
            local entry = history[i]
            if not entry:IsTrinket() then add(entry:GetItemID()) end
        end
    end
    -- doplnit itemy, ktere v historii nejsou (napr. bez REPENTOGONu)
    for id = 1, itemConfig:GetCollectibles().Size - 1 do
        add(id)
    end
    return result
end

-- Seznam odemcenych itemu dane kvality, ze kterych se generuji nabidky.
function items.GetByQuality(quality)
    if not byQuality then
        byQuality = { [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {} }
        for id = 1, itemConfig:GetCollectibles().Size - 1 do
            local config = itemConfig:GetCollectible(id)
            if config and items.IsEligible(id) and config:IsAvailable() then
                local list = byQuality[config.Quality]
                if list then list[#list + 1] = id end
            end
        end
    end
    return byQuality[quality] or {}
end

return items
