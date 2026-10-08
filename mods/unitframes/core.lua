local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/unitframes/core.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Modern Unit Frames Subsystem: Core Foundation


local module = FT:register({
    title = "Unit Frames (Modern)",
    description = "Modern unit frames for Player and Target inspired by Luna Unit Frames, backed by enhanced client APIs.",
    category = "Unit Frames",
    enabled = false,
    config = {
        ["uf_scale"] = 1.0,
    }
})

-- Positive modern unit frame toggles (disabled by default for new users)
FT:register({
    title = "Modern Player Frame",
    description = "Enable the modern FostercareTweaks player unit frame instead of the default Blizzard frame.",
    category = "Unit Frames",
    enabled = false,
})

FT:register({
    title = "Modern Target Frame",
    description = "Enable the modern FostercareTweaks target unit frame instead of the default Blizzard frame.",
    category = "Unit Frames",
    enabled = false,
})

FT:register({
    title = "Modern Combo Points",
    description = "Display combo points on the modern target unit frame.",
    category = "Unit Frames",
    enabled = true,
})

FT:register({
    title = "Modern Target's Target",
    description = "Enable the modern FostercareTweaks Target of Target frame instead of the standard Blizzard frame.",
    category = "Unit Frames",
    enabled = false,
})

FT:register({
    title = "Show PvP Emblem",
    description = "Display faction PvP emblem on modern unit frames.",
    category = "Unit Frames",
    enabled = true,
})

FT:register({
    title = "Show Target Level",
    description = "Display target level and difficulty color on the modern target frame.",
    category = "Unit Frames",
    enabled = true,
})

FT:register({
    title = "Show Target Class",
    description = "Display target class or creature type on the modern target frame.",
    category = "Unit Frames",
    enabled = false,
})

FT:register({
    title = "Show Unit Name",
    description = "Display unit name text on modern unit frames.",
    category = "Unit Frames",
    enabled = true,
})

FT:register({
    title = "Improved Standard Auras",
    description = "Display enhanced buffs and debuffs with timers, spirals and dispel borders on standard Blizzard frames.",
    category = "Unit Frames",
    enabled = true,
})

-- Granular toggles for modern aura visibility and configuration
FT:register({
    title = "Show Player Buffs",
    description = "Display buff icons above the modern player unit frame.",
    category = "Unit Frames",
    enabled = true,
})

FT:register({
    title = "Show Target Buffs",
    description = "Display buff icons above the modern target unit frame.",
    category = "Unit Frames",
    enabled = true,
})

FT:register({
    title = "Show Player Debuffs",
    description = "Display debuff icons on the modern player unit frame.",
    category = "Unit Frames",
    enabled = true,
})

FT:register({
    title = "Show Target Debuffs",
    description = "Display debuff icons below the modern target unit frame.",
    category = "Unit Frames",
    enabled = true,
})

FT:register({
    title = "Show Buff Cooldown Spiral",
    description = "Display the radial cooldown sweep on unit frame buffs.",
    category = "Unit Frames",
    enabled = true,
})

FT:register({
    title = "Show Buff Duration Text",
    description = "Display remaining time numbers on unit frame buffs.",
    category = "Unit Frames",
    enabled = true,
})

FT:register({
    title = "Show Debuff Cooldown Spiral",
    description = "Display the radial cooldown sweep on unit frame debuffs.",
    category = "Unit Frames",
    enabled = true,
})

FT:register({
    title = "Show Debuff Duration Text",
    description = "Display remaining time numbers on unit frame debuffs.",
    category = "Unit Frames",
    enabled = true,
})

FT:register({
    title = "Color Debuffs by Dispel Type",
    description = "Color debuff borders by magic, curse, disease, or poison.",
    category = "Unit Frames",
    enabled = true,
})

FT:register({
    title = "Only Show My Debuffs on Target",
    description = "Only show debuffs cast by you on the target unit frame.",
    category = "Unit Frames",
    enabled = false,
})

