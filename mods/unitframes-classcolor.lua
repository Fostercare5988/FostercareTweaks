-- FostercareTweaks: mods/unitframes-classcolor.lua
local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Unit Frame Class Colors"],
    description = T["Class colors on standard player and target name backgrounds and party names."],
    category = T["Unit Frames"],
    enabled = true,
})

local hooksInstalled = false
local ownsPlayerBackground = false
local originalPlayerColor, originalPlayerShown
local originalPartyColors = {}

local function IsActive()
    return FostercareTweaks_Config and FostercareTweaks_Config[T["Unit Frame Class Colors"]] == 1
end

local function ClassColor(unit)
    local _, class = UnitClass(unit)
    -- Use our fixed class palette, never a shared global or its grey fallback.
    local colors = FostercareTweaks.UnitFrames and FostercareTweaks.UnitFrames.ClassColors
    return class and colors and rawget(colors, class)
end

local function ColorTarget()
    if not IsActive() or not UnitIsPlayer("target") or not TargetFrameNameBackground then return end
    local color = ClassColor("target")
    if color then TargetFrameNameBackground:SetVertexColor(color.r, color.g, color.b, 1) end
end

local function ColorParty()
    if not IsActive() then return end
    for id = 1, MAX_PARTY_MEMBERS do
        local name = _G["PartyMemberFrame" .. id .. "Name"]
        local color = ClassColor("party" .. id)
        if name and color then
            if not originalPartyColors[name] then
                originalPartyColors[name] = { name:GetTextColor() }
            end
            name:SetTextColor(color.r, color.g, color.b, 1)
        end
    end
end

local function RestoreParty()
    for name, color in pairs(originalPartyColors) do
        name:SetTextColor(unpack(color))
    end
    originalPartyColors = {}
end

local function EnsureHooks()
    if hooksInstalled then return end
    FostercareTweaks.hooksecurefunc("TargetFrame_CheckFaction", ColorTarget)
    FostercareTweaks.hooksecurefunc("PartyMemberFrame_UpdateMember", ColorParty)
    hooksInstalled = true
    local worldRefresh = CreateFrame("Frame")
    worldRefresh:RegisterEvent("PLAYER_ENTERING_WORLD")
    worldRefresh:SetScript("OnEvent", function()
        module:apply()
        this:UnregisterAllEvents()
    end)
end

local function EnsurePlayerBackground()
    if not PlayerFrameNameBackground then
        PlayerFrameNameBackground = PlayerFrame:CreateTexture(nil, "BACKGROUND")
        PlayerFrameNameBackground:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground")
        PlayerFrameNameBackground:SetWidth(119)
        PlayerFrameNameBackground:SetHeight(19)
        PlayerFrameNameBackground:SetPoint("TOPLEFT", 106, -22)
        ownsPlayerBackground = true
    elseif not ownsPlayerBackground and not originalPlayerColor then
        originalPlayerColor = { PlayerFrameNameBackground:GetVertexColor() }
        originalPlayerShown = PlayerFrameNameBackground:IsShown()
    end
end

function module:apply()
    if IsActive() then
        EnsureHooks()
        local color = ClassColor("player")
        if color then
            EnsurePlayerBackground()
            PlayerFrameNameBackground:SetVertexColor(color.r, color.g, color.b, 1)
            if ownsPlayerBackground then PlayerFrameNameBackground:Show() end
        end
        if UnitExists("target") and TargetFrame_CheckFaction then TargetFrame_CheckFaction() end
        ColorParty()
    else
        if PlayerFrameNameBackground then
            if ownsPlayerBackground then
                PlayerFrameNameBackground:Hide()
            elseif originalPlayerColor then
                PlayerFrameNameBackground:SetVertexColor(unpack(originalPlayerColor))
                if originalPlayerShown then PlayerFrameNameBackground:Show()
                else PlayerFrameNameBackground:Hide() end
                originalPlayerColor, originalPlayerShown = nil, nil
            end
        end
        -- The native 1.12 function owns reaction/PvP/tapped target colors.
        if UnitExists("target") and TargetFrame_CheckFaction then TargetFrame_CheckFaction() end
        RestoreParty()
    end
end

module.enable = module.apply
