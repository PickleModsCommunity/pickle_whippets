if GetResourceState('qs-inventory') ~= 'started' then return end

Inventory = {}

Inventory.Items = {}

Inventory.Ready = false

Inventory.CanCarryItem = function(source, name, count)
    return exports['qs-inventory']:CanCarryItem(source, name, count)
end

Inventory.GetInventory = function(source)
    local items = {}
    local data = exports['qs-inventory']:GetInventory(source)
    for slot, item in pairs(data) do 
        items[#items + 1] = {
            name = item.name,
            label = item.label,
            count = item.amount,
            weight = item.weight,
            slot = item.slot,
            durability = (item.info.quality ~= nil and item.info.quality or 100),
            metadata = item.info
        }
    end
    return items
end

Inventory.AddItem = function(source, name, count, metadata, slot) -- Metadata is not required.
    local data = nil
    if metadata and metadata.durability then
        data = {quality = metadata.durability * 100}
    end
    exports['qs-inventory']:AddItem(source, name, count, slot, data)
end

Inventory.RemoveItem = function(source, name, count, slot)
    exports['qs-inventory']:RemoveItem(source, name, count, slot)
end

Inventory.SetMetadata = function(source, slot, metadata)
    exports['qs-inventory']:SetItemMetadata(source, slot, metadata)
end

Inventory.GetItemCount = function(source, name)
    return exports['qs-inventory']:GetItemTotalAmount(source, name) or 0
end

-- STASHES

Inventory.RegisterStash = function(id, label, coords)
    exports['qs-inventory']:RegisterStash(id, Config.Storage.slots, Config.Storage.maxWeight)
end

function InitializeInventory()
    lib.callback.register("pickle_whippets:getInventory", function(source)
        return Inventory.GetInventory(source)
    end)
    
    for item, data in pairs(exports['qs-inventory']:GetItemList()) do
        Inventory.Items[item] = {label = data.label}
    end
    
    Inventory.Ready = true
end