AAI_OnAddonLoadedTags = function(instance)
    aai_item_tags = aai_item_tags or {}
    aai_tag_colors = aai_tag_colors or {}
    aai_item_tags_global = aai_item_tags_global or {}
end


-- CLI
SLASH_AUTO_INVENTORY_COMMAND_LINE_INTERFACE1 = "/aai"
SLASH_AUTO_INVENTORY_COMMAND_LINE_INTERFACE2 = "/anaronsautoinventory"

SlashCmdList["AUTO_INVENTORY_COMMAND_LINE_INTERFACE"] = function(option)
    local operation, option = AAI_GetLeftWord(option)

    local valid_operations = {
        help        = "get help with AAI",
        tag         = "assign a tag to an item",
        remove      = "prepend to \"tag\" to remove a tag from an item\n prepend to \"tagcolor\" to reset the color of a tag",
        taglist     = "display a list of tags handled by AAI",
        use         = "use all items with the provided tag",
        force       = "prepend to other action to ignore precious tags",
        silent      = "ignore any prints during the following operation",
        restore     = "restore AAI after a crash",
        bank        = "prepend to \"bank\" to use from bank rather than inventory",
        display     = "display saved data",
        need        = "automatically roll \"need\" on this item",
        greed       = "automatically roll \"greed\" on this item",
        tagcolor    = "manually override the color of a tag",
        global      = "prepend to \"tag\" to apply the action across all characters",
        auction     = "Prepend \"stack size, bid price, buyout price, item link\" to automatically sell items on the auction house"
    }


    local forced = false
    local global = false
    local remove = false
    local inventory = "character"
    while true do
        local should_break = true
        -- prefixes
        if operation == "silent" then
            AAI_print = function() end
            operation, option = AAI_GetLeftWord(option)
            should_break = false
        end

        if operation == "force" then
            forced = true
            operation, option = AAI_GetLeftWord(option)
            should_break = false
        end

        if operation == "global" then
            global = true
            operation, option = AAI_GetLeftWord(option)
            should_break = false
        end

        if operation == "remove" then
            remove = true
            operation, option = AAI_GetLeftWord(option)
            should_break = false
        end

        if operation == "bank" then
            inventory = "bank"
            operation, option = AAI_GetLeftWord(option)
            should_break = false
        end

        if should_break then
            break
        end
    end

    if valid_operations[operation] == nil then
        AAI_print(string.format("\"%s\" is an invalid operation - try \"/aai h\"", operation))
    end

    -- operations
    if operation == "restore" then
        AAI_print = AAI_print_original
        AAI_print("Restored AAI")
    
    elseif operation == "display" then
        for key, value in pairs(aai_item_tags) do
            if option == nil or string.match(key, string.format(".*%s.*", AAI_ReplaceLinkWithID(option))) then
                AAI_print(string.format("%s: %s", key, key:gsub("\124", "")))
    --         return text:gsub("(.*)(\124c[0-9a-f]+\124Hitem:([0-9]+):.*[^\124]*\124h[^\124]*\124h\124r)(.*)", "%1%3%4")
                for key2, value2 in pairs(value) do
                    print(string.format("- %s", key2))
                end
            end
        end

    elseif operation == "help" then
        if option then
            AAI_print(string.format("Items tagged as %s are %s", AAI_SetColor(option, AAI_GetTagColor(option)), AAI_GetTagHelp(option)))
        else
            AAI_print("AAI options:")
            AAI_print("help [tag]:")
            AAI_print("- get information related to a tag")
            for key, value in pairs(valid_operations) do
                AAI_print(string.format("%s:\n %s", key, value):gsub("\n", "\n-"))
            end
        end

    elseif operation == "taglist" then
        AAI_print("The tags handled by AAI are:")
        for _, value in ipairs(AAI_TagList) do
            AAI_print(string.format("%s: %s", AAI_TitleCase(AAI_SetColor(value, AAI_GetTagColor(value))), AAI_GetTagHelp(value)))
        end

    elseif operation == "tagcolor" then
        tag, option = AAI_GetLeftWord(option)
        if remove then
            aai_tag_colors[tag] = nil

        elseif option then
            aai_tag_colors[tag] = option
        end

    elseif operation == "tag" then
        tags = {}

        while true do
            left_word, option = AAI_GetLeftWord(option)
            table.insert(tags, left_word)
            if AAI_IsItemLink(option) then
                break
            end
        end
        option_back = option
        
        for _, tag in pairs(tags) do
            option = option_back
            while option ~= nil do
                item_link, option = AAI_GetLeftItemLink(option)


                if tag and option then
                    tag = string.lower(tag)
                    item_link = AAI_CleanItemLinkForDatabase(item_link)

                    if not remove then
                        AAI_AddTag(item_link, tag, global)
                    else
                        AAI_RemoveTag(item_link, tag, global)
                    end
                end
            end
        end

    elseif operation == "use" then
        tags = {}

        while true do
            left_word, option = AAI_GetLeftWord(option)
            table.insert(tags, left_word)
            if not option then
                break
            end
        end
        
        for _, tag in pairs(tags) do
            print(tag)
            -- FIXME: set destructive to true when merchant is open
            AAI_UseAllTaggedItems(inventory, tag, false, forced)
        end

    elseif operation == "auction" then
        stack_size, option = AAI_GetLeftWord(option)
        bid_price, option = AAI_GetLeftWord(option)
        buyout_price, option = AAI_GetLeftWord(option)
        item_link = AAI_CleanItemLinkForDatabase(option)
        
        AAI_SellItemsOnAuctionHouse(item_link, stack_size, bid_price, buyout_price)
    end -- end of operation list

    AAI_print = AAI_print_original
