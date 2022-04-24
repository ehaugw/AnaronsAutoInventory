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


local agi_to_crit_chance = 0.05
local hit_rating_to_hit_chance = 0.081666667
local crit_rating_to_crit_chance = 0.0581818181
local dps_to_attack_power = 14
local int_to_spell_crit_chance = 0.04842

local get_stat_api_key = {
    dps = "dps",
    attackpower = "attack power",
    critrating = "crit rating",
    hitrating = "hit rating",
    stamina = "stamina",
    strength = "strength",
    agility = "agility",
    spellhit = "spell hit rating",
    spellcrit = "spell critical hit rating",
    spellhealing = "healing",
    spelldamage = "damage spells",
    intellect = "intellect",
}
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


function AAI_StrengthToAttackPower(strength)
    local mod = 1
    local _, player_class = UnitClass("player")
    player_class = string.lower(player_class)
    if player_class == "paladin" or player_class == "warrior" then
         mod = 2
    end
    return strength * mod * (1 + 0.02 * AAI_GetDivineStrengthLevel())
end


function AAI_AgilityToCritChance(agility)
    return agility * agi_to_crit_chance
end


function AAI_HitRatingToHitChance(hitrating)
    return hitrating * hit_rating_to_hit_chance
end


function AAI_CritRatingToCritChance(critrating)
    return critrating * crit_rating_to_crit_chance
end


function AAI_DpsToAttackPower(dps)
    return dps * dps_to_attack_power
end


function AAI_IntellectToSpellCritChance(intellect)
    return intellect * int_to_spell_crit_chance
end


function AAI_GetItemTotalAttackPower(item_link)
    return AAI_StrengthToAttackPower(AAI_GetItemStat(item_link, "strength")) + AAI_GetItemStat(item_link, "attackpower") + AAI_DpsToAttackPower(AAI_GetItemStat(item_link, "dps"))
end


function AAI_GetItemTotalCritChance(item_link)
    return (AAI_AgilityToCritChance(AAI_GetItemStat(item_link, "agility")) + AAI_CritRatingToCritChance(AAI_GetItemStat(item_link, "critrating"))) / 100
end


function AAI_GetItemTotalHitChance(item_link)
    return (AAI_HitRatingToHitChance(AAI_GetItemStat(item_link, "hitrating"))) / 100
end


function AAI_GetItemTotalSpellDamageAndHealing(item_link)
    return AAI_GetItemStat(item_link, "spelldamageandhealing")
end


function AAI_GetItemTotalSpellHealing(item_link)
    return AAI_GetItemStat(item_link, "spellhealing") + AAI_GetItemTotalSpellDamageAndHealing(item_link)
end


function AAI_GetItemTotalSpellDamage(item_link)
    return AAI_GetItemStat(item_link, "spelldamage") + AAI_GetItemTotalSpellDamageAndHealing(item_link)
end


function AAI_GetItemTotalSpellCritChance(item_link)
    return (AAI_GetItemStat(item_link, "spellcrit") + AAI_IntellectToSpellCritChance(AAI_GetItemStat(item_link, "intellect"))) / 100
end


function AAI_DisplayStatKeys(item_link)
    local stat_table = AAI_GetItemStats(item_link)
    for key, val in pairs(stat_table) do
        print(key)
    end
end


function AAI_GetCompetingItemFromInventory(item_link, tag)
    local competing_item_link = AAI_GetCompetingItem(item_link)
    for bag, slot, link in AAI_GetInventoryBagIndexLinkTuples("inventory") do
        if AAI_HasTag(link, tag) and AAI_GetCompetingItem(link) == competing_item_link then
            return link
        end
    end
    return nil
end


function AAI_GetCompetingItem(item_link)
    local slot = select(9, GetItemInfo(item_link)) or nil
    slot = item_slot_table[slot]
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
    return stat_table and stat_table[get_stat_api_key[stat]] or 0
end


-- function AAI_GetItemDamageScore(item_link)
--     local competing_item_link = AAI_GetCompetingItem(item_link)
--     local attackpower = UnitAttackPower("player") -- unbuffed
-- 
--     local attackpower_diff = AAI_GetItemTotalAttackPower(item_link) - AAI_GetItemTotalAttackPower(competing_item_link)
--     local crit_diff = AAI_GetItemTotalCritChance(item_link)         - AAI_GetItemTotalCritChance(competing_item_link)
--     local hit_diff = AAI_GetItemTotalHitChance(item_link)         - AAI_GetItemTotalHitChance(competing_item_link)
-- 
--     crithit = crit_diff + hit_diff
-- 
--     return AAI_GetItemTotalAttackPower(item_link) + attackpower * crithit
--     -- attackpower + attackpower_diff) * 
-- end


function AAI_GetItemMeleePowerDelta(item_link)
    a, b, _ = UnitAttackPower("player") -- unbuffed
    local unbuffed_attackpower = a + b
    local competing_item_link = AAI_GetCompetingItem(item_link)

    if competing_item_link == nil then
        return 0
    end

    local power = (
        unbuffed_attackpower - AAI_GetItemTotalAttackPower(competing_item_link) + AAI_GetItemTotalAttackPower(item_link)
    ) * (
        1 + AAI_GetItemTotalHitChance(item_link) + AAI_GetItemTotalCritChance(item_link)
    )
    local competing_power = (
        unbuffed_attackpower
    ) * (
        1 + AAI_GetItemTotalHitChance(competing_item_link) + AAI_GetItemTotalCritChance(competing_item_link)
    )
    return power - competing_power
end


function AAI_GetItemHealingPowerDelta(item_link)
    -- local healing_power = 2100 -- Holy Light Rank 10
    local healing_power = 538*2.5/1.5 -- Holy Light Rank 10
    local competing_item_link = AAI_GetCompetingItem(item_link)

    if competing_item_link == nil then
        return 0
    end

    local power = (
        healing_power - AAI_GetItemTotalSpellHealing(competing_item_link) + AAI_GetItemTotalSpellHealing(item_link)
    ) * (
        1 + AAI_GetItemTotalSpellCritChance(item_link) * 0.5
    ) / (
        1 - AAI_GetItemTotalSpellCritChance(item_link) * 0.2 * AAI_GetIlluminationRank()
    )
    local competing_power = (
        healing_power
    ) * (
        1 + AAI_GetItemTotalSpellCritChance(competing_item_link) * 0.5
    ) / (
        1 - AAI_GetItemTotalSpellCritChance(competing_item_link) * 0.2 * AAI_GetIlluminationRank()
    )
    return power - competing_power
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


function AAI_GetIlluminationRank()
    return 5
    -- return AAI_GetTalentRankForClass("paladin", 1, 9)
end


function AAI_GetDivineStrengthLevel()
    return 5
    -- return AAI_GetTalentRankForClass("paladin", 1, 1)
end


function AAI_GetTalentRankForClass(class, spec, talent)
    local _, player_class = UnitClass("player")
    player_class = string.lower(player_class)
    if string.lower(class) == player_class then
        _, _, _, _, rank = GetTalentInfo(spec, talent)
        return rank
    end
    return 0
end


