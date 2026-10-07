-- Ukladani stavu modu.
--   enabled - prepinac v menu vyberu postavy (truhla); plati napric runy
--   offers  - aktualni nabidky na obrazovce "Choose Your Destiny"; jen pro aktualni run,
--             aby se nedaly prerollovat zavrenim a otevrenim menu
local json = require("json")

local save = {}

local mod = nil
local data = { enabled = false, offers = {} }

function save.Init(m)
    mod = m
end

-- nacte vse ze souboru (save data jsou per save slot, proto se vola az po vyberu slotu)
function save.LoadAll()
    data = { enabled = false, offers = {} }
    if mod:HasData() then
        local ok, loaded = pcall(json.decode, mod:LoadData())
        if ok and type(loaded) == "table" then
            data.enabled = loaded.enabled == true
            data.offers = type(loaded.offers) == "table" and loaded.offers or {}
        end
    end
end

-- zacatek hry: nabidky z minuleho runu plati jen pri pokracovani
function save.Load(isContinued)
    save.LoadAll()
    if not isContinued then
        data.offers = {}
        save.Save()
    end
end

function save.Save()
    mod:SaveData(json.encode(data))
end

function save.IsEnabled()
    return data.enabled
end

function save.SetEnabled(enabled)
    data.enabled = enabled
    save.Save()
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
