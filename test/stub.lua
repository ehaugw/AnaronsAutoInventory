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


GameTooltip = {
    HookScript = function(_, _, _) end
}


GetTime = function() end
GetUnitName = function(_, _) end
GetZoneText = function() end

UIParent = {}

