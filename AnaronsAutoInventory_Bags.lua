function AAI_OnAddonLoadedBags(instance)
    aai_bag_preferences = aai_bag_preferences or {tags = {}, items = {}}
end


function AAI_OnBankFrameOpened()
    for tag, preferences in pairs(aai_bag_preferences["tags"]) do
        for _, bag in pairs(preferences) do
            AAI_MoveToDesiredBag(
                AAI_InventoryIterator("inventory"),
                AAI_BagIterator(bag, true),
                function(item_link)
                    return AAI_HasTag(item_link, "bank") and AAI_HasTag(item_link, tag)
                end
            )
        end
    end
    -- AAI_UseAllTaggedItems("inventory", "bank", false, false)
    AAI_ResupplyItems()
end


function AAI_MoveToDesiredBag(source_iterator, target_bag_iterator, evaluator)

    local target_bag, target_slot, target_link = target_bag_iterator()

    for bag, slot, item_link in source_iterator do
        if item_link and evaluator(item_link) and AAI_BagCanContainItem(target_bag, item_link) then

            local _, stack_size, stack_size_max = AAI_GetInventoryStackInfo(bag, slot)

            while true do
                if target_bag == nil then return end -- this means the iterator is exhausted

                local can_put_here = target_link == nil or target_link == item_link and select(2, AAI_GetInventoryStackInfo(target_bag, target_slot)) + stack_size <= stack_size_max

                if can_put_here then
                    PickupContainerItem(bag, slot)
                    PickupContainerItem(target_bag, target_slot)
                    target_link = true
                    target_bag, target_slot, target_link = target_bag_iterator()
                    break -- this means we got rid of the item and can move on to the new item in the source iterator
                end
                target_bag, target_slot, target_link = target_bag_iterator()
            end
        end
    end
end
