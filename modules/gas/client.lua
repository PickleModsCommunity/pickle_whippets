local CurrentWhippet = nil
local TrailEntities = {}
local VehicleNitrous = {}
local LocalVehicleNitrous = {}

function SetVehicleNitrous(netId, data)
    VehicleNitrous[netId] = data
end

function SetVehicleNitrousActive(netId, active)
    if not NetworkDoesNetworkIdExist(netId) then return end
    local vehicle = NetToVeh(netId)
    if not DoesEntityExist(vehicle) then return end
    local nitrous = VehicleNitrous[netId]
    local whippetCfg = Config.Whippets[nitrous.item]
    if not LocalVehicleNitrous[netId] then
        LocalVehicleNitrous[netId] = {
            particles = {},
        }
    end
    for i=1, 17 do
        local boneName = (i > 1 and "exhaust_"..(i - 1) or "exhaust")
        local boneId = GetEntityBoneIndexByName(vehicle, boneName)
        if boneId ~= -1 then
            if active then
                RequestNamedPtfxAsset("scr_ar_planes")
                while not HasNamedPtfxAssetLoaded("scr_ar_planes") do
                    Citizen.Wait(0)
                end
                UseParticleFxAssetNextCall("scr_ar_planes")
                local particleEffect = StartParticleFxLoopedOnEntityBone("scr_ar_trail_smoke", vehicle, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, boneId, 0.3, 0.0, 0.0, 0.0)
                -- Customize the smoke color (RGB format)
                SetParticleFxLoopedAlpha(particleEffect, 0.5)  -- 50% transparency
                SetParticleFxLoopedColour(particleEffect, whippetCfg.vaporColor.r / 255, whippetCfg.vaporColor.g / 255, whippetCfg.vaporColor.b / 255)  -- Red smoke
                LocalVehicleNitrous[netId].particles[i] = particleEffect
            else
                StopParticleFxLooped(LocalVehicleNitrous[netId].particles[i], 0)
                LocalVehicleNitrous[netId].particles[i] = nil
            end
        end
    end
end

function GetClosestVehicleAtPos(coords, radius)
    local vehicles = GetGamePool("CVehicle")
    local closest, dist
    for i=1, #vehicles do
        local vehicle = vehicles[i]
        local vCoords = GetEntityCoords(vehicle)
        local d = #(coords - vCoords)
        if not dist or d < dist then
            closest = vehicle
            dist = d
        end
    end
    if dist and dist <= radius then
        return closest
    end
end

function GetNitrousDisplay(netId)
    local nitrous = VehicleNitrous[netId]?.fuel
    return string.format(Config.WhippetSettings.measurementUnits.format, math.floor(lerp(0, Config.WhippetSettings.measurementUnits.capacity, (nitrous and nitrous or 0))) .. " / " .. Config.WhippetSettings.measurementUnits.capacity)
end

