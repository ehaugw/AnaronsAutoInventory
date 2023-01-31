local inventory = {}


-- set up mocked environment
RemoveBrackets = function(string)
    return string:gsub("(.*)%[(.*)%](.*)", "%1%2%3")
end


MakeItem = function(item_link, rarity, stack_size, stack_size_max)
    local name = nil
    if item_link ~= nil then
        name = AAI_CleanItemLinkForConsole(item_link)
    end
    return {
        name = name,
        item_link = item_link,
        rarity = rarity,
        stack_size = stack_size,
        stack_size_max = stack_size_max
    }
end


MakeBag = function(size)
    local bag = {}
    for i = 1, size do
        bag[i] = MakeItem(nil, nil, nil, nil)
    end
    return bag
end


SetItem = function(bag, slot, item)
    inventory[bag+1][slot] = item
end


for bag_slot = 1, 2 do
    local bag = MakeBag(4)
    inventory[bag_slot] = bag
end


-- implement mocked functions
GetInventoryItemLink = function(bag, slot)
    return inventory[bag+1][slot].item_link
end


print("Mocked WoW item API")
