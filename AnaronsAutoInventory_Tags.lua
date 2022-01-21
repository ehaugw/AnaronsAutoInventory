AAI_OnAddonLoadedTags = function(instance)
    aai_item_tags = aai_item_tags or {}
end


-- CLI
SLASH_AUTO_INVENTORY_COMMAND_LINE_INTERFACE1 = "/aai"
SLASH_AUTO_INVENTORY_COMMAND_LINE_INTERFACE2 = "/anaronsautoinventory"

SlashCmdList["AUTO_INVENTORY_COMMAND_LINE_INTERFACE"] = function(option)
    local operation, option = AAI_GetLeftWord(option)

    local valid_operations = {
        help        = "get help with AAI",
        tag         = "assign a tag to an item",
        remove      = "prepend to \"tag\" to remove a tag from an item",
        taglist     = "display a list of tags handled by AAI",
        use         = "use all items with the provided tag",
        force       = "prepend to other action to ignore precious tags",
        silent      = "ignore any prints during the following operation",
        restore     = "restore AAI after a crash",
        bank        = "prepend to \"bank\" to use from bank rather than inventory"
    }

    -- prefixes
    if operation == "silent" then
        AAI_print = function() end
        operation, option = AAI_GetLeftWord(option)
    end

    local forced = false
    if operation == "force" then
        forced = true
        operation, option = AAI_GetLeftWord(option)
    end

    local remove = false
    if operation == "remove" then
        remove = true
        operation, option = AAI_GetLeftWord(option)
    end

    local inventory = "character"
    if operation == "bank" then
        inventory = "bank"
        operation, option = AAI_GetLeftWord(option)
    end

    if valid_operations[operation] == nil then
        AAI_print(string.format("\"%s\" is an invalid operation - try \"/aai h\"", operation))
    end

    -- operations
    if operation == "restore" then
        AAI_print = AAI_print_original
        AAI_print("Restored AAI")
    
    elseif operation == "help" then
        if option then
            AAI_print(string.format("Items tagged as %s are %s", AAI_SetColor(option, AAI_GetTagColor(option)), AAI_GetTagHelp(option)))
        else
            AAI_print("- help [tag]: get information related to a tag")
            AAI_print("AAI options:")
            for key, value in pairs(valid_operations) do
                AAI_print(string.format("- %s: %s", key, value))
            end
        end

    elseif operation == "taglist" then
        AAI_print("The tags handled by AAI are:")
        for _, value in ipairs(AAI_TagList) do
            AAI_print(string.format("%s: %s", AAI_TitleCase(AAI_SetColor(value, AAI_GetTagColor(value))), AAI_GetTagHelp(value)))
        end

    elseif operation == "tag" then
        local tag, option = AAI_GetLeftWord(option)
        
        while option ~= nil do
            item_link, option = AAI_GetLeftItemLink(option)


            if tag and option then
                tag = string.lower(tag)

                if not remove then
                    AAI_AddTag(item_link, tag)
                else
                    AAI_RemoveTag(item_link, tag)
                end
            end
        end

    elseif operation == "use" then
        -- FIXME: set destructive to true when merchant is open
        AAI_UseAllTaggedItems(inventory, option, false, forced)
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


function AAI_AddTag(item, tag)
    if aai_item_tags[item] == nil then
        aai_item_tags[item] = {}
    end
    aai_item_tags[item][tag] = true

    -- _, item_link = GetItemInfo(item)
    AAI_print(string.format("%s was tagged as %s.", item, AAI_SetColor(tag, AAI_GetTagColor(tag))))
end


function AAI_RemoveTag(item, tag)
    if aai_item_tags[item] == nil then
        aai_item_tags[item] = {}
    end
    aai_item_tags[item][tag] = nil
    -- _, item_link = GetItemInfo(item)
    AAI_print(string.format("%s is no longer tagged as %s", item, AAI_SetColor(tag, "ffffff")))
end


function AAI_HasTag(item, tag)
    if item and tag == "junk" then
        _, _, rarity = GetItemInfo(item)
        if rarity == 0 then
            return true
        end
    end

    if aai_item_tags[item] ~= nil then
        return aai_item_tags[item][tag]
    end
    return false
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
    return color_table[tag] or "ffffff"
end


function AAI_GetTagHelp(tag)
    local help_table = {
        junk        = "automatically sold to vendors",
        precious    = "never sold through AAI",
        bank        = "automaticall transfered to the bank"
    }
    return help_table[tag] or "not handled by AAI"
end


-- function AAI_ReplaceLinkWithID(text)
--     if text ~= nil then
--         return text:gsub("(.*)(\124c[0-9a-f]+\124Hitem:([0-9]+):.*[^\124]*\124h[^\124]*\124h\124r)(.*)", "%1%3%4")
--     else
--         return nil
--     end
-- end


AAI_TagList = {"junk", "precious", "bank"}
