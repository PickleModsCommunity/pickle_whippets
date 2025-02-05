RegisterNetEvent("pickle_whippets:buyItem", function(index, itemIndex, quantity)
    local source = source
    local shop = Config.Shops[index]
    if not shop then return end
    local item = shop.buy[itemIndex]
    if not item then return end
    local price = item.price * quantity
    if price < 0 then return end
    if GetPaymentMethodAmount(source, "cash") < price then
        ShowNotification(source, _L("shop_not_enough_money"))
        return
    end
    ChargePaymentMethod(source, "cash", price)
    Inventory.AddItem(source, item.item, quantity)
    ShowNotification(source, _L("shop_bought_item", GetItemLabel(item.item), quantity, price))
end)

RegisterNetEvent("pickle_whippets:sellItem", function(index, itemIndex, quantity)
    local source = source
    local shop = Config.Shops[index]
    if not shop then return end
    local item = shop.sell[itemIndex]
    if not item then return end
    local price = item.price * quantity
    if price < 0 then return end
    if Inventory.GetItemCount(source, item.item) < quantity then
        ShowNotification(source, _L("shop_not_enough_item", GetItemLabel(item.item), quantity - Inventory.GetItemCount(item.item)))
        return
    end
    AddPaymentMethodAmount(source, "cash", price)
    Inventory.RemoveItem(source, item.item, quantity)
    ShowNotification(source, _L("shop_sold_item", GetItemLabel(item.item), quantity, price))
end)