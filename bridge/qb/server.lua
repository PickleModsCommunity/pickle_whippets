if GetResourceState('qb-core') ~= 'started' then return end

QBCore = exports['qb-core']:GetCoreObject()

function RegisterCallback(name, cb)
    QBCore.Functions.CreateCallback(name, cb)
end

function RegisterUsableItem(name, cb)
    QBCore.Functions.CreateUseableItem(name, function(source, data, item)
        local durability = Config.DefaultDurability or 100
        if type(data) == "table" and data.info and (data.info.quality ~= nil) then
            durability = data.info.quality
        end
        if type(item) == "table" and data.info and (item.info.quality ~= nil) then
            durability = item.info.quality
        end
        cb(source, {durability = durability}, data.slot)
    end)
end

function ShowNotification(target, text)
	TriggerClientEvent(GetCurrentResourceName()..":showNotification", target, text)
end

function GetIdentifier(source)
    local xPlayer = QBCore.Functions.GetPlayer(source).PlayerData
    return xPlayer.citizenid 
end

function GetSourceFromIdentifier(identifier)
    local xPlayer = QBCore.Functions.GetPlayerByCitizenId(identifier)
    return xPlayer and xPlayer.PlayerData.source or nil
end

function GetPaymentMethodAmount(source, method)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if method == "cash" then
        return xPlayer.PlayerData.money.cash
    elseif method == "card" then
        return xPlayer.PlayerData.money.bank
    elseif method == "dirtycash" then
        return xPlayer.PlayerData.money.black_money
    end
end

function ChargePaymentMethod(source, method, amount)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if method == "cash" then
        xPlayer.Functions.RemoveMoney("cash", amount)
    elseif method == "card" then
        xPlayer.Functions.RemoveMoney("bank", amount)
    elseif method == "dirtycash" then
        xPlayer.Functions.RemoveMoney("black_money", amount)
    end
end

function AddPaymentMethodAmount(source, method, amount)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if method == "cash" then
        xPlayer.Functions.AddMoney("cash", amount)
    elseif method == "card" then
        xPlayer.Functions.AddMoney("bank", amount)
    elseif method == "dirtycash" then
        xPlayer.Functions.AddMoney("black_money", amount)
    end
end

function GetPlayerCharacterName(source)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    return xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
end

function CanAdministrateBusinesses(source)
    return CheckPermission(source, Config.BusinessAdministration)
end

function CheckPermission(source, permission)
    local source = tonumber(source)
    local xPlayer = QBCore.Functions.GetPlayer(source).PlayerData
    local name = xPlayer.job.name
    local rank = xPlayer.job.grade.level
    if permission.jobs[name] and permission.jobs[name] <= rank then 
        return true
    end
    for i=1, #permission.groups do 
        if QBCore.Functions.HasPermission(source, permission.groups[i]) then 
            return true 
        end
    end
end

function GetItemLabel(item)
    return Inventory.Items[item] and Inventory.Items[item].label or item
end

function IsPlayerAdmin(source)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    local group = xPlayer.PlayerData.permission
    local job = xPlayer.PlayerData.job.name
    local grade = xPlayer.PlayerData.job.grade.level
    if IsPlayerAceAllowed(source, "whippets.admin") then
        return true
    end
    if Config.Admin.jobs[job] and Config.Admin.jobs[job] <= grade then
        return true
    end
    return false
end

-- Status

local DefaultMax = 100

for k,v in pairs(Config.MaxValues) do 
    if v < 1 then
        Config.MaxValues[k] = DefaultMax
    end  
end

function ExecuteStatus(source, statuses)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    for k,v in pairs(statuses) do 
        if Config.MaxValues[k] then
            local value = (0.01 * v) * Config.MaxValues[k]
            if xPlayer.PlayerData.metadata[k] then
                xPlayer.PlayerData.metadata[k] = ((xPlayer.PlayerData.metadata[k] + value < 0) and 0 or (xPlayer.PlayerData.metadata[k] + value))
            else
                xPlayer.PlayerData.metadata[k] = (value > 0 and value or 0)
            end
            xPlayer.Functions.SetMetaData(k, xPlayer.PlayerData.metadata[k])
        else
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

    Inventory.Items = {}
    
    Inventory.Ready = false

    Inventory.CanCarryItem = function(source, name, count)
        local xPlayer = QBCore.Functions.GetPlayer(source)
        local weight = QBCore.Player.GetTotalWeight(xPlayer.PlayerData.items)
        local item = QBCore.Shared.Items[name:lower()]
        return ((weight + (item.weight * count)) <= QBCore.Config.Player.MaxWeight)
    end

    Inventory.GetInventory = function(source)
        local xPlayer = QBCore.Functions.GetPlayer(source)
        local items = {}
        local data = xPlayer.PlayerData.items
        for slot, item in pairs(data) do 
            local durability = item.info and item.info.quality or nil
            if durability == nil then
                durability = 100
            end
            items[#items + 1] = {
                slot = slot,
                name = item.name,
                label = item.label,
                count = item.amount,
                durability = durability,
                metadata = item.info or {},
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
        local xPlayer = QBCore.Functions.GetPlayer(source)
        local data = nil
        if metadata and metadata.durability then
            data = {quality = metadata.durability}
        end
        xPlayer.Functions.AddItem(name, count, nil, data)
        Inventory.UpdateInventory(source)
    end

    Inventory.RemoveItem = function(source, name, count, slot)
        local xPlayer = QBCore.Functions.GetPlayer(source)
        xPlayer.Functions.RemoveItem(name, count, slot)
        Inventory.UpdateInventory(source)
    end

    Inventory.AddWeapon = function(source, name, count, metadata) -- Metadata is not required.
        Inventory.AddItem(source, name, count, metadata)
    end

    Inventory.RemoveWeapon = function(source, name, count)
        Inventory.RemoveItem(source, name, count, metadata)
    end

    Inventory.GetItemCount = function(source, name)
        local xPlayer = QBCore.Functions.GetPlayer(source)
        local item = xPlayer.Functions.GetItemByName(name)
        return item and item.amount or 0
    end

    Inventory.HasWeapon = function(source, name, count)
        return (Inventory.GetItemCount(source, name) > 0)
    end

    -- STASH FALLBACK
    
    Inventory.RegisterStash = function(id, label, coords)
    end

    RegisterCallback("pickle_whippets:getInventory", function(source, cb)
        cb(Inventory.GetInventory(source))
    end)

    for item, data in pairs(QBCore.Shared.Items) do
        Inventory.Items[item] = {label = data.label}
    end
    Inventory.Ready = true
end)