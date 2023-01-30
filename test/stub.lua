-- SETUP DEFAULT DICTS
aai_item_tags = {}
aai_item_tags_global = {}
aai_tag_colors = {}


C_Container = {
    GetContainerItemCooldown = function(_) end,
    UseContainerItem = function(_, _) end,
    GetContainerNumSlots = function(_) end,
    GetContainerItemLink = function (_, _) end,
    PickupContainerItem = function (_, _) end,
}


SlashCmdList = {}
function chat_command(msg, silent)
    if silent == nil then
        print("Executing: /aai " .. msg)
        silent = ""
    else
        silent = "silent "
    end

    SlashCmdList["AUTO_INVENTORY_COMMAND_LINE_INTERFACE"](silent .. msg)
end


CreateFrame = function(_, _, _, _)
    return {
        RegisterEvent = function(_, _) end,
        SetScript = function(_, _, _) end
    }
end


self = CreateFrame()


GameTooltip = {
    HookScript = function(_, _, _) end
}


GameTooltip_InitializeComparisonTooltips = function(_, _) end
GameTooltip_AnchorComparisonTooltips = function(_, _, _, _, _, _) end

GetTime = function() end
GetUnitName = function(_, _) end
GetZoneText = function() end

UIParent = {}

IsShiftKeyDown = function() end
GetCritChance = function () end
IsAltKeyDown = function () end

GetItemInfo = function() end

unpack = unpack
