function AAI_OnAddonLoadedWarn(instance)
    aai_warn_players = aai_warn_players or {}
    aai_warn_guilds = aai_warn_guilds or {}
end


function AAI_WarnAboutPartyMembers(args)
    for i = 1,4 do
        local name = GetUnitName("party" .. i)
        if name then
            AAI_WarnAboutPlayer(name, "PARTY")
        end
    end
    for i = 1,40 do
        local name = GetUnitName("raid" .. i)
        if name then
            AAI_WarnAboutPlayer(name, "RAID")
        end
    end
end


function AAI_WarnAboutPlayer(name, chat)
    if aai_warn_players[name] ~= nil then
        SendChatMessage(string.format("WARNING! I have saved a note regarding %s: %s", name, aai_warn_players[name]), chat)
    end
end


-- AAI_SubscribeEvent("PARTY_MEMBERS_CHANGED", function(...) AAI_WarnAboutPartyMembers() end)
AAI_SubscribeEvent("GROUP_ROSTER_UPDATE", function(args, ...) AAI_WarnAboutPartyMembers(args) end)