FT:register({
    title = "Show Raid Aggro Indicator",
    description = "Show a red indicator box on group/raid frames when a member has aggro.",
    category = "Unit Frames",
    enabled = true,
})

FT:register({
    title = "Show Raid HoT Indicator",
    description = "Show corner status indicators for active healing over time buffs.",
    category = "Unit Frames",
    enabled = true,
})

FT:register({
    title = "Show Raid Debuff Badges",
    description = "Show compact debuff icons on group/raid frames.",
    category = "Unit Frames",
    enabled = true,
})

FT.UnitFrames = FT.UnitFrames or {}
local UF = FT.UnitFrames
UF.module = module
UF.frames = {}

-- Translate old combined/inverted settings before Core fills new defaults.
function FT.MigrateFrameSettings()
    local cfg = FostercareTweaks_Config
    local aliases = {
        ["Use Standard Player Frame"] = "Modern Player Frame",
        ["Use Standard Target Frame"] = "Modern Target Frame",
        ["Use Standard Target's Target"] = "Modern Target's Target",
    }
    for old, new in pairs(aliases) do
        if cfg[new] == nil and cfg[old] ~= nil then cfg[new] = cfg[old] == 0 and 1 or 0 end
    end
    for _, kind in ipairs({"Buff", "Debuff"}) do
        for _, suffix in ipairs({"Cooldown Spiral", "Duration Text"}) do
            local old, new = "Show Aura " .. suffix, "Show " .. kind .. " " .. suffix
            if cfg[new] == nil and cfg[old] ~= nil then cfg[new] = cfg[old] end
        end
    end
end


function UF:IsModernPlayer()
    if not FostercareTweaks_Config then return false end
    if FostercareTweaks_Config["Modern Player Frame"] ~= nil then
        return FostercareTweaks_Config["Modern Player Frame"] == 1
    end
    if FostercareTweaks_Config["Use Standard Player Frame"] ~= nil then
        return FostercareTweaks_Config["Use Standard Player Frame"] == 0
    end
    return false
end

function UF:IsModernTarget()
    if not FostercareTweaks_Config then return false end
    if FostercareTweaks_Config["Modern Target Frame"] ~= nil then
        return FostercareTweaks_Config["Modern Target Frame"] == 1
    end
    if FostercareTweaks_Config["Use Standard Target Frame"] ~= nil then
        return FostercareTweaks_Config["Use Standard Target Frame"] == 0
    end
    return false
end

function UF:IsModernComboPoints()
    return FT.IsEnabled("Modern Combo Points", true)
end

function UF:IsModernToT()
    if not FostercareTweaks_Config then return false end
    if FostercareTweaks_Config["Modern Target's Target"] ~= nil then
        return FostercareTweaks_Config["Modern Target's Target"] == 1
    end
    if FostercareTweaks_Config["Use Standard Target's Target"] ~= nil then
        return FostercareTweaks_Config["Use Standard Target's Target"] == 0
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

function UF:IsShowPvP()
    return FT.IsEnabled("Show PvP Emblem", true)
end

function UF:IsShowLevel()
    return FT.IsEnabled("Show Target Level", true)
end

function UF:IsShowClass()
    return FT.IsEnabled("Show Target Class", false)
end

function UF:IsShowName()
    return FT.IsEnabled("Show Unit Name", true)
end

function UF:GetHealthFormat()
    local val = FostercareTweaks_Config and FostercareTweaks_Config.overwrites and FostercareTweaks_Config.overwrites["uf_health_format"]
    if not val and FT.overwrites then
        val = FT.overwrites["uf_health_format"]
    end
    return val or "smart"
end

function UF:GetPowerFormat()
    local val = FostercareTweaks_Config and FostercareTweaks_Config.overwrites and FostercareTweaks_Config.overwrites["uf_power_format"]
    if not val and FT.overwrites then
        val = FT.overwrites["uf_power_format"]
    end
    return val or "smart"
