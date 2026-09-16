-- FostercareTweaks: mods/chat-history.lua
-- Save chat history of non-combatlog windows and restore on login

local T = FostercareTweaks.T
local rgbhex = FostercareTweaks.rgbhex

local module = FostercareTweaks:register({
    title = T["Chat History"],
    description = T["Save chat history of all non-combatlog windows and restore it on login."],
    expansions = { ["vanilla"] = true, ["tbc"] = false },
    category = T["Social & Chat"],
    enabled = true,
})

module.enable = function(self)
    local realm = GetRealmName()
    local player = UnitName("player")

    local function SaveChatHistory(id, msg, r, g, b)
        FostercareTweaks_Cache = FostercareTweaks_Cache or {}
        FostercareTweaks_Cache["chathistory"] = FostercareTweaks_Cache["chathistory"] or {}
        FostercareTweaks_Cache["chathistory"][realm] = FostercareTweaks_Cache["chathistory"][realm] or {}
        FostercareTweaks_Cache["chathistory"][realm][player] = FostercareTweaks_Cache["chathistory"][realm][player] or {}
        FostercareTweaks_Cache["chathistory"][realm][player][id] = FostercareTweaks_Cache["chathistory"][realm][player][id] or {}

        if r and g and b and rgbhex then
            local color = rgbhex(r * 0.5 + 0.2, g * 0.5 + 0.2, b * 0.5 + 0.2)
            msg = string.gsub(msg, "^", color)
            msg = string.gsub(msg, "|r", "|r" .. color)
        end

        local history = FostercareTweaks_Cache["chathistory"][realm][player][id]
        table.insert(history, 1, msg)
        if history[30] then table.remove(history, 30) end
    end

    local function GetChatHistory(id)
        FostercareTweaks_Cache = FostercareTweaks_Cache or {}
        FostercareTweaks_Cache["chathistory"] = FostercareTweaks_Cache["chathistory"] or {}
        FostercareTweaks_Cache["chathistory"][realm] = FostercareTweaks_Cache["chathistory"][realm] or {}
        FostercareTweaks_Cache["chathistory"][realm][player] = FostercareTweaks_Cache["chathistory"][realm][player] or {}
        FostercareTweaks_Cache["chathistory"][realm][player][id] = FostercareTweaks_Cache["chathistory"][realm][player][id] or {}

        return FostercareTweaks_Cache["chathistory"][realm][player][id]
    end

    local function AddMessage(frame, text, a1, a2, a3, a4, a5)
        if not text then return end
        SaveChatHistory(frame:GetID(), text, a1, a2, a3)
        if frame.FCTweaks_ChatHistoryAddMessage then
            frame.FCTweaks_ChatHistoryAddMessage(frame, text, a1, a2, a3, a4, a5)
        end
    end

    for i = 1, NUM_CHAT_WINDOWS do
        local cf = _G["ChatFrame" .. i]
        local combat = 0
        if cf and cf.messageTypeList then
            for _, msg in pairs(cf.messageTypeList) do
                if strfind(msg, "SPELL", 1) or strfind(msg, "COMBAT", 1) then
                    combat = combat + 1
                end
            end
        end

        if cf and combat <= 5 and not cf.FCTweaks_ChatHistoryAddMessage then
            local history = GetChatHistory(i)
            for j = 30, 0, -1 do
                if history[j] then
                    cf:AddMessage(history[j], 0.7, 0.7, 0.7)
                end
            end

            cf.FCTweaks_ChatHistoryAddMessage = cf.AddMessage
            cf.AddMessage = AddMessage
        end
    end
end
