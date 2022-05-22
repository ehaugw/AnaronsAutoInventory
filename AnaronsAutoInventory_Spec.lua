function AAI_OnAddonLoadedSpec(instance)
    aai_spec_settings = aai_spec_settings or {}
end


local spec_evaluators = {
    melee = function(item_link)
        local competing_item_link = AAI_GetCompetingItemEquipped(item_link)

        -- local a, b, _ = UnitAttackPower("player") -- unbuffed
        -- local power = a + b - AAI_GetItemTotalAttackPower(competing_item_link)
        local low, high = UnitDamage("player")
        local power = (low + high)/2/UnitAttackSpeed("player")*14

        local hit_chance = AAI_GetItemTotalHitChance(item_link)
        local total_crit_chance = GetCritChance() / 100 - AAI_GetItemTotalCritChance(competing_item_link) 
        if IsControlKeyDown() and hit_chance > 0 then
            local total_hit_chance = GetCombatRatingBonus(CR_HIT_MELEE) / 100 - AAI_GetItemTotalHitChance(competing_item_link) 
            hit_chance = max(0, min(AAI_GetHitCap() - total_hit_chance, hit_chance))
        end

        return (
            power  + AAI_GetItemTotalAttackPowerWithDps(item_link)
        ) / (
            1
        ) * (
            1 + (total_crit_chance + AAI_GetItemTotalCritChance(item_link)) * (1 + AAI_GetImpaleRank() * 0.1) * (1 + AAI_GetItemCriticalDamageBonus(item_link))
        ) * (
            1 + AAI_GetItemTotalHaste(item_link) * 0.75
        ) / (
            1 - AAI_GetItemTotalExpertise(item_link)
        ) / (
            1 - hit_chance
        ) + (power + AAI_GetItemTotalAttackPower(item_link)) * AAI_GetDeepWoundsRank()
    end,

    heal = function(item_link)
        local base_power, cast_time = AAI_GetSavedHealPowerAndCastTime()
        local power = base_power + (GetSpellBonusHealing() - AAI_GetItemTotalSpellHealing(AAI_GetCompetingItemEquipped(item_link))) / 3.5 * cast_time

        return (
            power + (AAI_GetItemTotalSpellHealing(item_link)) / 3.5 * cast_time
        ) * (
            1 + AAI_GetItemTotalSpellHaste(item_link)
        ) / (
            cast_time
        ) * (
            1 + AAI_GetItemTotalSpellCritChance(item_link) * 0.5
        ) / (
            1 - AAI_GetItemTotalSpellCritChance(item_link) * 0.2 * AAI_GetIlluminationRank()
        )
    end
}


function AAI_GetSavedHealPowerAndCastTime()
    local saved = aai_stat_settings["defaultheal"]
    if saved then
        return unpack(saved)
    end
    if AAI_IsHealerClass("player") then
        AAI_print("Default healing spell is not configurated! Type /run aai_stat_settings[\"defaultheal\"] = {spell healing, cast time}")
    end
    return 500, 1.5
end


function AAI_IsHealerClass(unit)
    local class = string.lower(UnitClass(unit))
    return class == "paladin" or class == "priest" or class == "druid" or class == "shaman"
end


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


function AAI_GetHitCap()
    local _, player_class = UnitClass("player")
    if string.lower(player_class) == "paladin" then
        return 6 / 100
    else
        return nil
    end
end


function AAI_CalculateYellowDps(option)
    local low, high = UnitDamage("player")
    local period = UnitAttackSpeed("player")
    local dps = (low + high)/2/period

    local hit_chance = AAI_GetItemTotalHitChance(item_link)
    local crit = GetCritChance() / 100 - AAI_GetItemTotalCritChance(competing_item_link) 
    local haste = GetCombatRatingBonus(CR_HASTE_MELEE)

    option = option and AAI_StringToItemLinksAndWords(option)[1]
    print(option)
    if option then
        dps = dps - AAI_GetItemTotalAttackPowerWithDps(AAI_GetCompetingItemEquipped(option)) / 14 + AAI_GetItemTotalAttackPowerWithDps(option) / 14
        hit_chance = hit_chance - AAI_GetItemTotalHitChance(AAI_GetCompetingItemEquipped(option)) + AAI_GetItemTotalHitChance(option)
        crit = crit - AAI_GetItemTotalCritChance(AAI_GetCompetingItemEquipped(option)) + AAI_GetItemTotalCritChance(option)
        haste = haste - AAI_GetItemTotalHaste(AAI_GetCompetingItemEquipped(option)) + AAI_GetItemTotalHaste(option)
        -- period = AAI_GetItemStat(option, "speed")
    end

    local actual_period = period / (1 + haste / 100)
    local effective_judgement_cd = AAI_GetCooldownBetweenSwings(8, actual_period) / period

    local proc_per_minute = 7
    local damage = dps * period * (1 + crit / 100)
    local white = damage / actual_period
    local soc_rate = 1 * period * 7 / 60 * period / actual_period
    local soc = damage * 0.7 * soc_rate / effective_judgement_cd
    local sob = white * 0.35
    local sob_twist = damage * 0.35 * soc_rate / effective_judgement_cd
    local crusader_strike = damage * 1.1 / 6
    local judgement = 346 / effective_judgement_cd * (1 + crit / 100)

    local total = (white + sob + sob_twist + sob + crusader_strike + judgement)

    print(string.format("White DPS: %s (%s)", white, AAI_Round(white / total * 100, 1)))
    print(string.format("SoC DPS: %s (%s)", soc, AAI_Round(soc / total * 100, 1)))
    -- print(string.format("SoB DPS: %s (%s)", sob, AAI_Round(sob / total * 100, 1)))
    -- print(string.format("SoB Twist DPS: %s (%s)", sob_twist, AAI_Round(sob_twist / total * 100, 1)))
    print(string.format("SoB Total DPS: %s (%s)", sob + sob_twist, AAI_Round((sob + sob_twist) / total * 100, 1)))
    print(string.format("Crusader Strike DPS: %s (%s)", crusader_strike, AAI_Round(crusader_strike / total * 100, 1)))
    print(string.format("Judgement DPS: %s (%s)", judgement, AAI_Round(judgement / total * 100, 1)))
    print(string.format("Total DPS: %s", total))
end


function AAI_GetCooldownBetweenSwings(cooldown, period)
    return period * ceil(cooldown / period)
end

