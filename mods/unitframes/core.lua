-- FostercareTweaks: mods/unitframes/core.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Modern Unit Frames Subsystem: Core Foundation

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Unit Frames (Modern)"],
    description = T["Modern unit frames for Player and Target inspired by Luna Unit Frames, backed by enhanced client APIs."],
    category = T["Unit Frames"],
    enabled = true,
    config = {
        ["uf_scale"] = 1.0,
    }
})

FostercareTweaks.UnitFrames = FostercareTweaks.UnitFrames or {}
local UF = FostercareTweaks.UnitFrames
UF.module = module
UF.frames = {}

function UF:GetScale()
    local scale = (FostercareTweaks.overwrites and tonumber(FostercareTweaks.overwrites["uf_scale"])) or 1.0
    if scale < 0.5 then scale = 0.5 end
    if scale > 2.0 then scale = 2.0 end
    return scale
end

function UF:ApplyScale(scale)
    scale = tonumber(scale) or UF:GetScale()
    if UF.playerFrame then UF.playerFrame:SetScale(scale) end
    if UF.targetFrame then UF.targetFrame:SetScale(scale) end
    if UF.raidFrame then UF.raidFrame:SetScale(scale) end
end

-- Visual Backdrop Configuration (1px solid border, dark semi-transparent fill)
UF.backdrop = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

