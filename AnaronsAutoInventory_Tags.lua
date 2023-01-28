AAI_OnAddonLoadedTags = function(instance)
    aai_item_tags = aai_item_tags or {}
    aai_tag_colors = aai_tag_colors or {}
    aai_item_tags_global = aai_item_tags_global or {}
    AAI_SubscribeEvent("UNIT_HEALTH_FREQUENT", function(...) AAI_ReplaceSwapItems("inventory") end)
end


function AAI_SellItemsOnAuctionHouse(item, stack_size, bid, buyout)
    -- The stacks must be split in to a slot before being put on the AH
    free_bag = -1
    free_slot = -1
    
    for bag, slot, link in AAI_InventoryIterator("inventory") do
        if link == nil then
            free_bag = bag
            free_slot = slot
            break
        end
    end

    -- Split the stacks and sell
    for _, bag in ipairs(container_ids) do
        for slot=1,GetContainerNumSlots(bag),1 do
        end
    end
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

    for bag, slot, item_link in AAI_InventoryIterator(inventory) do
        local was_equipped = false
        if AAI_HasTag(item_link, tag) and (not AAI_HasTag(item_link, "swap") or not swapped) then 
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


function AAI_GetRemainingCooldown(timestamp, cooldown, on_cooldown)
    if cooldown == 0 then
        return 0
    end
    return cooldown - GetTime() + timestamp
end


function AAI_ResupplyItems()
    for bag, slot, item_link in AAI_InventoryIterator("inventory") do
        if item_link and AAI_HasTag(item_link, "resupply") then
            local _, stack_size, stack_size_max = AAI_GetInventoryStackInfo(bag, slot)
            if stack_size < stack_size_max then
                local found_one = false
                for bank_bag, bank_slot, bank_item_link in AAI_InventoryIterator("bank") do
                    _, _, locked = GetContainerItemInfo(bank_bag, bank_slot)
                    if bank_item_link == item_link and not locked then
                        local _, bank_stack_size = AAI_GetInventoryStackInfo(bank_bag, bank_slot)
                        PickupContainerItem(bank_bag, bank_slot)
                        PickupContainerItem(bag, slot)
                        AAI_print(string.format("Resupplied %s", item_link))
                        if bank_stack_size + stack_size < stack_size_max then
                            AAI_print(AAI_SetColor(string.format("Could not fully resupply %s. Try opening the source again, or resupply the source if it is running low on supply!", item_link), "FF0000"))
                        end
                        found_one = true
                        break
                    end
                end
                if not found_one then
                    AAI_print(AAI_SetColor(string.format("Could not fully resupply %s. Try opening the source again, or resupply the source if it is running low on supply!", item_link), "FF0000"))
                end
            end
        end
    end
    for item_link in AAI_TaggedItemIterator("resupply") do
        if AAI_CountInBag("inventory", item_link) == 0 then
            local found_one = false
            for bag, slot, bank_item_link in AAI_InventoryIterator("bank") do
                if AAI_CleanItemLinkForDatabase(bank_item_link) == item_link then
                    UseContainerItem(bag, slot)
                    local _, stack_size, stack_size_max = AAI_GetInventoryStackInfo(bag, slot)
                    AAI_print(string.format("Resupplied %s", item_link))
                    if stack_size < stack_size_max then
                        AAI_print(AAI_SetColor(string.format("Could not fully resupply %s. Try opening the source again, or resupply the source if it is running low on supply!", item_link), "FF0000"))
                    end
                    found_one = true
                    break
                end
            end
            if not found_one then
                        AAI_print(AAI_SetColor(string.format("Could not fully resupply %s. Try opening the source again, or resupply the source if it is running low on supply!", item_link), "FF0000"))
            end
        end
    end
end


