function AAI_OnAddonLoadedSpec(_)
    aai_spec_settings = aai_spec_settings or {}
end


function AAI_GetCharacterCritChance()
    return (GetCritChance() + AAI_GetHeartOfTheCrusaderRank() + AAI_GetConvictionRank() + AAI_GetSanctityOfBattleRank()) / 100
end


function AAI_GetCharacterSpellCritChance(school)
    return (GetSpellCritChance(school)) / 100
end


function AAI_GetCharacterHaste()
    return AAI_GetSwiftRetributionRank() / 100
end

local white_dps_relative = 0.5
local instant_cast_reltive = 0.5
local speed_scaling = instant_cast_reltive

local spec_evaluators = {
    melee = function(item_link)
        local competing_item_link = AAI_GetCompetingItemEquipped(item_link)

        local low, high = UnitDamage("player")
        local power = (low + high)/2/UnitAttackSpeed("player")*14

        local hit_chance = AAI_GetItemTotalHitChance(item_link)
        local total_crit_chance = AAI_GetCharacterCritChance() - AAI_GetItemTotalCritChance(competing_item_link)

        if IsControlKeyDown() and hit_chance > 0 then
            local total_hit_chance = GetCombatRatingBonus(CR_HIT_MELEE) / 100 - AAI_GetItemTotalHitChance(competing_item_link)
            hit_chance = max(0, min(AAI_GetHitCap() - total_hit_chance, hit_chance))
        end

        return (
            power  + AAI_GetItemTotalAttackPowerWithDps(item_link)
        ) / (
            1
        ) * (
            1 + (total_crit_chance + AAI_GetItemTotalCritChance(item_link)) * (1 + AAI_GetRighteousVengeanceRank() * 0.1 * speed_scaling) * (1 + AAI_GetImpaleRank() * 0.05) * (1 + AAI_GetItemCriticalDamageBonus(item_link))
        ) * (
            1 + (AAI_GetCharacterHaste() + AAI_GetItemTotalHaste(item_link) + AAI_GetJudgementOfThePureRank()  * 0.03) * white_dps_relative
        ) / (
            1 - AAI_GetItemTotalExpertise(item_link)
        ) * (
            (AAI_GetItemSpeed(item_link) > 0 and (
                AAI_GetItemSpeed(item_link) / AAI_GetItemSpeed(competing_item_link) * speed_scaling
                +
                1 * (1 - speed_scaling))
            ) or 1
        ) / (
            1 - hit_chance
        ) + (power + AAI_GetItemTotalAttackPower(item_link)) * AAI_GetDeepWoundsRank() * 0.16
    end,

    heal = function(item_link)
        local competing_item_link = AAI_GetCompetingItemEquipped(item_link)

        local school = AAI_GetHealerSchool("player")
        local total_crit_chance = AAI_GetCharacterSpellCritChance(school) - AAI_GetItemTotalSpellCritChance(competing_item_link)
        local total_crit_chance_with_this = total_crit_chance + AAI_GetItemTotalSpellCritChance(item_link) + AAI_GetSanctifiedLightRank() * 0.02 + AAI_GetHolyPowerRank() * 0.01 + AAI_GetHolySpecializationRank() * 0.01 + AAI_GetFocusedWillRank() * 0.01

        local base_power, cast_time = AAI_GetSavedHealPowerAndCastTime()
        local power = base_power + (GetSpellBonusHealing() - AAI_GetItemTotalSpellHealing(AAI_GetCompetingItemEquipped(item_link))) / 3.5 * cast_time

        return (
            power + (AAI_GetItemTotalSpellHealing(item_link)) / 3.5 * cast_time
        ) * (
            1 + (AAI_GetCharacterHaste() + AAI_GetItemTotalHaste(item_link) + AAI_GetJudgementOfThePureRank()  * 0.03)
        ) / (
            cast_time
        ) * (
            1 + total_crit_chance_with_this * 0.5
        ) * (
            1 + total_crit_chance_with_this * (1/(1 - AAI_GetIlluminationRank() * 0.06))
        ) * (
            14 -- to map healing / second to healing power
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


function AAI_GetHealerSchool(unit)
    local class = string.lower(UnitClass(unit))
    if class == "paladin" or class == "priest" then
        return 2 -- holy
    elseif class == "shaman" or class == "druid" then
        return 4 -- nature
    end
    return -1
end


function AAI_GetItemScoreComparison(item_link, competing_item_link, spec_name)
    local this_score = spec_evaluators[spec_name](item_link)
    local competing_score = spec_evaluators[spec_name](competing_item_link)
    return this_score - competing_score, this_score, competing_score
end


AAI_GetJudgementOfThePureRank   = function() return AAI_GetTalentRankForClass("paladin", 1, 21)  end
AAI_GetHolyGuidanceRank         = function() return AAI_GetTalentRankForClass("paladin", 1, 19)  end
AAI_GetSanctifiedLightRank      = function() return AAI_GetTalentRankForClass("paladin", 1, 14)  end
AAI_GetHolyPowerRank            = function() return AAI_GetTalentRankForClass("paladin", 1, 16)  end
AAI_GetDivineStrengthRank       = function() return AAI_GetTalentRankForClass("paladin", 2, 2)  end
AAI_GetDivineIntellectRank      = function() return AAI_GetTalentRankForClass("paladin", 1, 1)  end
AAI_GetIlluminationRank         = function() return AAI_GetTalentRankForClass("paladin", 1, 7)  end
AAI_GetHeartOfTheCrusaderRank   = function() return AAI_GetTalentRankForClass("paladin", 2, 4)  end
AAI_GetConvictionRank           = function() return AAI_GetTalentRankForClass("paladin", 2, 7)  end
AAI_GetSanctityOfBattleRank     = function() return AAI_GetTalentRankForClass("paladin", 2, 11)  end
AAI_GetSwiftRetributionRank     = function() return AAI_GetTalentRankForClass("paladin", 2, 22)  end
AAI_GetRighteousVengeanceRank   = function() return AAI_GetTalentRankForClass("paladin", 2, 25)  end

AAI_GetDeepWoundsRank           = function() return AAI_GetTalentRankForClass("warrior", 1, 10)  end
AAI_GetImpaleRank               = function() return AAI_GetTalentRankForClass("warrior", 1, 9) end -- assumed only 50% efficiency due to being skills only

AAI_GetHolySpecializationRank   = function() return AAI_GetTalentRankForClass("priest", 2, 3)  end
AAI_GetMentalStrengthRank       = function() return AAI_GetTalentRankForClass("priest", 2, 14)  end
AAI_GetEnlightenmenthRank       = function() return AAI_GetTalentRankForClass("priest", 2, 17)  end
AAI_GetFocusedWillRank          = function() return AAI_GetTalentRankForClass("priest", 2, 18)  end
AAI_GetDivineAegisRank          = function() return AAI_GetTalentRankForClass("priest", 2, 24)  end
AAI_GetBorrowedTimeRank         = function() return AAI_GetTalentRankForClass("priest", 2, 27)  end


function AAI_GetTalentRankForClass(class, spec, talent)
    local _, player_class = UnitClass("player")
    player_class = string.lower(player_class)
    if string.lower(class) == player_class then
        return select(5, GetTalentInfo(spec, talent))
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
    local hit_chance = GetCombatRatingBonus(CR_HIT_MELEE) / 100
    local crit = GetCritChance() / 100
    local haste = GetCombatRatingBonus(CR_HASTE_MELEE) / 100

    local low, high = UnitDamage("player")
    local period = UnitAttackSpeed("player")
    local dps = (low + high)/2/period / (1 + haste)

    option = option and AAI_StringToItemLinksAndWords(option)[1]
    if option then
        dps = dps - AAI_GetItemTotalAttackPowerWithDps(AAI_GetCompetingItemEquipped(option)) / 14 + AAI_GetItemTotalAttackPowerWithDps(option) / 14
        hit_chance = hit_chance - AAI_GetItemTotalHitChance(AAI_GetCompetingItemEquipped(option)) + AAI_GetItemTotalHitChance(option)
        crit = crit - AAI_GetItemTotalCritChance(AAI_GetCompetingItemEquipped(option)) + AAI_GetItemTotalCritChance(option)
        haste = haste - AAI_GetItemTotalHaste(AAI_GetCompetingItemEquipped(option)) + AAI_GetItemTotalHaste(option)
        -- period = AAI_GetItemStat(option, "speed")
    end

    local actual_period = period / (1 + haste)
    local effective_judgement_cd = AAI_GetCooldownBetweenSwings(8, actual_period) / period

    -- local proc_per_minute = 7
    local damage = dps * period * (1 + crit)
    local white = damage / actual_period
    local soc_rate = 1 * period * 7 / 60 * period / actual_period
    local soc = damage * 0.7 * soc_rate / effective_judgement_cd
    local sob = white * 0.35
    local sob_twist = damage * 0.35 * soc_rate / effective_judgement_cd
    local crusader_strike = damage * 1.1 / 6
    local judgement = 346 / effective_judgement_cd * (1 + crit)

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