end

function UF.FormatHealthText(cur, max)
    if not cur or not max or max <= 0 then return "" end
    local fmt = UF:GetHealthFormat()
    if fmt == "none" then
        return ""
    elseif fmt == "current" then
        return FT.Abbreviate(cur)
    elseif fmt == "percent" then
        local pct = math.floor((cur / max) * 100)
        return pct .. "%"
    elseif fmt == "deficit" then
        local def = max - cur
        if def > 0 then
            return "-" .. FT.Abbreviate(def)
        else
            return ""
        end
    else -- "smart" / "current_max"
        local curStr = FT.Abbreviate(cur)
        if cur == max then
            return curStr
        else
            return curStr .. " / " .. FT.Abbreviate(max)
        end
    end
end

function UF.FormatPowerText(cur, max, powerType)
    if not cur then return "" end
    local fmt = UF:GetPowerFormat()
    if fmt == "none" then
        return ""
    end
    -- Smart format uses current energy/rage; explicit formats apply to all resources.
    if fmt == "smart" and (powerType == 1 or powerType == 3) then
        return tostring(cur)
    end
    if not max or max <= 0 then return tostring(cur) end
    if fmt == "current" then
        return FT.Abbreviate(cur)
    elseif fmt == "percent" then
        local pct = math.floor((cur / max) * 100)
        return pct .. "%"
    else -- "smart"
        local curStr = FT.Abbreviate(cur)
        if cur == max then
            return curStr
        else
            return curStr .. " / " .. FT.Abbreviate(max)
        end
    end
end

function UF:GetPlayerWidth()
    return FT.GetNumber("uf_player_width", 200, 140, 350)
end

function UF:GetPlayerHeight()
    return FT.GetNumber("uf_player_height", 42, 30, 80)
end

function UF:GetTargetWidth()
    return FT.GetNumber("uf_target_width", 200, 140, 350)
end

function UF:GetTargetHeight()
    return FT.GetNumber("uf_target_height", 42, 30, 80)
end

function UF:GetToTWidth()
    return FT.GetNumber("uf_tot_width", 120, 80, 220)
end

function UF:GetToTHeight()
    return FT.GetNumber("uf_tot_height", 26, 20, 50)
end

function UF:GetPowerHeight()
    return FT.GetNumber("uf_power_height", 10, 4, 20)
end

function UF:GetFontNameSize()
    return FT.GetNumber("uf_font_name", 12, 8, 20)
end

function UF:GetFontLevelSize()
    return FT.GetNumber("uf_font_level", 11, 8, 20)
end

function UF:GetFontHealthSize()
    return FT.GetNumber("uf_font_health", 11, 8, 20)
end

function UF:GetFontPowerSize()
    return FT.GetNumber("uf_font_power", 11, 8, 20)
end

function UF.SetFontSize(fontString, size)
    if not fontString or not size then return end
    local fontFile, currentSize, flags = fontString:GetFont()
    if currentSize == size then return end
    if not fontFile or fontFile == "" then
        fontFile = "Fonts\\FRIZQT__.TTF"
    end
    fontString:SetFont(fontFile, size, flags or "")
end

function UF:ApplyDimensions()
    if UF.playerFrame then
        local w = UF:GetPlayerWidth()
        local h = UF:GetPlayerHeight()
        UF.playerFrame:SetWidth(w)
        UF.playerFrame:SetHeight(h)
        UF:LayoutBars(UF.playerFrame)
    end
    if UF.targetFrame then
        local w = UF:GetTargetWidth()
        local h = UF:GetTargetHeight()
        UF.targetFrame:SetWidth(w)
        UF.targetFrame:SetHeight(h)
        UF:LayoutBars(UF.targetFrame)
    end
    if UF.totFrame then
        local w = UF:GetToTWidth()
        local h = UF:GetToTHeight()
        UF.totFrame:SetWidth(w)
        UF.totFrame:SetHeight(h)
        UF:LayoutBars(UF.totFrame)
    end
