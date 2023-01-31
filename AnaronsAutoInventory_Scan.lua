local scantip = CreateFrame("GameTooltip", "AAI_ScanningTooltip", nil, "GameTooltipTemplate")
scantip:SetOwner(UIParent, "ANCHOR_NONE")


function AAI_GetItemStatsByScanning(item_link)
    local gear_bonuses = {}

    local set_pieces = 0
    local has_empty_socket = false

    for left, right in AAI_ForEachTooltipLine(item_link) do
        for _, line in pairs({left, right}) do
            if line then
                local text = AAI_GeneraliseTooltipText(line)

                local equipped_set_pieces, _ = string.match(text, ".* %(([0-9]+)/([0-9]+)%)")
                if equipped_set_pieces then
                    set_pieces = tonumber(equipped_set_pieces)
                end

                local required_set_pieces, effect = string.match(text, "%(([0-9]+)%) set:(.*)")
                if required_set_pieces then
                    if set_pieces >= tonumber(required_set_pieces) then
                        text = effect
                    else
                        text = ""
                    end
                end

                local empty_socket = string.match(text, "^[^ ]+ socket$")
                if empty_socket then
                    has_empty_socket = true
                    text = ""
                end

                effect = string.match(text, "socket bonus: (.*)")
                if effect then
                    if has_empty_socket then
                        text = ""
                    else
                        text = effect
                    end
                end

                local sign, scalar
                sign, scalar, effect = string.match(text, "^([%+%-]) *([0-9]+%.?[0-9]*) *([^ ].*)")
                if scalar then
                    -- effect = string.gsub(effect, " +", "")
                    gear_bonuses[effect] = (gear_bonuses[effect] or 0) + tonumber(sign .. scalar)
                end
            end
        end
    end
    return gear_bonuses
end


function AAI_GeneraliseTooltipText(text)
    text = string.lower(text)

    -- spells
    local effect, scalar, situation = string.match(text, "increases (.*) done by ([0-9]+) for (.*)%.")
    if not effect then
        effect, situation, scalar = string.match(text, "increases (.*) done by (.*) by ([0-9]+)%.")
    end
    if effect then
        text = "increases " .. effect .. " " .. situation .. " by " .. scalar .. "."
    end

    text = string.gsub(text, "%+%+", "+")
    text = string.gsub(text, "%-%-", "+")
    text = string.gsub(text, "%+%-", "-")
    text = string.gsub(text, "%-%+", "-")

    text = string.gsub(text, "restores ([0-9]+) mana per 5 sec", "+ %1 mp5")
    text = string.gsub(text, "restores ([0-9]+) health per 5 sec", "+ %1 hp5")

    text = string.gsub(text, "spells_and_effects", "spells")
    text = string.gsub(text, " *all magical *", " ")
    text = string.gsub(text, " *magical *", " ")
    text = string.gsub(text, "healing spells", "healing")
    text = string.gsub(text, "damage spells", "spell damage")

    text = string.gsub(text, "increases your", "increases")
    text = string.gsub(text, "decreases your", "decreases")
    text = string.gsub(text, "improves your", "improves")
    text = string.gsub(text, "reduces your", "reduces")

    text = string.gsub(text, "increases +(.*) by ([0-9]+)%.", "+ %2 %1")
    text = string.gsub(text, "improves +(.*) by ([0-9]+)%.", "+ %2 %1")
    text = string.gsub(text, "decreases +(.*) by ([0-9]+)%.", "- %2 %1")
    text = string.gsub(text, "reduces +(.*) by ([0-9]+)%.", "- %2 %1")
    text = string.gsub(text, "(.*)% +increased", "+ %1")
    text = string.gsub(text, "([0-9]+) armor", "+ %1 armor")

    text = string.gsub(text, "%(([^ ]+) damage per second%)", "+ %1 dps")
    text = string.gsub(text, "speed ([^ ]+)", "+ %1 speed")

    text = string.gsub(text, " %+", " ")

    return text