function AAI_CountInBag(inventory, item_link)
    local count = 0
    for bag, slot, container_item_link in AAI_InventoryIterator(inventory) do
        if AAI_CleanItemLinkForDatabase(container_item_link) == item_link then
            local _, stack_size, stack_size_max = AAI_GetInventoryStackInfo(bag, slot)
            count = count + stack_size
        end
    end
    return count
end


function AAI_DeleteAllTaggedItems(inventory, tags, forced, exact)
    for bag, slot, item_link in AAI_InventoryIterator(inventory) do
        _, _, locked = GetContainerItemInfo(bag, slot)
        if not locked and ((not exact and AAI_HasTags(item_link, tags)) or (exact and AAI_HasTagsExact(item_link, tags))) then 
            AAI_print(string.format("Delete %s", item_link))
            if forced and not CursorHasItem() then
                PickupContainerItem(bag, slot)
                DeleteCursorItem()
            end
        end
    end
end


function AAI_UseAllTaggedItems(inventory, tags, destructive, forced, exact)
    for bag, slot, item_link in AAI_InventoryIterator(inventory) do
        _, _, locked = GetContainerItemInfo(bag, slot)
        if not locked and ((not exact and AAI_HasTags(item_link, tags)) or (exact and AAI_HasTagsExact(item_link, tags))) then 
            -- precious items can not be destroyed without "forced"
            if forced or not (AAI_HasTag(item_link, "precious") and destructive) then
                -- Equipment has a GCD in combat and can therefore not be used unless it is in destructive mode
                if not UnitAffectingCombat("player") or destructive then
                    UseContainerItem(bag,slot)
                    AAI_print(string.format("Used %s", item_link))
                end
            end
        end
    end
end


function AAI_AddTag(item, tag, global)
    item = AAI_CleanItemLinkForDatabase(item)
    tag_dict = aai_item_tags
    if global then
        tag_dict = aai_item_tags_global
    end

    if tag_dict[item] == nil then
        tag_dict[item] = {}
    end
    tag_dict[item][tag] = true

    -- _, item_link = GetItemInfo(item)
    AAI_print(string.format("%s was %s tagged as %s.", item, (global and "globaly" or not global and "localy"), AAI_SetColor(tag, AAI_GetTagColor(tag))))
end


function AAI_RemoveAllTags(item, global)
    item = AAI_CleanItemLinkForDatabase(item)
    if not global then
        aai_item_tags[item] = nil
    else
        aai_item_tags_global[item] = nil
    end
    AAI_print(string.format("Removed all %s tags from %s.", (global and "global" or not global and "local"), item))
end


function AAI_ClearTagForSlots(tag, slots)
    AAI_RenameItemTagInDatabase(tag, nil, function(item_link, _, _) return AAI_GetItemSlots(item_link) == slots end)
    for _, item_link in AAI_EquipmentIterator("inventory") do
        if AAI_HasTag(item_link, tag) and table.getn(AAI_GroupIntersect(slots, AAI_GetItemSlots(item_link))) > 0 then
            AAI_RemoveTag(item_link, tag)
        end
    end
    for _, _, item_link in AAI_InventoryIterator("inventory") do
        if AAI_HasTag(item_link, tag) and table.getn(AAI_GroupIntersect(slots, AAI_GetItemSlots(item_link))) > 0 then
            AAI_RemoveTag(item_link, tag)
        end
    end
end


function AAI_RemoveTag(item, tag, global)
    item = AAI_CleanItemLinkForDatabase(item)
    tag_dict = aai_item_tags
    if global then
        tag_dict = aai_item_tags_global
    end

    if tag_dict[item] == nil then
        tag_dict[item] = {}
    end
    tag_dict[item][tag] = nil

    if #AAI_GetKeysFromTable(tag_dict[item]) == 0 then
        tag_dict[item] = nil
    end
    
    -- _, item_link = GetItemInfo(item)
    AAI_print(string.format("%s is no longer %s tagged as %s.", item, (global and "globaly" or not global and "localy"), AAI_SetColor(tag, AAI_GetTagColor(tag))))