function UpdateWhippetControls(closestVehicle, isVehicleFilling)
    local controls = {}
    local currentVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if CurrentWhippet then
        local whippetFuelDisplay = string.format(Config.WhippetSettings.measurementUnits.format, math.floor(lerp(0, Config.WhippetSettings.measurementUnits.capacity, CurrentWhippet.durability)) .. " / " .. Config.WhippetSettings.measurementUnits.capacity)
        if not isVehicleFilling then
            controls[#controls + 1] = { key = "LeftClick", action = _L("w_use") .. " ("..whippetFuelDisplay..")" }
        elseif Config.NitrousBoost.enabled then
            controls[#controls + 1] = { key = "R", action = _L("w_use_vehicle") .. " ("..whippetFuelDisplay..")" }
        end
        if Config.NitrousBoost.enabled then
            if DoesEntityExist(currentVehicle) then
                local currentNetId = VehToNet(currentVehicle)
                local nitrous = VehicleNitrous[currentNetId]?.fuel
                local driverPed = GetPedInVehicleSeat(currentVehicle, -1)
                if driverPed == PlayerPedId() and nitrous and nitrous > 0 then
                    controls[#controls + 1] = { key = "SHIFT", action = _L("w_use_vehicle_nitrous") .. " ("..GetNitrousDisplay(currentNetId)..")" }
                end
            elseif closestVehicle then
                controls[#controls + 1] = { key = "R", action = _L("w_use_vehicle") }
            end
        end
        controls[#controls + 1] = { key = "Backspace", action = _L("w_stop") }
    elseif Config.NitrousBoost.enabled then
        if DoesEntityExist(currentVehicle) then
            local currentNetId = VehToNet(currentVehicle)
            local nitrous = VehicleNitrous[currentNetId]?.fuel
            local driverPed = GetPedInVehicleSeat(currentVehicle, -1)
            if driverPed == PlayerPedId() and nitrous and nitrous > 0 then
                controls[#controls + 1] = { key = "SHIFT", action = _L("w_use_vehicle_nitrous") .. " ("..GetNitrousDisplay(currentNetId)..")" }
            end
        elseif closestVehicle then
            controls[#controls + 1] = { key = "R", action = _L("w_use_vehicle") }
        end
    end
    SendNUIMessage({
        type = "showControls",
        controls = controls
    })
end

CreateThread(function()
    if not Config.NitrousBoost.enabled then return end
    local showingUI = false
    local activeVehicle = nil
    while true do
        local wait = 1500
        local currentVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        local currentlyShowing = false
        local ped = PlayerPedId()
        if DoesEntityExist(currentVehicle) then
            local driverPed = GetPedInVehicleSeat(currentVehicle, -1)
            local netId = VehToNet(currentVehicle)
            if VehicleNitrous[netId] and VehicleNitrous[netId].fuel > 0 and NetworkDoesNetworkIdExist(netId) then
                local currentNitrous = VehicleNitrous[netId].fuel
                if not activeVehicle then
                    if driverPed == ped and IsControlJustPressed(1, 21) then
                        local defaultPower = GetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveForce")
                        activeVehicle = { fuelLost = 0, vehicle = currentVehicle, defaultPower = defaultPower, currentPower = defaultPower }
                        TriggerServerEvent("pickle_whippets:setVehicleNitrousActive", netId, true)
                        -- SetVehicleNitrousActive(netId, true)
                        SetExtraTimecycleModifier("rply_motionblur")
                        SetExtraTimecycleModifierStrength(0.6)
                        SetTimecycleModifier("RaceTurboFlash")
                        SetTimecycleModifierStrength(0.6)
                        SetVehicleEnginePowerMultiplier(activeVehicle.vehicle, Config.NitrousBoost.enginePower) -- Set the engine power to 100% to prevent the vehicle from slowing down.
                    end
                else
                    -- activeVehicle.currentPower = activeVehicle.currentPower
                    activeVehicle.fuelLost = activeVehicle.fuelLost + Config.NitrousBoost.usagePercentPerTick
                    VehicleNitrous[netId].fuel = VehicleNitrous[netId].fuel - Config.NitrousBoost.usagePercentPerTick
                    SetVehicleHandlingFloat(activeVehicle.vehicle, "CHandlingData", "fInitialDriveForce", activeVehicle.currentPower * Config.NitrousBoost.driveForce)
                    if driverPed == ped and (IsControlJustReleased(1, 21) or VehicleNitrous[netId].fuel <= 0)then
                        SetVehicleHandlingFloat(activeVehicle.vehicle, "CHandlingData", "fInitialDriveForce", activeVehicle.defaultPower)
                        SetVehicleEnginePowerMultiplier(activeVehicle.vehicle, 1.0)
                        TriggerServerEvent("pickle_whippets:setVehicleNitrousActive", netId, false, activeVehicle.fuelLost)
                        activeVehicle = nil
                        -- SetVehicleNitrousActive(netId, false)
                        StopGameplayCamShaking(true)
                        SetTransitionTimecycleModifier('default', 0.75)
                        ClearTimecycleModifier()
                        ClearExtraTimecycleModifier()
                    end
                end
                showingUI = true
                currentlyShowing = true
                UpdateWhippetControls()
                wait = 0
            end
        end 
        if not currentlyShowing and showingUI then
            SendNUIMessage({ type = "hideControls" })
            if activeVehicle then
                SetVehicleHandlingFloat(activeVehicle.vehicle, "CHandlingData", "fInitialDriveForce", activeVehicle.defaultPower)
                SetVehicleEnginePowerMultiplier(activeVehicle.vehicle, 1.0)
                TriggerServerEvent("pickle_whippets:setVehicleNitrousActive", VehToNet(activeVehicle.vehicle), false, activeVehicle.fuelLost)
                activeVehicle = nil
                -- SetVehicleNitrousActive(VehToNet(activeVehicle.vehicle), false)
                StopGameplayCamShaking(true)
                SetTransitionTimecycleModifier('default', 0.75)
                ClearTimecycleModifier()
                ClearExtraTimecycleModifier()
            end
            showingUI = false
        end
        Wait(wait)
    end
end)

RegisterNetEvent("pickle_whippets:setVehicleNitrousActive", function(netId, status)
    if not NetworkDoesNetworkIdExist(netId) then return end
    if not DoesEntityExist(NetToVeh(netId)) then return end
    SetVehicleNitrousActive(netId, status)
end)

RegisterNetEvent("pickle_whippets:dequipWhippet", function()
    DeleteEntity(CurrentWhippet.whippetProp)
    SendNUIMessage({ type = "hideControls" })
    CurrentWhippet = nil
end)

RegisterNetEvent("pickle_whippets:useWhippet", function(data)
    CurrentWhippet = data
    local puffAnim = { dict = "amb@world_human_drinking@coffee@female@idle_a", name = "idle_a" }
    local idleAnim = { dict = "amb@world_human_drinking@coffee@female@base", name = "base" }
    local fillAnim = { dict = "timetable@gardener@filling_can", name = "gar_ig_5_filling_can" }
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local whippetCfg = Config.Whippets[data.item]
    local whippetProp = CreateProp(whippetCfg.model, playerCoords.x, playerCoords.y, playerCoords.z, true, true, false)
    TriggerServerEvent("pickle_whippets:setWhippetProp", ObjToNet(whippetProp))
    CurrentWhippet.whippetProp = whippetProp
    local attachment = whippetCfg.useAttachment.idle or {
        position = vector3(0.0, 0.0, 0.0),
        rotation = vector3(0.0, 0.0, 0.0),
        boneId = 57005
    }
    UpdateWhippetControls()
    CreateThread(function()
        local idle = true
        local whippetDelay = 70
        local whippetTime = 0
        local closestVehicle
        local vehicleUpdate = 20
        local fillingVehicle = false
        local fillingVehicleTime = 0
        while CurrentWhippet and CurrentWhippet.durability > 0 do
            DisableControlAction(0, 24, true) -- Disable attack
            DisableControlAction(0, 140, true) -- Disable melee attack light
            DisableControlAction(0, 141, true) -- Disable melee attack heavy
            DisableControlAction(0, 142, true) -- Disable melee attack alternative
            if IsControlJustPressed(0, 177) or GetEntityHealth(playerPed) <= 0 then
                ClearPedTasks(playerPed)
                TriggerServerEvent("pickle_whippets:dequipWhippet")
                break
            end
            if not fillingVehicle then
                if vehicleUpdate > 0 then
                    vehicleUpdate = vehicleUpdate - 1
                else
                    closestVehicle = GetClosestVehicleAtPos(GetEntityCoords(playerPed), 2.5)
                    vehicleUpdate = 20
                    UpdateWhippetControls(closestVehicle)
                end
                if Config.NitrousBoost.enabled and closestVehicle and not DoesEntityExist(GetVehiclePedIsIn(playerPed, false)) and IsDisabledControlJustPressed(0, 140) then
                    fillingVehicle = closestVehicle
                    idle = true
                    whippetDelay = 100
                    whippetTime = 0
                end
                if idle then
                    if IsDisabledControlJustPressed(0, 24) then
                        attachment = whippetCfg.useAttachment.use
                        AttachEntityToEntity(whippetProp, playerPed, GetPedBoneIndex(playerPed, attachment.boneId), attachment.position, attachment.rotation, false, false, false, false, 0, true)
                        ClearPedTasks(playerPed)
                        PlayAnim(playerPed, puffAnim.dict, puffAnim.name, 1.0, 1.0, -1, 49, 0, false, false, false)
                        idle = false
                        CreateThread(function()
                            Config.WhippetSettings.stateChanges.on()
                        end)
                        whippetDelay = 100
                    elseif not IsEntityPlayingAnim(playerPed, idleAnim.dict, idleAnim.name, 3) then
                        attachment = whippetCfg.useAttachment.idle
                        AttachEntityToEntity(whippetProp, playerPed, GetPedBoneIndex(playerPed, attachment.boneId), attachment.position, attachment.rotation, false, false, false, false, 0, true)
                        ClearPedTasks(playerPed)
                        PlayAnim(playerPed, idleAnim.dict, idleAnim.name, 1.0, 1.0, -1, 49, 0, false, false, false)
                    end
                else
                    whippetDelay = whippetDelay - 1
                    whippetTime = whippetDelay * -1
                    if whippetTime > 0 then
                        local newFuel = CurrentWhippet.durability - Config.WhippetSettings.usagePercentPerTick
                        if newFuel <= 0 then
                            CurrentWhippet.durability = 0
                        else
                            CurrentWhippet.durability = newFuel
                            Config.WhippetSettings.stateChanges.active(whippetTime)
                        end
                        UpdateWhippetControls()
                    end
                    DisableControlAction(0, 59, true) -- Disable steering in vehicles
                    DisableControlAction(0, 60, true) -- Disable vehicle turn left/right
                    if IsDisabledControlJustReleased(0, 24) or whippetDelay < -200 then
                        idle = true
                        if whippetDelay <= 0 then
                            TriggerServerEvent("pickle_whippets:whippetSmoke", whippetDelay * -1)
                        end
                        CreateThread(function()
                            Config.WhippetSettings.stateChanges.off(whippetTime)
                        end)
                        whippetDelay = 100
                        whippetTime = 0
                    end
                end
            else
                fillingVehicleTime = fillingVehicleTime + 1
                if not IsEntityPlayingAnim(playerPed, fillAnim.dict, fillAnim.name, 3) then
                    ClearPedTasks(playerPed)
                    PlayAnim(playerPed, fillAnim.dict, fillAnim.name, 1.0, 1.0, -1, 49, 0, false, false, false)
                end
                if not IsDisabledControlPressed(0, 140) or CurrentWhippet.durability <= 0 then
                    TriggerServerEvent("pickle_whippets:whippetSmoke", fillingVehicleTime, VehToNet(fillingVehicle))
                    fillingVehicle = false
                    fillingVehicleTime = 0
                    ClearPedTasks(playerPed)
                else
                    local newFuel = CurrentWhippet.durability - Config.WhippetSettings.usagePercentPerTick
                    if newFuel <= 0 then
                        CurrentWhippet.durability = 0
                    else
                        CurrentWhippet.durability = newFuel
                    end
                end
                UpdateWhippetControls(nil, true)
            end
            Wait(0)
        end
        ClearPedTasks(playerPed)
        Config.WhippetSettings.stateChanges.off(whippetTime)
        if CurrentWhippet and CurrentWhippet.durability <= 0 then
            if whippetTime > 0 then
                TriggerServerEvent("pickle_whippets:whippetSmoke", whippetTime)
            end
            if fillingVehicleTime > 0 then
                TriggerServerEvent("pickle_whippets:whippetSmoke", fillingVehicleTime, VehToNet(fillingVehicle))
            end
            SetTimeout(500, function()
                TriggerServerEvent("pickle_whippets:dequipWhippet")
            end)
        end
    end)
end)

RegisterNetEvent("pickle_whippets:whippetSmoke", function(targetId, whippetName, time)
    local whippetCfg = Config.Whippets[whippetName]
    local time = time or 0
    if not whippetCfg then return end
    for _, playerId in ipairs(GetActivePlayers()) do
        local playerPed = GetPlayerPed(playerId)
        local serverId = GetPlayerServerId(playerId)
        if serverId == targetId then
            local coords = GetEntityCoords(playerPed)
            local trailEntity = CreateProp(`prop_tennis_ball`, coords.x, coords.y, coords.z, false, false, false)
            SetEntityAlpha(trailEntity, 0.0, false)
            table.insert(TrailEntities, trailEntity)
            RequestNamedPtfxAsset("scr_ar_planes")
            while not HasNamedPtfxAssetLoaded("scr_ar_planes") do
                Citizen.Wait(0)
            end
            UseParticleFxAssetNextCall("scr_ar_planes")
            local particleEffect = StartParticleFxLoopedOnEntity("scr_ar_trail_smoke", trailEntity, 0.0, 0.0, 0.0, 0.0, 90.0, 0.0, Config.WhippetSettings.cloudSize, false, false, false)
            -- Customize the smoke color (RGB format)
            SetParticleFxLoopedAlpha(particleEffect, 0.5)  -- 50% transparency
            SetParticleFxLoopedColour(particleEffect, whippetCfg.vaporColor.r / 255, whippetCfg.vaporColor.g / 255, whippetCfg.vaporColor.b / 255)  -- Red smoke
            AttachEntityToEntity(trailEntity, playerPed, GetPedBoneIndex(playerPed, 31086), vector3(0.0, 0.15, 0.0), vector3(0.0, 0.0, 180.0), false, false, false, false, 0, true)
            -- The color values are in RGB (Red, Green, Blue), with values ranging from 0.0 to 1.0
            Wait(math.floor(time) or 0)
            for i, entity in ipairs(TrailEntities) do
                if entity == trailEntity then
                    table.remove(TrailEntities, i)
                    StopParticleFxLooped(particleEffect, 0)
                    DetachEntity(entity)
                    DeleteEntity(entity)
                    break
                end
            end
            break
        end
    end
end)

RegisterNetEvent("pickle_whippets:whippetEffect", function(tierId)
    local tier = Config.WhippetSettings.usageTiers[tierId]
    if not tier then return end
    if tier.effect then
        CreateThread(function()
            tier.effect()
        end)
    end
end)

RegisterNetEvent("pickle_whippets:setVehicleNitrous", function(netId, data)
    SetVehicleNitrous(netId, data)
end)

RegisterNetEvent("pickle_whippets:updateVehiclesNitrous", function(data)
    VehicleNitrous = data
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, entity in ipairs(TrailEntities) do
            DeleteEntity(entity)
        end
    end
end)