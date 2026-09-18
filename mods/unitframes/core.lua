-- FostercareTweaks: mods/unitframes/core.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Modern Unit Frames Subsystem: Core Foundation

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Unit Frames (Modern)"],
    description = T["Modern unit frames for Player and Target inspired by Luna Unit Frames, backed by enhanced client APIs."],
    category = T["Unit Frames"],
    enabled = false,
    config = {
        ["uf_scale"] = 1.0,
    }
})

-- Positive modern unit frame toggles (disabled by default for new users)
FostercareTweaks:register({
    title = T["Modern Player Frame"],
    description = T["Enable the modern FostercareTweaks player unit frame instead of the default Blizzard frame."],
    category = T["Unit Frames"],
    enabled = false,
})

FostercareTweaks:register({
    title = T["Modern Target Frame"],
    description = T["Enable the modern FostercareTweaks target unit frame instead of the default Blizzard frame."],
    category = T["Unit Frames"],
    enabled = false,
})

FostercareTweaks:register({
    title = T["Modern Target's Target"],
    description = T["Enable the modern FostercareTweaks Target of Target frame instead of the standard Blizzard frame."],
    category = T["Unit Frames"],
    enabled = false,
})

-- Backward compatibility aliases
FostercareTweaks:register({
    title = T["Use Standard Player Frame"],
    description = T["Use the default Blizzard player unit frame instead of the modern FostercareTweaks frame."],
    category = T["Unit Frames"],
    enabled = false,
})

FostercareTweaks:register({
    title = T["Use Standard Target Frame"],
    description = T["Use the default Blizzard target unit frame instead of the modern FostercareTweaks frame."],
    category = T["Unit Frames"],
    enabled = false,
})

FostercareTweaks:register({
    title = T["Use Standard Target's Target"],
    description = T["Use the standard Target of Target frame instead of the modern FostercareTweaks frame."],
    category = T["Unit Frames"],
    enabled = false,
})

FostercareTweaks:register({
    title = T["Improved Standard Auras"],
    description = T["Display enhanced buffs and debuffs with timers, spirals and dispel borders on standard Blizzard frames."],
    category = T["Unit Frames"],
    enabled = true,
})

-- Granular toggles for modern aura visibility and configuration
FostercareTweaks:register({
    title = T["Show Player Buffs"],
    description = T["Display buff icons above the modern player unit frame."],
    category = T["Unit Frames"],
    enabled = true,
})

FostercareTweaks:register({
    title = T["Show Target Buffs"],
    description = T["Display buff icons above the modern target unit frame."],
    category = T["Unit Frames"],
    enabled = true,
})

FostercareTweaks:register({
    title = T["Show Player Debuffs"],
    description = T["Display debuff icons on the modern player unit frame."],
    category = T["Unit Frames"],
    enabled = true,
})

FostercareTweaks:register({
    title = T["Show Target Debuffs"],
    description = T["Display debuff icons below the modern target unit frame."],
    category = T["Unit Frames"],
    enabled = true,
})

FostercareTweaks:register({
    title = T["Show Buff Cooldown Spiral"],
    description = T["Display the radial cooldown sweep on unit frame buffs."],
    category = T["Unit Frames"],
    enabled = true,
})

FostercareTweaks:register({
    title = T["Show Buff Duration Text"],
    description = T["Display remaining time numbers on unit frame buffs."],
    category = T["Unit Frames"],
    enabled = true,
})

FostercareTweaks:register({
    title = T["Show Debuff Cooldown Spiral"],
    description = T["Display the radial cooldown sweep on unit frame debuffs."],
    category = T["Unit Frames"],
    enabled = true,
})

FostercareTweaks:register({
    title = T["Show Debuff Duration Text"],
    description = T["Display remaining time numbers on unit frame debuffs."],
    category = T["Unit Frames"],
    enabled = true,
})

FostercareTweaks:register({
    title = T["Show Aura Cooldown Spiral"],
    description = T["Display the radial cooldown sweep on unit frame buffs and debuffs."],
    category = T["Unit Frames"],
    enabled = true,
})

FostercareTweaks:register({
    title = T["Show Aura Duration Text"],
    description = T["Display remaining time numbers on unit frame buffs and debuffs."],
    category = T["Unit Frames"],
    enabled = true,
})

FostercareTweaks:register({
    title = T["Color Debuffs by Dispel Type"],
    description = T["Color debuff borders by magic, curse, disease, or poison."],
    category = T["Unit Frames"],
    enabled = true,
})

