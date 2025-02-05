local PlayerWhippets = {}
VehicleNitrous = {}

function EquipWhippet(source, item, metadata, slot)
    local player = PlayerWhippets[source]
    if player then ShowNotification(source, _L("w_already_equipped")) return end
    PlayerWhippets[source] = {
        durability = ((metadata and metadata.durability ~= nil) and (metadata.durability / 100) or 1.0),
        item = item,
        metadata = metadata,
        slot = slot
    }
    TriggerClientEvent("pickle_whippets:useWhippet", source, PlayerWhippets[source])
end

function DequipWhippet(source)
    local player = PlayerWhippets[source]
    if not player then ShowNotification(source, _L("w_not_equipped")) return end
    if not Inventory.NoMetadata then
        if player.durability > 0 then
            Inventory.AddItem(source, player.item, 1, {durability = math.floor(player.durability * 100)}, player.slot)
        else
            Inventory.AddItem(source, player.item .. "_empty", 1, nil, player.slot)
        end
    end
    local object = NetworkGetEntityFromNetworkId(player.whippetProp)
    if DoesEntityExist(object) then
        DeleteEntity(object)
    end
    PlayerWhippets[source] = nil
    TriggerClientEvent("pickle_whippets:dequipWhippet", source)
end

function ProcessEffects(source, time)
    local maxTime = 200
    local percent = math.floor((time / maxTime) * 100)
    if percent > 100 then percent = 100 end
    local usageTier = nil
    for i=1, #Config.WhippetSettings.usageTiers do
        local tier = Config.WhippetSettings.usageTiers[i]
        local minPercent = tier.minPercent
        if percent >= minPercent and (not usageTier or (usageTier.percent < minPercent)) then
            usageTier = {percent = minPercent, tier = i}
        end
    end
    if usageTier then
        local tier = Config.WhippetSettings.usageTiers[usageTier.tier]
        ExecuteStatus(source, tier.status)
        TriggerClientEvent("pickle_whippets:whippetEffect", source, usageTier.tier)
    end
end

function RestrictionCheck(source, restrictionId, restrictionData)
    local restriction = Config.CustomRestrictions[restrictionId]
    local restrictionData = restrictionData or {}
    if not restriction then return true end
    local result = function(source, ...)
        local result, reason = restriction(source, ...)
        if not reason then 
            reason = _L("restriction_generic")
        end
        return result, reason
    end
    if restrictionId == "useWhippet" then
        return result(source, restrictionData.item)
    elseif restrictionId == "gasProcessor" then
        return result(source, restrictionData.id)
    elseif restrictionId == "shop" then
        return result(source, restrictionData.id)
    end
end

function SetVehicleNitrous(netId, amount)
    VehicleNitrous[netId].fuel = amount
    TriggerClientEvent("pickle_whippets:setVehicleNitrous", -1, netId, VehicleNitrous[netId])
end

function GetVehicleNitrous(netId)
    return (VehicleNitrous[netId])
end

function AddVehicleNitrous(netId, amount)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(veh) then return end
    local currentNitrous = GetVehicleNitrous(netId).fuel
    local newNitrous = currentNitrous + amount
    if newNitrous > 1.0 then newNitrous = 1.0 end
    SetVehicleNitrous(netId, newNitrous)
end

CreateThread(function()
    while true do
        for k,v in pairs(VehicleNitrous) do
            local veh = NetworkGetEntityFromNetworkId(k)
            if not DoesEntityExist(veh) then
                VehicleNitrous[k] = nil
                TriggerClientEvent("pickle_whippets:setVehicleNitrous", -1, k, nil)
                TriggerClientEvent("pickle_whippets:setVehicleNitrousActive", -1, k, false)
            end
        end 
        Wait(5000)
    end
end)

RegisterCallback("pickle_whippets:restrictionCheck", function(source, cb, restrictionId, restrictionData)
    cb(RestrictionCheck(source, restrictionId, restrictionData))
end)

RegisterNetEvent("pickle_whippets:whippetSmoke", function(time, vehNetId)
    local source = source
    local player = PlayerWhippets[source]
    if not player then return end
    PlayerWhippets[source].durability = PlayerWhippets[source].durability - (time * Config.WhippetSettings.usagePercentPerTick)
    if not vehNetId then
        -- local whippetFuelDisplay = string.format(Config.WhippetSettings.measurementUnits.format, math.floor(lerp(0, Config.WhippetSettings.measurementUnits.capacity, PlayerWhippets[source].durability)) .. " / " .. Config.WhippetSettings.measurementUnits.capacity)
        TriggerClientEvent("pickle_whippets:whippetSmoke", -1, source, player.item, time * 10)
        ProcessEffects(source, time)
    else
        if not VehicleNitrous[vehNetId] then 
            VehicleNitrous[vehNetId] = {fuel = 0.0, item = player.item}
        end
        AddVehicleNitrous(vehNetId, (time * Config.WhippetSettings.usagePercentPerTick))
    end
end)

RegisterNetEvent("pickle_whippets:setVehicleNitrousActive", function(netId, status, fuelLost)
    local vehicle = VehicleNitrous[netId]
    if not vehicle then return end
    VehicleNitrous[netId].status = status
    if fuelLost then
        local newFuel = VehicleNitrous[netId].fuel - fuelLost
        if newFuel < 0 then newFuel = 0 end
        VehicleNitrous[netId].fuel = newFuel
        if newFuel == 0 then
            VehicleNitrous[netId].status = false
            TriggerClientEvent("pickle_whippets:setVehicleNitrousActive", -1, netId, status)
            return
        end
    end
    TriggerClientEvent("pickle_whippets:setVehicleNitrousActive", -1, netId, status)
end)

RegisterNetEvent("pickle_whippets:dequipWhippet", function()
    local source = source
    DequipWhippet(source)
end)

RegisterNetEvent("pickle_whippets:setWhippetProp", function(netId)
    local source = source
    local player = PlayerWhippets[source]
    if not player then return end
    PlayerWhippets[source].whippetProp = netId
end)

AddEventHandler("playerDropped", function()
    local source = source
    DequipWhippet(source)
end)

for k,v in pairs(Config.Whippets) do
    RegisterUsableItem(k, function(source, metadata, slot)
        local result, reason = RestrictionCheck(source, "useWhippet", {item = k})
        if not result then ShowNotification(source, reason) return end
        Inventory.RemoveItem(source, k, 1, slot)
        EquipWhippet(source, k, metadata, slot)
    end)
end

-- CreateThread(function()
--     Wait(5000)
--     EquipWhippet(7, "n2o_strawberry", {}, nil)
--     EquipWhippet(8, "n2o_raspberry", {}, nil)
-- end)