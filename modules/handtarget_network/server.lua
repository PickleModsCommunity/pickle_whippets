-- operatorAnimation: { dict: string, name: string }
-- baseProp: { model: `hash`, coords: vec3(world), rotation: vec3(world) }
-- props[]: { model: `hash`, position: vec3(offset), rotation: vec3(offset) }
-- scenario: { type: string, args: any }

local HTScenarios = {}

function GetUniqueScenarioId()
    local id
    repeat
        id = "id_"..math.random(1, 999999)
    until not HTScenarios[id]
    return id
end

function CreateHTScenario(operatorAnimation, baseProp, props, scenario, databaseInfo)
    local id = GetUniqueScenarioId()
    HTScenarios[id] = {
        active = nil,
        operatorAnimation = operatorAnimation,
        baseProp = baseProp,
        props = props,
        scenario = scenario
    }
    if not databaseInfo then return id end
    HTScenarios[id].owner = databaseInfo.owner
    TriggerClientEvent("pickle_whippets:ht:createScenario", -1, id, HTScenarios[id])
    return id
end

function GetClosestHTScenario(coords)
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

function IsHTScenarioActive(id)
    return HTScenarios[id] and HTScenarios[id].active
end

function GetProcessGasCans(source, flavor)
    local priorityCans = {}
    local backupCans = {}
    for k,v in pairs(Config.Whippets) do
        local emptyItem = k .. "_empty"
        local count = Inventory.GetItemCount(source, emptyItem)
        local isPriority = (k == flavor)
        if count > 0 then
            for i=1, count do
                table.insert((isPriority and priorityCans or backupCans), { name = k })
            end
        end
    end
    local gasCans = {}
    for i=1, #priorityCans do
        if #gasCans + 1 > Config.GasProcess.EmptyTanksPerProcess then break end
        table.insert(gasCans, priorityCans[i])
    end
    for i=1, #backupCans do
        if #gasCans + 1 > Config.GasProcess.EmptyTanksPerProcess then break end
        table.insert(gasCans, backupCans[i])
    end
    return gasCans
end

function SetHTScenarioActive(id, source, data)
    if not HTScenarios[id] then return end
    if source then
        HTScenarios[id].active = {
            source = source,
            identifier = GetIdentifier(source),
            startedCooking = false,
            gasCans = {},
        }
        HTScenarios[id].active.gasCans = data.gasCans
        TriggerClientEvent("pickle_whippets:startGasProcess", source, id, {gasCans = HTScenarios[id].active.gasCans})
    else
        HTScenarios[id].active = nil
    end
end

function GetPlayerHTScenario(source)
    for id, scenario in pairs(HTScenarios) do
        if scenario.active and scenario.active.source == source then
            return id
        end
    end
end

function RemoveHTScenario(id)
    if not HTScenarios[id] then return end
    if HTScenarios[id].active then
        TriggerClientEvent("pickle_whippets:stopGasProcess", HTScenarios[id].active.source, id)
        SetHTScenarioActive(id)
    end
    SetTimeout(100, function()
        HTScenarios[id] = nil
        TriggerClientEvent("pickle_whippets:ht:removeScenario", -1, id)
    end)
end

RegisterNetEvent("pickle_whippets:scenarioAction", function(actionType, data)
    local source = source
    local id = GetPlayerHTScenario(source)
    if not id then return end
    local scenario = HTScenarios[id]
    if actionType == "startCooking" then
        if scenario.active.startedCooking then return end
        scenario.active.startedCooking = true
    elseif actionType == "explode" then
        scenario.noRefund = true
        TriggerClientEvent("pickle_whippets:explodeProcess", -1, source, id)
        SetTimeout(2000, function()
            SetHTScenarioActive(id)
            TriggerClientEvent("pickle_whippets:stopGasProcess", source, id)
        end)
    elseif actionType == "fillGasCan" then
        local gasCan = data.gasCan
        if not gasCan then return end
        for i=1, #scenario.active.gasCans do
            if scenario.active.gasCans[i].name == gasCan then
                Inventory.AddItem(source, scenario.active.gasCans[i].name, 1)
                table.remove(scenario.active.gasCans, i)
                break
            end
        end
    end
end)

