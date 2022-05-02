local item_slot_table = {
    --Source: http://wowwiki.wikia.com/wiki/ItemEquipLoc
    ["INVTYPE_AMMO"] =           { 0 },
    ["INVTYPE_HEAD"] =           { 1 },
    ["INVTYPE_NECK"] =           { 2 },
    ["INVTYPE_SHOULDER"] =       { 3 },
    ["INVTYPE_BODY"] =           { 4 },
    ["INVTYPE_CHEST"] =          { 5 },
    ["INVTYPE_ROBE"] =           { 5 },
    ["INVTYPE_WAIST"] =          { 6 },
    ["INVTYPE_LEGS"] =           { 7 },
    ["INVTYPE_FEET"] =           { 8 },
    ["INVTYPE_WRIST"] =          { 9 },
    ["INVTYPE_HAND"] =           { 10 },
    ["INVTYPE_FINGER"] =         { 11, 12 },
    ["INVTYPE_TRINKET"] =        { 13, 14 },
    ["INVTYPE_CLOAK"] =          { 15 },
    ["INVTYPE_WEAPON"] =         { 16, 17 },
    ["INVTYPE_SHIELD"] =         { 17 },
    ["INVTYPE_2HWEAPON"] =       { 16 },
    ["INVTYPE_WEAPONMAINHAND"] = { 16 },
    ["INVTYPE_WEAPONOFFHAND"] =  { 17 },
    ["INVTYPE_HOLDABLE"] =       { 17 },
    ["INVTYPE_RANGED"] =         { 18 },
    ["INVTYPE_THROWN"] =         { 18 },
    ["INVTYPE_RANGEDRIGHT"] =    { 18 },
    ["INVTYPE_RELIC"] =          { 18 },
    ["INVTYPE_TABARD"] =         { 19 },
    ["INVTYPE_BAG"] =            { 20, 21, 22, 23 },
    ["INVTYPE_QUIVER"] =         { 20, 21, 22, 23 }
};


local get_stat_api_key = {
    dps = "dps",
    attackpower = "attack power",
    critrating = "critical hit rating",
    hitrating = "hit rating",
    stamina = "stamina",
    strength = "strength",
    agility = "agility",
    spellhit = "spell hit rating",
    spellcrit = "spell critical hit rating",
    spellhealing = "healing",
    spelldamage = "spell damage",
    intellect = "intellect",
    expertiserating = "expertise rating"
}


function AAI_StrengthToAttackPower(ability_score)
    local _, player_class = UnitClass("player")
    local mod_dict = {
        druid = 2,
        hunter = 1,
        mage = 1,
        paladin = 2,
        priest = 1,
        rogue = 1,
        shaman = 2,
        warlock = 1,
        warrior = 2
    }
    local mod = mod_dict[string.lower(player_class)]

    return ability_score * mod * (1 + 0.02 * AAI_GetDivineStrengthRank())
end


function AAI_AgilityToCritChance(ability_score)
    local _, player_class = UnitClass("player")
    local mod_dict = {
        druid = 1/24,
        hunter = 1/40,
        mage = 0,
        paladin = 1/24,
        priest = 0,
        rogue = 1/40,
        shaman = 1/24,
        warlock = 0,
        warrior = 1/33
    }
    local mod = mod_dict[string.lower(player_class)]

    return ability_score * mod
end


function AAI_IntellectToSpellCritChance(ability_score)
    local _, player_class = UnitClass("player")
    local mod_dict = {
        druid = 1/79.4,
        hunter = 0,
        mage = 1/81,
        paladin = 1/75.8,
        priest = 1/80,
        rogue = 0,
        shaman = 1/78.1,
        warlock = 1/81.9,
        warrior = 0
    }
    local mod = mod_dict[string.lower(player_class)]

    return ability_score * mod
end


function AAI_ExpertiseRatingPerExpertise(rating)
    local level = UnitLevel("player")
    local scalars = {
        {0,  1 / 0.2        * 1.39466},
        {10, 1 / 0.7        * 1.39466},
        {15, 1 / 1.88476    * 1.39466},
        {20, 1 / 3.230272   * 1.39466},
        {30, 1 / 5.922166   * 1.39466},
        {40, 1 / 8.610086   * 1.39466},
        {50, 1 / 11.308562  * 1.39466},
        {60, 1 / 14.0       * 1.39466},
        {70, 1 / 22.1       * 1.39466},
    }
    return AAI_Interpolate(scalars, level) * rating
end


function AAI_HitRatingToHitChance(rating)
    local level = UnitLevel("player")
    local scalars = {
        {0,  1 / 0.2        * 1.40626341},
        {10, 1 / 0.7        * 1.40626341},
        {15, 1 / 1.88476    * 1.40626341},
        {20, 1 / 3.230272   * 1.40626341},
        {30, 1 / 5.922166   * 1.40626341},
        {40, 1 / 8.610086   * 1.40626341},
        {50, 1 / 11.308562  * 1.40626341},
        {60, 1 / 14.0       * 1.40626341},
        {70, 1 / 22.1       * 1.40626341},
    }
    return AAI_Interpolate(scalars, level) * rating
end


function AAI_CritRatingToCritChance(rating)
    local level = UnitLevel("player")
    local scalars = {
        {1,  1 / 0.2},
        {10, 1 / 0.7},
        {15, 1 / 1.88476},
        {20, 1 / 3.230272},
        {30, 1 / 5.922166},
        {40, 1 / 8.610086},
        {50, 1 / 11.308562},
        {60, 1 / 14.0},
        {70, 1 / 22.1},
    }
    return AAI_Interpolate(scalars, level) * rating