end


function AAI_GetInventoryBags(inventory)
    local container_ids = {}
    if inventory == "character" then
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


function AAI_SellItemsOnAuctionHouse(item, stack_size, bid, buyout)
    -- The stacks must be split in to a slot before being put on the AH
    free_bag = -1
    free_slot = -1
    
    container_ids = AAI_GetInventoryBags("character")

    -- Find a free slot to split stacks into
    for _, bag in ipairs(container_ids) do
        for slot=1,GetContainerNumSlots(bag),1 do
            if etContainerItemLink(bag, slot) == nil then
                free_bag = bag
                free_slot = slot
                break
            end
        end
    end

    -- Split the stacks and sell
    for _, bag in ipairs(container_ids) do
        for slot=1,GetContainerNumSlots(bag),1 do
        end
    end
end


function AAI_UseAllTaggedItems(inventory, tag, destructive, forced)
    container_ids = AAI_GetInventoryBags(inventory)

    for _, bag in ipairs(container_ids) do
        for slot=1,GetContainerNumSlots(bag),1 do
            local name = GetContainerItemLink(bag,slot)
            -- Use only items with the correct tag
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


function AAI_GetLeftWord(inputstr)
    local one, two= string.match(inputstr, "(%S+)%s+(%S.*)")
    if one == nil then
        one = inputstr
    end
    return one, two
end


function AAI_GetLeftItemLink(text)
    item_link, _, _, remainer = string.match(text, "(\124c[0-9a-f]+\124Hitem:([0-9]+):[^\124]*\124h[^\124]*\124h\124r)(%s?)(.*)")
    return item_link, remainer
end


function AAI_IsItemLink(text)
    item_link, _, _, remainer = string.match(text, "^(\124c[0-9a-f]+\124Hitem:([0-9]+):[^\124]*\124h[^\124]*\124h\124r)(%s?)(.*)")
    return item_link ~= nil
end


function AAI_HasValue (tab, val)
    for index, value in pairs(tab) do
        if value == val then
            return true
        end
    end
    return false
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


function AAI_ReplaceLinkWithID(text)
    if text ~= nil then
        return text:gsub("(.*)(\124c[0-9a-f]+\124Hitem:([0-9]+):.*[^\124]*\124h[^\124]*\124h\124r)(.*)", "%1%3%4")
    else
        return nil
    end
end


function AAI_CleanItemLinkForDatabase(text)
    -- remove the level component of the item link because it casues data to be "lost" whenever you levelup
    return AAI_ClearItemLinkLevel(text)
end


function AAI_ClearItemLinkLevel(text)
    return AAI_ReplaceNumberAtIndex(text, 9, "")
end


function AAI_ReplaceNumberAtIndex(text, index, level)
    if text ~= nil then
        local pre = "(.*)(\124c[0-9a-f]+\124Hitem)"
        local post = "(\124h[^\124]*\124h\124r)(.*)"
        local mid = "(" .. AAI_TextRepeat(":[0-9]*", index - 1) .. ":)([0-9]*)(" .. AAI_TextRepeat(":[0-9]*", 18 - index) .. ")"
        text, _ = text:gsub(pre .. mid .. post, "%1%2%3" .. level .. "%5%6%7")
        return text
    end
end


function AAI_TextRepeat(text, repetitions)
    local result = ""
    while repetitions > 0 do
        repetitions = repetitions - 1
        result = result .. text
    end
    return result
end


AAI_TagList = {"junk", "precious", "bank"}