RegisterNetEvent("pickle_whippets:startGasProcess", function(id, flavor)
    local source = source
    local currentId = GetPlayerHTScenario(source)
    if currentId then return ShowNotification(source, _L("gp_already_in")) end
    local scenario = HTScenarios[id]
    if not scenario then return ShowNotification(source, _L("gp_not_exist")) end
    if scenario.active then return ShowNotification(source, _L("gp_already_player")) end
    local result, reason = RestrictionCheck(source, "gasProcessor", {id = id})
    if not result then ShowNotification(source, reason) return end
    local gasCans = GetProcessGasCans(source, flavor)
    if #gasCans <= 0 then return ShowNotification(source, _L("gp_no_empty_tanks")) end
    local ammonium = Inventory.GetItemCount(source, Config.GasProcess.AmmoniumItem)
    if ammonium < Config.GasProcess.AmmoniumRequiredPerProcess then return ShowNotification(source, _L("gp_not_enough_ammonium", Config.GasProcess.AmmoniumRequiredPerProcess - ammonium)) end
    Inventory.RemoveItem(source, Config.GasProcess.AmmoniumItem, Config.GasProcess.AmmoniumRequiredPerProcess)
    for i=1, #gasCans do
        Inventory.RemoveItem(source, gasCans[i].name .. "_empty", 1)
    end
    SetHTScenarioActive(id, source, {gasCans = gasCans})
end)

RegisterNetEvent("pickle_whippets:stopGasProcess", function(id)
    local source = source
    TriggerClientEvent("pickle_whippets:stopGasProcess", source, id)
    local id = GetPlayerHTScenario(source)
    if not id then return end
    local scenario = HTScenarios[id]
    if not scenario then return ShowNotification(source, _L("gp_not_exist")) end
    if not scenario.active then return ShowNotification(source, _L("gp_not_active")) end
    if scenario.active.source ~= source then return end
    if not scenario.noRefund then 
        if not scenario.active.startedCooking then
            Inventory.AddItem(source, Config.GasProcess.AmmoniumItem, Config.GasProcess.AmmoniumRequiredPerProcess)
        end
        for i=1, #scenario.active.gasCans do
            Inventory.AddItem(source, scenario.active.gasCans[i].name .. "_empty", 1)
        end    
        SetHTScenarioActive(id)
    end
end)

RegisterNetEvent("pickle_whippets:initializePlayer", function()
    local source = source
    TriggerClientEvent("pickle_whippets:ht:updateScenarios", source, HTScenarios)
    TriggerClientEvent("pickle_whippets:setupInventory", source, { items = Inventory.Items })
    TriggerClientEvent("pickle_whippets:updateVehiclesNitrous", source, VehicleNitrous)
end)

RegisterCallback("pickle_whippets:getGasProcessOptions", function(source, cb)
    local ammoniumRequired = Config.GasProcess.AmmoniumRequiredPerProcess
    local ammonium = Inventory.GetItemCount(source, Config.GasProcess.AmmoniumItem)
    if ammonium < ammoniumRequired then return cb({}, _L("gp_not_enough_ammonium", ammoniumRequired - ammonium)) end
    local whippets = {}
    for k,v in pairs(Config.Whippets) do
        local emptyItem = k .. "_empty"
        local count = Inventory.GetItemCount(source, emptyItem)
        if count > 0 then
            table.insert(whippets, { name = k, label = GetItemLabel(k), count = count })
        end
    end
    cb(whippets)
end)

AddEventHandler("onPlayerDropped", function(source)
    local id = GetPlayerHTScenario(source)
    if not id then return end
    local scenario = HTScenarios[id]
    if not scenario then return end
    if scenario.active.source ~= source then return end
    SetHTScenarioActive(id)
end)