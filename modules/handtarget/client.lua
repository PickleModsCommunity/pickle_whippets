local targetEntity
local targetProps = {}
local removedProps = {}
local baseProp
local centerEntity
local clonePed
local clonePedAttachment
local pointerEntity
local sceneCam
local endCb
local handTargetActive = false

function GetHTCenter()
    return centerEntity
end

function CreateSceneCam(pos, rot, fov)
    if sceneCam then 
        DeleteSceneCam(sceneCam)
    end
    local ped = PlayerPedId()
    local cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, fov or 45.00, false, 0)
	SetCamActive(cam, true)
	RenderScriptCams(true, true, 1, true, true)
    return cam
end

function DeleteSceneCam(cam)
	SetCamActive(cam, false)
	RenderScriptCams(false, true, 1, true, true)
    DestroyCam(cam) 
end

function SetHandTargetPositions(axis, centerEntity, clonePed, clonePedAttachment, sceneCam, currentDepth, size)
    local coords = GetOffsetFromEntityInWorldCoords(centerEntity, lerp(-size, size, axis.x), lerp(0, -size, axis.y), 0.0)
    SetEntityCoords(clonePedAttachment, coords.x, coords.y, coords.z - currentDepth)
    local targetCoords = GetOffsetFromEntityInWorldCoords(clonePed, 0.0, 2.0, 0.0)
    SetEntityCoords(targetEntity, targetCoords.x, targetCoords.y, targetCoords.z)
    local camCoords = GetOffsetFromEntityInWorldCoords(clonePed, 0.18, 0.45, 0.8)
    SetCamCoord(sceneCam, camCoords.x, camCoords.y, camCoords.z)
    return coords
end

function IsCoordsInsideHTProp(coords, propId)
    local prop = targetProps[propId]
    if not prop then return false end
    local entity = prop.entity
    local position = GetOffsetFromEntityInWorldCoords(entity, prop.settings.interactOffset.x, prop.settings.interactOffset.y, prop.settings.interactOffset.z)
    local dist = #(coords - position)
    return dist <= prop.settings.interactDistance
end

