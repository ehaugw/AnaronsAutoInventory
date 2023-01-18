GetContainerItemCooldown = C_Container.GetContainerItemCooldown
UseContainerItem = C_Container.UseContainerItem
GetContainerNumSlots = C_Container.GetContainerNumSlots
GetContainerItemLink = C_Container.GetContainerItemLink
PickupContainerItem  = C_Container.PickupContainerItem

function GetContainerItemInfo(...)
    r = C_Container.GetContainerItemInfo(...)
    if not r then return end
    return r.iconFileID, r.stackCount, r.isLocked, r.quality, r.isReadable, r.hasLoot, r.hyperlink, r.isFiltered, r.hasNoValue, r.itemID, r.isBound
end

