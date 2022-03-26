local roll_types = {"pass", "need", "greed"}


function AAI_HandleRoll(event, args)
    if event == "START_LOOT_ROLL" or event == "PLAYER_ENTERING_WORLD" then
        for _, roll_id in ipairs(GetActiveLootRollIDs()) do
            item_link = GetLootRollItemLink(roll_id)
            -- local _, _, _, quality, bindOnPickUp, canNeed, canGreed, _ = GetLootRollItemInfo(RollID)
            for roll, keyword in ipairs(roll_types) do
                if AAI_HasTag(AAI_CleanItemLinkForDatabase(item_link), keyword) then
                    if event == "START_LOOT_ROLL" or event == "PLAYER_ENTERING_WORLD" then
                        RollOnLoot(roll_id, roll)
                        print(string.format("Rolled %s on %s", keyword, item_link))
                    end
                end
            end
        end
    elseif event == "CONFIRM_LOOT_ROLL" then
        roll_id = args[1]
        roll = args[2]
        item_link = GetLootRollItemLink(roll_id)
        if AAI_HasTag(AAI_CleanItemLinkForDatabase(item_link), roll_types[roll]) then
            if event == "START_LOOT_ROLL" or event == "PLAYER_ENTERING_WORLD" then
                ConfirmLootRoll(roll_id, roll)
                print(string.format("Confirmed %s on %s", keyword, item_link))
            end
        end
    end
end


AAI_ConfirmLootRoll = ConfirmLootRoll


function ConfirmLootRoll(roll_id, roll, ...)
    AAI_ConfirmLootRoll(roll_id, roll, ...)
    item_link = GetLootRollItemLink(roll_id)
    if roll ~= 2 and not AAI_HasTag(item_link, roll_types[roll]) then
        AAI_AddTag(item_link, roll_types[roll])
    end
end
