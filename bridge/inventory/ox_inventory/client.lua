if GetResourceState('ox_inventory') ~= 'started' then return end

Inventory = {}

Inventory.Items = {}

Inventory.Ready = false

-- STASHES

Inventory.OpenStash = function(id, label)
    exports.ox_inventory:openInventory('stash', id)
end

RegisterNetEvent("pickle_whippets:setupInventory", function(data)
    Inventory.Items = data.items
    Inventory.Ready = true
end)

function InitializeInventory()
end