function StartHandTarget(scenario, size, depth, canCancel, cb)
    handTargetActive = true

    local coords = scenario.baseProp.coords
    local heading = scenario.baseProp.rotation.z

    local recoverPropOffset = vector3(0.0, 0.0, 0.0)

    local ped = PlayerPedId()
    PlayAnim(ped, scenario.operatorAnimation.dict, scenario.operatorAnimation.name, 1.0, 1.0, -1, 1, 0, 0, 0, 0)
    FreezeEntityPosition(ped, true)

    -- BASE

    baseProp = CreateProp(scenario.baseProp.model, scenario.baseProp.coords, false, true, false)
    SetEntityRotation(baseProp, scenario.baseProp.rotation)
    FreezeEntityPosition(baseProp, true)
    centerEntity = CreateProp("prop_tennis_ball", GetOffsetFromEntityInWorldCoords(baseProp, scenario.baseProp.surfaceOffset.x, scenario.baseProp.surfaceOffset.y, scenario.baseProp.surfaceOffset.z), false, true, false)
    AttachEntityToEntity(centerEntity, baseProp, 0, scenario.baseProp.surfaceOffset.position, scenario.baseProp.surfaceOffset.rotation, false, false, false, false, 0, true)
    SetEntityCollision(centerEntity, false, false)
    SetEntityAlpha(centerEntity, 0, false)

    -- local idleCoords = GetOffsetFromEntityInWorldCoords(centerEntity, 0.0, -2.0, -1.0)
    -- SetEntityCoords(ped, idleCoords.x, idleCoords.y, idleCoords.z) 
    -- HAND TARGET

    local pedCoords = coords
    local pedHeading = heading
    clonePed = ClonePed(ped, false, false, true) 
    FreezeEntityPosition(clonePed, true)
    clonePedAttachment = CreateProp(`prop_tennis_ball`, pedCoords.x, pedCoords.y, pedCoords.z, false, true, true)
    FreezeEntityPosition(clonePedAttachment, true)
    SetEntityHeading(clonePedAttachment, heading)
    SetEntityCollision(clonePedAttachment, false, false)
    SetEntityAlpha(clonePedAttachment, 0, true)
    AttachEntityToEntity(clonePed, clonePedAttachment, -1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 0, 2)
    pointerEntity = CreateProp(`prop_golf_ball`, pedCoords.x, pedCoords.y, pedCoords.z, false, true, true)
    FreezeEntityPosition(pointerEntity, true)
    SetEntityHeading(pointerEntity, heading)
    SetEntityCollision(pointerEntity, false, false)
    SetEntityAlpha(pointerEntity, 0, true)
    AttachEntityToEntity(pointerEntity, clonePed, GetPedBoneIndex(clonePed, 0xE5F3), 0.05, 0.05, -0.01, 0.0, 0.0, 0.0, false, false, false, true, 0, 2)
    local cloneRotation = {yaw = pedHeading, roll = 0}
    local rotationLimit = {yaw = {cloneRotation.yaw + 170, cloneRotation.yaw + 20}, roll = {cloneRotation.roll + 70, cloneRotation.roll - 70}}
    
    targetEntity = CreateProp(`prop_tennis_ball`, coords.x, coords.y, coords.z, false, true, true)
    SetEntityCollision(targetEntity, false, false)
    SetEntityAlpha(targetEntity, 0, true)
    FreezeEntityPosition(targetEntity, true)
    sceneCam = CreateSceneCam(coords, vector3(-70.0, 0.0, pedHeading), 75.0)
    SetEntityHeading(targetEntity, pedHeading + 90.0)
    SetCursorLocation(0.5, 1.0)
    ClearPedTasksImmediately(clonePed)
    endCb = cb

    -- PROPS
    for i=1, #scenario.props do
        local prop = scenario.props[i]
        if not prop.ignoreHT then
            local position = GetOffsetFromEntityInWorldCoords(centerEntity, prop.position.x, prop.position.y, prop.position.z)
            local rotation = GetEntityRotation(centerEntity) - prop.rotation
            local entity = CreateProp(prop.model, position, false, true, false)
            SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 2)
            AttachEntityToEntity(entity, centerEntity, 0, prop.position, prop.rotation, false, false, false, false, 0, true)

            targetProps["base_"..i] = {
                enabled = true,
                entity = entity,
                model = prop.model,
                coords = position,
                rotation = rotation,
                settings = prop.settings or {
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
            }
        end
        -- AddHandTargetProp(prop.model, position, rotation, {
        --     draggable = true,
        --     interactDistance = 0.05,
        --     interactOffset = vector3(0.0, 0.0, 0.0),
        --     dragOffset = vector3(0.0, 0.0, 0.0),
        --     attachment = {
        --         position = vector3(0.0, 0.0, 0.0),
        --         rotation = vector3(0.0, 0.0, 0.0),
        --         boneId = vector3(0.0, 0.0, 0.0)
        --     },
        --     inside = function() end
        -- })
    end
    local controls = {}
    if canCancel then
        table.insert(controls, {key = "Backspace", action = _L("cancel_process")})
    end
    table.insert(controls, {key = "Spacebar", action = _L("grab_object")})
    table.insert(controls, {key = "LeftClick", action = _L("lower_hand")})
    table.insert(controls, {key = "RightClick", action = _L("rotate_hand")})
    SendNUIMessage({
        type = "showControls",
        controls = controls
    })
    CreateThread(function()
        local currentDepth = 0
        local lastPosAxis
        local lastRotAxis
        local resetAxis = false
        local depthPerTick = 0.0025
        SetPedCanArmIk(clonePed, true)
        SetBlockingOfNonTemporaryEvents(clonePed, true)
        CreateThread(function()
            while handTargetActive do 
                local ikIndex = 4
                local entityLookAt = targetEntity
                local targetFlags = 64
                local duration = 0
                SetIkTarget(clonePed, ikIndex, targetEntity, GetPedBoneIndex(clonePed, 0x49D9), 0, 0, 0, targetFlags, 0, 0)
                DisableControlAction(1, 24, true)
                DisableControlAction(1, 25, true)
                local xAxis = GetControlNormal(1, 239)
                local yAxis = GetControlNormal(1, 240)
                if IsDisabledControlPressed(1, 24) then
                    currentDepth = ((currentDepth + depthPerTick <= depth) and (currentDepth + depthPerTick) or depth)
                else
                    currentDepth = ((currentDepth - depthPerTick >= 0) and (currentDepth - depthPerTick) or 0)
                end
                if IsDisabledControlPressed(1, 25) then
                    resetPosAxis = true
                    if resetRotAxis and lastRotAxis then
                        SetCursorLocation(lastRotAxis.x, lastRotAxis.y)
                        resetRotAxis = false
                    end
                    lastRotAxis = { x = xAxis, y = yAxis }
                    local newRotation = rotation
                    local scale = 0.2
                    cloneRotation.yaw = lerp(rotationLimit.yaw[1], rotationLimit.yaw[2], xAxis)
                    cloneRotation.roll = lerp(rotationLimit.roll[1], rotationLimit.roll[2], yAxis)
                    SetEntityRotation(targetEntity, 0.0, cloneRotation.roll, cloneRotation.yaw, 2)
                    SetHandTargetPositions({x = lastPosAxis.x, y = lastPosAxis.y}, centerEntity, clonePed, clonePedAttachment, sceneCam, currentDepth, size)
                else
                    resetRotAxis = true
                    if resetPosAxis and lastPosAxis then
                        SetCursorLocation(lastPosAxis.x, lastPosAxis.y)
                        resetPosAxis = false
                    else
                        lastPosAxis = { x = xAxis, y = yAxis }
                        SetHandTargetPositions({x = lastPosAxis.x, y = lastPosAxis.y}, centerEntity, clonePed, clonePedAttachment, sceneCam, currentDepth, size)
                    end
                end
                SetEntityLocallyInvisible(ped, true)   
                Wait(0)
            end
        end)
        CreateThread(function()
            local currentDragId = nil
            local defaultAttachment = {
                position = vector3(0.05, 0.05, -0.01),
                rotation = vector3(0.0, 0.0, 0.0),
                boneId = 0xE5F3
            }
            while handTargetActive do 
                DisableControlAction(1, 22, true)
                if not currentDragId then
                    local handCoords = GetEntityCoords(pointerEntity)
                    for k,v in pairs(targetProps) do 
                        if v.enabled then 
                            if v.settings.draggable then
                                SetEntityDrawOutline(v.entity, true)
                            end
                            local entityCoords = GetOffsetFromEntityInWorldCoords(v.entity, v.settings.interactOffset.x, v.settings.interactOffset.y, v.settings.interactOffset.z)
                            -- DrawMarker(0, entityCoords.x, entityCoords.y, entityCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.settings.interactDistance, v.settings.interactDistance, v.settings.interactDistance, 0, 255, 0, 255, false, true, 2, false, false, false, false)
                            local dist = #(handCoords - entityCoords)
                            if dist <= v.settings.interactDistance then
                                SetEntityDrawOutlineColor(0, 255, 0, 255)
                                if v.settings.draggable and IsDisabledControlPressed(1, 22) then
                                    if not currentDragId then
                                        currentDragId = k
                                        local attachment = v.settings.attachment or defaultAttachment
                                        AttachEntityToEntity(v.entity, clonePed, GetPedBoneIndex(clonePed, attachment.boneId), attachment.position.x, attachment.position.y, attachment.position.z, attachment.rotation.x, attachment.rotation.y, attachment.rotation.z, false, false, false, true, 1, 2)
                                    end
                                else
                                    v.settings.inside(k)
                                end
                            else
                                SetEntityDrawOutline(v.entity, false)
                            end
                        end
                    end
                else 
                    local entityDrag = targetProps[currentDragId]
                    if entityDrag then
                        local dragCoords = GetOffsetFromEntityInWorldCoords(entityDrag.entity, entityDrag.settings.dragOffset.x, entityDrag.settings.dragOffset.y, entityDrag.settings.dragOffset.z)
                        -- DrawMarker(0, dragCoords.x, dragCoords.y, dragCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.05, 0.05, 0.05, 0, 255, 0, 255, false, true, 2, false, false, false, true)
                        -- DrawMarker(type, posX, posY, posZ, dirX, dirY, dirZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ, red, green, blue, alpha, bobUpAndDown, faceCamera, p19, rotate, textureDict, textureName, drawOnEnts)
                        SetEntityDrawOutline(entityDrag.entity, false)
                        if not IsDisabledControlPressed(1, 22) then
                            currentDragId = nil
                            local attachment = entityDrag.settings.attachment or defaultAttachment
                            AttachEntityToEntity(entityDrag.entity, pointerEntity, -1, attachment.position.x, attachment.position.y, attachment.position.z, attachment.rotation.x, attachment.rotation.y, attachment.rotation.z, false, false, false, true, 1, 2)
                            FreezeEntityPosition(entityDrag.entity, false)
                            DetachEntity(entityDrag.entity)
                            SetEntityCoords(entity, dragCoords.x, dragCoords.y, dragCoords.z)
                        else
                            for k,v in pairs(targetProps) do 
                                if currentDragId ~= k and v.enabled then 
                                    local entityCoords = GetOffsetFromEntityInWorldCoords(v.entity, v.settings.interactOffset.x, v.settings.interactOffset.y, v.settings.interactOffset.z)
                                    local dist = #(dragCoords - entityCoords)
                                    if dist <= v.settings.interactDistance then
                                        SetEntityDrawOutlineColor(0, 255, 0, 255)
                                        v.settings.inside(k, currentDragId)
                                    else
                                        SetEntityDrawOutline(v.entity, false)
                                    end
                                end
                            end
                        end
                    else
                        currentDragId = nil
                    end
                end
                for k,v in pairs(removedProps) do
                    DeleteHandTargetProp(k, true)
                end
                Wait(0)
            end
        end)
        CreateThread(function()
            while handTargetActive do 
                local centerCoords = GetEntityCoords(centerEntity)
                for k,v in pairs(targetProps) do 
                    if currentDragId ~= k and v.settings.draggable and v.enabled then 
                        local coords = GetEntityCoords(v.entity)
                        if coords.z < centerCoords.z - 0.1 and v.settings.draggable then
                            FreezeEntityPosition(v.entity, true)
                            SetEntityCoords(v.entity, coords.x, coords.y, centerCoords.z - 0.05)
                            Wait(100)
                        end
                    end
                end
                Wait(0)
            end
        end)
    end)
end

function StopHandTarget(cancelTransition)
    handTargetActive = false
    local done = function()
        DeleteEntity(centerEntity)
        DeleteEntity(baseProp)
        DeleteEntity(targetEntity)
        DeleteEntity(clonePed)
        DeleteEntity(clonePedAttachment)
        DeleteEntity(pointerEntity)
        DeleteSceneCam(sceneCam)
        FreezeEntityPosition(PlayerPedId(), false)
        ClearPedTasksImmediately(PlayerPedId())
        SetEntityLocallyVisible(PlayerPedId(), true)
        if not cancelTransition then
            SendNUIMessage({
                type = "hideControls",
            })
        end
        for k,v in pairs(targetProps) do 
            DeleteEntity(v.entity)
        end
        if endCb then
            endCb()
        end
        endCb = nil
    end
    if cancelTransition then
        done()
    else
        CreateThread(function()
            DoScreenFadeOut(1000)
            Wait(1050)
            done()
            Wait(200)
            DoScreenFadeIn(1000)
        end)
    end
end

function GetHandTargetProp(index)
    return targetProps[index]
end

function AddHandTargetProp(modelHash, coords, _heading, settings)
    local entity = CreateProp(modelHash, coords.x, coords.y, coords.z, false, true, false)
    FreezeEntityPosition(entity, true)
    SetEntityAlpha(entity, settings.opacity or 255)
    local rotation
    local heading
    if type(_heading) == "vector3" then
        rotation = _heading
        heading = rotation.z
        SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 2)
    else
        rotation = vector3(0.0, 0.0, _heading)
        heading = _heading
        SetEntityHeading(entity, _heading)
    end
    SetEntityCollision(entity, true, true)
    local index
    repeat
        index = math.random(1,999999) .. "_" .. math.random(1,999999)
    until not targetProps[index]
    targetProps[index] = {
        enabled = true,
        entity = entity,
        model = modelHash,
        coords = coords,
        rotation = vector3(0.0, 0.0, heading),
        settings = {
            draggable = (settings.draggable == nil and true or settings.draggable),
            interactDistance = settings.interactDistance or 0.05,
            interactOffset = settings.interactOffset or vector3(0.0, 0.0, 0.0),
            dragOffset = settings.dragOffset or vector3(0.0, 0.0, 0.0),
            attachment = settings.attachment or {
                position = vector3(0.0, 0.0, 0.0),
                rotation = vector3(0.0, 0.0, 0.0),
                boneId = vector3(0.0, 0.0, 0.0)
            },
            inside = settings.inside or function() end
        }
    }
    return index, targetProps[index]
end

function DeleteHandTargetProp(index, isLoopDone)
    if not isLoopDone then
        removedProps[index] = true
    else
        removedProps[index] = nil
        if targetProps[index] then
            local entity = targetProps[index].entity
            targetProps[index] = nil
            DeleteEntity(entity)
        end
    end
end

function ToggleHandTargetProp(index, bool)
    if not targetProps[index] then return end
    targetProps[index].enabled = bool
end

AddEventHandler("onResourceStop", function(name)
    if name ~= GetCurrentResourceName() then return end
    StopHandTarget(true)
end)