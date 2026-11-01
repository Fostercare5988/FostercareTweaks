local FT = FostercareTweaks
if not FT then return end

local GetPlayerClass, rgbhex = FT.GetPlayerClass, FT.rgbhex
local module = FT:register({
    title = "Chat Class Colors",
    description = "Color player names in chat by class. Friends, Guild and Who use the game's built-in colors.",
    category = "Social & Chat",
    enabled = true,
})

-- "|Hplayer:Name:id|h[Name]|h" becomes the name in its class color (grey when
-- the class is unknown), brackets in the line's color. Lua 5.0's gsub uses the
-- empty string for a nil result, so a link left alone is returned whole.
local function Colorize(link, shown)
    local real = string.gsub(link, ":.*$", "")
    if shown ~= real then return "|Hplayer:" .. link .. "|h[" .. shown .. "]|h" end
    local class = GetPlayerClass(real)
    local color = class and RAID_CLASS_COLORS[class] and rgbhex(RAID_CLASS_COLORS[class]) or "|cffaaaaaa"
    return "|r[" .. color .. "|Hplayer:" .. link .. "|h" .. color .. real .. "|h|r]|r"
end

module.enable = function(self)
    for i = 1, NUM_CHAT_WINDOWS do
        local cf = _G["ChatFrame" .. i]
        if cf and not cf.FCTweaks_HookAddMessageColor and not FT.IsCombatChatFrame(cf) then
            cf.FCTweaks_HookAddMessageColor = cf.AddMessage
            cf.AddMessage = function(frame, text, a1, a2, a3, a4, a5)
                if text and string.find(text, "|Hplayer:", 1, true) then
                    text = string.gsub(text, "|Hplayer:([^|]*)|h%[([^%]|]*)%]|h", Colorize)
                end
                cf.FCTweaks_HookAddMessageColor(frame, text, a1, a2, a3, a4, a5)
            end
        end
    end
end
