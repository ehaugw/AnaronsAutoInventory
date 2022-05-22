local addon_name, addon_data = ...

addon_data = {}
addon_data.core = {}
addon_data.event_frames = {}


function AAI_SubscribeEvent(event, callable, identifier)
    local name = addon_name .. (identifier or string.gsub(tostring(callable), " ", "")) .. event
    local frame = addon_data.event_frames[name] or CreateFrame("Frame", name , UIParent)
    frame:RegisterEvent(event)
    frame:SetScript("OnEvent", callable)
    addon_data.event_frames[name] = frame
end


function AAI_UnsubscribeEvent(event, identifier)
    local name = addon_name .. identifier .. event
    local frame = addon_data.event_frames[name]
    frame:UnregisterEvent(event)
end


local function OnAddonLoadedCore(addon_name)
    if addon_name == "AnaronsAutoInventory" then
        AAI_print("Anaron's Auto Inventory was loaded")
        AAI_OnAddonLoadedTags(self)
        AAI_OnAddonLoadedWarn(self)
        AAI_OnAddonLoadedSpec(self)
        AAI_OnAddonLoadedStat(self)
        AAI_OnAddonLoadedBags(self)
    end
end


AAI_SubscribeEvent("ADDON_LOADED", function(_, _, addon_name) OnAddonLoadedCore(addon_name) end)


function AAI_SetComparetooltip(tooltip_self, anchorFrame)
    -- taken from https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/FrameXML/GameTooltip.lua
    local tooltip, anchorFrame, shoppingTooltip1, shoppingTooltip2 = GameTooltip_InitializeComparisonTooltips(tooltip_self, anchorFrame);
    local primaryItemShown, secondaryItemShown = shoppingTooltip1:SetCompareItem(shoppingTooltip2, tooltip);
    GameTooltip_AnchorComparisonTooltips(tooltip, anchorFrame, shoppingTooltip1, shoppingTooltip2, primaryItemShown, secondaryItemShown);

    -- private code
    if primaryItemShown then
        local _, item_link = GameTooltip:GetItem()

        local item_spec = AAI_GetItemSpec(item_link)
        if item_spec then
            local competing_item_link = AAI_GetCompetingItemFromInventory(item_link, item_spec)

            if competing_item_link then
                shoppingTooltip1:SetCompareItem(shoppingTooltip2, tooltip);
                shoppingTooltip1:ClearLines()
                shoppingTooltip1:SetHyperlink(competing_item_link)

                AAI_AddTooltipInformation(shoppingTooltip1, competing_item_link, item_spec)
                shoppingTooltip1:Show()
            end
        end
    end

end


function AAI_AddTooltipInformation(tooltip, item_link, item_spec)

    if AAI_GetItemSlots(item_link) ~= nil then
        compete_with_equipped = item_spec == nil and IsShiftKeyDown()

        local attackpower = AAI_GetItemTotalAttackPowerWithDps(item_link)
        local critchance = AAI_GetItemTotalCritChance(item_link)
        local hitchance = AAI_GetItemTotalHitChance(item_link)
        local spellcritchance = AAI_GetItemTotalSpellCritChance(item_link)
        local expertise = AAI_GetItemTotalExpertise(item_link)
        local haste = AAI_GetItemTotalHaste(item_link)

        if attackpower > 0 then
            tooltip:AddDoubleLine("Effective Attack Power", AAI_Round(attackpower, 2))
        end
        if expertise > 0 then
            tooltip:AddDoubleLine("Effective Expertise", AAI_Round(expertise * 100, 2) .. "%")
        end
        if haste > 0 then
            tooltip:AddDoubleLine("Effective Haste", AAI_Round(haste * 100, 2) .. "%")
        end
        if critchance > 0 then
            tooltip:AddDoubleLine("Effective Crit Chance", AAI_Round(critchance * 100,2) .. "%")
        end
        if hitchance > 0 then
            tooltip:AddDoubleLine("Effective Hit Chance", AAI_Round(hitchance * 100,2) .. "%")
        end
        if spellcritchance > 0 then
            tooltip:AddDoubleLine("Effective Spell Crit Chance", AAI_Round(spellcritchance * 100,2) .. "%")
        end

        item_link = AAI_ClearItemLinkEnchant(item_link)
        for spec_name, description in pairs({melee = "Melee Power Delta", heal = "Healing/Second Delta"}) do
            if spec_name ~= "heal" or AAI_IsHealerClass("player") then
                local competing_item_link = compete_with_equipped and AAI_GetCompetingItemEquipped(item_link) or AAI_GetCompetingItemFromInventory(item_link, item_spec or spec_name) or AAI_GetCompetingItemEquipped(item_link)
                competing_item_link = AAI_ClearItemLinkEnchant(competing_item_link)

                local score_delta, provided_score, competing_score = AAI_GetItemScoreComparison(item_link, competing_item_link, spec_name)
                if provided_score > 0 then
                    tooltip:AddDoubleLine(description,   AAI_SetColor(AAI_Round(score_delta,   2), score_delta   < 0 and "FF0000" or "00FF00"))
                end
            end
        end
    end

    item_link = AAI_CleanItemLinkForDatabase(item_link)
    if aai_item_tags[item_link] ~= nil then
        for key, value in pairs(aai_item_tags[item_link]) do
            if not (aai_item_tags_global[item_link] and aai_item_tags_global[item_link][key]) then
                tooltip:AddLine(AAI_SetColor(AAI_TitleCase(key), AAI_GetTagColor(key)))
            end
        end
    end
    if aai_item_tags_global[item_link] ~= nil then
        for key, value in pairs(aai_item_tags_global[item_link]) do
            tooltip:AddDoubleLine(AAI_SetColor(AAI_TitleCase(key), AAI_GetTagColor(key)), AAI_SetColor("Global", "FFFFFF"))
        end
    end
end


function AAI_AddTooltipTags()
    local _, item_link = GameTooltip:GetItem()

    if IsAltKeyDown() then
        AAI_SetComparetooltip(GameTooltip, GameTooltip)
    end

    AAI_AddTooltipInformation(GameTooltip, item_link, IsAltKeyDown() and AAI_GetItemSpec(item_link) or nil)

end


GameTooltip:HookScript("OnTooltipSetItem", AAI_AddTooltipTags)

