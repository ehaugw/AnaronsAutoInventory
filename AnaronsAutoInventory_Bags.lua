function AAI_OnAddonLoadedBags(instance)
    aai_bag_preferences = aai_bag_preferences or {tags = {}, items = {}}
    aai_item_cache = aai_item_cache or {}
end


function AAI_GetCachedInventoryIterator(inventory, reverse)
    return aai_item_cache[inventory] and AAI_ForEachUnpack(aai_item_cache[inventory], reverse) or function() return nil end
end



function AAI_ItemTableFromIterator(source_iterator)
    local result = {}
    source_iterator{reset = true}

    for bag, slot, item_link, stack_size in source_iterator do

        stack_size = stack_size or item_link and select(2, AAI_GetInventoryStackInfo(bag, slot))

        if item_link then
            if not result[item_link] then
                result[item_link] = {}
            end
            table.insert(result[item_link], {bag, slot, item_link, stack_size})
        end
    end

    source_iterator{recover = true}

    return result
end


function AAI_CacheInventory(inventory)
    local cleared = false

    for bag, slot, item_link in AAI_InventoryIterator(inventory) do
        if item_link then
            local _, stack_size = AAI_GetInventoryStackInfo(bag, slot)
            if not cleared then
                aai_item_cache[inventory] = {}
                cleared = true
                -- AAI_print(string.format("Updated %s cache", inventory))
            end
            table.insert(aai_item_cache[inventory], {bag, slot, item_link, stack_size})
        end
    end
end


function AAI_DepositItemsToBank(require_bank_tag)
    for tag, preferences in pairs(aai_bag_preferences["tags"]) do
        for _, bag in pairs(preferences) do
            AAI_MoveToDesiredBag(
                AAI_InventoryIterator("inventory"),
                AAI_BagIterator(bag, true),
                function(item_link)
                    return not require_bank_tag or AAI_HasTag(item_link, "bank") and AAI_HasTag(item_link, tag)
                end
            )
        end
    end
    AAI_UseAllTaggedItems("inventory", {"bank"}, false, false)
    AAI_ResupplyItems()
end


function AAI_MoveToDesiredBag(source_iterator, target_bag_iterator, evaluator)

    target_bag_iterator{reset = true}
    local item_table = AAI_ItemTableFromIterator(target_bag_iterator)
    target_bag_iterator{recover = true}

    for bag, slot, item_link in source_iterator do
        if item_link and evaluator(item_link) then
            local _, stack_size, stack_size_max = AAI_GetInventoryStackInfo(bag, slot)

            local deposited = false
            if item_table[item_link] then
                for target_bag, target_slot, target_item_link, target_stack_size in AAI_ForEachUnpack(item_table[item_link]) do
                    if target_stack_size + stack_size <= stack_size_max then
                        PickupContainerItem(bag, slot)
                        PickupContainerItem(target_bag, target_slot)
                        deposited = true
                        break
                    end
                end
            end
            if not deposited then
                for target_bag, target_slot, target_item_link in target_bag_iterator do -- note that this iterator is not reset between each source iteratation
                    if target_item_link == nil then
                        PickupContainerItem(bag, slot)
                        PickupContainerItem(target_bag, target_slot)
                        break
                    end
                end
            end
        end
    end
end


function AAI_GetInventoryStackInfo(bag, slot)
    local texture, item_count, locked, quality, readable, lootable, item_link = GetContainerItemInfo(bag, slot);
    local itemName, _, _, _, _, _, _, item_stack_max = GetItemInfo(item_link)
    return item_link, item_count, item_stack_max
end


function AAI_BagSlotToItemLink(bag)
    return GetInventoryItemLink("player", ContainerIDToInventoryID(bag))
end


function AAI_BagCanContainItem(bag, item_link)
    if bag == 0 or bag == -1 then return true end
    local bag_family = GetItemFamily(AAI_BagSlotToItemLink(bag))
    return bag_family == 0 or bit.band(bag_family, GetItemFamily(item_link)) ~= 0
end

function AAI_EquipmentIterator(reverse)
    local inventory_tuple = {}
    for slot = 1, 19 do
        local item_link = GetInventoryItemLink("player", slot)
        -- if item_link then
        if reverse then
            table.insert(inventory_tuple, 0, {bag, slot, item_link})
        else
            table.insert(inventory_tuple, {bag, slot, item_link})
        end
        -- end
    end
    return AAI_ForEachUnpack(inventory_tuple)
end


function AAI_InventoryIterator(inventory, reverse)
    local inventory_tuple = {}
    local container_ids = AAI_GetInventoryBags(inventory)

    for _, bag in ipairs(container_ids) do
        for slot=1,GetContainerNumSlots(bag),1 do
            local item_link = GetContainerItemLink(bag, slot)
            -- local _, stack_size = item_link and AAI_GetInventoryStackInfo(bag, slot) or nil
            -- if item_link then
            if reverse then
                table.insert(inventory_tuple, 0, {bag, slot, item_link})
            else
                table.insert(inventory_tuple, {bag, slot, item_link})
            end
            -- end
        end
    end

    return AAI_ForEachUnpack(inventory_tuple)
end


function AAI_BagIterator(bag, reverse)
    local inventory_tuple = {}

    for slot=1,GetContainerNumSlots(bag),1 do
        local item_link = GetContainerItemLink(bag, slot)
        -- local _, stack_size = item_link and AAI_GetInventoryStackInfo(bag, slot) or nil
        -- if item_link then
        if reverse then
            table.insert(inventory_tuple, 1, {bag, slot, item_link})
        else
            table.insert(inventory_tuple, {bag, slot, item_link})
        end
        -- end
    end

    return AAI_ForEachUnpack(inventory_tuple)
end


function AAI_GetInventoryBags(inventory)
    local container_ids = {}
    if inventory == "inventory" then
        container_ids = {0, 1, 2, 3, 4}
    elseif inventory == "bank" then
        container_ids = {-1}
        local bank_slots, _ = GetNumBankSlots()
        if bank_slots then
            for bank_bag_id = 5, 5 + bank_slots, 1 do
                table.insert(container_ids, bank_bag_id)
            end
        end
    end
    return container_ids
end
