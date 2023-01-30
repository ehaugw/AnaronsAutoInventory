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


function AAI_CleanItemLinkForConsole(text)
    if text ~= nil then
        old = nil
        while text ~= old do
            old = text
            text, _ = text:gsub("(.*)\124c[0-9a-f]+([^\124]*)\124r(.*)", "%1%2%3")
        end

        old = nil
        while text ~= old do
            old = text
            text, _ = text:gsub("(.*)(\124c[0-9a-f]+\124Hitem:[^\124]*\124h)([^\124]*)\124h\124r(.*)", "%1%3%4")
        end
        return text
    else
        return nil
    end
end


function AAI_CleanItemLinkForDatabase(text)
    return AAI_ClearItemLinkGems(AAI_ClearItemLinkEnchant(AAI_ClearItemLinkLevel(text)))
end


function AAI_ClearItemLinkGems(text)
    for i = 3, 6 do
        text = AAI_ReplaceNumberAtIndex(text, i, "")
    end
    return text
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


aai_to_be_printed = ""
function AAI_BatchPrint(str)
    if str == nil then
        AAI_print(aai_to_be_printed)
        aai_to_be_printed = ""
    else
        aai_to_be_printed = aai_to_be_printed .. "\n" .. str
    end
end


AAI_print_original = AAI_print


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


function AAI_ForEachUnpack(tab)
    local i = 0
    local n = table.getn(tab)
    local recover = 0

    return function(options)
        if options and options.recover then
            i = recover
            return
        elseif options and options.reset then
            recover = i
            i = 0
            return
        end

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

function AAI_Join(list, delim)
    local out = ""
    for index, value in pairs(list) do
        if out ~= "" then
            out = out .. delim
        end
        out = out .. tostring(value)
    end
    return out
end
