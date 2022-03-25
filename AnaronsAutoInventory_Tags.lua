AAI_OnAddonLoadedTags = function(instance)
    aai_item_tags = aai_item_tags or {}
    aai_tag_colors = aai_tag_colors or {}
    aai_item_tags_global = aai_item_tags_global or {}
end


function AAI_SellItemsOnAuctionHouse(item, stack_size, bid, buyout)
    -- The stacks must be split in to a slot before being put on the AH
    free_bag = -1
    free_slot = -1
    
    for bag, slot, link in AAI_GetInventoryBagIndexLinkTuples("character") do
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
        -- precious items can not be destroyed without "forced"
        if AAI_HasTag(name, tag) then 
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


function AAI_RemoveTag(item, tag, global)
    tag_dict = aai_item_tags
    if global then
        tag_dict = aai_item_tags_global
    end

    if tag_dict[item] == nil then
        tag_dict[item] = {}
    end
    tag_dict[item][tag] = nil
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


function AAI_GetTagColor(tag)
    local color_table = {
        junk        = "666666",
        precious    = "ffff77",
        bank        = "7777ff"
    }

    return aai_tag_colors[tag] or color_table[tag] or "ffffff"
end


function AAI_GetTagHelp(tag)
    local help_table = {
        junk        = "automatically sold to vendors",
        precious    = "never sold through AAI",
        bank        = "automaticall transfered to the bank"
    }
    return help_table[tag] or "not handled by AAI"
end


function AAI_CleanUpItemTagDatabase()
    for key, val in pairs(aai_item_tags) do
        if not AAI_IsItemLink(key) then
            aai_item_tags[key] = nil
        elseif AAI_CleanItemLinkForDatabase(key) ~= key then
            aai_item_tags[AAI_CleanItemLinkForDatabase(key)] = aai_item_tags[key]
            aai_item_tags[key] = nil
        end
    end
end


AAI_TagList = {"junk", "precious", "bank"}
