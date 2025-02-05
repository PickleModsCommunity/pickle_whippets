if GetResourceState('qb-core') ~= 'started' then return end

QBCore = exports['qb-core']:GetCoreObject()

function ServerCallback(name, cb, ...)
    QBCore.Functions.TriggerCallback(name, cb,  ...)
end

function ShowNotification(text)
	QBCore.Functions.Notify(text)
end

function CanAccessGroup(data)
    if not data then return true end
    local pdata = QBCore.Functions.GetPlayerData()
    for k,v in pairs(data) do 
        if (pdata.job.name == k and pdata.job.grade.level >= v) then return true end
    end
    return false
end 

function GetItemLabel(item)
    return Inventory.Items[item] and Inventory.Items[item].label or item
end

RegisterNetEvent(GetCurrentResourceName()..":showNotification", function(text)
    ShowNotification(text)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent("pickle_whippets:initializePlayer")
end)

RegisterNetEvent("pickle_whippets:executeStatus", function(statuses)
    -- Not needed as server handles this.
end)

-- Inventory Fallback

CreateThread(function()
    Wait(100)
    
    if InitializeInventory then return InitializeInventory() end -- Already loaded through inventory folder.

    Inventory = {}

    Inventory.Items = {}
    
    Inventory.Ready = false
    
    -- STASHES
    
    Inventory.OpenStash = function(id, label)
        TriggerServerEvent("inventory:server:OpenInventory", "stash", id, {
            maxweight = Config.Storage.maxWeight,
            slots = Config.Storage.slots,
        })
        TriggerEvent("inventory:client:SetCurrentStash", id)
    end
    
    RegisterNetEvent("pickle_whippets:setupInventory", function(data)
        Inventory.Items = data.items
        Inventory.Ready = true
    end)
end)