FostercareTweaks:register({
    title = T["Only Show My Debuffs on Target"],
    description = T["Only show debuffs cast by you on the target unit frame."],
    category = T["Unit Frames"],
    enabled = false,
})

FostercareTweaks:register({
    title = T["Show Raid Aggro Indicator"],
    description = T["Show a red indicator box on group/raid frames when a member has aggro."],
    category = T["Unit Frames"],
    enabled = true,
})

FostercareTweaks:register({
    title = T["Show Raid HoT Indicator"],
    description = T["Show corner status indicators for active healing over time buffs."],
    category = T["Unit Frames"],
    enabled = true,
})

FostercareTweaks:register({
    title = T["Show Raid Debuff Badges"],
    description = T["Show compact debuff icons on group/raid frames."],
    category = T["Unit Frames"],
    enabled = true,
})

FostercareTweaks.UnitFrames = FostercareTweaks.UnitFrames or {}
local UF = FostercareTweaks.UnitFrames
UF.module = module
UF.frames = {}

function UF:IsModernPlayer()
    if not FostercareTweaks_Config then return false end
    if FostercareTweaks_Config[T["Modern Player Frame"]] ~= nil then
        return FostercareTweaks_Config[T["Modern Player Frame"]] == 1
    end
    if FostercareTweaks_Config[T["Use Standard Player Frame"]] ~= nil then
        return FostercareTweaks_Config[T["Use Standard Player Frame"]] == 0
    end
    return false
end

function UF:IsModernTarget()
    if not FostercareTweaks_Config then return false end
    if FostercareTweaks_Config[T["Modern Target Frame"]] ~= nil then
        return FostercareTweaks_Config[T["Modern Target Frame"]] == 1
    end
    if FostercareTweaks_Config[T["Use Standard Target Frame"]] ~= nil then
        return FostercareTweaks_Config[T["Use Standard Target Frame"]] == 0
    end
    return false
end

function UF:IsModernToT()
    if not FostercareTweaks_Config then return false end
    if FostercareTweaks_Config[T["Modern Target's Target"]] ~= nil then
        return FostercareTweaks_Config[T["Modern Target's Target"]] == 1
    end
    if FostercareTweaks_Config[T["Use Standard Target's Target"]] ~= nil then
        return FostercareTweaks_Config[T["Use Standard Target's Target"]] == 0
    end
    return false
end

function UF:IsStandardPlayer()
    return not UF:IsModernPlayer()
end

function UF:IsStandardTarget()
    return not UF:IsModernTarget()
end

function UF:IsStandardToT()
    return not UF:IsModernToT()
end

function UF:IsImprovedStandardAuras()
    if not FostercareTweaks_Config then return true end
    local val = FostercareTweaks_Config[T["Improved Standard Auras"]]
    if val == nil then return true end
    return val == 1
end

function UF:IsShowPlayerBuffs()
    if not FostercareTweaks_Config then return true end
    local val = FostercareTweaks_Config[T["Show Player Buffs"]]
    if val == nil then return true end
    return val == 1
end

function UF:IsShowTargetBuffs()
    if not FostercareTweaks_Config then return true end
    local val = FostercareTweaks_Config[T["Show Target Buffs"]]
    if val == nil then return true end
    return val == 1
end

function UF:GetBuffSize()
    if not FostercareTweaks_Config then return 20 end
    local val = FostercareTweaks_Config.overwrites and tonumber(FostercareTweaks_Config.overwrites["uf_buff_size"])
    if not val then
        val = FostercareTweaks_Config.overwrites and tonumber(FostercareTweaks_Config.overwrites["uf_aura_size"])
    end
    if not val then return 20 end
    if val < 14 then val = 14 end
    if val > 32 then val = 32 end
    return val
end

function UF:IsBuffSpin()
    if not FostercareTweaks_Config then return true end
    local val = FostercareTweaks_Config[T["Show Buff Cooldown Spiral"]]
    if val == nil then
        val = FostercareTweaks_Config[T["Show Aura Cooldown Spiral"]]
    end
    if val == nil then return true end
    return val == 1
end

function UF:IsBuffText()
    if not FostercareTweaks_Config then return true end
    local val = FostercareTweaks_Config[T["Show Buff Duration Text"]]
    if val == nil then
        val = FostercareTweaks_Config[T["Show Aura Duration Text"]]
    end
    if val == nil then return true end
    return val == 1
