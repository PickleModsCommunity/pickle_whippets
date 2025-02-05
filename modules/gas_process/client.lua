local compressorId
local compressor
local cookingEnabled = false
local cookingStatusVisible = false
local cookingComplete = false
local cookingStatus = {
    isOnline = false,
    progress = 0,
    temperature = 0,
}
local scenarioActive = false
local sentConfig = false
local gasCans = {}
local rope1
local rope2

function UpdateCookingStatus()
    if not cookingStatusVisible then return end
    SendNUIMessage({
        type = "setProcessStatus",
        status = cookingStatus
    })
end

function GasProcessCookComplete()
    cookingComplete = true
    SendNUIMessage({
        type = "hideObjective",
    })
    SetTimeout(300, function()
        SendNUIMessage({
            type = "setObjective",
            title = _L("gp_step_3"),
            text = _L("gp_step_3_text")
        })
    end)
end

function GasProcessLoadingComplete()
    local perfectTemperture = Config.GasProcess.Temperature
    local acceptableRange = Config.GasProcess.TemperatureRange
    cookingEnabled = true
    cookingStatusVisible = true
    SendNUIMessage({
        type = "setObjective",
        title = _L("gp_step_2"),
        text = _L("gp_step_2_text", perfectTemperture)
    })
    UpdateCookingStatus()
end