end

function UF:ApplyFonts()
    local nameSize = UF:GetFontNameSize()
    local levelSize = UF:GetFontLevelSize()
    local healthSize = UF:GetFontHealthSize()
    local powerSize = UF:GetFontPowerSize()

    if UF.playerFrame then
        local hb = UF.playerFrame.healthBar
        if hb then
            if hb.nameText then UF.SetFontSize(hb.nameText, nameSize) end
            if hb.levelText then UF.SetFontSize(hb.levelText, levelSize) end
            if hb.healthText then UF.SetFontSize(hb.healthText, healthSize) end
        end
        local pb = UF.playerFrame.powerBar
        if pb and pb.powerText then
            UF.SetFontSize(pb.powerText, powerSize)
        end
    end

    if UF.targetFrame then
        local hb = UF.targetFrame.healthBar
        if hb then
            if hb.nameText then UF.SetFontSize(hb.nameText, nameSize) end
            if hb.levelText then UF.SetFontSize(hb.levelText, levelSize) end
            if hb.healthText then UF.SetFontSize(hb.healthText, healthSize) end
        end
        local pb = UF.targetFrame.powerBar
        if pb then
            if pb.leftText then UF.SetFontSize(pb.leftText, levelSize) end
            if pb.powerText then UF.SetFontSize(pb.powerText, powerSize) end
        end
    end

    if UF.totFrame then
        local hb = UF.totFrame.healthBar
        if hb then
            if hb.nameText then UF.SetFontSize(hb.nameText, math.max(8, nameSize - 1)) end
            if hb.healthText then UF.SetFontSize(hb.healthText, math.max(8, healthSize - 1)) end
        end
    end
    for _, frame in pairs(UF.frames) do UF:LayoutText(frame) end
end

-- Bound every text lane, then fit the requested font to its actual height/width.
-- Names may truncate; numeric and status text shrink only to a readable 8 px.
local function FitText(text, width, height, requested, fitWidth)
    if not text then return end
    width, height = math.max(1, width), math.max(1, height)
    local size = math.max(8, math.min(requested, height))
    UF.SetFontSize(text, size)
    if fitWidth then
        while size > 8 and text:GetStringWidth() > width do
            size = size - 1
            UF.SetFontSize(text, size)
        end
    end
    text:SetWidth(width)
    text:SetHeight(height)
end

function UF:LayoutText(frame)
    local hb, pb = frame.healthBar, frame.powerBar
    if not hb or not hb.nameText or not hb.healthText then return end
    local width, height = hb:GetWidth() - 8, hb:GetHeight() - 2
    local rows = height >= 18
    local rowH = rows and math.floor(height / 2) or height
    local classText = pb and pb.leftText
    local hasClass = rows and classText and classText:GetText() and classText:GetText() ~= ""
    local healthW = hasClass and math.floor(width * 0.6) or (rows and width or math.floor(width * 0.55))
    hb.nameText:ClearAllPoints()
    hb.nameText:SetPoint(rows and "TOPLEFT" or "LEFT", hb, rows and "TOPLEFT" or "LEFT", 4, rows and -1 or 0)
    FitText(hb.nameText, rows and width or width - healthW - 3, rowH, UF:GetFontNameSize(), false)
    hb.healthText:ClearAllPoints()
    hb.healthText:SetPoint(rows and "BOTTOMRIGHT" or "RIGHT", hb, rows and "BOTTOMRIGHT" or "RIGHT", -4, rows and 1 or 0)
    FitText(hb.healthText, healthW, rowH, UF:GetFontHealthSize(), true)
    if classText then
        classText:ClearAllPoints()
        classText:SetPoint("BOTTOMLEFT", hb, "BOTTOMLEFT", 4, 1)
        FitText(classText, math.max(1, width - healthW - 3), rowH, UF:GetFontLevelSize(), false)
        if hasClass then classText:Show() else classText:Hide() end
    end
    if pb and pb.powerText then
        FitText(pb.powerText, pb:GetWidth() - 8, pb:GetHeight(), UF:GetFontPowerSize(), true)
        if pb:GetHeight() >= 8 then pb.powerText:Show() else pb.powerText:Hide() end
    end
    if frame.levelBadge then
        local badge = frame.levelBadge
        local side = frame.portrait:GetWidth()
        local size = math.min(UF:GetFontLevelSize(), math.max(8, side - 18))
        UF.SetFontSize(badge.text, size)
        badge:SetWidth(math.min(side, math.max(20, badge.text:GetStringWidth() + 6)))
        badge:SetHeight(math.min(side, size + 4))
        if badge.skull then
            local skullSize = math.min(14, badge:GetHeight() - 2)
            badge.skull:SetWidth(skullSize); badge.skull:SetHeight(skullSize)
        end
        badge:ClearAllPoints()
        local anchor = frame.portraitSide == "left" and "BOTTOMLEFT" or "BOTTOMRIGHT"
        badge:SetPoint(anchor, frame.portrait, anchor, 0, 0)
    end
