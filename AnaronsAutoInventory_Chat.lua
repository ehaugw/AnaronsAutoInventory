-- CLI
SLASH_AUTO_INVENTORY_COMMAND_LINE_INTERFACE1 = "/aai"
SLASH_AUTO_INVENTORY_COMMAND_LINE_INTERFACE2 = "/anaronsautoinventory"

SlashCmdList["AUTO_INVENTORY_COMMAND_LINE_INTERFACE"] = function(option)
    local operation
    operation, option = AAI_GetLeftWord(option)

    local forced = false
    local global = false
    local remove = false
    local inventory = "inventory"
    local debug = false
    local replace =false
    local distinct = false
    local exact = false
    local print_count = false

    while true do
        local should_break = true
        if operation == "silent" then
            AAI_print = function() end
            operation, option = AAI_GetLeftWord(option)
            should_break = false
        end

        if operation == "exact" then
            exact = true
            operation, option = AAI_GetLeftWord(option)
            should_break = false
        end


        if operation == "distinct" then
            distinct = true
            operation, option = AAI_GetLeftWord(option)
            should_break = false
        end


        if operation == "replace" then
            replace = true
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

        if operation == "count" then
            print_count = true
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

    local valid_operations = {
        help        = "get help with AAI",
        tag         = "assign a tag to an item",
        taglist     = "display a list of tags handled by AAI",
        use         = "use all items with the provided tag",
        prefixes    = "list prefixes that can be prepended to any action",
        restore     = "restore AAI after a crash",
        equip       = "equip all items with a given tag",
        gearset     = "first remove the provided tag from every item you have previously tagged, and then add it to the currently equipped items",

        display     = "display saved data",
        debug       = "prepend to display to show more information",
        tagcolor    = "manually override the color of a tag",
        tagrename   = "replace all occurences of from_name with to_name",
        playerwarn  = "Set a note about a players negative behaviour",
        stats       = "configure how stats are calculated",
        cache       = "cache an inventory",
        count       = "prepend to cache to print a count of items in the provided inventory",
        bagpreference = "set the prefered bags for a tag",
        delete      = "delete all times with the given tags, \"prepend\" force to actually delete",
        sort        = "sort your inventory according to bagpreference",
    }

    local no_help_required = {"taglist", "prefixes", "restore", "gearset"}

    local prefixes = {
        force       = "prepend to other action to ignore precious tags",
        silent      = "prepend to other action to ignore any prints during the following operation",
    }

    local tag_prefixes = {
        remove      = "remove tag(s) from item(s) rather than adding it/them. Remove all tag(s) from the item(s) if no tag(s) are provided",
        global      = "apply the tagging action across all characters",
        replace     = "delete existing tag(s) from the item(s) before adding new tag(s)",
        distinct    = "remove occurence(s) of the provided tag(s) from item(s) of the same item slot(s) as the provided item(s)",
    }

    local use_prefixes = {
        bank        = "use from bank rather than inventory",
        exact       = "only use item(s) with, and only with, the provided tag(s)",
    }


    -- Prefixes does not change the actual operation, thus this output must be printed when we know what the actual
    -- command is.
    if valid_operations[operation] == nil then
        AAI_print(string.format("\"%s\" is an invalid operation - try \"/aai help\"", operation))


    elseif operation == "help" then
        if option == nil then
            AAI_print("AAI options:")
            for key, value in pairs(valid_operations) do
                AAI_print(string.format("- %s: %s", key, value))
            end

        else
            local help_operation, option = AAI_GetLeftWord(option)

            if valid_operations[help_operation] == nil then
                AAI_print(string.format("There is no help for \"%s\", as it is an invalid operation - try \"/aai help\"", help_operation))

            elseif help_operation == "tag" then
                local optionals = table.concat(AAI_Map(AAI_GetKeysFromTable(tag_prefixes), function(x) return "[" .. x .. "]" end), " ")
                AAI_print("Description: Applies the specified tag(s) to the provided item(s). Tags are shown on item tooltips.")
                AAI_print(string.format("Usage: /aai %s tag <tag> <ITEMLINK>", optionals))
                AAI_print(string.format("Example: /aai tag melee %s", "\124cffe6cc80\124Hitem:36942::::::::70:::::\124h[Frostmourne]\124h\124r"))
                AAI_print("Hint: \"/aai taglist\" to list tags with special meaning to AAI")
                AAI_print("Optional arguments for the \"tag\" operation:")
                for key, value in pairs(tag_prefixes ) do
                    AAI_print(string.format("- %s: %s", key, value):gsub("\n", "\n-"))
                end

            elseif help_operation == "use" then
                local optionals = table.concat(AAI_Map(AAI_GetKeysFromTable(use_prefixes), function(x) return "[" .. x .. "]" end), " ")
                AAI_print("Description: Uses all items in your inventory (or bank if specified) that are tagged with one (or each, and only each, if provided) of the provided tag(s)")
                AAI_print(string.format("Usage: /aai %s use <tag>", optionals))
                AAI_print("Example: /aai use cooking")
                AAI_print(string.format("- Expected outcome: use (as if you right clicked) all items in your inventory that are tagged with %s", AAI_SetColor("cooking")))
                AAI_print("Optional arguments for the \"use\" operation:")
                for key, value in pairs(use_prefixes ) do
                    AAI_print(string.format("- %s: %s", key, value):gsub("\n", "\n-"))
                end

            elseif help_operation == "equip" then
                local equip_tags = {"level", "melee", "tank", "heal", "spell", "uniform"}
                local equip_tag_string = table.concat(AAI_Map(equip_tags, function(x) return AAI_SetColor(x) end), ", ")
                AAI_print("Description: Equips all items in your inventory that are tagged with one of the provided tag(s)")
                AAI_print("Usage: /aai equip <tag>")
                AAI_print(string.format("Example: /aai equip %s", AAI_SetColor("melee")))
                AAI_print(string.format("- Expected outcome: equip all items from your inventory that are tagged with %s", AAI_SetColor("melee")))
                AAI_print(string.format("Hint: Keep in mind that equipping %s", equip_tag_string))

            elseif AAI_HasValue(no_help_required, help_operation) then
                AAI_print(string.format("\"%s\" is a simple and harmless operation without detailed help, try \"/aai %s\"", help_operation, help_operation))

            else
                AAI_print(string.format("There is no detailed help for %s yet", help_operation))
            end
        end

    -- operations
    elseif operation == "prefixes" then
        AAI_print("Prefixes that can be applied to any AAI command:")
        for key, value in pairs(prefixes) do
            AAI_print(string.format("%s:\n %s", key, value):gsub("\n", "\n-"))
        end

    -- operations
    elseif operation == "restore" then
        AAI_print = AAI_print_original
        AAI_CleanUpItemTagDatabase()
        AAI_print("Restored AAI")

    elseif operation == "bagpreference" then
        local tag, option = AAI_GetLeftWord(option)
        local _, tags = AAI_StringToItemLinksAndWords(option)
        aai_bag_preferences["tags"][tag] = AAI_Map(tags, tonumber, 1)

    elseif operation == "cache" then
        if not print_count then
            AAI_CacheInventory(inventory)
            AAI_print(string.format("Updated %s cache", inventory))
        else
            local links, tags = AAI_StringToItemLinksAndWords(option)
            for _, tag in pairs(tags) do
                local count = 0
                for _, _, item_link_cached, stack_size in AAI_GetCachedInventoryIterator(inventory) do
                    if AAI_HasTag(item_link_cached, tag) then
                        count = count + stack_size
                    end
                end
                print(string.format("%s x%s", tag, count))
            end
            for _, item_link in pairs(links) do
                local count = 0

                for _, _, item_link_cached, stack_size in AAI_GetCachedInventoryIterator(inventory) do
                    if AAI_ClearItemLinkLevel(item_link_cached) == AAI_ClearItemLinkLevel(item_link) then
                        count = count + stack_size
                    end
                end
                print(string.format("%s x%s", item_link, count))
            end
        end

    elseif operation == "warn" then
        AAI_WarnAboutPartyMembers()

    elseif operation == "playerwarn" then
        option = AAI_GeneralStringFormat(option)
        local name, remainder = AAI_GetLeftWord(option)
        name = AAI_TitleCase(name)
        aai_warn_players[name] = remainder
        AAI_print(string.format("Warning set for %s: %s", name, remainder))

    elseif operation == "tagrename" then
        local from_name, to_name
        from_name, option = AAI_GetLeftWord(option)
        to_name, option = AAI_GetLeftWord(option)
        AAI_RenameItemTagInDatabase(from_name, to_name)
        if to_name then
            AAI_print(string.format("Replaced all occurences of %s with %s.", from_name, to_name))
        else
            AAI_print(string.format("Deleted all occurences of %s.", from_name))
        end

    elseif operation == "display" then
        local mode
        mode, option = AAI_GetLeftWord(option)
        if mode == "bagpreference" then
            local tag
            tag, option = AAI_GetLeftWord(option)
            print(unpack(aai_bag_preferences["tags"][tag]))
        elseif mode == "tag" then
            local links, tags = AAI_StringToItemLinksAndWords(option)
            local link_names = AAI_Map(links, GetItemInfo, 1)

            for item_link, tag_list in pairs(aai_item_tags) do
                if (#tags == 0 or #AAI_GroupIntersect(AAI_GetKeysFromTable(tag_list), tags) > 0) and (#links == 0 or AAI_HasValue(link_names, GetItemInfo(item_link))) then
                -- if table.getn(tags) == 0 or AAI_HasValue(links, item_link) or table.getn(AAI_GroupIntersect(AAI_GetKeysFromTable(tag_list), tags)) > 0 then
                    if debug then
                        AAI_print(string.format("%s: %s", item_link, item_link:gsub("\124", "")))
                        for tag, _ in pairs(tag_list) do
                            AAI_print(string.format("- %s", tag))
                        end
                    else
                        AAI_print(item_link)
                    end
                end
            end
        else
            AAI_print("Invalid option for display. Try \"bagpreference\" or \"tag\"")
        end

    elseif operation == "taglist" then
        AAI_print("The tags handled by AAI are:")
        for _, value in ipairs(AAI_GetKeysFromTable(AAI_HandledTagsWithHelp)) do
            AAI_print(string.format("%s: %s", AAI_TitleCase(AAI_SetColor(value, AAI_GetTagColor(value))), AAI_GetTagHelp(value)))
        end

    elseif operation == "tagcolor" then
        local tag
        tag, option = AAI_GetLeftWord(option)
        if remove then
            aai_tag_colors[tag] = nil

        elseif option then
            aai_tag_colors[tag] = option
        end

    elseif operation == "gearset" then
        local _, tags = AAI_StringToItemLinksAndWords(option)
        for _, tag in pairs(tags) do
            AAI_RenameItemTagInDatabase(tag, nil, function(item_link, _,_) return not AAI_HasTag(item_link, "swap") end)
            for _, item_link in AAI_EquipmentIterator() do
                if item_link then
                    AAI_AddTag(item_link, tag, false)
                end
            end
        end

    elseif operation == "tag" then
        local links, tags = AAI_StringToItemLinksAndWords(option)
        if #links == 0 then
            AAI_print("Invalid use of \"tag\" operation. Try \"/aai help tag\"")
        end

        for _, item_link in pairs(links) do
            if replace or (remove and #tags == 0) then
                AAI_RemoveAllTags(item_link, true)
                AAI_RemoveAllTags(item_link, false)
            end

            for _, tag in pairs(tags) do
                tag = string.lower(tag)

                if not remove then
                    if distinct then
                        AAI_ClearTagForSlots(tag, AAI_GetItemSlots(item_link))
                    end
                    AAI_AddTag(item_link, tag, global)
                else
                    AAI_RemoveTag(item_link, tag, global)
                end
            end
        end

    elseif operation == "equip" then
        local links, tags = AAI_StringToItemLinksAndWords(option)

        if #links > 0 then
            AAI_print("You provided item links. This feature has not yet been implemented")
        end

        for _, tag in pairs(tags) do
            AAI_print("Equipping items tagged as " .. AAI_SetColor(tag, AAI_GetTagColor(tag)) .. ".")
            AAI_EquipAllTaggedItems(inventory, tag)
        end

    elseif operation == "sort" then
        AAI_SortInventory(inventory)

    elseif operation == "delete" then
        local links, tags = AAI_StringToItemLinksAndWords(option)

        if #links > 0 then
            AAI_print("You provided item links. This feature has not yet been implemented")
        end

        for _, tag in pairs(tags) do
            AAI_print("Delete items tagged as " .. AAI_SetColor(tag, AAI_GetTagColor(tag)) .. "...")
        end
        AAI_DeleteAllTaggedItems(inventory, tags, forced, exact)

    elseif operation == "use" then
        local links, tags = AAI_StringToItemLinksAndWords(option)

        if #links > 0 then
            AAI_print("You provided item links. This feature has not yet been implemented")
        end

        for _, tag in pairs(tags) do
            AAI_print("Used items tagged as " .. AAI_SetColor(tag, AAI_GetTagColor(tag)) .. "...")
        end
        AAI_UseAllTaggedItems(inventory, tags, false, forced, exact)

    end -- end of operation list

    AAI_print = AAI_print_original
end