-- Color Tables
UF.ClassColors = {
    ["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43 },
    ["MAGE"]    = { r = 0.41, g = 0.80, b = 0.94 },
    ["ROGUE"]   = { r = 1.00, g = 0.96, b = 0.41 },
    ["DRUID"]   = { r = 1.00, g = 0.49, b = 0.04 },
    ["HUNTER"]  = { r = 0.67, g = 0.83, b = 0.45 },
    ["SHAMAN"]  = { r = 0.00, g = 0.55, b = 0.87 },
    ["PRIEST"]  = { r = 1.00, g = 1.00, b = 1.00 },
    ["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79 },
    ["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73 },
}

UF.PowerColors = {
    [0] = { r = 0.30, g = 0.52, b = 0.90 }, -- MANA
    [1] = { r = 0.90, g = 0.20, b = 0.20 }, -- RAGE
    [2] = { r = 1.00, g = 0.50, b = 0.25 }, -- FOCUS
    [3] = { r = 1.00, g = 0.85, b = 0.10 }, -- ENERGY
}

UF.ReactionColors = {
    [1] = { r = 0.90, g = 0.20, b = 0.20 }, -- Hostile
    [2] = { r = 0.90, g = 0.20, b = 0.20 }, -- Hostile
    [3] = { r = 0.90, g = 0.20, b = 0.20 }, -- Hostile
    [4] = { r = 0.90, g = 0.85, b = 0.10 }, -- Neutral
    [5] = { r = 0.20, g = 0.80, b = 0.20 }, -- Friendly
    [6] = { r = 0.20, g = 0.80, b = 0.20 }, -- Friendly
    [7] = { r = 0.20, g = 0.80, b = 0.20 }, -- Friendly
    [8] = { r = 0.20, g = 0.80, b = 0.20 }, -- Friendly
}

-- Default status bar texture
UF.defaultBarTexture = "Interface\\TargetingFrame\\UI-StatusBar"

--------------------------------------------------------------------------------
-- 1. Custom StatusBar Implementation (CreateBar)
-- Replaces native 1.12 StatusBar with texture-clipped Frame widget to eliminate
-- stretching, shearing, and reverse-fill distortion.
--------------------------------------------------------------------------------

local function BarGetMinMaxValues(self)
    return self.minV, self.maxV
end

local function BarGetOrientation(self)
    return self.orientation
end

local function BarGetStatusBarColor(self)
    return self.texture:GetVertexColor()
end

local function BarGetStatusBarTexture(self)
    return self.texture
end

local function BarGetValue(self)
    return self.value
end

local function BarRefresh(self)
    self = self or this
    local range = (self.maxV or 1) - (self.minV or 0)
    if range <= 0 then
        self.texture:Hide()
        return
    end

    local progress = ((self.value or 0) - (self.minV or 0)) / range
    if progress < 0 then progress = 0 end
    if progress > 1 then progress = 1 end

    if progress <= 0 then
        self.texture:Hide()
        return
    else
        self.texture:Show()
    end

    local w = self:GetWidth() or 0
    local h = self:GetHeight() or 0
    if w <= 0 or h <= 0 then return end

    self.texture:ClearAllPoints()
    if self.reverse then
        if self.orientation == "VERTICAL" then
            self.texture:SetWidth(w)
            self.texture:SetHeight(h * progress)
            self.texture:SetPoint("TOP", self, "TOP")
            self.texture:SetTexCoord(0, 1, 0, progress)
        else
            self.texture:SetWidth(w * progress)
            self.texture:SetHeight(h)
            self.texture:SetPoint("RIGHT", self, "RIGHT")
            self.texture:SetTexCoord(1 - progress, 1, 0, 1)
        end
    else
        if self.orientation == "VERTICAL" then
            self.texture:SetWidth(w)
            self.texture:SetHeight(h * progress)
            self.texture:SetPoint("BOTTOM", self, "BOTTOM")
            self.texture:SetTexCoord(0, 1, 1 - progress, 1)
        else
            self.texture:SetWidth(w * progress)
            self.texture:SetHeight(h)
            self.texture:SetPoint("LEFT", self, "LEFT")
            self.texture:SetTexCoord(0, progress, 0, 1)
        end
    end
end

local function BarSetMinMaxValues(self, minV, maxV)
    minV = tonumber(minV) or 0
    maxV = tonumber(maxV) or 1
    if maxV < minV then maxV = minV end
    self.minV = minV
    self.maxV = maxV
    if self.value < minV then self.value = minV end
    if self.value > maxV then self.value = maxV end
    BarRefresh(self)
end

local function BarSetOrientation(self, orientation)
    local o = string.upper(orientation or "HORIZONTAL")
    if o == "HORIZONTAL" or o == "VERTICAL" then
        if self.orientation ~= o then
            self.orientation = o
            BarRefresh(self)
        end
    end
end

local function BarSetStatusBarColor(self, r, g, b, alpha)
    if not r or not g or not b then return end
    alpha = alpha or 1
    self.texture:SetVertexColor(r, g, b, alpha)
end

local function BarSetStatusBarTexture(self, texture)
    if not texture then return end
    if type(texture) == "string" then
        self.texture:SetTexture(texture)
        if self.bg then self.bg:SetTexture(texture) end
    elseif texture.GetTexture and texture:GetTexture() then
        self.texture:SetTexture(texture:GetTexture())
        if self.bg then self.bg:SetTexture(texture:GetTexture()) end
    end
    BarRefresh(self)
end

local function BarSetValue(self, value)
    value = tonumber(value) or 0
    if value < self.minV then value = self.minV end
    if value > self.maxV then value = self.maxV end
    if self.value ~= value then
        self.value = value
        BarRefresh(self)
    end
end

local function BarSetReverse(self, value)
    self.reverse = value and true or nil
    BarRefresh(self)
end

function UF:CreateBar(name, parent)
    local bar = CreateFrame("Frame", name, parent)
    bar.minV = 0
    bar.maxV = 1
    bar.value = 1
    bar.orientation = "HORIZONTAL"

    -- Dark translucent background layer
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints(bar)
    bar.bg:SetTexture(UF.defaultBarTexture)
    bar.bg:SetVertexColor(0, 0, 0, 0.45)

    -- Status bar fill layer
    bar.texture = bar:CreateTexture(nil, "ARTWORK")
    bar.texture:SetTexture(UF.defaultBarTexture)

    bar.GetMinMaxValues = BarGetMinMaxValues
    bar.GetOrientation = BarGetOrientation
    bar.GetStatusBarColor = BarGetStatusBarColor
    bar.GetStatusBarTexture = BarGetStatusBarTexture
    bar.GetValue = BarGetValue
    bar.SetMinMaxValues = BarSetMinMaxValues
    bar.SetOrientation = BarSetOrientation
    bar.SetStatusBarColor = BarSetStatusBarColor
    bar.SetStatusBarTexture = BarSetStatusBarTexture
    bar.SetValue = BarSetValue
    bar.SetReverse = BarSetReverse
    bar.Refresh = BarRefresh

    bar:SetScript("OnSizeChanged", BarRefresh)
    return bar
end

--------------------------------------------------------------------------------
-- 2. Proportional Layout Engine
-- Stacks horizontal bars (Health, Power) vertically with pixel-perfect weighting
-- and allocates square space for side portraits.
--------------------------------------------------------------------------------

function UF:LayoutBars(frame)
    if not frame then return end

    local totalW = frame:GetWidth() or 240
    local totalH = frame:GetHeight() or 44
    local borderInset = 1
    local innerW = totalW - (borderInset * 2)
    local innerH = totalH - (borderInset * 2)

    local barXOffset = borderInset
    local barW = innerW

    -- Handle portrait positioning
    if frame.portrait and frame.portrait:IsShown() then
        local portraitSize = innerH
        if frame.portraitSide == "left" then
            frame.portrait:ClearAllPoints()
            frame.portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", borderInset, -borderInset)
            frame.portrait:SetWidth(portraitSize)
            frame.portrait:SetHeight(portraitSize)
            barXOffset = borderInset + portraitSize + 1
            barW = innerW - portraitSize - 1
        elseif frame.portraitSide == "right" then
            frame.portrait:ClearAllPoints()
            frame.portrait:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -borderInset, -borderInset)
            frame.portrait:SetWidth(portraitSize)
            frame.portrait:SetHeight(portraitSize)
            barXOffset = borderInset
            barW = innerW - portraitSize - 1
        end
    end

    -- Stack health and power bars
    local powerShown = frame.powerBar and frame.powerBar:IsShown()
    local separator = 1

    if powerShown then
        local availH = innerH - separator
        local healthH = math.floor(availH * 0.72 + 0.5)
        local powerH = availH - healthH

        frame.healthBar:ClearAllPoints()
        frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", barXOffset, -borderInset)
        frame.healthBar:SetWidth(barW)
        frame.healthBar:SetHeight(healthH)

        frame.powerBar:ClearAllPoints()
        frame.powerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", barXOffset, -borderInset - healthH - separator)
        frame.powerBar:SetWidth(barW)
        frame.powerBar:SetHeight(powerH)
    else
        frame.healthBar:ClearAllPoints()
        frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", barXOffset, -borderInset)
        frame.healthBar:SetWidth(barW)
        frame.healthBar:SetHeight(innerH)
    end

    if frame.healthBar and frame.healthBar.Refresh then frame.healthBar:Refresh() end
    if frame.powerBar and frame.powerBar.Refresh then frame.powerBar:Refresh() end
end

--------------------------------------------------------------------------------
-- 3. Authoritative Health Query (ClassicAPI / SuperWoW / UnitXP)
--------------------------------------------------------------------------------

function UF.GetUnitHealthValues(unit)
    if not unit or not UnitExists(unit) then return 0, 0 end
    local cur, max
    local hasXP = FostercareTweaks.HasUnitXP and FostercareTweaks.HasUnitXP()
    if hasXP then
        local ok, ch, mh = pcall(function()
            return UnitXP("health", unit), UnitXP("maxhealth", unit)
        end)
        if ok and ch and mh and mh > 0 then
            cur = ch
            max = mh
        end
    end
    if not cur or not max or max == 0 then
        cur = UnitHealth(unit) or 0
        max = UnitHealthMax(unit) or 0
    end
    return cur, max
end

--------------------------------------------------------------------------------
-- 4. Standard Unit Frame Factory
--------------------------------------------------------------------------------

local function UnitFrame_OnClick()
    if FCTweaksUnitFrameUnlocker and FCTweaksUnitFrameUnlocker.movable then
        return
    end
    local unit = this.unit
    if not unit then return end
    local button = arg1 or "LeftButton"

    if button == "LeftButton" then
        if SpellIsTargeting() then
            SpellTargetUnit(unit)
        elseif CursorHasItem() then
            DropItemOnUnit(unit)
        else
            TargetUnit(unit)
        end
    elseif button == "RightButton" then
        if unit == "player" then
            ToggleDropDownMenu(1, nil, PlayerFrameDropDown, "cursor")
        elseif unit == "target" then
            ToggleDropDownMenu(1, nil, TargetFrameDropDown, "cursor")
        end
    end
end

local function UnitFrame_OnEnter()
    local unit = this.unit
    if not unit then return end

    if SetMouseoverUnit then
        SetMouseoverUnit(unit)
    end

    if SpellIsTargeting and SpellIsTargeting() then
        SetCursor("CAST_CURSOR")
    end

    GameTooltip_SetDefaultAnchor(GameTooltip, this)
    GameTooltip:SetUnit(unit)
    local r, g, b = GameTooltip_UnitColor(unit)
    if GameTooltipTextLeft1 and r and g and b then
        GameTooltipTextLeft1:SetTextColor(r, g, b)
    end
    GameTooltip:Show()
end

local function UnitFrame_OnLeave()
    if SetMouseoverUnit then
        SetMouseoverUnit()
    end
    if SpellIsTargeting and SpellIsTargeting() then
        SetCursor(nil)
    end
    GameTooltip:Hide()
end

function UF:CreateUnitFrame(unit, name, parent)
    local frame = CreateFrame("Button", name, parent or UIParent)
    frame.unit = unit
    frame:SetFrameStrata("LOW")
    frame:SetClampedToScreen(true)

    frame:SetBackdrop(UF.backdrop)
    frame:SetBackdropColor(0.08, 0.08, 0.08, 0.85)
    frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    -- Interaction handling
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:SetScript("OnClick", UnitFrame_OnClick)
    frame:SetScript("OnEnter", UnitFrame_OnEnter)
    frame:SetScript("OnLeave", UnitFrame_OnLeave)

    -- Draggable support: dynamically enabled by mods/move-unitframes.lua when Ctrl+Shift are held
    frame:SetMovable(true)

    table.insert(UF.frames, frame)
    return frame
end

--------------------------------------------------------------------------------
-- 5. Subsystem Lifecycle & Native Blizzard Frame Suppression
--------------------------------------------------------------------------------

local nativeBlizzardSuppressed = false

function UF:SuppressBlizzardFrames()
    if nativeBlizzardSuppressed then return end
    nativeBlizzardSuppressed = true

    if PlayerFrame then
        PlayerFrame:Hide()
        PlayerFrame:UnregisterAllEvents()
        if PlayerFrameHealthBar then PlayerFrameHealthBar:UnregisterAllEvents() end
        if PlayerFrameManaBar then PlayerFrameManaBar:UnregisterAllEvents() end
    end

    if TargetFrame then
        TargetFrame:Hide()
        TargetFrame:UnregisterAllEvents()
        if TargetFrameHealthBar then TargetFrameHealthBar:UnregisterAllEvents() end
        if TargetFrameManaBar then TargetFrameManaBar:UnregisterAllEvents() end
        if ComboFrame then ComboFrame:UnregisterAllEvents() end
    end
end

function UF:RestoreBlizzardFrames()
    if not nativeBlizzardSuppressed then return end
    nativeBlizzardSuppressed = false

    if PlayerFrame then
        PlayerFrame:RegisterEvent("UNIT_LEVEL")
        PlayerFrame:RegisterEvent("UNIT_COMBAT")
        PlayerFrame:RegisterEvent("UNIT_FACTION")
        PlayerFrame:RegisterEvent("UNIT_NAME_UPDATE")
        PlayerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        PlayerFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
        PlayerFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
        PlayerFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        PlayerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        PlayerFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
        PlayerFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
        PlayerFrame:RegisterEvent("PARTY_LEADER_CHANGED")
        PlayerFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
        PlayerFrame:RegisterEvent("RAID_ROSTER_UPDATE")
        PlayerFrame:RegisterEvent("PLAYER_PVP_INFO_CHANGED")
        PlayerFrame:RegisterEvent("UNIT_PORTRAIT_UPDATE")
        PlayerFrame:RegisterEvent("UNIT_MODEL_CHANGED")
        PlayerFrame:Show()
        if PlayerFrame_Update then PlayerFrame_Update() end
    end

    if TargetFrame then
        TargetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        TargetFrame:RegisterEvent("UNIT_HEALTH")
        TargetFrame:RegisterEvent("UNIT_LEVEL")
        TargetFrame:RegisterEvent("UNIT_FACTION")
        TargetFrame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
        TargetFrame:RegisterEvent("UNIT_AURA")
        TargetFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
        TargetFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
        TargetFrame:RegisterEvent("RAID_TARGET_UPDATE")
        if UnitExists("target") then
            TargetFrame:Show()
            if TargetFrame_Update then TargetFrame_Update() end
        else
            TargetFrame:Hide()
        end
    end
end

module.enable = function(self)
    UF.enabled = true
    UF:SuppressBlizzardFrames()
    if UF.EnablePlayerFrame then UF:EnablePlayerFrame() end
    if UF.EnableTargetFrame then UF:EnableTargetFrame() end
    if UF.EnableRaidFrames then UF:EnableRaidFrames() end
end

-- Hook Blizzard frames so they stay hidden while modern unit frames are enabled
if PlayerFrame and FostercareTweaks.HookScript then
    FostercareTweaks.HookScript(PlayerFrame, "OnShow", function()
        if UF.enabled then PlayerFrame:Hide() end
    end)
end

if TargetFrame and FostercareTweaks.HookScript then
    FostercareTweaks.HookScript(TargetFrame, "OnShow", function()
        if UF.enabled then TargetFrame:Hide() end
    end)
end
