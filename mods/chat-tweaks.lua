-- FostercareTweaks: mods/chat-tweaks.lua
-- Mouse wheel chat scrolling, sticky chat channels, and arrow key history

local T = FostercareTweaks.T
local scrollspeed = 1

local module = FostercareTweaks:register({
    title = T["Chat Tweaks"],
    description = T["Allows to scroll using the mouse wheel, enables sticky chat channels and repeats message on arrow up."],
    expansions = { ["vanilla"] = true, ["tbc"] = true },
    category = T["Social & Chat"],
    enabled = true,
})

local function ChatOnMouseWheel()
    local delta = _G.arg1 or 0
    if delta > 0 then
        if IsShiftKeyDown() then
            this:ScrollToTop()
        else
            for i = 1, scrollspeed do
                this:ScrollUp()
            end
        end
    elseif delta < 0 then
        if IsShiftKeyDown() then
            this:ScrollToBottom()
        else
            for i = 1, scrollspeed do
                this:ScrollDown()
            end
        end
    end
end

module.enable = function(self)
    if ChatTypeInfo then
        if ChatTypeInfo.WHISPER then ChatTypeInfo.WHISPER.sticky = 1 end
        if ChatTypeInfo.OFFICER then ChatTypeInfo.OFFICER.sticky = 1 end
        if ChatTypeInfo.RAID_WARNING then ChatTypeInfo.RAID_WARNING.sticky = 1 end
        if ChatTypeInfo.CHANNEL then ChatTypeInfo.CHANNEL.sticky = 1 end
    end

    if ChatFrameEditBox then
        ChatFrameEditBox:SetAltArrowKeyMode(false)
    end

    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        if frame then
            frame:EnableMouseWheel(true)
            frame:SetScript("OnMouseWheel", ChatOnMouseWheel)
        end
    end
end
