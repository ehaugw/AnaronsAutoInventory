-- import form parent directory
package.path = package.path .. ";../?.lua"


-- backup actual print and make a new print that removes wow highlights
true_print = print
print = function(msg)
    true_print(AAI_CleanItemLinkForConsole(msg))
end


-- WRAP
C_Container = {
    GetContainerItemCooldown = function(_) end,
    UseContainerItem = function(_, _) end,
    GetContainerNumSlots = function(_) end,
    GetContainerItemLink = function (_, _) end,
    PickupContainerItem = function (_, _) end,
}


require "AnaronsAutoInventory_Wrap"


-- CHAT
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


require "AnaronsAutoInventory_Chat"


-- UTILS
require "AnaronsAutoInventory_Util"


AAI_print = function(msg) print("    " .. msg) end
AAI_print_original = AAI_print


-- CORE
CreateFrame = function(_, _, _)
    return {
        RegisterEvent = function(_, _) end,
        SetScript = function(_, _, _) end
    }
end


GameTooltip = {
    HookScript = function(_, _, _) end
}


require "AnaronsAutoInventory_Core"


-- MISC
require "AnaronsAutoInventory_Misc"


-- ROLL
require "AnaronsAutoInventory_Roll"


-- TAGS
require "AnaronsAutoInventory_Tags"




---- IMPORT TEST THINGS ----
require "item"
require "tags"
require "util"

