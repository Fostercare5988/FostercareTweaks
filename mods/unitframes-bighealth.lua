-- FostercareTweaks: mods/unitframes-bighealth.lua
local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Unit Frame Big Health"],
    description = T["Increases the healthbar of the player and target unitframe."],
    category = T["Unit Frames"],
    enabled = nil,
})

local addonpath = "Interface\\AddOns\\FostercareTweaks"

module.enable = function(self)
    PlayerFrameTexture:SetTexture(addonpath .. "\\img\\UI-TargetingFrame")
    PlayerFrameHealthBar:SetPoint("TOPLEFT", 106, -22)
    PlayerFrameHealthBar:SetHeight(30)

    PlayerStatusTexture:SetTexture(addonpath .. "\\img\\UI-Player-Status")

    TargetFrameTexture:SetTexture(addonpath .. "\\img\\UI-TargetingFrame")
    TargetFrameHealthBar:SetPoint("TOPRIGHT", -106, -22)
    TargetFrameHealthBar:SetHeight(30)

    local function UpdateTargetClassification()
        local classification = UnitClassification("target")
        if classification == "worldboss" or classification == "rareelite" or classification == "elite" then
            TargetFrameTexture:SetTexture(addonpath .. "\\img\\UI-TargetingFrame-Elite")
        elseif classification == "rare" then
            TargetFrameTexture:SetTexture(addonpath .. "\\img\\UI-TargetingFrame-Rare")
        else
            TargetFrameTexture:SetTexture(addonpath .. "\\img\\UI-TargetingFrame")
        end
    end
    FostercareTweaks.hooksecurefunc("TargetFrame_CheckClassification", UpdateTargetClassification)

    local function UpdateTargetFactionColor(s)
        if TargetFrameHealthBar._SetStatusBarColor and TargetFrameNameBackground then
            local r, g, b, a = TargetFrameNameBackground:GetVertexColor()
            TargetFrameHealthBar:_SetStatusBarColor(r, g, b, a)
        end
    end
    FostercareTweaks.hooksecurefunc("TargetFrame_CheckFaction", UpdateTargetFactionColor)

    local wait = CreateFrame("Frame")

    wait:SetScript("OnUpdate", function()
        if PlayerFrameHealthBar.TextString then
            PlayerFrameHealthBar.TextString:SetPoint("TOP", PlayerFrameHealthBar, "BOTTOM", 0, 23)
        end

        if TargetFrameHealthBar.TextString then
            TargetFrameHealthBar.TextString:SetPoint("TOP", TargetFrameHealthBar, "BOTTOM", -2, 23)
        end

        if PlayerFrameNameBackground then
            PlayerFrameHealthBar._SetStatusBarColor = PlayerFrameHealthBar.SetStatusBarColor
            PlayerFrameHealthBar.SetStatusBarColor = function() return end

            local r, g, b, a = PlayerFrameNameBackground:GetVertexColor()
            PlayerFrameHealthBar:_SetStatusBarColor(r, g, b, a)

            PlayerFrameNameBackground:Hide()
            PlayerFrameNameBackground.Show = function() return end
        end

        if TargetFrameNameBackground then
            TargetFrameHealthBar._SetStatusBarColor = TargetFrameHealthBar.SetStatusBarColor
            TargetFrameHealthBar.SetStatusBarColor = function() return end

            TargetFrameNameBackground.Show = function() return end
            TargetFrameNameBackground:Hide()
        end

        TargetFrame_CheckFaction(PlayerFrame)
        wait:UnregisterAllEvents()
        wait:Hide()
    end)
end
