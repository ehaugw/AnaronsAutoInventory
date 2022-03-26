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
        bank        = "prepend to \"use\" to use from bank rather than inventory",
        display     = "display saved data",
        debug       = "prepend to display to show more information",
        need        = "automatically roll \"need\" on this item",
        greed       = "automatically roll \"greed\" on this item",
        tagcolor    = "manually override the color of a tag",
        global      = "prepend to \"tag\" to apply the action across all characters",
        auction     = "Prepend \"stack size, bid price, buyout price, item link\" to automatically sell items on the auction house"
    }


    local forced = false
    local global = false
    local remove = false
    local inventory = "inventory"
    local debug = false
    while true do
        local should_break = true
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

        if operation == "debug" then
            debug = true
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

    -- Prefixes does not change the actual operation, thus this output must be printed when we know what the actual
    -- command is.
    if valid_operations[operation] == nil then
        AAI_print(string.format("\"%s\" is an invalid operation - try \"/aai help\"", operation))
    end

    -- operations
    if operation == "restore" then
        AAI_print = AAI_print_original
        AAI_CleanUpItemTagDatabase()
        AAI_print("Restored AAI")
    
    elseif operation == "display" then
        local links, tags = AAI_StringToItemLinksAndWords(option)

        for key, value in pairs(aai_item_tags) do
            if table.getn(tags) == 0 or AAI_HasValue(links, key) or table.getn(AAI_GroupIntersect(AAI_GetKeysFromTable(value), tags)) > 0 then
                if debug then
                    AAI_print(string.format("%s: %s", key, key:gsub("\124", "")))
                    for key2, value2 in pairs(value) do
                        AAI_print(string.format("- %s", key2))
                    end
                else
                    AAI_print(key)
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
        local links, tags = AAI_StringToItemLinksAndWords(option)
        
        for _, tag in pairs(tags) do
            for _, item_link in pairs(links) do
                tag = string.lower(tag)
                item_link = AAI_CleanItemLinkForDatabase(item_link)

                if not remove then
                    AAI_AddTag(item_link, tag, global)
                else
                    AAI_RemoveTag(item_link, tag, global)
                end
            end
        end

    elseif operation == "use" then
        local links, tags = AAI_StringToItemLinksAndWords(option)
        
        if table.getn(links) > 0 then
            AAI_print("You provided item links. This feature has not yet been implemented")
        end

        for _, tag in pairs(tags) do
            AAI_print("Used items tagged as " .. tag .. "...")
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