end


function AAI_HasTag(item, tag)
    item = AAI_CleanItemLinkForDatabase(item)

    if item and tag == "junk" then
        _, _, rarity = GetItemInfo(item)
        if rarity == 0 then
            return true
        end
    end
    if item and tag == "quest" then
        if select(6, GetItemInfo(item)) == "Quest" then
            return true
        end
    end

    local has_tag = false
    if aai_item_tags[item] ~= nil then
        has_tag = has_tag or aai_item_tags[item][tag]
    end
    if aai_item_tags_global[item] ~= nil then
        has_tag = has_tag or aai_item_tags_global[item][tag]
    end
    return has_tag
end


function AAI_HasTagsExact(item, tags)
    item = AAI_CleanItemLinkForDatabase(item)
    local all_tags = AAI_GroupUnion(AAI_GetKeysFromTable(aai_item_tags[item] or {}), AAI_GetKeysFromTable(aai_item_tags_global[item] or {}))
    return #tags == #all_tags and #tags == #AAI_GroupIntersect(tags, all_tags)
end


function AAI_HasTags(item, tags, require_all_tags)
    for _, tag in ipairs(tags) do
        if not require_all_tags and AAI_HasTag(item, tag) then
            return true
        elseif require_all_tags and not AAI_HasTag(item, tag) then
            return false
        end
    end
    return require_all_tags
end


function AAI_TaggedItemIterator(tag)
    local item_tuples = {}
    for item_link, tag_list in pairs(aai_item_tags) do
        if AAI_HasTag(item_link, tag) then
            table.insert(item_tuples, {item_link, tag_list})
        end
    end

    return AAI_ForEachUnpack(item_tuples)
end


function AAI_GetTagColor(tag)
    tag = string.lower(tag)
    local color_table = {
        junk        = "666666",
        precious    = "ffff77",
        bank        = "7777ff",

        greed       = "ff8888",
        need        = "88ff88",

        melee       = "ff8800",
        spell       = "8888ff",
        tank        = "8844ff",
        heal        = "00ff00",
        level       = "ff5555",
    }

    return aai_tag_colors[tag] or color_table[tag] or "ffffff"
end


function AAI_GetTagHelp(tag)
    return AAI_HandledTagsWithHelp[tag] or "not handled by AAI"
end


function AAI_CleanUpItemTagDatabase()
    for item_link, val in pairs(aai_item_tags) do
        if not AAI_IsItemLink(item_link) then
            aai_item_tags[item_link] = nil
        elseif AAI_CleanItemLinkForDatabase(item_link) ~= item_link then
            for tag, _ in pairs(val) do
                AAI_AddTag(item_link, tag)
            end
            aai_item_tags[item_link] = nil
        end
    end
end


function AAI_RenameItemTagInDatabase(from_name, to_name, condition)
    for item_link, tag_dict in pairs(aai_item_tags) do
        if (condition == nil or condition(item_link, from_name, to_name)) and AAI_HasTag(item_link, from_name) then
            if to_name then
                AAI_AddTag(item_link, to_name)
            end
            AAI_RemoveTag(item_link, from_name)
        end
    end
end

AAI_HandledTagsWithHelp = {
    junk        = "automatically sold to vendors",
    precious    = "never sold through AAI",
    bank        = "automaticall transfered to the bank",
    pass        = "automatically pass on rolls",
    greed       = "automatically greed on rolls",
    need        = "automatically need on rolls",
    resupply    = "automatically resupply your inventory when opening the bank",
    melee       = "does nothing on its own but using it can be keybound",
    uniform     = "does nothing on its own but using it can be keybound",
    tank        = "does nothing on its own but using it can be keybound",
    heal        = "does nothing on its own but using it can be keybound",
    spell       = "does nothing on its own but using it can be keybound",
    level       = "does nothing on its own but using it can be keybound",
}

