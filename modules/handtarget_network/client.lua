HTScenarios = {}
SpectatorHTScenarios = {}

function EnsureLocalHTScenario(id)
    if not SpectatorHTScenarios[id] then
        SpectatorHTScenarios[id] = {
            visible = false,
            baseProp = nil,
            surfaceProp = nil,
            props = {}
        }
    end
    return SpectatorHTScenarios[id]
end

function SetLocalHTScenarioVisible(id, state)
    if not SpectatorHTScenarios[id] then EnsureLocalHTScenario(id) end
    SpectatorHTScenarios[id].visible = state
    if not state then
        UnrenderLocalHTScenario(id)
    else
        RenderLocalHTScenario(id)
    end
end

function SetLocalHTScenarioDisabled(id, state)
    if not SpectatorHTScenarios[id] then EnsureLocalHTScenario(id) end
    SpectatorHTScenarios[id].disabled = state
    if state then
        SetLocalHTScenarioVisible(id, false)
    end
end

function GetClosestHTScenario(coords)
    local coords = coords or GetEntityCoords(PlayerPedId())
    local closest, dist
    for id, scenario in pairs(HTScenarios) do
        local d = #(coords - scenario.baseProp.coords)
        if not dist or d < dist then
            closest = id
            dist = d
        end
    end
    return closest, dist
end

function RenderLocalHTScenario(id)
    local scenario = HTScenarios[id]
    if not scenario then return end
    local localScenario = EnsureLocalHTScenario(id)
    if #localScenario.props > 0 and #localScenario.props == #scenario.props then -- If we have props and they match the server props, we're good; otherwise we need to refresh.
        local refresh = false
        for i=1, #localScenario.props do
            local prop = localScenario.props[i]
            local entity = prop.entity
            if not DoesEntityExist(entity) then
                refresh = true
            end
        end
        if not refresh then return false end
    end
    UnrenderLocalHTScenario(id) -- This will delete, then re-render.
    localScenario.baseProp = {
        entity = nil,
        interaction = nil, -- TODO: Add interaction
        model = scenario.baseProp.model,
        coords = scenario.baseProp.coords, 
        rotation = scenario.baseProp.rotation
    }
    localScenario.baseProp.entity = CreateProp(scenario.baseProp.model, scenario.baseProp.coords, false, true, false)
    SetEntityRotation(localScenario.baseProp.entity, scenario.baseProp.rotation)
    FreezeEntityPosition(localScenario.baseProp.entity, true)
    localScenario.surfaceProp = {
        entity = nil,
        coords = GetOffsetFromEntityInWorldCoords(localScenario.baseProp.entity, scenario.baseProp.surfaceOffset.x, scenario.baseProp.surfaceOffset.y, scenario.baseProp.surfaceOffset.z),
    }
    localScenario.surfaceProp.entity = CreateProp("prop_tennis_ball", localScenario.surfaceProp.coords, false, true, false)
    AttachEntityToEntity(localScenario.surfaceProp.entity, localScenario.baseProp.entity, 0, scenario.baseProp.surfaceOffset.position, scenario.baseProp.surfaceOffset.rotation, false, false, false, false, 0, true)
    SetEntityAlpha(localScenario.surfaceProp.entity, 0, false)
    SetEntityCollision(localScenario.surfaceProp.entity, false, false)
    localScenario.props = {}
    for i=1, #scenario.props do
        local prop = scenario.props[i]
        local entity = CreateProp(prop.model, localScenario.surfaceProp.coords, false, true, false)
        local position = GetOffsetFromEntityInWorldCoords(localScenario.surfaceProp.entity, prop.position.x, prop.position.y, prop.position.z)
        local rotation = GetEntityRotation(localScenario.surfaceProp.entity) - prop.rotation
        SetEntityCoords(entity, position)
        SetEntityRotation(entity, rotation)
        FreezeEntityPosition(entity, true)
        localScenario.props[#localScenario.props + 1] = {
            entity = entity,
            model = prop.model,
            position = prop.position,
            rotation = prop.rotation
        }
    end
    localScenario.interaction = CreateInteraction({
        label = _L("gp_interact"),
        coords = scenario.baseProp.coords + vector3(0.0, 0.0, 1.0),
        heading = scenario.baseProp.rotation.z
    }, function(selected)
        GasProcessMenu(id)
    end)
    return true
end

