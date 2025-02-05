Config = {}

Config.Debug = true

Config.Language = "en" -- Language to use.

Config.RenderDistance = 20.0 -- Scenario display Radius.

Config.InteractDistance = 1.5 -- Interact Radius

Config.UseTarget = true -- When set to true, it'll use targeting instead of key-presses to interact.

Config.NoModelTargeting = true -- When set to true and using Target, it'll spawn a small invisible prop so you can third-eye when no entity is defined.

Config.InventoryLimit = false -- If using ESX 1.1, this must be on if using a limit-based inventory.

Config.DefaultDurability = 100 -- Maximum durability for items. If you put away a whippet and it's way over 100% - set this to 1.

Config.ProcessLocations = { -- Locations for Gas Processing. You can spawn personal processors with the nitrous_compressor item.
    {coords = vector3(-1474.9208, -3166.1367, 13.0581), heading = 0.3024}
}

Config.CustomRestrictions = { -- Good for restricting actions to donations, or other coded checks
    useWhippet = function(source, whippetType) -- Using whippets
        return true
        -- return false, "You are not allowed to use whippets."
    end,
    gasProcessor = function(source, gasProcessorId) -- Using gas processors
        return true
        -- return false, "You are not allowed to use gas processors."
    end,
    shop = function(source, shopIndex) -- Using shops
        return true
        -- return false, "You are not allowed to use shops."
    end,
}

Config.Shops = {
    {
        label = "Nitrous Dealer",
        model = {hash = `s_m_m_doctor_01`, modelType = "ped"},
        coords = vector3(-670.9746, -1185.1781, 10.6126),
        heading = 311.7422,
        buy = {
            {item = "nitrous_compressor", price = 1000},
            {item = "ammonium_nitrate", price = 100},
        },
        sell = {}
    },
    {
        label = "Solar Gas Dealer",
        model = {hash = `mp_m_shopkeep_01`, modelType = "ped"},
        coords = vector3(18.8422, -1337.7562, 29.2810),
        heading = 96.8836,
        buy = {
            {item = "n2o_strawberry_empty", price = 100},
            {item = "n2o_watermelon_empty", price = 100},
            {item = "n2o_mango_empty", price = 100},
            {item = "n2o_grape_empty", price = 100},
            {item = "n2o_raspberry_empty", price = 100},
        },
        sell = {
            {item = "n2o_strawberry", price = 300},
            {item = "n2o_watermelon", price = 300},
            {item = "n2o_mango", price = 300},
            {item = "n2o_grape", price = 300},
            {item = "n2o_raspberry", price = 300},
        }
    }
}

Config.NitrousBoost = {
    enabled = true, -- Enable or disable the nitrous boost feature.
    driveForce = 1.5, -- Drive force multiplier.
    enginePower = 100.0, -- Engine power multiplier.
    usagePercentPerTick = 0.0006, -- Percent of usage every frame the nitrous is being used.
}

Config.MaxValues = { -- If you want a custom maximum for a value, change -1 to the number. This is already handled in the bridge.
    hunger  = -1,
    thirst  = -1,
    stress  = -1,
    stamina = -1,
}

Config.ExternalStatus = function(source, name, amount) -- (Server-Sided) Implement custom exports and events for external status resources.
    if amount == 0 then return end
    if name == "armor" then
        local ped = GetPlayerPed(source)
        local armor = GetPedArmour(ped)
        armor = armor + amount
        if armor < 0 then armor = 0 end
        if armor > 100 then armor = 100 end
        SetPedArmour(ped, math.floor(armor))
    end
end

Config.Admin = {
    groups = { -- Groups that can remove gas processors that are placed.
        "admin",
        "superadmin",
        "god",
        "moderator",
        "mod"
    },
    jobs = { -- Jobs that can remove gas processors that are placed.
        ["police"] = 3,
    },
}

Config.GasProcess = {
    CompressorItem = "nitrous_compressor", -- Name of the item used as a placeable compressor.
    AmmoniumItem = "ammonium_nitrate", -- Name of the item used as ammonium nitrate.
    AmmoniumRequiredPerProcess = 1, -- Amount of Ammonium required for a Gas Process.
    EmptyTanksPerProcess = 6, -- Amount of empty tanks allowed for a Gas Process. Minimum 1 per process. Max reccomended is 6.
    ProgressPerTick = 5, -- Progress to add per tick (only when in temperature range).
    OvercookExplosionRange = 20, -- Heat on top the acceptable range (Config.GasProcess.TemperatureRange) that will trigger an explosion.
    HeatPerTick = 2, -- Heat to add per tick (automaticly scales when outside of range), will cool down at half this rate.
    Temperature = 250, -- Temperature to reach for Gas Process.
    TemperatureRange = 10, -- Acceptable range for Gas Process, progress will occur while temperature is at this value.
}

