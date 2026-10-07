-- Logika duplikace itemu (kapitola 1.2 design dokumentu).
--
-- Duplikace zdvojnasobi pocet kopii itemu (1 -> 2 -> 4 -> 8 ...). Sance klesa exponencialne
-- s log2 vysledneho poctu kopii:
--     sance(n) = BASE_CHANCE * DECAY ^ (log2(n) - 1)
-- DECAY = sqrt(0.5 % / 10 %) prolozi krivku body z tabulky: 2x = 10 %, 4x = 2.2 %, 8x = 0.5 %.
local duplication = {}

duplication.BASE_CHANCE = 0.10
duplication.DECAY = math.sqrt(0.005 / 0.10)
duplication.DOUBLES = true -- false = duplikace prida vzdy jen 1 kopii

function duplication.GetCount(player, id)
    return player:GetCollectibleNum(id, true)
end

function duplication.GetTargetCount(count)
    if duplication.DOUBLES then
        return math.max(count, 1) * 2
    end
    return count + 1
end

function duplication.GetChance(targetCount)
    local k = math.log(targetCount) / math.log(2)
    return duplication.BASE_CHANCE * duplication.DECAY ^ (k - 1)
end

-- Vrati true pri uspechu. Pri neuspechu se nic nestane (jen se spotrebuje naboj).
function duplication.Try(player, id, rng)
    local count = duplication.GetCount(player, id)
    local target = duplication.GetTargetCount(count)
    if rng:RandomFloat() >= duplication.GetChance(target) then
        return false
    end
    for _ = 1, target - count do
        player:AddCollectible(id, 0, false)
    end
    return true
end

return duplication
