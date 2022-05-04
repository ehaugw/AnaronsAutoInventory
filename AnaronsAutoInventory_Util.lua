-- WOW SPECIFIC STRING HANDLING
function AAI_GeneralStringFormat(message)
    message = string.gsub(message, "%%player", "%%p")
    message = string.gsub(message, "%%p", GetUnitName("player", false))

    message = string.gsub(message, "%%location", "%%l")
    message = string.gsub(message, "%%l", GetZoneText())

    message = string.gsub(message, "%%player", "%%p")
    message = string.gsub(message, "%%p", GetZoneText())

    return message
end

    
function AAI_StringToItemLinksAndWords(option)
    local links = {}
    local tags = {}
    while true do
        if option then
            if AAI_IsItemLink(option) then
                left_word, option = AAI_GetLeftItemLink(option)
                left_word = AAI_CleanItemLinkForDatabase(left_word)
                table.insert(links, left_word)
            else
                left_word, option = AAI_GetLeftWord(option)
                table.insert(tags, left_word)
            end
        else
            break
        end
    end
    return links, tags
end


function AAI_SetColor(str, color)
    if not color then
        color = AAI_GetTagColor(str)
    end
    return string.format("\124cff%s%s\124r", color, str)
end


function AAI_IsItemLink(text)
    item_link, _, _, remainer = string.match(text, "^(\124c[0-9a-f]+\124Hitem:([0-9]+):[^\124]*\124h[^\124]*\124h\124r)(%s?)(.*)")
    return item_link ~= nil
end


function AAI_GetLeftItemLink(text)
    item_link, _, _, remainer = string.match(text, "(\124c[0-9a-f]+\124Hitem:([0-9]+):[^\124]*\124h[^\124]*\124h\124r)(%s?)(.*)")
    return item_link, remainer
end


function AAI_GetLeftWord(inputstr)
    if not inputstr or inputstr == "" then
        return nil, nil
    end

    local one, two= string.match(inputstr, "(%S+)%s+(%S.*)")
    if one == nil then
        one = inputstr
    end
    return one, two
end


function AAI_ReplaceLinkWithID(text)
    if text ~= nil then
        return text:gsub("(.*)(\124c[0-9a-f]+\124Hitem:([0-9]+):.*[^\124]*\124h[^\124]*\124h\124r)(.*)", "%1%3%4")
    else
        return nil
    end
end


function AAI_CleanItemLinkForDatabase(text)
    return AAI_ClearItemLinkEnchant(AAI_ClearItemLinkLevel(text))
end


function AAI_ClearItemLinkEnchant(text)
    return AAI_ReplaceNumberAtIndex(text, 2, "")
end


function AAI_ClearItemLinkLevel(text)
    return AAI_ReplaceNumberAtIndex(text, 9, "")
end


function AAI_ReplaceNumberAtIndex(text, index, level)
    local old = text
    if text ~= nil then
        local pre = "(.*)(\124c[0-9a-f]+\124Hitem)"
        local mid = "(" .. AAI_TextRepeat(":%-?[0-9]*", index - 1) .. ":)(%-?[0-9]*)(" .. AAI_TextRepeat(":%-?[0-9]*", 18 - index) .. ")"
        local post = "(\124h[^\124]*\124h\124r)(.*)"
        text, _ = text:gsub(pre .. mid .. post, "%1%2%3" .. level .. "%5%6%7")
        return text
    end
end


-- GENERAL STRING HANDLING
function AAI_TextRepeat(text, repetitions)
    local result = ""
    while repetitions > 0 do
        repetitions = repetitions - 1
        result = result .. text
    end
    return result
end


function AAI_TitleCase(str)
    return str:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
end


function AAI_print(str)
    print(AAI_SetColor(str, "aaaaff"))
end


AAI_print_original = AAI_print


-- WOW ITEM AND INVENTORY HANDLING
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

    -- if include_equipment then
    --     local bag = 0
    --     for slot=-3-19,-3-1 do
    --         local item_link = GetContainerItemLink(bag, slot)
    --         -- if item_link then
    --         if reverse then
    --             table.insert(inventory_tuple, 0, {bag, slot, item_link})
    --         else
    --             table.insert(inventory_tuple, {bag, slot, item_link})
    --         end
    --     end
    -- end

    for _, bag in ipairs(container_ids) do
        for slot=1,GetContainerNumSlots(bag),1 do
            local item_link = GetContainerItemLink(bag, slot)
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


-- GENERAL TABLE OPERATIONS
function AAI_HasValue (tab, val)
    for index, value in pairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end


function AAI_GetKeysFromTable(tab)
    local keys = {}
    for key, _ in pairs(tab) do
        table.insert(keys, key)
    end
    return keys
end


function AAI_ForEach(tab)
    local i = 0
    local n = table.getn(tab)

    return function()
        i = i + 1
        if i <= n then
            return tab[i]
        end
    end
end


function AAI_ForEachUnpack(tab)
    local i = 0
    local n = table.getn(tab)

    return function()
        i = i + 1
        if i <= n then
            return unpack(tab[i])
        end
    end
end


function AAI_GroupUnion(tab1, tab2)
    local union = {}
    for _, value in ipairs(tab1) do
        table.insert(union, value)
    end
    for _, value in ipairs(tab2) do
        if not AAI_HasValue(union, value) then
            table.insert(union, value)
        end
    end
    return union
end


function AAI_GroupIntersect(tab1, tab2)
    local intersection = {}
    for _, value in ipairs(tab1) do
        if AAI_HasValue(tab2, value) then
            table.insert(intersection, value)
        end
    end
    return intersection
end


function AAI_Map(tab, func, selector)
    local output = {}
    for key, val in pairs(tab) do
        output[key] = not selector and func(val) or selector and select(selector, func(val))
    end
    return output
end


-- GENERAL MATH
function AAI_Interpolate(tuple_list, value)
    local smaller = nil
    local smaller_value = nil
    for x, y in AAI_ForEachUnpack(tuple_list) do
        if x == value then
            return y
        end
        if smaller ~= nil then
            if x > value then
                return ((x - value) * smaller_value + (value - smaller) * y) / (x - smaller)
            end
        end
        smaller = x
        smaller_value = y
    end
    return nil
end


function AAI_Round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end
