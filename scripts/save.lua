-- Ukladani stavu modu (aktualni nabidky na obrazovce "Choose Your Destiny").
-- Nabidky se pamatuji po celou dobu runu, aby se nedaly prerollovat zavrenim a otevrenim menu.
local json = require("json")

local save = {}

local mod = nil
local data = { offers = {} }

function save.Init(m)
    mod = m
end

function save.Load(isContinued)
    data = { offers = {} }
    if isContinued and mod:HasData() then
        local ok, loaded = pcall(json.decode, mod:LoadData())
        if ok and type(loaded) == "table" then
            data = loaded
            data.offers = data.offers or {}
        end
    end
end

function save.Save()
    mod:SaveData(json.encode(data))
end

-- klice jsou stringy, protoze json neumi ciselne klice v objektu
function save.GetOffers(sourceId)
    return data.offers[tostring(sourceId)]
end

function save.SetOffers(sourceId, offers)
    data.offers[tostring(sourceId)] = offers
    save.Save()
end

return save