end

function UF:IsImprovedStandardAuras()
    return FT.IsEnabled("Improved Standard Auras", true)
end

function UF:IsShowPlayerBuffs()
    return FT.IsEnabled("Show Player Buffs", true)
end

function UF:IsShowTargetBuffs()
    return FT.IsEnabled("Show Target Buffs", true)
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
    local val = FostercareTweaks_Config["Show Buff Cooldown Spiral"]
    if val == nil then
        val = FostercareTweaks_Config["Show Aura Cooldown Spiral"]
    end
    if val == nil then return true end
    return val == 1
end

function UF:IsBuffText()
    if not FostercareTweaks_Config then return true end
    local val = FostercareTweaks_Config["Show Buff Duration Text"]
    if val == nil then
        val = FostercareTweaks_Config["Show Aura Duration Text"]
    end
    if val == nil then return true end
    return val == 1
end

function UF:IsShowPlayerDebuffs()
    return FT.IsEnabled("Show Player Debuffs", true)
end

function UF:IsShowTargetDebuffs()
    return FT.IsEnabled("Show Target Debuffs", true)
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
    local val = FostercareTweaks_Config["Show Debuff Cooldown Spiral"]
    if val == nil then
        val = FostercareTweaks_Config["Show Aura Cooldown Spiral"]
    end
    if val == nil then return true end
    return val == 1
end

function UF:IsDebuffText()
    if not FostercareTweaks_Config then return true end
    local val = FostercareTweaks_Config["Show Debuff Duration Text"]
    if val == nil then
        val = FostercareTweaks_Config["Show Aura Duration Text"]
    end
    if val == nil then return true end
    return val == 1
end

function UF:IsColorDebuffsByDispel()
    return FT.IsEnabled("Color Debuffs by Dispel Type", true)
end

function UF:IsOnlyMyDebuffs()
    return FT.IsEnabled("Only Show My Debuffs on Target", false)
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
    return FT.IsEnabled("Show Raid Aggro Indicator", true)
end

function UF:IsRaidShowHoT()
    return FT.IsEnabled("Show Raid HoT Indicator", true)
end

function UF:IsRaidShowDebuffs()
    return FT.IsEnabled("Show Raid Debuff Badges", true)
end

function UF:GetScale()
    return FT.GetNumber("uf_scale", 1, 0.5, 2)
end

