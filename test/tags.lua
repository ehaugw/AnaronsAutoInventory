-- SETUP DEFAULT DICTS
aai_item_tags = {}
aai_item_tags_global = {}
aai_tag_colors = {}


-- Test HasTag
aai_item_tags = {}
assert(not AAI_HasTag(item_links_thunderfury, "melee"), "HasTag gives false positives")
chat_command("tag melee " .. item_links_thunderfury, true)
assert(AAI_HasTag(item_links_thunderfury, "melee"), "HasTag gives false negatives")
chat_command("tag melee2 " .. item_links_thunderfury, true)
assert(AAI_HasTag(item_links_thunderfury, "melee"), "HasTag failed after adding a second tag")
assert(AAI_HasTag(item_links_thunderfury, "melee2"), "HasTag failed at items with two tags")


-- Test HasTags
aai_item_tags = {}
assert(not AAI_HasTags(item_links_thunderfury, {"melee"}), "HasTags gives false positives when requesting one non-existing tag")
assert(not AAI_HasTags(item_links_thunderfury, {"melee", "melee2"}), "HasTags gives false positives when requesting two non-existing tags")
assert(not AAI_HasTags(item_links_thunderfury, {"melee"}, true), "HasTags gives false positives when requesting one non-existing tag when exact match is required")
assert(not AAI_HasTags(item_links_thunderfury, {"melee", "melee2"}, true), "HasTags gives false positives when requesting two tags when only one tag exists on the item and exact match is required")
chat_command("tag melee " .. item_links_thunderfury, true)
assert(AAI_HasTags(item_links_thunderfury, {"melee"}), "HasTags gives false negatives when the item has one tag and the requiested tag contains only that tag")
assert(AAI_HasTags(item_links_thunderfury, {"melee", "melee2"}), "HasTags gives false negatives when the item has one tag and the requiested tag contains only that tag")
assert(not AAI_HasTags(item_links_thunderfury, {"melee", "melee2"}, true), "HasTags gives false positive when the item has one tag but two tags are requested")
chat_command("tag melee2 " .. item_links_thunderfury, true)
assert(AAI_HasTags(item_links_thunderfury, {"melee"}), "HasTags gives false netagive after adding a second tag")
assert(AAI_HasTags(item_links_thunderfury, {"melee2"}), "HasTags gives false negative when attempting to match the second tag added to an item")
assert(AAI_HasTags(item_links_thunderfury, {"melee", "melee"}), "HasTags gives false negative when attempting to match two tags that exist on an item")


print("End of tags testing")