end



function AAI_GetTooltipLineAfterSplit(item_link)
    if item_link == nil then
        return {}, {}
    end
    scantip:ClearLines()
    scantip:SetHyperlink(item_link)

    local left_texts = {}
    local right_texts = {}

    for line_index = 2, scantip:NumLines() do
        local left_text = _G["AAI_ScanningTooltipTextLeft"..line_index]:GetText()
        local right_text = _G["AAI_ScanningTooltipTextRight"..line_index]:GetText()

        left_text = AAI_CleanTooltipText(left_text)
        left_text = AAI_FillEmptyGems(left_text)
        local left_text_2
        left_text, left_text_2 = AAI_SplitTooltipText(left_text)

        table.insert(left_texts, left_text)
        table.insert(right_texts, right_text)

        if left_text_2 then
            table.insert(left_texts, left_text_2)
            table.insert(right_texts, right_text)
        end
    end

    return left_texts, right_texts
end


function AAI_ForEachTooltipLine(item_link)
    local left_texts, right_texts = AAI_GetTooltipLineAfterSplit(item_link)

    local i = 1
    local n = #left_texts

    return function()
        i = i + 1
        if i <= n then
            return left_texts[i], right_texts[i]
        end
    end
end


function AAI_CleanTooltipText(text)
    text = string.gsub(text, "\124c[a-z][a-z][a-z][a-z][a-z][a-z][a-z][a-z]" ,"")
    text = string.gsub(text, "\124r" ,"")
    text = string.gsub(text, "[^%&0-9a-zA-Z%+%-%(%)%:/%., ]" ,"")
    text = string.gsub(text, "spells and effects", "spells_and_effects")
    text = string.gsub(text, "Equip: ", "")
    text = string.gsub(text, " up to ", " ")
    text = string.gsub(text, "%s*Requires at least [0-9] %S+ gems","")
    return text
end


function AAI_FillEmptyGems(text)
    for _, color in pairs({"red", "blue", "yellow", "meta"}) do
        if aai_stat_settings["defaultsocket" .. color] then
            text = string.gsub(text, AAI_TitleCase(color) .. " Socket", aai_stat_settings["defaultsocket" .. color])
        end
    end
    return text
end


function AAI_SplitTooltipText(text)
    text = string.gsub(text, "%&","and")
    local increases, remainder = string.match(text, "(.*[Ii]ncreases)(.*)")
    if not increases then
        increases, remainder = string.match(text, "(.*[Ii]mproves)(.*)")
    end
    if increases then
        text = remainder
    end
    local plus
    plus, text = string.match(text, "(%+?%-?[0-9]* ?)(.*)")

    local prefix = (increases or "") .. plus

    -- special cases
    -- increases healing done by # and damage done by # ...
    local effect1, effect2, situation = string.match(text, "(.* done by [0-9]+) and (.* done by [0-9]+)(.*)")
    if situation then
        prefix = prefix .. " "
        return prefix .. effect1 .. situation, prefix .. effect2 .. situation
    end
    -- increases damage and healing done by ... by #
    effect1, effect2, situation = string.match(text, "(damage) and (healing)( done by .* by [0-9]+%.)")
    if situation then
        prefix = prefix .. " "
        return prefix .. effect1 .. situation, prefix .. effect2 .. situation
    end
    -- increases damage and healing done by ... slightly
    effect1, effect2, situation = string.match(text, "(damage) and (healing)( done by .* slightly.)")
    if situation then
        prefix = prefix .. " "
        return prefix .. effect1 .. situation, prefix .. effect2 .. situation
    end

    local left, right = string.match(text, "(.*) +and +(.*)")

    if left then
        plus, text = string.match(right, "(%+?%-?[0-9]* ?)(.*)")
        if plus == "" or plus == " " then
            plus = nil
        end
        if text == "" or text == " " then
            text = nil
        end
        return prefix .. left, (plus or prefix) .. (text or right)
    else
        return prefix .. text, nil
    end
end

