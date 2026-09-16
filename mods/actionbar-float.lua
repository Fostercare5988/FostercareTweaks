-- FostercareTweaks: mods/actionbar-float.lua
local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Floating Actionbar"],
    description = T["Removes all background textures and lets the actionbar float."],
    category = T["Action Bar"],
    enabled = nil,
})

local actionbars = {
    "Action", "BonusAction", "MultiBarBottomLeft", "MultiBarBottomRight",
    "MultiBarLeft", "MultiBarRight", "Shapeshift"
}

module.enable = function(self)
    MainMenuBar:ClearAllPoints()
    MainMenuBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 8)

    for _, prefix in pairs(actionbars) do
        for i = 1, NUM_ACTIONBAR_BUTTONS do
            local button = _G[prefix .. "Button" .. i]
            local texture = _G[prefix .. "Button" .. i .. "NormalTexture"]

            if button and texture then
                texture:SetWidth(60)
                texture:SetHeight(60)
                texture:SetPoint("CENTER", button, "CENTER", 0, 0)
                FostercareTweaks.AddBorder(button, 3, { r = 0.7, g = 0.7, b = 0.7, a = 1 })
            end
        end
    end

    if MainMenuBarPerformanceBarFrameButton then
        FostercareTweaks.AddBorder(MainMenuBarPerformanceBarFrameButton, { -12, -0.5, -8, 4.5 }, { r = 0.7, g = 0.7, b = 0.7, a = 1 })
    end

    ReputationWatchStatusBar:SetStatusBarTexture("Interface\\AddOns\\FostercareTweaks\\img\\xpbar")
    ReputationWatchStatusBarBackground:SetTexture("Interface\\AddOns\\FostercareTweaks\\img\\xpbar")
    ReputationWatchStatusBarBackground:SetVertexColor(0, 0, 0, 0.5)

    MainMenuExpBar:SetStatusBarTexture("Interface\\AddOns\\FostercareTweaks\\img\\xpbar")
    local _, _, _, _, _, background = MainMenuExpBar:GetRegions()
    if background then
        background:SetTexture("Interface\\AddOns\\FostercareTweaks\\img\\xpbar")
        background:SetVertexColor(0, 0, 0, 0.5)
    end

    local function UpdateReputationWatchBar()
        if ReputationWatchBar and ReputationWatchBar:IsShown() then
            MainMenuExpBar:SetPoint("TOP", MainMenuBar, "TOP", 0, -5)
            ReputationWatchBar:SetPoint("BOTTOM", MainMenuBar, "TOP", 0, -5)
        elseif MainMenuExpBar then
            MainMenuExpBar:SetPoint("TOP", MainMenuBar, "TOP", 0, 0)
        end
    end
    FostercareTweaks.hooksecurefunc("ReputationWatchBar_Update", UpdateReputationWatchBar)
    UpdateReputationWatchBar()

    local hideTextures = {
        MainMenuXPBarTexture0, MainMenuXPBarTexture1, MainMenuXPBarTexture2, MainMenuXPBarTexture3,
        ReputationXPBarTexture0, ReputationXPBarTexture1, ReputationXPBarTexture2, ReputationXPBarTexture3,
        ReputationWatchBarTexture0, ReputationWatchBarTexture1, ReputationWatchBarTexture2, ReputationWatchBarTexture3,
        MainMenuBarTexture0, MainMenuBarTexture1, MainMenuBarTexture2, MainMenuBarTexture3,
        BonusActionBarTexture1, BonusActionBarTexture0, BonusActionBarTexture2
    }
    for _, tex in ipairs(hideTextures) do
        if tex and tex.SetTexture then tex:SetTexture("") end
    end
end