function GasProcessStartMenu(id)
    ServerCallback("pickle_whippets:getGasProcessOptions", function(whippets, cancel)
        if cancel then SetTimeout(300, function() GasProcessMenu(id) end) return ShowNotification(cancel) end
        local menuId = "gp_start_"..id
        local options = {}
        for i=1, #whippets do 
            options[#options + 1] = {
                title = whippets[i].label,
                onSelect = function()
                    TriggerServerEvent("pickle_whippets:startGasProcess", id, whippets[i].name)
                end
            }
        end
        if #options == 0 then
            options[#options + 1] = {
                title = _L("gp_no_whippets"),
                disabled = true
            }
        end
        lib.registerContext({
            id = menuId,
            title = _L("gp_interact_start"),
            onExit = function()
                SetTimeout(300, function() GasProcessMenu(id) end)
            end,
            options = options
        })
        lib.showContext(menuId)
    end)

end

function GasProcessMenu(id)
    local menuId = "gp_"..id
    local options = {
        {
            title = _L("gp_start"),
            onSelect = function()
                GasProcessStartMenu(id)
            end
        }
    }
    if HTScenarios[id].owner then
        options[#options + 1] = {
            title = _L("gp_pickup"),
            onSelect = function()
                TriggerServerEvent("pickle_whippets:removeGasProcessor", id)
            end
        }
    end
    lib.registerContext({
        id = menuId,
        title = _L("gp_interact"),
        options = options
    })
    lib.showContext(menuId)
end

function UnrenderLocalHTScenario(id)
    local localScenario = EnsureLocalHTScenario(id)
    if localScenario.baseProp then
        DeleteEntity(localScenario.baseProp.entity)
        localScenario.baseProp = nil
    end
    if localScenario.surfaceProp then
        DeleteEntity(localScenario.surfaceProp.entity)
        localScenario.surfaceProp = nil
    end
    for i=1, #localScenario.props do
        local prop = localScenario.props[i]
        DeleteEntity(prop.entity)
    end
    if localScenario.interaction then
        DeleteInteraction(localScenario.interaction)
        localScenario.interaction = nil
    end
    localScenario.props = {}
end

RegisterNetEvent("pickle_whippets:startGasProcess", function(id, data)
    local scenario = HTScenarios[id]
    if not scenario then return ShowNotification(_L("gp_not_exist")) end
    GasProcessScenario(id, data.gasCans)
end)

RegisterNetEvent("pickle_whippets:stopGasProcess", function(id)
    ExitGasProcessScenario(id)
end)

RegisterNetEvent("pickle_whippets:explodeProcess", function(source, id)
    local scenario = HTScenarios[id]
    local coords = scenario.baseProp.coords
    local dist = #(GetEntityCoords(PlayerPedId()) - coords)
    if dist > Config.RenderDistance then return end
    RequestNamedPtfxAsset("core")
    while not HasNamedPtfxAssetLoaded("core") do
        Wait(0)
    end
    UseParticleFxAssetNextCall("core")
    local cookPtfx = StartParticleFxLoopedAtCoord("exp_grd_molotov", coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, false)
    SetTimeout(5000, function()
        StopParticleFxLooped(cookPtfx, 0)
    end)
    if source == GetPlayerServerId(PlayerId()) then
        StartEntityFire(PlayerPedId())
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        for id, scenario in pairs(HTScenarios) do
            local dist = #(GetEntityCoords(PlayerPedId()) - scenario.baseProp.coords)
            local localScene = EnsureLocalHTScenario(id)
            if localScene.disabled then
                if localScene.visible then
                    SetLocalHTScenarioVisible(id, false)
                end
            else
                if localScene.visible then
                    if dist > Config.RenderDistance then
                        SetLocalHTScenarioVisible(id, false)
                    end
                else
                    if dist <= Config.RenderDistance then
                        SetLocalHTScenarioVisible(id, true)
                    end
                end
            end
        end
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        for id, _ in pairs(SpectatorHTScenarios) do
            UnrenderLocalHTScenario(id)
        end
    end
end)

CreateThread(function()
    Wait(1000)
    TriggerServerEvent("pickle_whippets:initializePlayer")
end)

RegisterNUICallback("requestConfig", function(data, cb)
    cb({
        type = "setConfig",
        locale = Language[Config.Language],
        gasProcess = Config.GasProcess
    })
end)

RegisterNetEvent("pickle_whippets:ht:updateScenarios", function(scenarios)
    HTScenarios = scenarios
end)

RegisterNetEvent("pickle_whippets:ht:createScenario", function(id, scenario)
    HTScenarios[id] = scenario
end)

RegisterNetEvent("pickle_whippets:ht:removeScenario", function(id)
    UnrenderLocalHTScenario(id)
    SpectatorHTScenarios[id] = nil
    HTScenarios[id] = nil
end)

RegisterNetEvent("pickle_whippets:ht:scenarioActiveState", function(id, state)
    if not HTScenarios[id] then return end
    if state then
        HTScenarios[id].active = state
    else
        HTScenarios[id].active = nil
    end
end)