end

function UF:IsShowPlayerDebuffs()
    if not FostercareTweaks_Config then return true end
    local val = FostercareTweaks_Config[T["Show Player Debuffs"]]
    if val == nil then return true end
    return val == 1
end

function UF:IsShowTargetDebuffs()
    if not FostercareTweaks_Config then return true end
    local val = FostercareTweaks_Config[T["Show Target Debuffs"]]
    if val == nil then return true end
    return val == 1
end

function UF:GetDebuffSize()
    if not FostercareTweaks_Config then return 20 end
    local val = FostercareTweaks_Config.overwrites and tonumber(FostercareTweaks_Config.overwrites["uf_debuff_size"])
    if not val then
        val = FostercareTweaks_Config.overwrites and tonumber(FostercareTweaks_Config.overwrites["uf_aura_size"])
    end
    if not val then return 20 end
    if val < 14 then val = 14 end
    if val > 32 then val = 32 end
    return val
end

function UF:IsDebuffSpin()
    if not FostercareTweaks_Config then return true end
    local val = FostercareTweaks_Config[T["Show Debuff Cooldown Spiral"]]
    if val == nil then
        val = FostercareTweaks_Config[T["Show Aura Cooldown Spiral"]]
    end
    if val == nil then return true end
    return val == 1
end

function UF:IsDebuffText()
    if not FostercareTweaks_Config then return true end
    local val = FostercareTweaks_Config[T["Show Debuff Duration Text"]]
    if val == nil then
        val = FostercareTweaks_Config[T["Show Aura Duration Text"]]
    end
    if val == nil then return true end
    return val == 1
end

function UF:IsColorDebuffsByDispel()
    if not FostercareTweaks_Config then return true end
    local val = FostercareTweaks_Config[T["Color Debuffs by Dispel Type"]]
    if val == nil then return true end
    return val == 1
end

function UF:IsOnlyMyDebuffs()
    if not FostercareTweaks_Config then return false end
    local val = FostercareTweaks_Config[T["Only Show My Debuffs on Target"]]
    if val == nil then return false end
    return val == 1
end

-- Backwards-compatible aliases
UF.GetAuraSize = UF.GetBuffSize
UF.IsAuraSpin = UF.IsBuffSpin
UF.IsAuraText = UF.IsBuffText

function UF:GetRaidHealthFormat()
    if not FostercareTweaks_Config then return "deficit" end
    local val = FostercareTweaks_Config.overwrites and FostercareTweaks_Config.overwrites["raid_health_format"]
    return val or "deficit"
end

function UF:IsRaidShowAggro()
    if not FostercareTweaks_Config then return true end
    local val = FostercareTweaks_Config[T["Show Raid Aggro Indicator"]]
    if val == nil then return true end
    return val == 1
end

function UF:IsRaidShowHoT()
    if not FostercareTweaks_Config then return true end
    local val = FostercareTweaks_Config[T["Show Raid HoT Indicator"]]
    if val == nil then return true end
    return val == 1
end

function UF:IsRaidShowDebuffs()
    if not FostercareTweaks_Config then return true end
    local val = FostercareTweaks_Config[T["Show Raid Debuff Badges"]]
    if val == nil then return true end
    return val == 1
end

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
    if UF.totFrame then UF.totFrame:SetScale(scale) end
    if UF.raidFrame then UF.raidFrame:SetScale(scale) end
end

-- Visual Backdrop Configuration (Luna-style solid black border and fill)
UF.backdrop = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
}
UF.backdropColor = { 0.00, 0.00, 0.00, 0.90 }
UF.backdropBorderColor = { 0.00, 0.00, 0.00, 1.00 }

