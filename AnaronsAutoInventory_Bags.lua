local inventory_lock_table = {}


local function set_inventory_lock_status(bag, slot, flag)
    inventory_lock_table[string.format("%s,%s", bag, slot)] = time() + (flag and 10 or 0)
end


local function get_inventory_lock_status(bag, slot)
    local timestamp = inventory_lock_table[string.format("%s,%s", bag, slot)]
    return (timestamp ~= nil) and (time() - timestamp <= 0)
end


function AAI_OnAddonLoadedBags(_)
    aai_bag_preferences = aai_bag_preferences or {tags = {}, items = {}}
    aai_item_cache = aai_item_cache or {}
end


function AAI_GetCachedInventoryIterator(inventory, reverse)
    if reverse then
        AAI_print("GetCachedInventoryIterator does not yet support reverse")
    end
    return aai_item_cache[inventory] and AAI_ForEachUnpack(aai_item_cache[inventory]) or function() return nil end
end


function AAI_EquipAllTaggedItems(inventory, tag)
    if UnitAffectingCombat("player") then
        AAI_print("You can not use this feature while in combat.")
        return
    end
    local equipped = {}
    for i = 1, 19 do
        equipped[i] = false
    end
    local swapped = false

    for _, _, item_link in AAI_InventoryIterator(inventory) do
        local was_equipped = false

        local level = item_link and select(5, GetItemInfo(item_link)) or 0

        if AAI_HasTag(item_link, tag) and (not AAI_HasTag(item_link, "swap") or not swapped) and level <= UnitLevel("player") then
            local slots = AAI_GetItemSlots(item_link)

            for _, equip_to in pairs(slots) do
                if AAI_HasTag(GetInventoryItemLink("player", equip_to), tag) then
                    equipped[equip_to] = GetInventoryItemLink("player", equip_to)
                end
                if not equipped[equip_to] then
                    if AAI_HasTag(item_link, "swap") then
                        swapped = true
                    end
                    EquipItemByName(item_link, equip_to)
                    equipped[equip_to] = item_link
                    was_equipped = true
                    break
                end
            end
            if not was_equipped and not AAI_HasTag(item_link, "swap") then
                AAI_print(string.format("There are %s items tagged as %s for that equipment slot, but only %s slots are available:", #slots + 1, AAI_SetColor(tag), #slots))
                AAI_print(item_link)
                for _, occupied_slot in pairs(slots) do
                    AAI_print(equipped[occupied_slot])
                end
            end
        end
    end
end


function AAI_ReplaceSwapItems(inventory)
    if UnitAffectingCombat("player") then
        return
    end

    for bag, slot, item_link in AAI_InventoryIterator(inventory) do
        if AAI_HasTag(item_link, "swap") then
            local slots = AAI_GetItemSlots(item_link)
            local cooldown = AAI_GetRemainingCooldown(GetContainerItemCooldown(bag, slot))

            for _, equip_to in pairs(slots) do
                local competing_item_link = GetInventoryItemLink("player", equip_to)
                local competing_cooldown = AAI_GetRemainingCooldown(GetInventoryItemCooldown("player", equip_to))

                if AAI_HasTag(competing_item_link, "swap") then
                    if competing_cooldown > 30 then
                        if cooldown < competing_cooldown then
                            EquipItemByName(item_link, equip_to)
                            return
                        end
                    end
                end
            end
        end
    end
end


function AAI_SortInventory(inventory)
    local inventory_iterator = AAI_InventoryIterator(inventory)
    for source_bag, slot, item_link in inventory_iterator do
        local skip = false
        for tag, preferences in pairs(aai_bag_preferences["tags"]) do
            if not skip then
                for _, bag in pairs(preferences) do
                    if AAI_HasTag(item_link, tag) then
                        if not skip and AAI_GetBagInventory(bag) == inventory then
                            skip = true
                            AAI_MoveToDesiredBag(
                            AAI_ForEachUnpack({{source_bag, slot, item_link}}),
                            AAI_BagIterator(bag, true),
                            function(_, source_bag, target_bag, source_slot, target_slot)
                                return ((source_bag == nil and target_bag == nil) or (target_bag ~= source_bag)) or ((source_slot == nil and target_slot == nil) or (target_slot > source_slot))
                            end
                            )
                        end
                    end
                end
            end
        end
    end
end


function AAI_ItemLockChanged(source_bag, slot)
    if slot then
        local _, _, locked = GetContainerItemInfo(source_bag, slot);
        if not locked then
            set_inventory_lock_status(source_bag, slot, false)

            -- inventory or bank depending on if the item was unlocked in inventory or bank
            local inventory = AAI_GetBagInventory(source_bag)
            -- make an iterator for the target inventory
            local inventory_iterator = AAI_InventoryIterator(inventory)
            local next_bag, next_slot, item_link = inventory_iterator()

            -- make sure this was the first available inventory slot. if it is not, it must have been manualy placed
            -- manualy placed items should not be moved
            while next_bag ~= source_bag or next_slot ~= slot do
                if not item_link then
                    return -- no item link should mean that the slot an item just left was unlocked as empty
                end
                next_bag, next_slot, item_link = inventory_iterator()
            end

            for tag, preferences in pairs(aai_bag_preferences["tags"]) do
                if AAI_HasTag(item_link, tag) then
                    for _, bag in pairs(preferences) do
                        if source_bag ~= bag and AAI_GetBagInventory(bag) == inventory then
                            AAI_MoveToDesiredBag(
                                AAI_ForEachUnpack({{source_bag, slot, item_link}}),
                                AAI_BagIterator(bag, true),
                                function(_, _, _, _ ,_) return true end
                            )
                        end
                    end
                end
            end
        end
    end
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
            end
            table.insert(aai_item_cache[inventory], {bag, slot, item_link, stack_size})
        end
    end
end


function AAI_DepositItemsToBank(require_bank_tag)
    for tag, preferences in pairs(aai_bag_preferences["tags"]) do
        for _, bag in pairs(preferences) do
            if AAI_GetBagInventory(bag) == "bank" and AAI_HasValue(AAI_GetInventoryBags("bank"), bag) then
                AAI_MoveToDesiredBag(
                    AAI_InventoryIterator("inventory"),
                    AAI_BagIterator(bag, true),
                    function(item_link, _, _, _, _)
                        return not require_bank_tag or AAI_HasTag(item_link, "bank") and AAI_HasTag(item_link, tag)
                    end
                )
            end
        end
    end
    AAI_UseAllTaggedItems("inventory", {"bank"}, false, false)
end


function AAI_MoveToDesiredBag(source_iterator, target_bag_iterator, evaluator)

    target_bag_iterator{reset = true}
    local item_table = AAI_ItemTableFromIterator(target_bag_iterator)
    target_bag_iterator{recover = true}
    source_iterator{reset = true}

    for bag, slot, item_link in source_iterator do
        if item_link and evaluator(item_link, nil, nil, nil, nil) then
            local _, stack_size, stack_size_max = AAI_GetInventoryStackInfo(bag, slot)

            if not select(3, GetContainerItemInfo(bag, slot)) then
                local deposited = false
                if item_table[item_link] then
                    for target_bag, target_slot, _, target_stack_size in AAI_ForEachUnpack(item_table[item_link]) do
                        if evaluator(item_link, bag, target_bag, slot, target_slot) then
                            local _, _, locked = GetContainerItemInfo(target_bag, target_slot);
                            if not locked and not get_inventory_lock_status(target_bag, target_slot) and target_stack_size + stack_size <= stack_size_max then
                                PickupContainerItem(bag, slot)
                                PickupContainerItem(target_bag, target_slot)
                                set_inventory_lock_status(target_bag, target_slot, true)
                                deposited = true
                                break
                            end
                        end
                    end
                end
                if not deposited then
                    for target_bag, target_slot, target_item_link in target_bag_iterator do -- note that this iterator is not reset between each source iteratation
                        if evaluator(item_link, bag, target_bag, slot, target_slot) then
                            local _, _, locked = GetContainerItemInfo(target_bag, target_slot);
                            if not locked and not get_inventory_lock_status(target_bag, target_slot) and target_item_link == nil then
                                PickupContainerItem(bag, slot)
                                PickupContainerItem(target_bag, target_slot)
                                set_inventory_lock_status(target_bag, target_slot, true)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end


function AAI_GetInventoryStackInfo(bag, slot)
    local _, item_count, _, _, _, _, item_link = GetContainerItemInfo(bag, slot);
    if not item_link then return end
    local _, _, _, _, _, _, _, item_stack_max = GetItemInfo(item_link)
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
    local slot = nil
    local reversed = reverse
    local recover = nil

    return function(options)
        if options and options.recover then
            slot = recover
            return
        elseif options and options.reset then
            recover = slot
            slot = nil
            return
        end

        if slot == nil then
            slot = reversed and 19 or 1
        else
            slot = slot + (reversed and -1 or 1)
            if slot < 1 or slot > 19 then
                return
            end
        end

        return slot, GetInventoryItemLink("player", slot)
    end
end


function AAI_InventoryIterator(inventory, reverse)
    local bag_iterator = nil
    local bags_index = nil
    local bags = AAI_GetInventoryBags(inventory)
    local reversed = reverse

    local recover_bag_iterator = nil
    local recover_bags_index = nil

    local step = reversed and -1 or 1

    return function(options)
        if options and options.recover then
            bag_iterator = recover_bag_iterator
            bags_index = recover_bags_index
            return
        elseif options and options.reset then
            recover_bag_iterator = bag_iterator
            recover_bags_index = bags_index
            bags_index = nil
            return
        end

        if bags_index == nil then
            bags_index = reversed and #bags or 1
            bag_iterator = AAI_BagIterator(bags[bags_index], reversed)
        end

        local bag, slot, item_link = bag_iterator()
        if bag == nil then
            bags_index = bags_index + step
            if bags_index < 1 or bags_index > #bags then
                return
            end
            bag_iterator = AAI_BagIterator(bags[bags_index], reversed)
            bag, slot, item_link = bag_iterator()
        end
        return bag, slot, item_link
    end
end


function AAI_BagIterator(bag, reverse)
    local slot = nil
    local reversed = reverse
    local iterated_bag = bag
    local recover = nil
    local bag_space = GetContainerNumSlots(iterated_bag)

    return function(options)
        if options and options.recover then
            slot = recover
            return
        elseif options and options.reset then
            recover = slot
            slot = nil
            return
        end

        if slot == nil then
            slot = reversed and bag_space or 1
        else
            slot = slot + (reversed and -1 or 1)
            if slot < 1 or slot > bag_space then
                return
            end
        end
        return iterated_bag, slot, GetContainerItemLink(bag, slot)
    end
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


function AAI_GetBagInventory(bag)
    for _, inventory in pairs({"inventory", "bank"}) do
        if AAI_HasValue(AAI_GetInventoryBags(inventory), bag) then
            return inventory
        end
    end
    AAI_print("Unknown inventory!")
end


function AAI_SplitAllStacks(item_link, stack_size)
    local _item_link = item_link
    local _stack_size = stack_size
    local inventory_iterator = AAI_InventoryIterator("inventory")
    -- local done_slots = {}

    AAI_SubscribeEvent("ITEM_LOCK_CHANGED", function(_, _, bag, slot)
        if not select(3, GetContainerItemInfo(bag, slot)) then
            set_inventory_lock_status(bag, slot, false)

            local remaining_stacks
            item_link, remaining_stacks, _ = AAI_GetInventoryStackInfo(bag, slot)
            if item_link == _item_link then
                if remaining_stacks > _stack_size then
                    for target_bag, target_slot, target_item_link in inventory_iterator do
                        if not target_item_link or (false and target_item_link == _item_link and select(2, AAI_GetInventoryStackInfo(target_bag, target_slot)) < _stack_size) then
                            SplitContainerItem(bag, slot, _stack_size)
                            PickupContainerItem(target_bag, target_slot)

                            -- set_inventory_lock_status(bag, slot, true)
                            -- done_slots[string.format("%s,%s", bag, slot)] = {target_bag, target_slot}
                            -- done_slots[string.format("%s,%s", target_bag, target_slot)] = nil
                            return
                        end
                    end
                    -- inventory_iterator = AAI_InventoryIterator("inventory")
                end
                AAI_UnsubscribeEvent("ITEM_LOCK_CHANGED", "SPLIT_ITERATOR_EVENT_HANDLER")
                print("done")
            end
        end
    end,
    "SPLIT_ITERATOR_EVENT_HANDLER"
    )
end


AAI_SubscribeEvent("BANKFRAME_OPENED", function(...) if not IsShiftKeyDown() then AAI_DepositItemsToBank(true) end AAI_ResupplyItems() end)
AAI_SubscribeEvent("BANKFRAME_CLOSED", function(...) AAI_CacheInventory("bank") end)
AAI_SubscribeEvent("ITEM_LOCK_CHANGED", function(_, _, bag, slot) AAI_ItemLockChanged(bag, slot) end)
AAI_SubscribeEvent("MERCHANT_SHOW", function(...) AAI_UseAllTaggedItems("inventory", {"junk"}, true, false) end)
