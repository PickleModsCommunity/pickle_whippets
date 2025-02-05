function OpenShopBuyItemMenu(index, itemIndex, quantity)
    local quantity = quantity or 1
    local shop = Config.Shops[index]
    local item = shop.buy[itemIndex]
    local back = function()
        SetTimeout(300, function()
            OpenShopBuyMenu(index)
        end)
    end
    local options = {
        {
            title = _L("shop_quantity", quantity),
            onSelect = function()
                local back = function(quantity)
                    SetTimeout(300, function()
                        OpenShopBuyItemMenu(index, itemIndex, quantity)
                    end)
                end
                local input = lib.inputDialog(_L("shop_quantity_set"), {
                    {type = 'input', label = _L("shop_quantity_field"), required = true},
                })
                if not input or not input[1] or not tonumber(input[1]) or tonumber(input[1]) < 1 then back(quantity) return end
                back(tonumber(input[1]))
            end
        },
        {
            title = _L("shop_buy_item", GetItemLabel(item.item), item.price * quantity),
            onSelect = function()
                TriggerServerEvent('pickle_whippets:buyItem', index, itemIndex, quantity)
            end
        }
    }
    lib.registerContext({
        id = 'whippets_shop_buy_item',
        title = _L("shop_buy_item_checkout", GetItemLabel(item.item)),
        onExit = back,
        options = options
    })
    lib.showContext('whippets_shop_buy_item')
end

function OpenShopSellItemMenu(index, itemIndex, quantity)
    local quantity = quantity or 1
    local shop = Config.Shops[index]
    local item = shop.sell[itemIndex]
    local back = function()
        SetTimeout(300, function()
            OpenShopSellMenu(index)
        end)
    end
    local options = {
        {
            title = _L("shop_quantity", quantity),
            onSelect = function()
                local back = function(quantity)
                    SetTimeout(300, function()
                        OpenShopSellItemMenu(index, itemIndex, quantity)
                    end)
                end
                local input = lib.inputDialog(_L("shop_quantity_set"), {
                    {type = 'input', label = _L("shop_quantity_field"), required = true},
                })
                if not input or not input[1] or not tonumber(input[1]) or tonumber(input[1]) < 1 then back(quantity) return end
                back(tonumber(input[1]))
            end
        },
        {
            title = _L("shop_sell_item", GetItemLabel(item.item), item.price * quantity),
            onSelect = function()
                TriggerServerEvent('pickle_whippets:sellItem', index, itemIndex, quantity)
            end
        }
    }
    lib.registerContext({
        id = 'whippets_shop_sell_item',
        title = _L("shop_sell_item_checkout", GetItemLabel(item.item)),
        onExit = back,
        options = options
    })
    lib.showContext('whippets_shop_sell_item')
end

function OpenShopBuyMenu(index)
    local shop = Config.Shops[index]
    local back = function()
        SetTimeout(300, function()
            OpenShopMenu(index, true)
        end)
    end
    local options = {}
    for i=1, #shop.buy do
        local item = shop.buy[i]
        options[#options + 1] = {
            title = GetItemLabel(item.item) .. " - $" .. item.price,
            onSelect = function()
                SetTimeout(300, function()
                    OpenShopBuyItemMenu(index, i)
                end)
            end
        }
    end
    lib.registerContext({
        id = 'whippets_shop_buy',
        title = _L("shop_buy_items"),
        onExit = back,
        options = options
    })
    lib.showContext('whippets_shop_buy')
end

function OpenShopSellMenu(index)
    local shop = Config.Shops[index]
    local back = function()
        SetTimeout(300, function()
            OpenShopMenu(index, true)
        end)
    end
    local options = {}
    for i=1, #shop.sell do
        local item = shop.sell[i]
        options[#options + 1] = {
            title = GetItemLabel(item.item) .. " - $" .. item.price,
            onExit = back,
            onSelect = function()
                SetTimeout(300, function()
                    OpenShopSellItemMenu(index, i)
                end)
            end
        }
    end
    
    lib.registerContext({
        id = 'whippets_shop_sell',
        title = _L("shop_sell_items"),
        onExit = back,
        options = options
    })
    lib.showContext('whippets_shop_sell')
end

function OpenShopMenu(index, goingBack)
    local shop = Config.Shops[index]
    local options = {}
    if shop.buy and #shop.buy > 0 then
        options[#options + 1] = {
            title = _L("shop_buy_items"),
            onSelect = function()
                SetTimeout(300, function()
                    OpenShopBuyMenu(index)
                end)
            end
        }
    end
    if shop.sell and #shop.sell > 0 then
        options[#options + 1] = {
            title = _L("shop_sell_items"),
            onSelect = function()
                SetTimeout(300, function()
                    OpenShopSellMenu(index)
                end)
            end
        }
    end
    if #options == 0 then return end
    if #options == 1 and not goingBack then
        options[1].onSelect()
        return
    elseif #options == 1 and goingBack then
        return
    end
    lib.registerContext({
        id = 'whippets_shop',
        title = shop.label,
        options = options
    })
    lib.showContext('whippets_shop')
end
CreateThread(function()
    for i=1, #Config.Shops do
        local shop = Config.Shops[i]
        CreateInteraction({
            label = shop.label,
            coords = shop.coords,
            heading = shop.heading,
            model = shop.model
        }, function(selected)
            ServerCallback("pickle_whippets:restrictionCheck", function(result, reason)
                if not result then ShowNotification(reason) return end
                OpenShopMenu(i)
            end, "shop", {id = i})
        end)
    end
end)