function GasProcessLoading(availableGasCans)
    local center = GetHTCenter()
    local centerRotation = GetEntityRotation(center)
    SendNUIMessage({
        type = "setObjective",
        title = _L("gp_step_1"),
        text = _L("gp_step_1_text")
    })
    -- { model = `bkr_prop_coke_powder_02`, position = vector3(0.16, 0.2, -0.034), rotation = vector3(0.0, 0.0, 0.0) },
    -- { model = `h4_prop_h4_coke_spatula_04`, position = vector3(0.16, -0.1, 0.0), rotation = vector3(0.0, 0.0, 180.0) },
    local cokePowderId
    local cokeSpatulaId
    local cokePowder
    local cokeSpatula
    local progress = 0.0
    local progressPerScoop = 0.2
    local scoopEntity
    local scoopThread = false

    local floorId, floor = AddHandTargetProp(`prop_police_id_board`, GetOffsetFromEntityInWorldCoords(center, 0.525, 0.20, -0.15), vector3(-90.0, -90.0, centerRotation.z), { 
        draggable = false, 
        interactDistance = 0.1,
        inside = function(targetId, dragId)
        end
    })
    local floorId2, floor2 = AddHandTargetProp(`prop_police_id_board`, GetOffsetFromEntityInWorldCoords(center, 0.525, -0.17, -0.15), vector3(-90.0, -90.0, centerRotation.z), { 
        draggable = false, 
        interactDistance = 0.1,
        inside = function(targetId, dragId)
        end
    })
    for i=1, #availableGasCans do
        local whippetCfg = Config.Whippets[availableGasCans[i].name]
        local gasCanId, gasCan = AddHandTargetProp(whippetCfg.model, GetOffsetFromEntityInWorldCoords(center, 0.525, 0.45 - (i * 0.125), -0.05), vector3(0.0, 0.0, centerRotation.z + 135.0), { 
            draggable = true, 
            interactDistance = 0.1,
            dragOffset = vector3(0.0, 0.0, 0.175),
            attachment = {
                position = vector3(0.1, 0.08, 0.0),
                rotation = vector3(0.0, 75.0, 180.0),
                boneId = 0xE5F3
            },
            inside = function(targetId, dragId)
            end
        }) 
        gasCans[#gasCans + 1] = { id = gasCanId, progress = 0, data = gasCan, whippet = availableGasCans[i] }
    end

    cokePowderId, cokePowder = AddHandTargetProp(`bkr_prop_coke_powder_02`, GetOffsetFromEntityInWorldCoords(center, 0.16, 0.2, -0.034), centerRotation.z, { 
        draggable = false, 
        interactDistance = 0.1,
        inside = function(targetId, dragId)
            if scoopEntity == nil then
                if cokeSpatulaId and dragId == cokeSpatulaId then
                    progress = progress + progressPerScoop
                    scoopEntity = CreateProp(`vw_prop_casino_cards_02`, GetOffsetFromEntityInWorldCoords(center, 0.16, 0.2, -0.034), false, true, false)
                    AttachEntityToEntity(scoopEntity, cokeSpatula.entity, 0, vector3(0.005, -0.13, 0.01), vector3(0.0, 0.0, -5.0), false, false, false, false, 0, true)
                    SetEntityCoords(cokePowder.entity, lerp(cokePowder.coords, vector3(cokePowder.coords.x, cokePowder.coords.y, cokePowder.coords.z - 0.03), progress))
                    CreateThread(function()
                        if scoopThread then return end
                        scoopThread = true
                        while not IsCoordsInsideHTProp(GetEntityCoords(scoopEntity), compressorId) do 
                            Wait(0)
                        end
                        DeleteEntity(scoopEntity)
                        scoopEntity = nil
                        scoopThread = false
                        if progress >= 1.0 then
                            SendNUIMessage({
                                type = "hideObjective",
                            })
                            SetTimeout(300, function()
                                GasProcessLoadingComplete()
                            end)
                        end
                    end)
                    if progress >= 1.0 then
                        progress = 1.0
                        DeleteHandTargetProp(cokePowderId)
                    end
                end
            end
        end
    })
    cokeSpatulaId, cokeSpatula = AddHandTargetProp(`h4_prop_h4_coke_spatula_04`, GetOffsetFromEntityInWorldCoords(center, 0.16, -0.1, 0.0), vector3(180.0, 180.0, centerRotation.z), { 
        draggable = true, 
        interactDistance = 0.075,
        dragOffset = vector3(0.0, -0.2, 0.0),
        interactOffset = vector3(0.0, 0.1, 0.0),
        attachment = {
            position = vector3(0.1, 0.08, 0.0),
            rotation = vector3(-90.0, 75.0, 180.0),
            boneId = 0xE5F3
        },
        inside = function(targetId, dragId)
        end
    })
end

function GetModelInteractionDistance(model)
    local min, max = GetModelDimensions(model)
    return #(min - max) / 2
end

function ExitGasProcessScenario()
    SendNUIMessage({
        type = "hideObjective",
    })
    SendNUIMessage({
        type = "hideProcessStatus",
    })
    scenarioActive = false
    SetLocalHTScenarioDisabled(GetClosestHTScenario(), false)
    DeleteRope(rope1)
    DeleteRope(rope2)
    StopHandTarget()
    if scoopEntity then
        DeleteEntity(scoopEntity)
    end
    compressorId = nil
    compressor = nil
    cookingEnabled = false
    cookingStatusVisible = false
    cookingComplete = false
    cookingStatus = {
        isOnline = false,
        progress = 0,
        temperature = 0,
    }
    scenarioActive = false
    sentConfig = false
    gasCans = {}
end

function GasProcessScenario(id, availableGasCans)
    if scenarioActive then return end
    local scenario = HTScenarios[id]
    if not scenario then return end
    scenarioActive = true
    SetLocalHTScenarioDisabled(id, true)
    StartHandTarget(scenario, 1, 0.3, true, function()
        -- cfgSurgery.endSurgery()
    end)
    cookingStatus = {
        isOnline = false,
        progress = 0,
        temperature = 0,
    }
    local center = GetHTCenter()
    local centerRotation = GetEntityRotation(center, 2)
    local inputTankId = "base_1"
    local outputTankId = "base_2"
    compressorId, compressor = AddHandTargetProp(`v_ret_fh_pot01`, GetOffsetFromEntityInWorldCoords(center, -0.175, -0.175, -0.02), centerRotation.z, { 
        draggable = false, 
        interactDistance = 0.2,
        interactOffset = vector3(0.0, 0.0, 0.0),
        dragOffset = vector3(0.0, 0.0, 0.0),
        attachment = {
            position = vector3(0.0, 0.0, 0.0),
            rotation = vector3(0.0, 0.0, 0.0),
            boneId = 0xE5F3
        },
        inside = function(targetId, dragId)
            if not cookingComplete or not dragId then return end
            for i=1, #gasCans do
                if dragId and gasCans[i] and dragId == gasCans[i].id then
                    if not gasCans[i].filling and gasCans[i].progress < 100 then
                        PlaySoundFrontend(-1, "1st_Person_Transition", "PLAYER_SWITCH_CUSTOM_SOUNDSET", true)
                        gasCans[i].filling = true
                        gasCans[i].progress = gasCans[i].progress + 10
                        if gasCans[i].progress >= 100 then
                            DeleteHandTargetProp(gasCans[i].id)
                            TriggerServerEvent("pickle_whippets:scenarioAction", "fillGasCan", { gasCan = gasCans[i].whippet.name })
                            for i=1, #gasCans do
                                if not gasCans[i].filling then
                                    return
                                end
                            end
                            return SetTimeout(1000, function()
                                TriggerServerEvent("pickle_whippets:stopGasProcess", id)
                            end)
                        end
                        SetTimeout(1000, function()
                            if gasCans[i] then
                                gasCans[i].filling = false
                            end
                        end)
                    end
                end
            end
        end
    })
    SetEntityCollision(compressor.entity, false, false)
    local canPressCookButton = true
    local lastPressed = 0
    local cookPtfx = nil
    local buttonId, button = AddHandTargetProp(`h4_prop_h4_casino_button_01b`, GetOffsetFromEntityInWorldCoords(center, 0.19, -0.28, -0.18), vector3(-90.0, 0.0, centerRotation.z - 90), { 
        draggable = false, 
        interactDistance = 0.1,
        interactOffset = vector3(0.0, 0.05, -0.05),
        dragOffset = vector3(0.0, 0.0, 0.0),
        attachment = {
            position = vector3(0.0, 0.0, 0.0),
            rotation = vector3(0.0, 0.0, 0.0),
            boneId = 0xE5F3
        },
        inside = function(targetId, dragId)
            if not cookingEnabled then return end
            if lastPressed + 1000 > GetGameTimer() then 
                lastPressed = GetGameTimer()
                return
            end
            lastPressed = GetGameTimer()
            cookingStatus.isOnline = not cookingStatus.isOnline
            TriggerServerEvent("pickle_whippets:scenarioAction", "startCooking", {})
            PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", true)
            UpdateCookingStatus()
            if cookingStatus.isOnline then
                RequestNamedPtfxAsset("core")
                while not HasNamedPtfxAssetLoaded("core") do
                    Wait(0)
                end
                UseParticleFxAssetNextCall("core")
                cookPtfx = StartParticleFxLoopedOnEntity("fire_wheel", compressor.entity, 0.0, 0.0, -0.25, 0.0, 90.0, 0.0, 0.18, false, false, false)
            else
                StopParticleFxLooped(cookPtfx, 0)
            end
        end
    })
    CreateThread(function()
        local onCoords = GetOffsetFromEntityInWorldCoords(button.entity, -0.0475, -0.03, 0.0325)
        local offCoords = GetOffsetFromEntityInWorldCoords(button.entity, -0.0475, -0.03, 0.061)
        while scenarioActive do 
            if cookingStatus.isOnline then
                DrawMarker(28, onCoords.x, onCoords.y, onCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.012, 0.012, 0.005, 0, 255, 0, 255, false, false, 2, false, false, false, false)
            else
                DrawMarker(28, offCoords.x, offCoords.y, offCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.012, 0.012, 0.005, 255, 0, 0, 255, false, false, 2, false, false, false, false)
            end
            if IsControlJustPressed(0, 202) then -- 177 is the control ID for backspace
                TriggerServerEvent("pickle_whippets:stopGasProcess", id)
            end
            Wait(0)
        end
    end)
    CreateThread(function()
        local result = nil
        while scenarioActive do
            local heatPerTick = Config.GasProcess.HeatPerTick
            local coolestTemp = (Config.GasProcess.Temperature - Config.GasProcess.TemperatureRange)
            local minRange = (Config.GasProcess.Temperature - Config.GasProcess.TemperatureRange)
            local maxRange = (Config.GasProcess.Temperature + Config.GasProcess.TemperatureRange)
            if cookingStatus.isOnline then
                local scale = cookingStatus.temperature / coolestTemp
                if scale > 1.0 then
                    scale = 1.0
                end
                local scaledHeat = math.floor(lerp(Config.GasProcess.TemperatureRange * 10, Config.GasProcess.TemperatureRange * 2, scale))
                if cookingStatus.temperature > (coolestTemp - (Config.GasProcess.TemperatureRange * 2)) then
                    scaledHeat = heatPerTick
                end
                cookingStatus.temperature = cookingStatus.temperature + scaledHeat
                PlaySoundFrontend(-1, "1st_Person_Transition", "PLAYER_SWITCH_CUSTOM_SOUNDSET", true)
            else
                if cookingStatus.temperature > 0 then
                    cookingStatus.temperature = cookingStatus.temperature - 1
                end
            end
            if cookingStatus.temperature >= minRange and cookingStatus.temperature <= maxRange then
                cookingStatus.progress = cookingStatus.progress + Config.GasProcess.ProgressPerTick
                if cookingStatus.progress >= 100 then
                    cookingStatus.isOnline = false
                    cookingEnabled = false
                    result = "success"
                    UpdateCookingStatus()
                    break
                end
            end
            if cookingStatus.temperature > maxRange + Config.GasProcess.OvercookExplosionRange then
                result = "explosion"
                UpdateCookingStatus()
                break
            end
            UpdateCookingStatus()
            Wait(1000)
        end
        if not result then return end
        cookingStatus.isOnline = false
        SendNUIMessage({
            type = "hideProcessStatus",
        })
        StopParticleFxLooped(cookPtfx, 0)
        if result == "success" then
            GasProcessCookComplete()
        elseif result == "explosion" then
            TriggerServerEvent("pickle_whippets:scenarioAction", "explode", {})
        end
    end)
    for i=1, #scenario.props do
        local settings = {
            draggable = false,
            interactDistance = 0.05,
            interactOffset = vector3(0.0, 0.0, 0.0),
            dragOffset = vector3(0.0, 0.0, 0.0),
            attachment = {
                position = vector3(0.0, 0.0, 0.0),
                rotation = vector3(0.0, 0.0, 0.0),
                boneId = 0xE5F3
            },
            inside = function() end
        }
        scenario.props[i].settings = settings
    end

    local inputTank = GetHandTargetProp(inputTankId)
    local compressor = GetHandTargetProp(compressorId)
    local outputTank = GetHandTargetProp(outputTankId)
    if not RopeAreTexturesLoaded() then
		-- load the textures so we can see the rope
		RopeLoadTextures()
		while not RopeAreTexturesLoaded() do
			Wait(0)
		end
	end
    local inputTankCoords = GetOffsetFromEntityInWorldCoords(inputTank.entity, 0.0, 0.0, 0.3)
    local compressorInputCoords = GetOffsetFromEntityInWorldCoords(compressor.entity, 0.0, 0.11, 0.04)
    local outputTankCoords = GetOffsetFromEntityInWorldCoords(outputTank.entity, 0.0, 0.0, 0.3)
    local compressorOutputCoords = GetOffsetFromEntityInWorldCoords(compressor.entity, 0.0, -0.11, 0.04)
    rope1 = AddRope(compressorInputCoords.x, compressorInputCoords.y, compressorInputCoords.z, 0.0, 0.0, 0.0, 0.0, 6, 10.0, 0.0, 1.0, false, false, false, 1.0, false, 0)
    rope2 = AddRope(compressorOutputCoords.x, compressorOutputCoords.y, compressorOutputCoords.z, 0.0, 0.0, 0.0, 0.0, 6, 10.0, 0.0, 1.0, false, false, false, 1.0, false, 0)
    -- local rope2 = AddRope(compressorCoords.x, compressorCoords.y, compressorCoords.z, 0.0, 0.0, 0.0, 10.0, 1, 10.0, 0.0, 1.0, false, false, false, 1.0, false, 0)
    AttachEntitiesToRope(rope1, inputTank.entity, compressor.entity, inputTankCoords.x, inputTankCoords.y, inputTankCoords.z, compressorInputCoords.x, compressorInputCoords.y, compressorInputCoords.z, 0.1, false, false, 0, 0)
    AttachEntitiesToRope(rope2, outputTank.entity, compressor.entity, outputTankCoords.x, outputTankCoords.y, outputTankCoords.z, compressorOutputCoords.x, compressorOutputCoords.y, compressorOutputCoords.z, 0.1, false, false, 0, 0)
    GasProcessLoading(availableGasCans)
end

function GetRaycastCoords()
    local hit, entityHit, endCoords, surfaceNormal, materialHash
    if lib.raycast.fromCamera then
        hit, entityHit, endCoords, surfaceNormal, materialHash = lib.raycast.fromCamera(511, 4, 20)
    elseif lib.raycast.cam then
        hit, entityHit, endCoords, surfaceNormal, materialHash = lib.raycast.cam(511, 4, 20.0)
    end
    if hit and endCoords then
        return endCoords
    end
end

RegisterNetEvent("pickle_whippets:placeGasProcessor", function()
    local object = nil
    local pot = nil
    local tank1 = nil
    local tank2 = nil
    local endCoords = nil
    local rotation = {x = 0, y = 0, z = 0}
    SendNUIMessage({
        type = "showControls",
        controls = {
            { action = "Place", key = "E" },
            { action = "Rotate Left", key = "Left Arrow" },
            { action = "Rotate Right", key = "Right Arrow" },
            { action = "Cancel", key = "Backspace" }
        }
    })
    CreateThread(function()
        local ticksLeft = 0
        local cancelled = false
        local surface = 0.95
        while true do
            ticksLeft = ticksLeft - 1
            if ticksLeft == 0 or endCoords == nil then
                CreateThread(function()
                    local coords = GetRaycastCoords()
                    if coords and #(coords - GetEntityCoords(PlayerPedId())) < 10.0 then
                        endCoords = coords + vec3(0.0, 0.0, 0.0)
                    end
                    ticksLeft = 5
                end)
            end
            if endCoords then
                if not object then
                    minZ = GetModelDimensions(model).z
                    object = CreateProp(`prop_cooker_03`, endCoords.x, endCoords.y, endCoords.z, true, false, false)
                    SetEntityCollision(object, false, false)
                    SetEntityAsMissionEntity(object, true, true)
                    FreezeEntityPosition(object, true)
                    local potOffset = vector3(-0.175, -0.175, 0.1)
                    local tank1Offset, tank2Offset = vector3(-0.83, -0.075, -0.15), vector3(-0.83, -0.30, -0.15)
                    pot = CreateProp(`v_ret_fh_pot01`, endCoords.x, endCoords.y, endCoords.z, true, false, false)
                    tank1 = CreateProp(`v_ind_cs_gascanister`, endCoords.x + tank1Offset.x, endCoords.y + tank1Offset.y, endCoords.z + tank1Offset.z, true, false, false)
                    tank2 = CreateProp(`v_ind_cs_gascanister`, endCoords.x + tank2Offset.x, endCoords.y + tank2Offset.y, endCoords.z + tank2Offset.z, true, false, false)
                    AttachEntityToEntity(pot, object, 0, potOffset + vec3(0.0, 0.0, surface), vector3(0.0, 0.0, 0.0), false, false, false, false, 0, true)
                    AttachEntityToEntity(tank1, object, 0, tank1Offset + vec3(0.0, 0.0, surface), vector3(0.0, 0.0, 0.0), false, false, false, false, 0, true)
                    AttachEntityToEntity(tank2, object, 0, tank2Offset + vec3(0.0, 0.0, surface), vector3(0.0, 0.0, 0.0), false, false, false, false, 0, true)
                end 
                SetEntityCoords(object, endCoords.x, endCoords.y, endCoords.z - minZ, false, false, false, false)
                SetEntityRotation(object, rotation.x, rotation.y, rotation.z, 2, true)
            end
            if IsControlPressed(1, 174) then
                rotation.z = rotation.z + 0.5
            elseif IsControlPressed(1, 175) then
                rotation.z = rotation.z - 0.5
            end
            if IsControlPressed(1, 51) or IsControlJustPressed(1, 201) then
                break
            elseif IsControlPressed(1, 177) then
                cancelled = true
                break
            end
            Wait(0)
        end
        DeleteEntity(object)
        DeleteEntity(pot)
        DeleteEntity(tank1)
        DeleteEntity(tank2)
        SendNUIMessage({
            type = "hideControls",
        })
        if cancelled or not endCoords then TriggerServerEvent("pickle_whippets:cancelPlacement") return end
        TriggerServerEvent("pickle_whippets:placeGasProcessor", vector3(endCoords.x, endCoords.y, endCoords.z), vector3(rotation.x, rotation.y, rotation.z))
    end)
end)
