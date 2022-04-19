-- WOW SPECIFIC STRING HANDLING
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
    if inputstr == "" then
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
function AAI_GetInventoryBagIndexLinkTuples(inventory)
    local inventory_tuple = {}
    local container_ids = AAI_GetInventoryBags(inventory)

    for _, bag in ipairs(container_ids) do
        for slot=1,GetContainerNumSlots(bag),1 do
            local name = GetContainerItemLink(bag,slot)
            table.insert(inventory_tuple, {bag, slot, name})
        end
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
function AAI_Round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end
