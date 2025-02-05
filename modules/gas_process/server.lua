local PlacementPlayers = {}
local DatabaseGasProcessors = {}

function StartPlacingGasProcessor(source)
    if PlacementPlayers[source] then return end
    local count = Inventory.GetItemCount(source, Config.GasProcess.CompressorItem)
    if count < 1 then return end
    Inventory.RemoveItem(source, Config.GasProcess.CompressorItem, 1)
    PlacementPlayers[source] = true
    TriggerClientEvent("pickle_whippets:placeGasProcessor", source)
end

function CreateGasProcessor(coords, heading, databaseInfo)
    local cfg = {
        scenario = { type = "test", args = { test = true } },
        props = {
            { model = `v_ind_cs_gascanister`, position = vector3(-0.83, -0.075, -0.15), rotation = vector3(0.0, 0.0, 0.0) },
            { model = `v_ind_cs_gascanister`, position = vector3(-0.83, -0.30, -0.15), rotation = vector3(0.0, 0.0, 0.0) },
            { model = `v_ret_fh_pot01`, position = vector3(-0.175, -0.175, 0.1), rotation = vector3(0.0, 0.0, 0.0), ignoreHT = true }
        },
        operatorAnimation = { dict = "amb@prop_human_bbq@male@idle_a", name = "idle_b" },
        baseProp = { 
            model = `prop_cooker_03`, 
            coords = coords, 
            rotation = vector3(0.0, 0.0, heading), 
            surfaceOffset = {
                position = vector3(0.0, 0.0, 0.95),
                rotation = vector3(0.0, 0.0, 0.0)
            } 
        },
    }
    local id = CreateHTScenario(cfg.operatorAnimation, cfg.baseProp, cfg.props, cfg.scenario, databaseInfo) 
    if databaseInfo then
        DatabaseGasProcessors[id] = {
            id = databaseInfo.id,
            owner = databaseInfo.owner,
        }
    end
end

RegisterNetEvent("pickle_whippets:removeGasProcessor", function(id)
    local source = source
    local processor = DatabaseGasProcessors[id]
    if not processor then return end
    if processor.owner ~= GetIdentifier(source) and not IsPlayerAdmin(source) then ShowNotification(source, _L("gp_not_own")) return end
    MySQL.Async.execute("DELETE FROM gas_processors WHERE id = @id;", {
        ["@id"] = processor.id
    }, function()
        Inventory.AddItem(source, Config.GasProcess.CompressorItem, 1)
        DatabaseGasProcessors[id] = nil
        RemoveHTScenario(id)
    end)
end)

RegisterNetEvent("pickle_whippets:placeGasProcessor", function(coords, rotation)
    local source = source
    local player = PlacementPlayers[source]
    if not player then return end
    PlacementPlayers[source] = nil
    MySQL.Async.insert("INSERT INTO gas_processors (owner, coords, rotation) VALUES (@owner, @coords, @rotation);", {
        ["@owner"] = GetIdentifier(source),
        ["@coords"] = json.encode(coords),
        ["@rotation"] = json.encode(rotation)
    }, function(id)
        CreateGasProcessor(coords, rotation.z, {
            id = id,
            owner = GetIdentifier(source)
        })
    end)
end)

RegisterNetEvent("pickle_whippets:cancelPlacement", function() 
    local source = source
    if not PlacementPlayers[source] then return end
    PlacementPlayers[source] = nil
    Inventory.AddItem(source, Config.GasProcess.CompressorItem, 1)
end)

RegisterUsableItem(Config.GasProcess.CompressorItem, function(source)
    local result, reason = RestrictionCheck(source, "gasProcessor")
    if not result then ShowNotification(source, reason) return end
    StartPlacingGasProcessor(source)
end)

MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `gas_processors` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `owner` varchar(64) NOT NULL,
            `coords` longtext NOT NULL,
            `rotation` longtext NOT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    ]], {}, function()
        MySQL.Async.fetchAll("SELECT * FROM gas_processors;", {}, function(processors)
            for i=1, #processors do
                local processor = processors[i]
                local coords = json.decode(processor.coords)
                local rotation = json.decode(processor.rotation)
                coords = vec3(coords.x, coords.y, coords.z)
                rotation = vec3(rotation.x, rotation.y, rotation.z)
                CreateGasProcessor(coords, rotation.z, {
                    id = processor.id,
                    owner = processor.owner
                })
            end
        end)
    end)
end)

CreateThread(function()
    for i=1, #Config.ProcessLocations do 
        local loc = Config.ProcessLocations[i]
        CreateGasProcessor(loc.coords, loc.heading)
    end
end)