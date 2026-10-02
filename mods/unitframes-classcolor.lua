if not FostercareTweaks then return end

-- FostercareTweaks: mods/unitframes-classcolor.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Colors standard player and target name backgrounds by class.
-- Health bars remain standard Blizzard green.

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Unit Frame Class Colors"],
    description = T["Class colors on standard player and target name backgrounds."],
    category = T["Unit Frames"],
    enabled = true,
})

local function IsActive()
    return not FostercareTweaks_Config or FostercareTweaks_Config[T["Unit Frame Class Colors"]] ~= 0
end

local function GetClassColor(unit)
    if not unit or not UnitExists(unit) then return nil end
    local _, class = UnitClass(unit)
    if not class or class == "" then
        class = UnitClass(unit)
    end
    if class and FostercareTweaks.NormalizeClass then
        class = FostercareTweaks.NormalizeClass(class)
    elseif class then
        class = string.upper(class)
    end
    if (not class or class == "") and UnitName(unit) and FostercareTweaks.GetUnitData then
        class = FostercareTweaks.GetUnitData(UnitName(unit))
    end
    if not class then return nil end
    local colors = FostercareTweaks.UnitFrames and FostercareTweaks.UnitFrames.ClassColors
    if colors and colors[class] then
        return colors[class]
    end
    if RAID_CLASS_COLORS and rawget(RAID_CLASS_COLORS, class) then
        return rawget(RAID_CLASS_COLORS, class)
    end
    return nil
end

local ownsPlayerBackground = false
local originalPartyColors = {}

local function EnsurePlayerBackground()
    if not PlayerFrameNameBackground and PlayerFrame then
        PlayerFrameNameBackground = PlayerFrame:CreateTexture(nil, "BACKGROUND")
        PlayerFrameNameBackground:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground")
        PlayerFrameNameBackground:SetWidth(119)
        PlayerFrameNameBackground:SetHeight(19)
        PlayerFrameNameBackground:SetPoint("TOPLEFT", 106, -22)
        ownsPlayerBackground = true
    end
end

local function ColorPlayer()
    if not IsActive() then return end
    local color = GetClassColor("player")
    if color then
        EnsurePlayerBackground()
        if PlayerFrameNameBackground then
            PlayerFrameNameBackground:SetVertexColor(color.r, color.g, color.b, 1)
            PlayerFrameNameBackground:Show()
        end
    end
end

local function ColorTarget()
    if not IsActive() or not TargetFrameNameBackground then return end
    if UnitExists("target") and UnitIsPlayer("target") then
        local color = GetClassColor("target")
        if color then
            TargetFrameNameBackground:SetVertexColor(color.r, color.g, color.b, 1)
            TargetFrameNameBackground:Show()
        end
    else
        -- For NPCs (like Scarlet Myrmidon): Blizzard's native TargetFrame_CheckFaction
        -- sets the reaction color (red/yellow/green). Ensure background is visible.
        TargetFrameNameBackground:Show()
    end
end

local function ColorParty()
    if not IsActive() then return end
    for id = 1, MAX_PARTY_MEMBERS do
        local name = _G["PartyMemberFrame" .. id .. "Name"]
        local unit = "party" .. id
        if UnitExists(unit) then
            local color = GetClassColor(unit)
            if color and name then
                if not originalPartyColors[name] then
                    originalPartyColors[name] = { name:GetTextColor() }
                end
                name:SetTextColor(color.r, color.g, color.b, 1)
            end
        end
    end
end

local function RestoreParty()
    for name, color in pairs(originalPartyColors) do
        if name and name.SetTextColor then
            name:SetTextColor(unpack(color))
        end
    end
    originalPartyColors = {}
end

local function RestoreHealthBars()
    -- Ensure health bars are native green, never class-tinted
    if PlayerFrameHealthBar then
        PlayerFrameHealthBar:SetStatusBarColor(0, 1, 0, 1)
    end
    if TargetFrameHealthBar then
        TargetFrameHealthBar:SetStatusBarColor(0, 1, 0, 1)
    end
    for id = 1, MAX_PARTY_MEMBERS do
        local bar = _G["PartyMemberFrame" .. id .. "HealthBar"]
        if bar then
            bar:SetStatusBarColor(0, 1, 0, 1)
        end
    end
end

local function ApplyAll()
    if not IsActive() then return end
    ColorPlayer()
    ColorTarget()
    ColorParty()
    RestoreHealthBars()
end

local hooksInstalled = false
local function EnsureHooks()
    if hooksInstalled then return end
    hooksInstalled = true

    if TargetFrame_CheckFaction then
        FostercareTweaks.hooksecurefunc("TargetFrame_CheckFaction", ColorTarget)
    end

    if TargetFrame_Update then
        FostercareTweaks.hooksecurefunc("TargetFrame_Update", ColorTarget)
    end

    if PlayerFrame_Update then
        FostercareTweaks.hooksecurefunc("PlayerFrame_Update", ColorPlayer)
    end

    if PartyMemberFrame_UpdateMember then
        FostercareTweaks.hooksecurefunc("PartyMemberFrame_UpdateMember", ColorParty)
    end

    local worldRefresh = CreateFrame("Frame")
    worldRefresh:RegisterEvent("PLAYER_ENTERING_WORLD")
    worldRefresh:RegisterEvent("PLAYER_TARGET_CHANGED")
    worldRefresh:RegisterEvent("PARTY_MEMBERS_CHANGED")
    worldRefresh:SetScript("OnEvent", function()
        ApplyAll()
    end)
end

function module:apply()
    if IsActive() then
        EnsureHooks()
        ApplyAll()
    else
        if PlayerFrameNameBackground and ownsPlayerBackground then
            PlayerFrameNameBackground:Hide()
        end
        if UnitExists("target") and TargetFrame_CheckFaction then
            TargetFrame_CheckFaction()
        end
        RestoreParty()
        RestoreHealthBars()
    end
end

module.enable = function(self)
    self:apply()
end
