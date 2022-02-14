function AAI_HandleRoll(event, args)
    roll_id = args[1]
    item_link = GetLootRollItemLink(roll_id)
    
    for roll, keyword in ipairs({"pass", "need", "greed"}) do
        if AAI_HasTag(AAI_CleanItemLinkForDatabase(item_link), keyword) then
            if event == "START_LOOT_ROLL" then
                RollOnLoot(roll_id, roll)
                print(string.format("Rolled %s on %s", keyword, item_link))
            elseif event == "CONFIRM_LOOT_ROLL" then
                ConfirmLootRoll(roll_id, roll)
                print(string.format("Confirmed %s on %s", keyword, item_link))
            end
        end
    end
end