end


function AAI_DpsToAttackPower(dps)
    return dps * 14
end


function AAI_GetItemTotalAttackPowerWithDps(item_link)
    return AAI_GetItemTotalAttackPower(item_link, true)
end


function AAI_GetItemTotalAttackPower(item_link, include_dps)
    return AAI_StrengthToAttackPower(AAI_GetItemStat(item_link, "strength")) + AAI_GetItemStat(item_link, "attackpower") + (include_dps and AAI_DpsToAttackPower(AAI_GetItemStat(item_link, "dps")) or 0)
end


function AAI_GetItemTotalCritChance(item_link)
    return (AAI_AgilityToCritChance(AAI_GetItemStat(item_link, "agility")) + AAI_CritRatingToCritChance(AAI_GetItemStat(item_link, "critrating"))) / 100
end


function AAI_GetItemTotalExpertise(item_link)
    return (AAI_ExpertiseRatingPerExpertise(AAI_GetItemStat(item_link, "expertiserating"))) / 100
end


function AAI_GetItemTotalHitChance(item_link)
    return (AAI_HitRatingToHitChance(AAI_GetItemStat(item_link, "hitrating"))) / 100
end


function AAI_GetItemTotalSpellDamageAndHealing(item_link)
    return AAI_GetItemStat(item_link, "spelldamageandhealing") + AAI_GetItemStat(item_link, "intellect") * AAI_HolyGuidanceRank() * 0.07
end


function AAI_GetItemTotalSpellHealing(item_link)
    return AAI_GetItemStat(item_link, "spellhealing") + AAI_GetItemTotalSpellDamageAndHealing(item_link)
end


function AAI_GetItemTotalSpellDamage(item_link)
    return AAI_GetItemStat(item_link, "spelldamage") + AAI_GetItemTotalSpellDamageAndHealing(item_link)
end


function AAI_GetItemTotalSpellCritChance(item_link)
    return (AAI_CritRatingToCritChance(AAI_GetItemStat(item_link, "spellcrit")) + AAI_IntellectToSpellCritChance(AAI_GetItemStat(item_link, "intellect"))) / 100
end


function AAI_DisplayStatKeys(item_link)
    local stat_table = AAI_GetItemStats(item_link)
    for key, val in pairs(stat_table) do
        print(key)
    end
end


function AAI_GetCompetingItemFromInventory(item_link, tag)
    local item_slots = AAI_GetItemSlots(item_link)
    for bag, slot, link in AAI_InventoryIterator("inventory") do
        if AAI_HasTag(link, tag) and AAI_GetItemSlots(link)[1] == item_slots[1] then
            return link
        end
    end
    local competing_item_link = AAI_GetCompetingItemEquipped(item_link)
    return AAI_HasTag(competing_item_link, tag) and competing_item_link or nil
end


function AAI_GetItemSlots(item_link)
    local slot = item_link and select(9, GetItemInfo(item_link)) or nil
    return item_slot_table[slot]
end


function AAI_GetCompetingItemEquipped(item_link)
    local slot = AAI_GetItemSlots(item_link)
    if slot ~= nil then
        slot = slot[1]
    end
    if slot ~= nil then
        return GetInventoryItemLink("player", slot) or nil
    else
        return nil
    end
end


function AAI_GetItemStat(item_link, stat)
    local stat_table = AAI_GetItemStats(item_link)
    local value = stat_table and stat_table[get_stat_api_key[stat]] or 0
    if AAI_HasValue({"strength", "stamina", "agility", "intellect", "spirit"}, stat) then
        -- value = value * 1.1
    end
    return value
end


local aai_cached_item = nil
local aai_cached_dict = nil

function AAI_GetItemStats(item_link)
    if aai_cached_item ~= item_link then
        aai_cached_dict = AAI_GetItemStatsByScanning(item_link)
        aai_cached_item = item_link
    end
    return aai_cached_dict 
end


function AAI_GetItemSpec(item_link)
    if AAI_GetItemTotalAttackPower(item_link) > 0 then
        return "melee"
    elseif AAI_GetItemTotalSpellHealing(item_link) > 0 then
        return "heal"
    elseif AAI_GetItemTotalSpellDamage(item_link) >= max(0, AAI_GetItemTotalSpellHealing(item_link)) then
        return "spell"
    else
        return "tank"
    end
end


-- local get_stat_api_key = {
--     dps = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT",
--     attackpower = "ITEM_MOD_ATTACK_POWER_SHORT",
--     critrating = "ITEM_MOD_CRIT_RATING",
--     hitrating = "ITEM_MOD_HIT_RATING",
--     stamina = "ITEM_MOD_STAMINA_SHORT",
--     strength = "ITEM_MOD_STRENGTH_SHORT",
--     agility = "ITEM_MOD_AGILITY_SHORT",
--     spelldamageandhealing = "ITEM_MOD_SPELL_POWER_SHORT",
--     spellhit = "ITEM_MOD_SPELL_HIT_RATING",
--     spellcrit = "ITEM_MOD_SPELL_CRIT_RATING",
--     spellhealing = "ITEM_MOD_SPELL_HEALING_DONE_SHORT",
--     spelldamage = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT",
--     intellect = "ITEM_MOD_INTELLECT_SHORT",
-- }

