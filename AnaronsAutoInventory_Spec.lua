function AAI_GetItemMeleePowerDelta(item_link, competing_item_link)
    if competing_item_link == nil then return 0 end

    local a, b, _ = UnitAttackPower("player") -- unbuffed
    local unequipped_base = a + b - AAI_GetItemTotalAttackPowerWithDps(AAI_GetCompetingItemEquipped(item_link))
    return AAI_GetEquivalentMeleePower(unequipped_base, item_link) - AAI_GetEquivalentMeleePower(unequipped_base, competing_item_link)
end


function AAI_GetItemHealingPowerDelta(item_link, competing_item_link)
    if competing_item_link == nil then return 0 end

    unequipped_base = 538*2.5/1.5 + GetSpellBonusHealing() - AAI_GetItemTotalSpellHealing(AAI_GetCompetingItemEquipped(item_link))
    return AAI_GetEquivalentHealingPower(unequipped_base, item_link) - AAI_GetEquivalentHealingPower(unequipped_base, competing_item_link)
end


function AAI_GetEquivalentHealingPower(unequipped_base, item_link)
    return (
        unequipped_base + AAI_GetItemTotalSpellHealing(item_link)
    ) * (
        1 + AAI_GetItemTotalSpellCritChance(item_link) * 0.5
    ) / (
        1 - AAI_GetItemTotalSpellCritChance(item_link) * 0.2 * AAI_GetIlluminationRank()
    )
end


function AAI_GetEquivalentMeleePower(unequipped_base, item_link)
    return (
        unequipped_base  + AAI_GetItemTotalAttackPowerWithDps(item_link)
    ) * (
        1 + AAI_GetItemTotalCritChance(item_link)
    ) / (
        1 - AAI_GetItemTotalHitChance(item_link)
    ) + (unequipped_base + AAI_GetItemTotalAttackPower(item_link)) * AAI_GetDeepWoundsRank()
end


AAI_GetIlluminationRank      = function() return AAI_GetTalentRankForClass("paladin", 1, 9) end
AAI_GetDivineStrengthRank    = function() return AAI_GetTalentRankForClass("paladin", 1, 1) end
AAI_GetDeepWoundsRank        = function() return AAI_GetTalentRankForClass("warrior", 1, 9) end


function AAI_GetTalentRankForClass(class, spec, talent)
    local _, player_class = UnitClass("player")
    player_class = string.lower(player_class)
    if string.lower(class) == player_class then
        _, _, _, _, rank = GetTalentInfo(spec, talent)
        return rank
    end
    return 0
end