function UF:ApplyScale(scale)
    scale = FT.ClampNumber(scale, UF:GetScale(), 0.5, 2)
    if UF.playerFrame then UF.playerFrame:SetScale(scale) end
    if UF.targetFrame then UF.targetFrame:SetScale(scale) end
    if UF.totFrame then UF.totFrame:SetScale(scale) end
    if FT.RefreshEnergyTick then FT.RefreshEnergyTick() end
    if FT.LayoutTargetCastbar then FT.LayoutTargetCastbar() end
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
    if self.minV == minV and self.maxV == maxV then return end
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
    local bgOverride = self.bg and self.bg.overrideColor
    if self.fillR == r and self.fillG == g and self.fillB == b and self.fillAlpha == alpha and
        self.bgOverride == bgOverride then return end
    self.fillR, self.fillG, self.fillB, self.fillAlpha = r, g, b, alpha
    self.bgOverride = bgOverride
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
    local reverse = value and true or nil
    if self.reverse == reverse then return end
    self.reverse = reverse
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

    local totalW = frame:GetWidth() or 200
    local totalH = frame:GetHeight() or 42
    local borderInset = 1
    local innerW = totalW - (borderInset * 2)
    local innerH = totalH - (borderInset * 2)

    local barXOffset = borderInset
    local barW = innerW

    -- Handle portrait positioning
    if frame.portrait and frame.portrait:IsShown() then
        -- Tall/narrow frames still need enough horizontal space for text.
        local portraitSize = math.min(innerH, math.floor(innerW * 0.3))
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

        if frame.comboFrame then
            local pSize = frame.portrait:GetWidth() or portraitSize
            if pSize and pSize >= 35 and frame.comboFrame.pips then
                frame.comboFrame:SetWidth(pSize)
                local pipSpacing = 1
                local totalSpacing = (5 - 1) * pipSpacing
                local availablePipW = pSize - 2 - totalSpacing
                local pipW = math.floor(availablePipW / 5)
                if pipW < 4 then pipW = 4 end
                for i = 1, 5 do
                    local pip = frame.comboFrame.pips[i]
                    if pip then
                        pip:SetWidth(pipW)
                        pip:SetPoint("LEFT", frame.comboFrame, "LEFT", 1 + (i - 1) * (pipW + pipSpacing), 0)
                    end
                end
            end
        end
    end

    -- Stack health and power bars
    local powerShown = frame.powerBar and frame.powerBar:IsShown()
    local separator = 1

    if powerShown then
        local availH = innerH - separator
        local powerH = UF:GetPowerHeight()
        local minHealthH = frame.unit == "targettarget" and 14 or 20
        if powerH > availH - minHealthH then
            powerH = math.max(4, availH - minHealthH)
        end
        local healthH = math.max(4, availH - powerH)

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
    UF:LayoutText(frame)
end

--------------------------------------------------------------------------------
-- 3. Authoritative Health Query (native / SuperWoW)
--------------------------------------------------------------------------------

UF.GetUnitHealthValues = FT.GetUnitHealthValues

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

    if FT.RegisterFrameMover then
        FT.RegisterFrameMover(frame, unit, unit == "player" and "Player" or (unit == "targettarget" and "Target of Target" or "Target"))
    end
    table.insert(UF.frames, frame)
    return frame
end

