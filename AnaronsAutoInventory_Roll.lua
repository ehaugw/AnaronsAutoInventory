local roll_types = {"pass", "need", "greed"}


function AAI_HandleRoll(event, args)
    if event == "START_LOOT_ROLL" or event == "PLAYER_ENTERING_WORLD" then
        for _, roll_id in ipairs(GetActiveLootRollIDs()) do
            item_link = GetLootRollItemLink(roll_id)
            -- local _, _, _, quality, bindOnPickUp, canNeed, canGreed, _ = GetLootRollItemInfo(RollID)
            for roll_plus_one, keyword in ipairs(roll_types) do
                if AAI_HasTag(AAI_CleanItemLinkForDatabase(item_link), keyword) then
                    RollOnLoot(roll_id, roll_plus_one - 1)
                    -- print(string.format("Rolled %s on %s", keyword, item_link))
                end
            end
        end
    elseif event == "CONFIRM_LOOT_ROLL" then
        roll_id = args[1]
        roll = args[2]
        item_link = GetLootRollItemLink(roll_id)
        if AAI_HasTag(AAI_CleanItemLinkForDatabase(item_link), roll_types[roll + 1]) then
            ConfirmLootRoll(roll_id, roll)
            -- print(string.format("Confirmed %s on %s", keyword, item_link))
        end
    end
end


AAI_RollOnLoot = RollOnLoot

function RollOnLoot(roll_id, roll, ...)
    item_link = GetLootRollItemLink(roll_id)
    AAI_RollOnLoot(roll_id, roll, ...)
    -- if roll ~= 1 and not AAI_HasTag(item_link, roll_types[roll + 1]) then
    if IsShiftKeyDown() then
        for _, roll_tag in pairs(roll_types) do
            if AAI_HasTag(item_link, roll_tag) then
                AAI_RemoveTag(item_link, roll_tag)
            end
        end
        AAI_AddTag(item_link, roll_types[roll + 1])
    end
    if IsAltKeyDown() then
        AAI_AddTag(item_link, "junk")
    end
    if IsControlKeyDown() then
        AAI_AddTag(item_link, "disenchant")
    end
end
