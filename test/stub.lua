-- SETUP DEFAULT DICTS
aai_item_tags = {}
aai_item_tags_global = {}
aai_tag_colors = {}

aai_bag_preferences  = {}
aai_item_cache = {}


C_Container = {
    GetContainerItemCooldown = function(_, _) end,
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
UnitClass = function(_, _) end
UnitDamage = function (_) end
UnitAttackSpeed = function (_) end
UnitAffectingCombat = function(_) end
GetCombatRatingBonus = function(_) end
UnitLevel = function(_) end
GetZoneText = function() end

GetInventoryItemLink = function(_, _) end
GetInventoryItemCooldown = function(_, _) end
EquipItemByName = function(_, _) end

UIParent = {}
CR_HIT_MELEE = ""
CR_HASTE_MELEE = ""

IsShiftKeyDown = function() end
GetCritChance = function () end
GetSpellBonusHealing = function () end
GetSpellCritChance = function (_) end
IsAltKeyDown = function () end
IsControlKeyDown = function () end

GetItemInfo = function(_) end
time = function() end
max = function(...) end
min = function (...) end
ceil = function (...) end

unpack = unpack

ContainerIDToInventoryID = function (_) end
GetItemFamily = function(_) end
GetNumBankSlots = function () end
SplitContainerItem = function (_, _, _) end
GuildSetMOTD = function(_) end
GetBuildInfo = function() end
ReloadUI = function () end
GetActiveLootRollIDs = function() end
GetLootRollItemLink = function (_) end
ConfirmLootRoll = function (_, _) end
GetTalentInfo = function (_, _) end
CursorHasItem = function () end
DeleteCursorItem = function () end
