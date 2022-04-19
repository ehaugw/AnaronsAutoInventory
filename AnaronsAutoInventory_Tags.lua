AAI_OnAddonLoadedTags = function(instance)
    aai_item_tags = aai_item_tags or {}
    aai_tag_colors = aai_tag_colors or {}
    aai_item_tags_global = aai_item_tags_global or {}
end


function AAI_SellItemsOnAuctionHouse(item, stack_size, bid, buyout)
    -- The stacks must be split in to a slot before being put on the AH
    free_bag = -1
    free_slot = -1
    
    for bag, slot, link in AAI_GetInventoryBagIndexLinkTuples("inventory") do
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


function AAI_UseAllTaggedItems(inventory, tag, destructive, forced)
    for bag, slot, name in AAI_GetInventoryBagIndexLinkTuples(inventory) do
        if AAI_HasTag(name, tag) then 
            -- precious items can not be destroyed without "forced"
            if forced or not (AAI_HasTag(name, "precious") and destructive) then
                -- Equipment has a GCD in combat and can therefore not be used unless it is in destructive mode
                if not UnitAffectingCombat("player") or destructive then
                    UseContainerItem(bag,slot)
                    AAI_print(string.format("Used %s", name))
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

    local has_tag = false
    if aai_item_tags[item] ~= nil then
        has_tag = has_tag or aai_item_tags[item][tag]
    end
    if aai_item_tags_global[item] ~= nil then
        has_tag = has_tag or aai_item_tags_global[item][tag]
    end
    return has_tag
end


function AAI_HasTags(item, tags)
    for _, tag in ipairs(tags) do
        if AAI_HasTag(item, tag) then
            return true
        end
    end
    return false
end


function AAI_GetTagColor(tag)
    local color_table = {
        junk        = "666666",
        precious    = "ffff77",
        bank        = "7777ff",

        greed       = "ff8888",
        need        = "88ff88",

        melee       = "ff8800",
        spell       = "8888ff",
        tank        = "8844ff",
        heal        = "00ff00"
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


function AAI_RenameItemTagInDatabase(from_name, to_name)
    for item_link, tag_dict in pairs(aai_item_tags) do
        if AAI_HasTag(item_link, from_name) then
            AAI_AddTag(item_link, to_name)
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
    melee       = "does nothing on its own but using it can be keybound",
    tank        = "does nothing on its own but using it can be keybound",
    heal        = "does nothing on its own but using it can be keybound",
    spell       = "does nothing on its own but using it can be keybound",
}

