-- FostercareTweaks: mods/chat-input-center.lua
-- Move the chat input box to the center of the screen

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Center Text Input Box"],
    description = T["Move the chat input box to the center of the screen."],
    expansions = { ["vanilla"] = true, ["tbc"] = false },
    category = T["Social & Chat"],
    enabled = nil,
})

local dodge_frames = {
    MainMenuBarArtFrame, MultiBarBottomLeft, MultiBarBottomRight, PetActionBarFrame, ShapeshiftBarFrame
}

module.enable = function(self)
    if not ChatFrameEditBox then return end

    ChatFrameEditBox:ClearAllPoints()
    ChatFrameEditBox:SetWidth(300)

    local function PositionChatInputBox()
        local top = 0
        for _, frame in ipairs(dodge_frames) do
            if frame and frame:IsVisible() and frame:GetTop() then
                top = math.max(top, frame:GetTop())
            end
        end

        ChatFrameEditBox:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, top)
    end

    FostercareTweaks.hooksecurefunc("UIParent_ManageFramePositions", PositionChatInputBox)
    PositionChatInputBox()
end
