-- Ceny slotu na obrazovce "Choose Your Destiny".
-- Presny cenovy system je zatim otevrena otazka (kapitola 5), proto je vse v tabulce TIERS.
local pricing = {}

local currencies = {
    coins = { get = function(p) return p:GetNumCoins() end, add = function(p, n) p:AddCoins(n) end },
    keys  = { get = function(p) return p:GetNumKeys() end,  add = function(p, n) p:AddKeys(n) end },
    bombs = { get = function(p) return p:GetNumBombs() end, add = function(p, n) p:AddBombs(n) end },
}

pricing.TIERS = {
    normal = { currency = "coins", amount = 3 },
    rare   = { currency = "coins", amount = 4 },
}

-- slot s itemem aspon o RARE_DELTA kvality lepsim nez zdroj je "rare"
pricing.RARE_DELTA = 2

function pricing.GetTierName(sourceQuality, slotQualities)
    for _, q in ipairs(slotQualities) do
        if q - sourceQuality >= pricing.RARE_DELTA then
            return "rare"
        end
    end
    return "normal"
end

function pricing.GetTier(name)
    return pricing.TIERS[name] or pricing.TIERS.normal
end

function pricing.CanAfford(player, tierName)
    local tier = pricing.GetTier(tierName)
    return currencies[tier.currency].get(player) >= tier.amount
end

function pricing.Pay(player, tierName)
    local tier = pricing.GetTier(tierName)
    currencies[tier.currency].add(player, -tier.amount)
end

return pricing