Config.WhippetSettings = {
    usagePercentPerTick = 0.0012, -- Percent of usage every frame the whippet is being inhaled.
    measurementUnits = {
        capacity = 2000, -- Capacity of the whippet in milliliters.
        format = "%sml", -- Format of the capacity display. %s is the value, do not remove.
    },
    cloudSize = 0.1, -- Size of the smoke cloud. (Trust me, don't go over 0.1 unless you are trying to smoke out the entire city.)
    stateChanges = {
        on = function()
            local enabled = false

            if not enabled then return end
        end,
        active = function(whippetTime) 
            local enabled = true -- Enable the speed boost feature.

            if not enabled then return end
            if not speedBoosting and whippetTime > 0 then
                speedBoosting = true
                SetPedMoveRateOverride(PlayerId(),10.0)
                SetRunSprintMultiplierForPlayer(PlayerId(),1.49)
            end
        end,
        off = function()
            local enabled = true -- Enable the speed boost feature.

            if not enabled then return end
            speedBoosting = false
            SetPedMoveRateOverride(PlayerId(),1.0)
            SetRunSprintMultiplierForPlayer(PlayerId(),1.0)
        end,
    },
    usageTiers = { -- Usage tiers for the whippet. Make sure minPercent doesn't overlap in the different tiers.
        -- Quick Puff
        {
            minPercent = 0, -- Minimum puff time percent to use the below effects.
            status = { health = 0, armor = 0, thirst = 0, hunger = 0, stress = 0 }, -- Status effects to add or remove (-1 will remove 1 as an example) per whippet.
            effect = function()
                -- Add any client-side effects here that you want to trigger when the puff time is between the min and max percent.
            end
        },
        -- Casual Use
        {
            minPercent = 50, -- Minimum puff time percent to use the below effects.
            status = { health = 0, armor = 0, thirst = 0, hunger = 0, stress = 0 }, -- Status effects to add or remove (-1 will remove 1 as an example) per whippet.
            effect = function()
                local time = 5000
                local intensity = 1.0
                local player = PlayerId()
                local ped = PlayerPedId()
                RequestAnimSet("MOVE_M@DRUNK@VERYDRUNK") 
                while not HasAnimSetLoaded("MOVE_M@DRUNK@VERYDRUNK") do
                    Wait(0)
                end    
                SetPedMovementClipset(ped, "MOVE_M@DRUNK@VERYDRUNK", 1.0)
                SetPedMotionBlur(ped, true)
                SetPedIsDrunk(ped, true)
                SetTimecycleModifier("drug_wobbly")
                for i=1, 100 do 
                    SetTimecycleModifierStrength(i * 0.01)
                    ShakeGameplayCam("DRUNK_SHAKE", i * 0.01)
                    Wait(10)
                end
                Wait(time)
                for i=1, 100 do 
                    SetTimecycleModifierStrength(1.0 - (i * 0.01))
                    ShakeGameplayCam("DRUNK_SHAKE", (1.0 - (i * 0.01)))
                    Wait(10)
                end
                SetPedMoveRateOverride(player, 1.0)
                SetRunSprintMultiplierForPlayer(player,1.0)
                SetPedIsDrunk(ped, false)		
                SetPedMotionBlur(ped, false)
                ResetPedMovementClipset(ped, 1.0)
                -- Add any client-side effects here that you want to trigger when the puff time is between the min and max percent.
            end
        },
        -- Overdose effects / death.
        { 
            minPercent = 100, -- Minimum puff time percent to use the below effects.
            status = { health = 0, armor = 0, thirst = 0, hunger = 0, stress = 0 }, -- Status effects to add or remove (-1 will remove 1 as an example) per whippet.
            effect = function()
                local time = 5000
                local ped = PlayerPedId()
                SetPedToRagdoll(ped, time, time, 0, true, true, false)
                TriggerScreenblurFadeIn(1000)
                TriggerServerEvent("pickle_whippets:dequipWhippet")
                Wait(5000)
                TriggerScreenblurFadeOut(1000)
                -- Add any client-side effects here that you want to trigger when the puff time is between the min and max percent.
            end
        },
    }
}

Config.Whippets = {
    -- ["n2o_strawberry"] is the item name and it's co-responding data.
    -- The empty varient will be appended as "_empty" to the end of each whippet.
    -- Example: n2o_strawberry_empty would be the empty variant of n2o_strawberry.
    -- Make sure to add the empty variant to the item database / list for anything new.
    ["n2o_strawberry"] = {
        model = `picklemods_strawberry`,
        vaporColor = {r = 232, g = 70, b = 84},
        useAttachment = {
            idle = {
                position = vector3(0.0, 0.09, -0.1),
                rotation = vector3(0.0, 20.0, 300.0),
                boneId = 0xE5F3
            },
            use = {
                position = vector3(0.0, 0.10, -0.1),
                rotation = vector3(6.0, 5.0, 300.0),
                boneId = 0xE5F3
            }
        },
        -- Don't change the below unless you love adjusting offsets all day.
        interactDistance = 0.1,
        dragOffset = vector3(0.0, 0.0, 0.175),
        attachment = {
            position = vector3(0.1, 0.08, 0.0),
            rotation = vector3(0.0, 75.0, 180.0),
            boneId = 0xE5F3
        },
    },
    ["n2o_mango"] = {
        model = `picklemods_mango`,
        vaporColor = {r = 249, g = 200, b = 43},
        useAttachment = {
            idle = {
                position = vector3(0.0, 0.09, -0.1),
                rotation = vector3(0.0, 20.0, 300.0),
                boneId = 0xE5F3
            },
            use = {
                position = vector3(0.0, 0.10, -0.1),
                rotation = vector3(6.0, 5.0, 300.0),
                boneId = 0xE5F3
            }
        },
        -- Don't change the below unless you love adjusting offsets all day.
        interactDistance = 0.1,
        dragOffset = vector3(0.0, 0.0, 0.175),
        attachment = {
            position = vector3(0.1, 0.08, 0.0),
            rotation = vector3(0.0, 75.0, 180.0),
            boneId = 0xE5F3
        },
    },
    ["n2o_grape"] = {
        model = `picklemods_grape`,
        vaporColor = {r = 147, g = 135, b = 239},
        useAttachment = {
            idle = {
                position = vector3(0.0, 0.09, -0.1),
                rotation = vector3(0.0, 20.0, 300.0),
                boneId = 0xE5F3
            },
            use = {
                position = vector3(0.0, 0.10, -0.1),
                rotation = vector3(6.0, 5.0, 300.0),
                boneId = 0xE5F3
            }
        },
        -- Don't change the below unless you love adjusting offsets all day.
        interactDistance = 0.1,
        dragOffset = vector3(0.0, 0.0, 0.175),
        attachment = {
            position = vector3(0.1, 0.08, 0.0),
            rotation = vector3(0.0, 75.0, 180.0),
            boneId = 0xE5F3
        },
    },
    ["n2o_raspberry"] = {
        model = `picklemods_raspberry`,
        vaporColor = {r = 126, g = 105, b = 116},
        useAttachment = {
            idle = {
                position = vector3(0.0, 0.09, -0.1),
                rotation = vector3(0.0, 20.0, 300.0),
                boneId = 0xE5F3
            },
            use = {
                position = vector3(0.0, 0.10, -0.1),
                rotation = vector3(6.0, 5.0, 300.0),
                boneId = 0xE5F3
            }
        },
        -- Don't change the below unless you love adjusting offsets all day.
        interactDistance = 0.1,
        dragOffset = vector3(0.0, 0.0, 0.175),
        attachment = {
            position = vector3(0.1, 0.08, 0.0),
            rotation = vector3(0.0, 75.0, 180.0),
            boneId = 0xE5F3
        },
    },
    ["n2o_watermelon"] = {
        model = `picklemods_watermelon`,
        vaporColor = {r = 253, g = 113, b = 90},
        useAttachment = {
            idle = {
                position = vector3(0.0, 0.09, -0.1),
                rotation = vector3(0.0, 20.0, 300.0),
                boneId = 0xE5F3
            },
            use = {
                position = vector3(0.0, 0.10, -0.1),
                rotation = vector3(6.0, 5.0, 300.0),
                boneId = 0xE5F3
            }
        },
        -- Don't change the below unless you love adjusting offsets all day.
        interactDistance = 0.1,
        dragOffset = vector3(0.0, 0.0, 0.175),
        attachment = {
            position = vector3(0.1, 0.08, 0.0),
            rotation = vector3(0.0, 75.0, 180.0),
            boneId = 0xE5F3
        },
    },
}