--------------------------------------------------------------------------------
-- 5. Subsystem Lifecycle & Native Blizzard Frame Suppression
--------------------------------------------------------------------------------


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
        if ComboFrame then
            ComboFrame:Hide()
            ComboFrame:UnregisterAllEvents()
        end
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
        if ComboFrame_Update then
            ComboFrame_Update()
        elseif ComboPointsFrame_OnEvent then
            ComboPointsFrame_OnEvent()
        end
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
    UF.enabled = true
    local tick = FT.mods["Show Energy Ticks"]
    if tick and FostercareTweaks_Config["Show Energy Ticks"] ~= 0 then tick:enable() end
    local cast = FT.mods["Enemy Castbars"]
    if cast and FostercareTweaks_Config["Enemy Castbars"] ~= 0 then cast:enable() end
    -- Dimensions & Fonts Live Application
    if UF.ApplyDimensions then UF:ApplyDimensions() end
    if UF.ApplyFonts then UF:ApplyFonts() end

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
        if UF.playerFrame and UF.playerFrame:IsShown() then
            if UF.UpdatePlayerPvP then UF.UpdatePlayerPvP(UF.playerFrame) end
            if UF.UpdatePlayerHealth then UF.UpdatePlayerHealth(UF.playerFrame) end
            if UF.UpdatePlayerPower then UF.UpdatePlayerPower(UF.playerFrame) end
        end
    else
        if UF.DisablePlayerFrame then UF:DisablePlayerFrame() end
        UF:RestorePlayerFrame()
    end

    -- Target Frame
    if UF:IsModernTarget() then
        UF:SuppressTargetFrame()
        if UF.EnableTargetFrame then UF:EnableTargetFrame() end
        if UF.targetFrame and UF.targetFrame:IsShown() then
            if UF.UpdateTargetPvP then UF.UpdateTargetPvP(UF.targetFrame) end
            if UF.UpdateTargetHealth then UF.UpdateTargetHealth(UF.targetFrame) end
            if UF.UpdateTargetPower then UF.UpdateTargetPower(UF.targetFrame) end
            if UF.UpdateComboPoints then UF.UpdateComboPoints(UF.targetFrame) end
            if UF.UpdateRaidTarget then UF.UpdateRaidTarget(UF.targetFrame) end
        end
    else
        if UF.DisableTargetFrame then UF:DisableTargetFrame() end
        UF:RestoreTargetFrame()
    end

    -- Target of Target
    if UF:IsModernToT() then
        if TargetofTargetFrame then TargetofTargetFrame:Hide() end
        if UF.EnableToTFrame then UF:EnableToTFrame() end
        if UF.totFrame and UF.totFrame:IsShown() then
            if UF.UpdateToTHealth then UF.UpdateToTHealth(UF.totFrame) end
            if UF.UpdateToTPower then UF.UpdateToTPower(UF.totFrame) end
        end
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
        UF.Auras:UpdateBlizzPlayerAuras()
    end
    local movement = FT.mods["Movable Unit Frames"]
    if movement and FostercareTweaks_Config["Movable Unit Frames"] ~= 0 then
        movement:enable()
    elseif FT.UpdateFrameMovers then
        FT.UpdateFrameMovers()
    end
    if FT.RefreshEnergyTick then FT.RefreshEnergyTick() end
    if FT.RefreshTargetCastbar then FT.RefreshTargetCastbar() end
end

function UF:SuppressBlizzardFrames()
    UF:ApplyConfiguration()
end

function UF:RestoreBlizzardFrames()
    UF:RestorePlayerFrame()
    UF:RestoreTargetFrame()
    UF:RestorePartyFrames()
end

module.enable = function(self)
    UF.enabled = true
    UF:ApplyConfiguration()
end

-- Hook Blizzard frames so they respect user toggles
if PlayerFrame then
    FT.HookScript(PlayerFrame, "OnShow", function(frame)
        if UF:IsModernPlayer() then frame:Hide() end
    end)
end

if TargetFrame then
    FT.HookScript(TargetFrame, "OnShow", function(frame)
        if UF:IsModernTarget() then
            frame:Hide()
        elseif UF.Auras and UF.Auras.UpdateBlizzTargetAuras then
            UF.Auras:UpdateBlizzTargetAuras()
        end
    end)
end

if TargetofTargetFrame then
    FT.HookScript(TargetofTargetFrame, "OnShow", function(frame)
        if UF:IsModernToT() then frame:Hide() end
    end)
end

for i = 1, 4 do
    local pf = _G["PartyMemberFrame" .. i]
    if pf then
        FT.HookScript(pf, "OnShow", function(frame)
            local groupDims = UF.GetGroupDimensions and UF:GetGroupDimensions()
            if groupDims and groupDims.enabled then frame:Hide() end
        end)
    end
end

-- Guaranteed configuration initialization on PLAYER_LOGIN
local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
FT.SetEventHandler(loginFrame, function()
    UF:ApplyConfiguration()
end)
