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
        unequipped_base  + AAI_GetItemTotalAttackPower(item_link)
    ) * (
        1 + AAI_GetItemTotalHitChance(item_link) + AAI_GetItemTotalCritChance(item_link)
    )
end


AAI_GetIlluminationRank      = function() return AAI_GetTalentRankForClass("paladin", 1, 9) end
AAI_GetDivineStrengthLevel   = function() return AAI_GetTalentRankForClass("paladin", 1, 1) end


function AAI_GetTalentRankForClass(class, spec, talent)
    local _, player_class = UnitClass("player")
    player_class = string.lower(player_class)
    if string.lower(class) == player_class then
        _, _, _, _, rank = GetTalentInfo(spec, talent)
        return rank
    end
    return 0
end


