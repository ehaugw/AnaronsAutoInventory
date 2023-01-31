item_links_thunderfury          = "\124cffff8000\124Hitem:19019::::::::70:::::\124h[Thunderfury, Blessed Blade of the Windseeker]\124h\124r"
item_links_arcanite_reaper      = "\124cff0070dd\124Hitem:12784::::::::60:::::\124h[Arcanite Reaper]\124h\124r"


-- run test
local bag, slot, item_link

bag, slot, item_link = 0, 3, item_links_thunderfury
SetItem(bag, slot, MakeItem(item_link, 3, 1, 1))
assert(GetInventoryItemLink(bag, slot) == item_link)
-- inventory[2][2] = MakeItem(item_links_thunderfury, 5, 1, 1)

