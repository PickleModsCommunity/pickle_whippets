if GetResourceState('qs-inventory') ~= 'started' then return end

Inventory = {}

Inventory.Items = {}

Inventory.Ready = false

-- STASHES

Inventory.OpenStash = function(id, label)
    local other = {}
    other.maxweight = Config.Storage.maxWeight
    other.slots = Config.Storage.slots
    TriggerServerEvent("inventory:server:OpenInventory", "stash", id, other)
    TriggerEvent("inventory:client:SetCurrentStash", id)
end

RegisterNetEvent("pickle_whippets:setupInventory", function(data)
    Inventory.Items = data.items
    Inventory.Ready = true
end)

function InitializeInventory()
end