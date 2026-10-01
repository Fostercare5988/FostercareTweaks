if not FostercareTweaks then return end

-- FostercareTweaks: mods/unitframes-classcolor.lua
-- Colors standard player, target, and party health bars by class without background tint.

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Unit Frame Class Colors"],
    description = T["Class colors on standard player, target, and party health bars."],
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

local function UpdateHealthBarColor(statusbar, unit)
    if not statusbar then return end
    unit = unit or statusbar.unit
    if not unit or not UnitExists(unit) then return end

    if not IsActive() then return end

    if UnitIsPlayer(unit) then
        local color = GetClassColor(unit)
        if color then
            statusbar:SetStatusBarColor(color.r, color.g, color.b, 1)
        end
    elseif unit == "target" then
        if UnitIsTapped("target") and not UnitIsTappedByPlayer("target") then
            statusbar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
        else
            local reaction = UnitReaction("target", "player")
            if reaction then
                if reaction <= 2 then
                    statusbar:SetStatusBarColor(0.90, 0.00, 0.00, 1)
                elseif reaction == 3 then
                    statusbar:SetStatusBarColor(0.90, 0.40, 0.00, 1)
                elseif reaction == 4 then
                    statusbar:SetStatusBarColor(0.93, 0.93, 0.00, 1)
                else
                    statusbar:SetStatusBarColor(0.20, 0.90, 0.20, 1)
                end
            end
        end
    end
end

local function UpdatePartyMembers()
    if not IsActive() then return end
    for id = 1, MAX_PARTY_MEMBERS do
        local name = _G["PartyMemberFrame" .. id .. "Name"]
        local bar = _G["PartyMemberFrame" .. id .. "HealthBar"]
        local unit = "party" .. id
        if UnitExists(unit) then
            local color = GetClassColor(unit)
            if color then
                if name then name:SetTextColor(color.r, color.g, color.b, 1) end
                if bar then bar:SetStatusBarColor(color.r, color.g, color.b, 1) end
            end
        end
    end
end

local function SuppressTargetNameTint()
    if not IsActive() then return end
    if TargetFrameNameBackground then
        TargetFrameNameBackground:Hide()
    end
end

local function ApplyAll()
    if not IsActive() then return end
    if PlayerFrameHealthBar then
        UpdateHealthBarColor(PlayerFrameHealthBar, "player")
    end
    if TargetFrameHealthBar and UnitExists("target") then
        UpdateHealthBarColor(TargetFrameHealthBar, "target")
    end
    SuppressTargetNameTint()
    UpdatePartyMembers()
end

local hooksInstalled = false
local function EnsureHooks()
    if hooksInstalled then return end
    hooksInstalled = true

    if HealthBar_OnValueChanged then
        FostercareTweaks.hooksecurefunc("HealthBar_OnValueChanged", function()
            local bar = this
            if bar then
                local unit = bar.unit or (bar.GetParent and bar:GetParent() and bar:GetParent().unit)
                if bar == PlayerFrameHealthBar then unit = "player" end
                if bar == TargetFrameHealthBar then unit = "target" end
                if unit then
                    UpdateHealthBarColor(bar, unit)
                end
            end
        end)
    end

    if TargetFrame_Update then
        FostercareTweaks.hooksecurefunc("TargetFrame_Update", function()
            if TargetFrameHealthBar and UnitExists("target") then
                UpdateHealthBarColor(TargetFrameHealthBar, "target")
            end
            SuppressTargetNameTint()
        end)
    end

    if TargetFrame_CheckFaction then
        FostercareTweaks.hooksecurefunc("TargetFrame_CheckFaction", function()
            SuppressTargetNameTint()
        end)
    end

    if PlayerFrame_Update then
        FostercareTweaks.hooksecurefunc("PlayerFrame_Update", function()
            if PlayerFrameHealthBar then
                UpdateHealthBarColor(PlayerFrameHealthBar, "player")
            end
        end)
    end

    if PartyMemberFrame_UpdateMember then
        FostercareTweaks.hooksecurefunc("PartyMemberFrame_UpdateMember", UpdatePartyMembers)
    end

    local worldRefresh = CreateFrame("Frame")
    worldRefresh:RegisterEvent("PLAYER_ENTERING_WORLD")
    worldRefresh:RegisterEvent("PLAYER_TARGET_CHANGED")
    worldRefresh:RegisterEvent("PARTY_MEMBERS_CHANGED")
    worldRefresh:RegisterEvent("UNIT_HEALTH")
    worldRefresh:RegisterEvent("UNIT_MAXHEALTH")
    worldRefresh:SetScript("OnEvent", function()
        ApplyAll()
    end)
end

function module:apply()
    if IsActive() then
        EnsureHooks()
        ApplyAll()
    else
        if TargetFrameNameBackground and UnitExists("target") and TargetFrame_CheckFaction then
            TargetFrame_CheckFaction()
        end
        if PlayerFrameHealthBar then
            PlayerFrameHealthBar:SetStatusBarColor(0, 1, 0, 1)
        end
        if TargetFrameHealthBar then
            TargetFrameHealthBar:SetStatusBarColor(0, 1, 0, 1)
        end
        for id = 1, MAX_PARTY_MEMBERS do
            local name = _G["PartyMemberFrame" .. id .. "Name"]
            local bar = _G["PartyMemberFrame" .. id .. "HealthBar"]
            if name then name:SetTextColor(1, 0.82, 0, 1) end
            if bar then bar:SetStatusBarColor(0, 1, 0, 1) end
        end
    end
end

module.enable = module.apply
