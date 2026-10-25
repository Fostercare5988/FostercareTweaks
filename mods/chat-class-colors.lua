local FT = FostercareTweaks
if not FT then return end

local GetPlayerClass, rgbhex = FT.GetPlayerClass, FT.rgbhex
local module = FT:register({
    title = "Chat Class Colors",
    description = "Color player names in chat by class. Friends, Guild and Who use the game's built-in colors.",
    category = "Social & Chat",
    enabled = true,
})

module.enable = function(self)
    for i = 1, NUM_CHAT_WINDOWS do
        local cf = _G["ChatFrame" .. i]
        if cf and not cf.FCTweaks_HookAddMessageColor and not Prat and not FT.IsCombatChatFrame(cf) then
            cf.FCTweaks_HookAddMessageColor = cf.AddMessage
            cf.AddMessage = function(frame, text, a1, a2, a3, a4, a5)
                if text then
                    for name in string.gmatch(text, "|Hplayer:(.-)|h") do
                        local real = string.gsub(name, ":.*$", "")
                        local color = "|cffaaaaaa"
                        local classToken = GetPlayerClass(real)

                        if classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
                            color = rgbhex(RAID_CLASS_COLORS[classToken])
                        end

                        local escaped_name = string.gsub(name, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
                        local escaped_real = string.gsub(real, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
                        local pattern1 = "|Hplayer:" .. escaped_name .. "|h%[" .. escaped_real .. "%]|h(.-:-)"
                        local repl1 = "|r[" .. color .. "|Hplayer:" .. name .. "|h" .. color .. real .. "|h|r" .. "]|r" .. "%1"
                        local new_text, count = string.gsub(text, pattern1, repl1)
                        if count == 0 then
                            local pattern2 = "(|Hplayer:" .. escaped_name .. "|h)%[" .. escaped_real .. "%](|h)"
                            local repl2 = "|r[" .. color .. "%1" .. color .. real .. "%2|r]"
                            text = string.gsub(text, pattern2, repl2)
                        else
                            text = new_text
                        end
                    end
                end
                cf.FCTweaks_HookAddMessageColor(frame, text, a1, a2, a3, a4, a5)
            end
        end
    end
end
