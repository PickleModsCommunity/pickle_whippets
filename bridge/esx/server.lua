if GetResourceState('es_extended') ~= 'started' then return end

ESX = exports.es_extended:getSharedObject()

function RegisterCallback(name, cb)
    ESX.RegisterServerCallback(name, cb)
end

function RegisterUsableItem(name, cb)
    ESX.RegisterUsableItem(name, function(source, item, data)
        local durability = Config.DefaultDurability or 100
        if type(item) == "table" and item.metadata and (item.metadata.durability ~= nil) then
            durability = item.metadata.durability
        end
        if type(data) == "table" and data.metadata and (data.metadata.durability ~= nil) then
            durability = data.metadata.durability
        end
        cb(source, {durability = durability}, data.slot)
    end)
end

function ShowNotification(target, text)
	TriggerClientEvent(GetCurrentResourceName()..":showNotification", target, text)
end

function GetIdentifier(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer.identifier
end

function IsPlayerAdmin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()
    local job = xPlayer.job.name
    local grade = xPlayer.job.grade
    if Config.Admin.groups[group] then
        return true
    end
    if Config.Admin.jobs[job] and Config.Admin.jobs[job] <= grade then
        return true
    end
    return false
end

function GetSourceFromIdentifier(identifier)
    local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
    return xPlayer and xPlayer.source or nil
end

function GetPaymentMethodAmount(source, method)
    local xPlayer = ESX.GetPlayerFromId(source)
    if method == "cash" then
        return xPlayer.getMoney()
    elseif method == "card" then
        return xPlayer.getAccount("bank").money
    elseif method == "dirtycash" then
        return xPlayer.getAccount("black_money").money
    end
end

function ChargePaymentMethod(source, method, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if method == "cash" then
        xPlayer.removeMoney(amount)
    elseif method == "card" then
        xPlayer.removeAccountMoney("bank", amount)
    elseif method == "dirtycash" then
        xPlayer.removeAccountMoney("black_money", amount)
    end
end

function AddPaymentMethodAmount(source, method, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if method == "cash" then
        xPlayer.addMoney(amount)
    elseif method == "card" then
        xPlayer.addAccountMoney("bank", amount)
    elseif method == "dirtycash" then
        xPlayer.addAccountMoney("black_money", amount)
    end
end

function GetPlayerCharacterName(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer.getName()
end

function CanAdministrateBusinesses(source)
    return CheckPermission(source, Config.BusinessAdministration)
end

function CheckPermission(source, permission)
    local xPlayer = ESX.GetPlayerFromId(source)
    local name = xPlayer.job.name
    local rank = xPlayer.job.grade
    local group = xPlayer.getGroup()
    if permission.jobs[name] and permission.jobs[name] <= rank then 
        return true
    end
    for i=1, #permission.groups do 
        if group == permission.groups[i] then 
            return true 
        end
    end
end

function GetItemLabel(item)
    return Inventory.Items[item] and Inventory.Items[item].label or item
end

-- Status

local DefaultMax = 1000000

for k,v in pairs(Config.MaxValues) do 
    if v < 1 then
        Config.MaxValues[k] = DefaultMax
    end  
end

function ExecuteStatus(source, statuses)
    local xPlayer = ESX.GetPlayerFromId(source)
    for k,v in pairs(statuses) do 
        if not Config.MaxValues[k] then
            Config.ExternalStatus(source, k, v)
        end
    end
    TriggerClientEvent("pickle_whippets:executeStatus", source, statuses)
end

-- Inventory Fallback

CreateThread(function()
    Wait(100)

    if InitializeInventory then return InitializeInventory() end -- Already loaded through inventory folder.
    
    Inventory = {}

    Inventory.NoMetadata = true

    Inventory.Items = {}
    
    Inventory.Ready = false

    Inventory.CanCarryItem = function(source, name, count)
        local xPlayer = ESX.GetPlayerFromId(source)
        if Config.InventoryLimit then 
            local item = xPlayer.getInventoryItem(name)
            return (item.limit >= item.count + count)
        else 
            return xPlayer.canCarryItem(name, count)
        end
    end

    Inventory.GetInventory = function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        local items = {}
        local data = xPlayer.getInventory()
        for i=1, #data do 
            local item = data[i]
            local durability = 100
            items[#items + 1] = {
                slot = nil,
                name = item.name,
                label = item.label,
                count = item.count,
                durability = durability,
                metadata = nil,
                weight = item.weight
            }
        end
        return items
    end

    Inventory.UpdateInventory = function(source)
        SetTimeout(1000, function()
            TriggerClientEvent("pickle_whippets:updateInventory", source, Inventory.GetInventory(source))
        end)
    end

    Inventory.AddItem = function(source, name, count, metadata) -- Metadata is not required.
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.addInventoryItem(name, count)
        Inventory.UpdateInventory(source)
    end

    Inventory.RemoveItem = function(source, name, count)
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.removeInventoryItem(name, count)
        Inventory.UpdateInventory(source)
    end

    Inventory.AddWeapon = function(source, name, count, metadata) -- Metadata is not required.
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.addWeapon(name, 0)
        Inventory.UpdateInventory(source)
    end

    Inventory.RemoveWeapon = function(source, name, count)
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.removeWeapon(name, 0)
        Inventory.UpdateInventory(source)
    end

    Inventory.GetItemCount = function(source, name)
        local xPlayer = ESX.GetPlayerFromId(source)
        local item = xPlayer.getInventoryItem(name)
        return item and item.count or 0
    end

    Inventory.HasWeapon = function(source, name, count)
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer.hasWeapon(name)
    end

    -- STASH FALLBACK

    Inventory.RegisterStash = function(id, label, coords)
    end

    MySQL.ready(function() 
        MySQL.Async.fetchAll("SELECT * FROM items;", {}, function(results) 
            for i=1, #results do 
                Inventory.Items[results[i].name] = {label = results[i].label}
            end
            Inventory.Ready = true
        end)
    end)
end)