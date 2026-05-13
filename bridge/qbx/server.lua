if GetResourceState('qbx_core') ~= 'started' then return end

-- QBX (Qbox) server-side overrides.
--
-- qbx_core ships a `qb-core` compatibility shim (it has `provide 'qb-core'`),
-- so `bridge/qb/server.lua` *does* load on a Qbox setup. Most of the QB bridge
-- works fine through that shim, but `RegisterUsableItem` does NOT: under Qbox,
-- usable items are dispatched by ox_inventory, which invokes the callback with
-- ox-shaped data (`item.metadata`, `item.slot`) — NOT the QB-shaped
-- `data.info.quality` the QB bridge expects.
--
-- The QB bridge therefore always falls back to `Config.DefaultDurability` /
-- 100 on use, *and* uses the wrong slot when removing the item, so any
-- durability that was on the slot is lost on the round trip. We override
-- `RegisterUsableItem` here so that durability is read from
-- `item.metadata.durability` and the originating slot is passed through.
--
-- This file loads after `bridge/qb/server.lua` (alphabetical glob order in
-- the fxmanifest) so the override sticks.

function RegisterUsableItem(name, cb)
    exports.qbx_core:CreateUseableItem(name, function(source, item)
        local metadata = (type(item) == "table" and item.metadata) or {}
        local durability = Config.DefaultDurability or 100
        if metadata.durability ~= nil then
            durability = metadata.durability
        end
        local slot = type(item) == "table" and item.slot or nil
        cb(source, { durability = durability }, slot)
    end)
end
