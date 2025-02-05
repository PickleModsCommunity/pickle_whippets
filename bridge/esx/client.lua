if GetResourceState('es_extended') ~= 'started' then return end

ESX = exports.es_extended:getSharedObject()

function ShowNotification(text)
	ESX.ShowNotification(text)
end

function ServerCallback(name, cb, ...)
    ESX.TriggerServerCallback(name, cb,  ...)
end

function CanAccessGroup(data)
    if not data then return true end
    local pdata = ESX.GetPlayerData()
    for k,v in pairs(data) do 
        if (pdata.job.name == k and pdata.job.grade >= v) then return true end
    end
    return false
end 

function GetItemLabel(item)
    return Inventory.Items[item] and Inventory.Items[item].label or item
end

RegisterNetEvent(GetCurrentResourceName()..":showNotification", function(text)
    ShowNotification(text)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded',function(xPlayer, isNew, skin)
    TriggerServerEvent("pickle_whippets:initializePlayer")
end)

RegisterNetEvent("pickle_whippets:executeStatus", function(statuses)
    for k,v in pairs(statuses) do 
        if Config.MaxValues[k] then
            local value = (0.01 * v) * Config.MaxValues[k]
            if value >= 0 then
                TriggerEvent('esx_status:add', status, value)
            else
                TriggerEvent('esx_status:remove', status, math.abs(value))
            end
        end
    end
end)

-- Inventory Fallback

CreateThread(function()
    Wait(100)
    
    if InitializeInventory then return InitializeInventory() end -- Already loaded through inventory folder.

    Inventory = {}

    Inventory.Items = {}
    
    Inventory.Ready = false
    
    RegisterNetEvent("pickle_whippets:setupInventory", function(data)
        Inventory.Items = data.items
        Inventory.Ready = true
    end)
end)