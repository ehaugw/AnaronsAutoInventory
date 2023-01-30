print("Start of tags testing")


print_backup = print
print = function(msg)
    print_backup("    " .. msg)
end

AAI_print_backup = AAI_print
AAI_print = function(_) end
AAI_print_original = AAI_print

-- test AddTag
print("Testing AAI_AddTag")
aai_item_tags = {}
AAI_AddTag(item_links_thunderfury, "melee")
assert(aai_item_tags[AAI_CleanItemLinkForDatabase(item_links_thunderfury)]["melee"] == true, "AddTag failed to add a tag")
assert(not aai_item_tags[AAI_CleanItemLinkForDatabase(item_links_thunderfury)]["heal"] == true, "AddTag added a tag that shouldn't be added")

print("Testing /aai tag melee heal " .. item_links_thunderfury)
aai_item_tags = {}
chat_command("tag melee heal " .. item_links_thunderfury, true)
assert(aai_item_tags[AAI_CleanItemLinkForDatabase(item_links_thunderfury)]["melee"] == true, "AddTag failed to add first of two tags")
assert(aai_item_tags[AAI_CleanItemLinkForDatabase(item_links_thunderfury)]["heal"] == true, "AddTag failed to add second of two tags")

print("Testing /aai tag melee " .. item_links_thunderfury .. " and " .. item_links_arcanite_reaper)
chat_command("tag melee " .. item_links_thunderfury .. " " .. item_links_arcanite_reaper, true)
assert(aai_item_tags[AAI_CleanItemLinkForDatabase(item_links_thunderfury)]["melee"] == true, "AddTag failed to add tag to first out of two items")
assert(aai_item_tags[AAI_CleanItemLinkForDatabase(item_links_arcanite_reaper)]["melee"] == true, "AddTag failed to add tag to second out of two items")


-- test HasTag
print("Testing AAI_HasTag")
aai_item_tags = {}
assert(not AAI_HasTag(item_links_thunderfury, "melee"), "HasTag gives false positives")
chat_command("tag melee " .. item_links_thunderfury, true)
assert(AAI_HasTag(item_links_thunderfury, "melee"), "HasTag gives false negatives")
chat_command("tag melee2 " .. item_links_thunderfury, true)
assert(AAI_HasTag(item_links_thunderfury, "melee"), "HasTag failed after adding a second tag")
assert(AAI_HasTag(item_links_thunderfury, "melee2"), "HasTag failed at items with two tags")


-- test HasTags
print("Testing AAI_HasTags")
aai_item_tags = {}
assert(not AAI_HasTags(item_links_thunderfury, {"melee"}), "HasTags gives false positives when requesting one non-existing tag")
assert(not AAI_HasTags(item_links_thunderfury, {"melee", "melee2"}), "HasTags gives false positives when requesting two non-existing tags")
assert(not AAI_HasTags(item_links_thunderfury, {"melee"}, true), "HasTags gives false positives when requesting one non-existing tag when all-match is required")
assert(not AAI_HasTags(item_links_thunderfury, {"melee", "melee2"}, true), "HasTags gives false positives when requesting two tags when only one tag exists on the item and all-match is required")
chat_command("tag melee " .. item_links_thunderfury, true)
assert(AAI_HasTags(item_links_thunderfury, {"melee"}), "HasTags gives false negatives when the item has one tag and the requiested tag contains only that tag")
assert(AAI_HasTags(item_links_thunderfury, {"melee", "melee2"}), "HasTags gives false negatives when the item has one tag and the requiested tag contains only that tag")
assert(not AAI_HasTags(item_links_thunderfury, {"melee", "melee2"}, true), "HasTags gives false positive when the item has one tag but two tags are requested")
chat_command("tag melee2 " .. item_links_thunderfury, true)
assert(AAI_HasTags(item_links_thunderfury, {"melee"}), "HasTags gives false netagive after adding a second tag")
assert(AAI_HasTags(item_links_thunderfury, {"melee2"}), "HasTags gives false negative when attempting to match the second tag added to an item")
assert(AAI_HasTags(item_links_thunderfury, {"melee", "melee"}), "HasTags gives false negative when attempting to match two tags that exist on an item")


-- test HasTagsExact
aai_item_tags = {}
assert(not AAI_HasTagsExact(item_links_thunderfury, {"melee"}), "HasTagsExact gives false positives when requesting one non-existing tag")
assert(not AAI_HasTagsExact(item_links_thunderfury, {"melee", "melee2"}), "HasTagsExact gives false positives when requesting two non-existing tags")
chat_command("tag melee " .. item_links_thunderfury, true)
assert(AAI_HasTagsExact(item_links_thunderfury, {"melee"}), "HasTagsExact gives false negatives when the item has one tag and the requiested tag contains only that tag")
assert(not AAI_HasTagsExact(item_links_thunderfury, {"melee", "melee2"}), "HasTagsExact gives false positive when requesting more than the one existing tag")
chat_command("tag melee2 " .. item_links_thunderfury)
assert(not AAI_HasTagsExact(item_links_thunderfury, {"melee"}), "HasTagsExact gives false positive when requesting one of two existing tags")
assert(AAI_HasTagsExact(item_links_thunderfury, {"melee", "melee"}), "HasTagsExact gives false negative when attempting to match the two tags that exist on an item")


-- test RemoveTag
print("Testing AAI_RemoveTag")
aai_item_tags = {}
chat_command("tag melee heal " .. item_links_thunderfury, true)
AAI_RemoveTag(item_links_thunderfury, "melee")
assert(not AAI_HasTag(item_links_thunderfury, "melee"), "RemoveTag failed to remove a single tag")
assert(AAI_HasTag(item_links_thunderfury, "heal"), "RemoveTag removed tags that were supposed to stay")


-- test RemoveAllTags
print("Testing AAI_RemoveAllTags")
aai_item_tags = {}
chat_command("tag melee heal " .. item_links_thunderfury, true)
AAI_RemoveAllTags(item_links_thunderfury)
assert(not AAI_HasTag(item_links_thunderfury, "melee"), "RemoveAllTags failed to remove an arbitrary tag")


-- test TaggedItemIterator
print("Testing TaggedItemIterator")
aai_item_tags = {}
chat_command("tag melee " .. item_links_thunderfury .. " " .. item_links_arcanite_reaper, true)
local iterator
iterator = AAI_TaggedItemIterator("melee")
assert(select(1,iterator()) == item_links_arcanite_reaper, "TaggedItemIterator did not yield the first expected item")
assert(select(1,iterator()) == item_links_thunderfury, "TaggedItemIterator did not yield the first expected item")
assert(select(1,iterator()) == nil, "TaggedItemIterator did not exhaust as expected")
iterator = AAI_TaggedItemIterator("melee")
assert(AAI_TableCompare(select(2,iterator()), {melee = true}), "TaggedItemIterator did not yield the expected tag with item")



print = print_backup
AAI_print = AAI_print_backup
AAI_print_original = AAI_print
print("End of tags testing\n")
