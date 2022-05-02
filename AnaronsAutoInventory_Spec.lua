local spec_evaluators = {
    melee = function(item_link)
        local competing_item_link = AAI_GetCompetingItemEquipped(item_link)

        local a, b, _ = UnitAttackPower("player") -- unbuffed
        local power = a + b - AAI_GetItemTotalAttackPower(competing_item_link)

        return (
            power  + AAI_GetItemTotalAttackPowerWithDps(item_link)
        ) * (
            1 + AAI_GetItemTotalCritChance(item_link) * (1 + AAI_GetImpaleRank() * 0.1)
        ) * (
            1 + AAI_GetItemTotalHaste(item_link) * 0.75
        ) / (
            1 - AAI_GetItemTotalExpertise(item_link)
        ) / (
            1 - AAI_GetItemTotalHitChance(item_link)
        ) + (power + AAI_GetItemTotalAttackPower(item_link)) * AAI_GetDeepWoundsRank()
    end,

    heal = function(item_link)
        local power = 538*2.5/1.5 + GetSpellBonusHealing() - AAI_GetItemTotalSpellHealing(AAI_GetCompetingItemEquipped(item_link))

        return (
            power + AAI_GetItemTotalSpellHealing(item_link)
        ) * (
            1 + AAI_GetItemTotalSpellCritChance(item_link) * 0.5
        ) / (
            1 - AAI_GetItemTotalSpellCritChance(item_link) * 0.2 * AAI_GetIlluminationRank()
        )
    end
}


function AAI_GetItemScoreComparison(item_link, competing_item_link, spec_name)
    local this_score = spec_evaluators[spec_name](item_link)
    local competing_score = spec_evaluators[spec_name](competing_item_link)
    return this_score - competing_score, this_score, competing_score
end


-- fury spec "flurry" not included"
AAI_GetIlluminationRank     = function() return AAI_GetTalentRankForClass("paladin", 1, 9)  end
AAI_GetDivineStrengthRank   = function() return AAI_GetTalentRankForClass("paladin", 1, 1)  end
AAI_GetDeepWoundsRank       = function() return AAI_GetTalentRankForClass("warrior", 1, 9)  end
AAI_GetImpaleRank           = function() return AAI_GetTalentRankForClass("warrior", 1, 11) end
AAI_HolyGuidanceRank        = function() return AAI_GetTalentRankForClass("warrior", 1, 19) end


function AAI_GetTalentRankForClass(class, spec, talent)
    local _, player_class = UnitClass("player")
    player_class = string.lower(player_class)
    if string.lower(class) == player_class then
        _, _, _, _, rank = GetTalentInfo(spec, talent)
        return rank
    end
    return 0
end


