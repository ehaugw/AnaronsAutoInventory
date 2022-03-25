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



local function OnAddonLoadedCore(self)
    AAI_print("Anaron's Auto Inventory was loaded")
    AAI_OnAddonLoadedTags(self)
end

local function CoreFrame_OnEvent(self, event, ...)
    local args = {...}
    if event == "ADDON_LOADED" then
        if args[1] == "AnaronsAutoInventory" then
            OnAddonLoadedCore()
        end

    elseif event == "MERCHANT_SHOW" then
        AAI_UseAllTaggedItems("character", "junk", true, false)

    elseif event == "BANKFRAME_OPENED" then
        AAI_UseAllTaggedItems("character", "bank", false, false)

    elseif event == "START_LOOT_ROLL" or event == "CONFIRM_LOOT_ROLL" then
        AAI_HandleRoll(event, args)
    end
end


function AAI_AddTooltipTags()
    _, link = GameTooltip:GetItem()
    link = AAI_CleanItemLinkForDatabase(link)
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

