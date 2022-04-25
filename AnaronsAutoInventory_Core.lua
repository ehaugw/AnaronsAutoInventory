local addon_name, addon_data = ...

addon_data = {}
addon_data.core = {}

-- Create frame that has the addon loaded event.
addon_data.core.core_frame = CreateFrame("Frame", addon_name .. "CoreFrame", UIParent)
addon_data.core.core_frame:RegisterEvent("ADDON_LOADED")
addon_data.core.core_frame:RegisterEvent("MERCHANT_SHOW")
addon_data.core.core_frame:RegisterEvent("BANKFRAME_OPENED")
addon_data.core.core_frame:RegisterEvent("START_LOOT_ROLL")
addon_data.core.core_frame:RegisterEvent("CONFIRM_LOOT_ROLL")
addon_data.core.core_frame:RegisterEvent("PLAYER_ENTERING_WORLD")


local function OnAddonLoadedCore(self)
    AAI_print("Anaron's Auto Inventory was loaded")
    AAI_OnAddonLoadedTags(self)
    AAI_OnAddonLoadedWarn(self)
end

local function CoreFrame_OnEvent(self, event, ...)
    local args = {...}
    if event == "ADDON_LOADED" then
        if args[1] == "AnaronsAutoInventory" then
            OnAddonLoadedCore()
        end

    elseif event == "MERCHANT_SHOW" then
        AAI_UseAllTaggedItems("inventory", "junk", true, false)

    elseif event == "BANKFRAME_OPENED" then
        AAI_UseAllTaggedItems("inventory", "bank", false, false)

    elseif event == "START_LOOT_ROLL" or event == "CONFIRM_LOOT_ROLL" or event == "PLAYER_ENTERING_WORLD" then
        AAI_HandleRoll(event, args)
    elseif event == "PARTY_MEMBERS_CHANGED" or event == "GROUP_ROSTER_UPDATE" then
        AAI_WarnAboutPartyMembers()
    end
end


function AAI_AddTooltipTags()
    local _, link = GameTooltip:GetItem()
    link = AAI_CleanItemLinkForDatabase(link)

    if GetUnitName("player") == "Anaron" then

        compete_with_equipped = IsShiftKeyDown()

        local attackpower = AAI_GetItemTotalAttackPower(link)
        local critchance = AAI_GetItemTotalCritChance(link)
        local hitchance = AAI_GetItemTotalHitChance(link)
        local competing_melee_link   = compete_with_equipped and AAI_GetCompetingItemEquipped(link) or AAI_GetCompetingItemFromInventory(link, "melee")
        local competing_healing_link = compete_with_equipped and AAI_GetCompetingItemEquipped(link) or AAI_GetCompetingItemFromInventory(link, "heal")
        local meleepowerdelta = AAI_GetItemMeleePowerDelta(link, competing_melee_link) or 0
        local healingpowerdelta = AAI_GetItemHealingPowerDelta(link, competing_healing_link) or 0
        local spellcritchance = AAI_GetItemTotalSpellCritChance(link)

        if attackpower > 0 then
            GameTooltip:AddDoubleLine("Effective Attack Power", AAI_Round(attackpower, 2))
        end
        if critchance > 0 then
            GameTooltip:AddDoubleLine("Effective Crit Chance", AAI_Round(critchance * 100,2) .. "%")
        end
        if hitchance > 0 then
            GameTooltip:AddDoubleLine("Effective Hit Chance", AAI_Round(hitchance * 100,2) .. "%")
        end
        if spellcritchance > 0 then
            GameTooltip:AddDoubleLine("Effective Spell Crit Chance", AAI_Round(spellcritchance * 100,2) .. "%")
        end
        if competing_melee_link then
            GameTooltip:AddDoubleLine("Melee Power Delta",   AAI_SetColor(AAI_Round(meleepowerdelta,   2), meleepowerdelta   < 0 and "FF0000" or "00FF00"))
        end
        if competing_healing_link then
            GameTooltip:AddDoubleLine("Healing Power Delta", AAI_SetColor(AAI_Round(healingpowerdelta, 2), healingpowerdelta < 0 and "FF0000" or "00FF00"))
        end
    end

    if aai_item_tags[link] ~= nil then
        for key, value in pairs(aai_item_tags[link]) do
            if not (aai_item_tags_global[link] and aai_item_tags_global[link][key]) then
                GameTooltip:AddLine(AAI_SetColor(AAI_TitleCase(key), AAI_GetTagColor(key)))
            end
        end
    end
    if aai_item_tags_global[link] ~= nil then
        for key, value in pairs(aai_item_tags_global[link]) do
            GameTooltip:AddDoubleLine(AAI_SetColor(AAI_TitleCase(key), AAI_GetTagColor(key)), AAI_SetColor("Global", "FFFFFF"))
        end
    end
end


-- Set the function that is run on every event.
addon_data.core.core_frame:SetScript("OnEvent", CoreFrame_OnEvent)
GameTooltip:HookScript("OnTooltipSetItem", AAI_AddTooltipTags)

