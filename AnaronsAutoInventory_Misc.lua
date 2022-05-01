------------------------------------
--    SET MESSAGE OF THE DAY      --
------------------------------------
SLASH_AAI_SET_MOTD1 = "/gmotd"
SLASH_AAI_SET_MOTD2 = "/guildmessageoftheday"

SlashCmdList["AAI_SET_MOTD"] = function(option)
    GuildSetMOTD(option)
end


------------------------------------
--    DISPLAY WISHLIST COMMAND    --
------------------------------------
SLASH_AAI_WISHLIST1 = "/wishlist"

SlashCmdList["AAI_WISHLIST"] = function(option)
    SlashCmdList["AUTO_INVENTORY_COMMAND_LINE_INTERFACE"]("display wishlist")
end


------------------------------------
--    RELOAD UIT SLASH COMMAND    --
------------------------------------
SLASH_RELOAD_UI1 = "/reui"
SLASH_RELOAD_UI2 = "/reloadui"

SlashCmdList["RELOAD_UI"] = function(option)
    ReloadUI()
end


------------------------------------
-- CHAT MESSAGE STRING FORMATTING --
------------------------------------
local OldSendChatMessage = SendChatMessage 
SendChatMessage = function(...)
    message, chat_type, language, channel = ...

    message = AAI_GeneralStringFormat(message)
    
    -- Replace %whisper with whisper recepient
    local whisper_recepient = "<no whisper recepient>"
    if chat_type == "WHISPER" then
        -- Tiny hack to make /w %t work
        if channel == "%t" then
            channel = GetUnitName("target", false)
        end
        whisper_recepient = channel
    end
    message = string.gsub(message, "%%whisper", "%%w")
    message = string.gsub(message, "%%w", whisper_recepient)
    OldSendChatMessage(message, chat_type, language, channel)
end

