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


local str_to_attack_power = 2 * 1.1
local agi_to_crit_chance = 0.05
local hit_rating_to_hit_chance = 0.081666667
local crit_rating_to_crit_chance = 0.0581818181
local dps_to_attack_power = 14

local get_stat_api_key = {
    dps = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT",
    attackpower = "ITEM_MOD_ATTACK_POWER_SHORT",
    critrating = "ITEM_MOD_CRIT_RATING",
    hitrating = "ITEM_MOD_HIT_RATING",
    stamina = "ITEM_MOD_STAMINA_SHORT",
    strength = "ITEM_MOD_STRENGTH_SHORT",
    agility = "ITEM_MOD_AGILITY_SHORT",
}


function AAI_StrengthToAttackPower(strength)
    return strength * str_to_attack_power
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


function AAI_GetItemTotalAttackPower(item_link)
    return AAI_StrengthToAttackPower(AAI_GetItemStat(item_link, "strength")) + AAI_GetItemStat(item_link, "attackpower") + AAI_DpsToAttackPower(AAI_GetItemStat(item_link, "dps"))
end


function AAI_GetItemTotalCritChance(item_link)
    return (AAI_AgilityToCritChance(AAI_GetItemStat(item_link, "agility")) + AAI_CritRatingToCritChance(AAI_GetItemStat(item_link, "critrating"))) / 100
end


function AAI_GetItemTotalHitChance(item_link)
    return (AAI_HitRatingToHitChance(AAI_GetItemStat(item_link, "hitrating"))) / 100
end


function AAI_DisplayStatKeys(item_link)
    local stat_table = GetItemStats(item_link)
    for key, val in pairs(stat_table) do
        print(key)
        -- print(string.format("%s: %s", key, value))
    end
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
    -- AAI_DisplayStatKeys(item_link)
    local stat_table = GetItemStats(item_link)
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


function AAI_GetItemPowerDelta(item_link)
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
    -- print(string.format("competing: %s, new: %s", competing_power, power))
    return power - competing_power
end