-- Exact Luna Unit Frames Class Colors
UF.ClassColors = {
    ["HUNTER"]  = { r = 0.67, g = 0.83, b = 0.45 },
    ["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79 },
    ["PRIEST"]  = { r = 1.00, g = 1.00, b = 1.00 },
    ["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73 },
    ["MAGE"]    = { r = 0.41, g = 0.80, b = 0.94 },
    ["ROGUE"]   = { r = 1.00, g = 0.96, b = 0.41 },
    ["DRUID"]   = { r = 1.00, g = 0.49, b = 0.04 },
    ["SHAMAN"]  = { r = 0.14, g = 0.35, b = 1.00 },
    ["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43 },
    ["PET"]     = { r = 0.20, g = 0.90, b = 0.20 },
}

-- Exact Luna Unit Frames Power Colors
UF.PowerColors = {
    [0] = { r = 0.30, g = 0.50, b = 0.85 }, -- MANA
    [1] = { r = 0.90, g = 0.20, b = 0.30 }, -- RAGE
    [2] = { r = 1.00, g = 0.50, b = 0.25 }, -- FOCUS
    [3] = { r = 1.00, g = 0.85, b = 0.10 }, -- ENERGY
}

-- Exact Luna Unit Frames Health / Reaction Colors
UF.ReactionColors = {
    [1] = { r = 0.90, g = 0.00, b = 0.00 }, -- Hostile
    [2] = { r = 0.90, g = 0.00, b = 0.00 }, -- Hostile
    [3] = { r = 0.90, g = 0.00, b = 0.00 }, -- Hostile
    [4] = { r = 0.93, g = 0.93, b = 0.00 }, -- Neutral
    [5] = { r = 0.20, g = 0.90, b = 0.20 }, -- Friendly
    [6] = { r = 0.20, g = 0.90, b = 0.20 }, -- Friendly
    [7] = { r = 0.20, g = 0.90, b = 0.20 }, -- Friendly
    [8] = { r = 0.20, g = 0.90, b = 0.20 }, -- Friendly
}

UF.HealthColors = {
    ["tapped"]   = { r = 0.50, g = 0.50, b = 0.50 },
    ["hostile"]  = { r = 0.90, g = 0.00, b = 0.00 },
    ["friendly"] = { r = 0.20, g = 0.90, b = 0.20 },
    ["neutral"]  = { r = 0.93, g = 0.93, b = 0.00 },
    ["offline"]  = { r = 0.50, g = 0.50, b = 0.50 },
}

-- Exact Luna Magic / Dispel Colors
UF.DispelColors = {
    ["Magic"]   = { r = 0.20, g = 0.60, b = 1.00 },
    ["Curse"]   = { r = 0.60, g = 0.00, b = 1.00 },
    ["Disease"] = { r = 0.60, g = 0.40, b = 0.00 },
    ["Poison"]  = { r = 0.00, g = 0.60, b = 0.00 },
    ["None"]    = { r = 0.60, g = 0.15, b = 0.15 },
}

function UF.IsRealPlayer(unit)
    if not unit or not UnitExists(unit) then return false end
    if not UnitIsPlayer(unit) or not UnitPlayerControlled(unit) then
        return false
    end
    return true
end

-- Default status bar texture (Luna smooth bar)
UF.defaultBarTexture = "Interface\\AddOns\\FostercareTweaks\\img\\bar-luna.tga"

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
    if self.bg and not self.bg.overrideColor then
        self.bg:SetVertexColor(r * 0.20, g * 0.20, b * 0.20, 1.0)
    end
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

    -- Background layer (Luna style 20% tinted texture against dark backdrop)
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints(bar)
    bar.bg:SetTexture(UF.defaultBarTexture)
    bar.bg:SetVertexColor(0.08, 0.08, 0.08, 1.0)

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

function UF:SuppressPlayerFrame()
    if PlayerFrame then
        PlayerFrame:Hide()
        PlayerFrame:UnregisterAllEvents()
        if PlayerFrameHealthBar then PlayerFrameHealthBar:UnregisterAllEvents() end
        if PlayerFrameManaBar then PlayerFrameManaBar:UnregisterAllEvents() end
    end
end

function UF:RestorePlayerFrame()
    if not PlayerFrame then return end
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
    if PlayerFrameHealthBar then
        PlayerFrameHealthBar:RegisterEvent("UNIT_HEALTH")
        PlayerFrameHealthBar:RegisterEvent("UNIT_MAXHEALTH")
    end
    if PlayerFrameManaBar then
        PlayerFrameManaBar:RegisterEvent("UNIT_MANA")
        PlayerFrameManaBar:RegisterEvent("UNIT_RAGE")
        PlayerFrameManaBar:RegisterEvent("UNIT_FOCUS")
        PlayerFrameManaBar:RegisterEvent("UNIT_ENERGY")
        PlayerFrameManaBar:RegisterEvent("UNIT_MAXMANA")
        PlayerFrameManaBar:RegisterEvent("UNIT_MAXRAGE")
        PlayerFrameManaBar:RegisterEvent("UNIT_MAXFOCUS")
        PlayerFrameManaBar:RegisterEvent("UNIT_MAXENERGY")
        PlayerFrameManaBar:RegisterEvent("UNIT_DISPLAYPOWER")
    end
    PlayerFrame:Show()
    local oldThis = this
    this = PlayerFrame
    if PlayerFrame_Update then PlayerFrame_Update() end
    this = oldThis
end

function UF:SuppressTargetFrame()
    if TargetFrame then
        TargetFrame:Hide()
        TargetFrame:UnregisterAllEvents()
        if TargetFrameHealthBar then TargetFrameHealthBar:UnregisterAllEvents() end
        if TargetFrameManaBar then TargetFrameManaBar:UnregisterAllEvents() end
        if ComboFrame then ComboFrame:UnregisterAllEvents() end
    end
end

function UF:RestoreTargetFrame()
    if not TargetFrame then return end
    TargetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    TargetFrame:RegisterEvent("UNIT_HEALTH")
    TargetFrame:RegisterEvent("UNIT_LEVEL")
    TargetFrame:RegisterEvent("UNIT_FACTION")
    TargetFrame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
    TargetFrame:RegisterEvent("UNIT_AURA")
    TargetFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
    TargetFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    TargetFrame:RegisterEvent("RAID_TARGET_UPDATE")
    if TargetFrameHealthBar then
        TargetFrameHealthBar:RegisterEvent("UNIT_HEALTH")
        TargetFrameHealthBar:RegisterEvent("UNIT_MAXHEALTH")
    end
    if TargetFrameManaBar then
        TargetFrameManaBar:RegisterEvent("UNIT_MANA")
        TargetFrameManaBar:RegisterEvent("UNIT_RAGE")
        TargetFrameManaBar:RegisterEvent("UNIT_FOCUS")
        TargetFrameManaBar:RegisterEvent("UNIT_ENERGY")
        TargetFrameManaBar:RegisterEvent("UNIT_MAXMANA")
        TargetFrameManaBar:RegisterEvent("UNIT_MAXRAGE")
        TargetFrameManaBar:RegisterEvent("UNIT_MAXFOCUS")
        TargetFrameManaBar:RegisterEvent("UNIT_MAXENERGY")
        TargetFrameManaBar:RegisterEvent("UNIT_DISPLAYPOWER")
    end
    if ComboFrame then
        ComboFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        ComboFrame:RegisterEvent("PLAYER_COMBO_POINTS")
    end
    if UnitExists("target") then
        local oldThis = this
        this = TargetFrame
        TargetFrame:Show()
        if TargetFrame_Update then TargetFrame_Update() end
        if TargetFrame_CheckDead then TargetFrame_CheckDead() end
        if ComboFrame_Update then ComboFrame_Update() end
        this = oldThis
    else
        TargetFrame:Hide()
    end
end

function UF:SuppressPartyFrames()
    for i = 1, 4 do
        local pf = _G["PartyMemberFrame" .. i]
        if pf then
            pf:Hide()
            pf:UnregisterAllEvents()
        end
    end
end

function UF:RestorePartyFrames()
    for i = 1, 4 do
        local pf = _G["PartyMemberFrame" .. i]
        if pf and GetNumPartyMembers() >= i then
            local oldThis = this
            this = pf
            pf:Show()
            if PartyMemberFrame_UpdateMember then PartyMemberFrame_UpdateMember() end
            this = oldThis
        end
    end
end

function UF:ApplyConfiguration()
    -- Group/Raid Frames lifecycle (independent toggle via groupframe_dimensions.enabled)
    local groupDims = UF.GetGroupDimensions and UF:GetGroupDimensions()
    local raidEnabled = groupDims and groupDims.enabled
    if raidEnabled then
        UF:SuppressPartyFrames()
        if UF.EnableRaidFrames then UF:EnableRaidFrames() end
    else
        if UF.DisableRaidFrames then UF:DisableRaidFrames() end
        UF:RestorePartyFrames()
    end

    -- Player Frame
    if UF:IsModernPlayer() then
        UF:SuppressPlayerFrame()
        if UF.EnablePlayerFrame then UF:EnablePlayerFrame() end
    else
        if UF.DisablePlayerFrame then UF:DisablePlayerFrame() end
        UF:RestorePlayerFrame()
    end

    -- Target Frame
    if UF:IsModernTarget() then
        UF:SuppressTargetFrame()
        if UF.EnableTargetFrame then UF:EnableTargetFrame() end
    else
        if UF.DisableTargetFrame then UF:DisableTargetFrame() end
        UF:RestoreTargetFrame()
    end

    -- Target of Target
    if UF:IsModernToT() then
        if TargetofTargetFrame then TargetofTargetFrame:Hide() end
        if UF.EnableToTFrame then UF:EnableToTFrame() end
    else
        if UF.DisableToTFrame then UF:DisableToTFrame() end
        if TargetofTargetFrame then
            if TargetFrame and TargetFrame:IsShown() and UnitExists("targettarget") then
                local oldThis = this
                this = TargetofTargetFrame
                TargetofTargetFrame:Show()
                if TargetofTarget_Update then TargetofTarget_Update() end
                this = oldThis
            else
                TargetofTargetFrame:Hide()
            end
        end
    end

    -- Auras Live Refresh
    if UF.playerFrame and UF.playerFrame.auraContainer then
        if UF.playerFrame.auraContainer.buffFrame then
            if UF:IsShowPlayerBuffs() then
                UF.playerFrame.auraContainer.buffFrame:Show()
            else
                UF.playerFrame.auraContainer.buffFrame:Hide()
            end
        end
        if UF.playerFrame.auraContainer.debuffFrame then
            if UF:IsShowPlayerDebuffs() then
                UF.playerFrame.auraContainer.debuffFrame:Show()
            else
                UF.playerFrame.auraContainer.debuffFrame:Hide()
            end
        end
        if UF.Auras and UF.Auras.UpdateContainer then
            UF.Auras:UpdateContainer(UF.playerFrame.auraContainer)
        end
    end

    if UF.targetFrame and UF.targetFrame.auraContainer then
        if UF.targetFrame.auraContainer.buffFrame then
            if UF:IsShowTargetBuffs() then
                UF.targetFrame.auraContainer.buffFrame:Show()
            else
                UF.targetFrame.auraContainer.buffFrame:Hide()
            end
        end
        if UF.targetFrame.auraContainer.debuffFrame then
            if UF:IsShowTargetDebuffs() then
                UF.targetFrame.auraContainer.debuffFrame:Show()
            else
                UF.targetFrame.auraContainer.debuffFrame:Hide()
            end
        end
        if UF.Auras and UF.Auras.UpdateContainer then
            UF.Auras:UpdateContainer(UF.targetFrame.auraContainer)
        end
    end

    if UF.Auras and UF.Auras.UpdateBlizzTargetAuras then
        UF.Auras:UpdateBlizzTargetAuras()
    end
end

function UF:SuppressBlizzardFrames()
    nativeBlizzardSuppressed = true
    UF:ApplyConfiguration()
end

function UF:RestoreBlizzardFrames()
    nativeBlizzardSuppressed = false
    UF:RestorePlayerFrame()
    UF:RestoreTargetFrame()
    UF:RestorePartyFrames()
end

module.enable = function(self)
    UF.enabled = true
    UF:ApplyConfiguration()
end

-- Hook Blizzard frames so they respect user toggles
if PlayerFrame and FostercareTweaks.HookScript then
    FostercareTweaks.HookScript(PlayerFrame, "OnShow", function()
        if UF:IsModernPlayer() then PlayerFrame:Hide() end
    end)
end

if TargetFrame and FostercareTweaks.HookScript then
    FostercareTweaks.HookScript(TargetFrame, "OnShow", function()
        if UF:IsModernTarget() then
            TargetFrame:Hide()
        elseif UF.Auras and UF.Auras.UpdateBlizzTargetAuras then
            UF.Auras:UpdateBlizzTargetAuras()
        end
    end)
end

if TargetofTargetFrame and FostercareTweaks.HookScript then
    FostercareTweaks.HookScript(TargetofTargetFrame, "OnShow", function()
        if UF:IsModernToT() then TargetofTargetFrame:Hide() end
    end)
end

for i = 1, 4 do
    local pf = _G["PartyMemberFrame" .. i]
    if pf and FostercareTweaks.HookScript then
        FostercareTweaks.HookScript(pf, "OnShow", function()
            local groupDims = UF.GetGroupDimensions and UF:GetGroupDimensions()
            if groupDims and groupDims.enabled then this:Hide() end
        end)
    end
end

-- Guaranteed configuration initialization on PLAYER_LOGIN
local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function()
    UF:ApplyConfiguration()
end)
