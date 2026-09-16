-- FostercareTweaks: mods/chat-timestamps.lua
-- Adds timestamps to chat messages

local T = FostercareTweaks.T
local rgbhex = FostercareTweaks.rgbhex

local module = FostercareTweaks:register({
    title = T["Chat Timestamps"],
    description = T["Add timestamps to chat messages."],
    expansions = { ["vanilla"] = true, ["tbc"] = false },
    category = T["Social & Chat"],
    enabled = false,
    config = {
        ["chat.timestamp.bracket"] = "[]",
        ["chat.timestamp.format"] = 24,
        ["chat.timestamp.color"] = { r = 0.8, g = 0.8, b = 0.8, a = 1 },
    }
})

module.enable = function(self)
    local bracket = self.config["chat.timestamp.bracket"] or "[]"
    local clock = self.config["chat.timestamp.format"] or 24
    local rgb = self.config["chat.timestamp.color"] or { r = 0.8, g = 0.8, b = 0.8, a = 1 }

    local left = string.sub(bracket, 1, 1) or ""
    local right = string.sub(bracket, 2, 2) or ""
    local timeFormat = (clock == 24) and "%H:%M:%S" or "%I:%M:%S %p"
    local color = rgbhex and rgbhex({ rgb.r, rgb.g, rgb.b, rgb.a }) or "|cffcccccc"

    for i = 1, NUM_CHAT_WINDOWS do
        local cf = _G["ChatFrame" .. i]
        if cf and cf.AddMessage then
            local origAddMessage = cf.AddMessage
            cf.AddMessage = function(frame, msg, a1, a2, a3, a4, a5)
                if not msg then return end
                msg = color .. left .. date(timeFormat) .. right .. "|r " .. msg
                origAddMessage(frame, msg, a1, a2, a3, a4, a5)
            end
        end
    end
end
