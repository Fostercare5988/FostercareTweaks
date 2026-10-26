local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/unitframes/core.lua
-- Shared unit-frame settings, colors and bars for the improved auras on
-- Blizzard's player and target frames and for the party and raid frames.

for _, spec in ipairs({
    { "Show Player Buffs", "Player buffs under the player frame.", true },
    { "Show Target Buffs", "Target buffs under the target frame.", true },
    { "Show Player Debuffs", "Player debuffs under the player frame.", true },
    { "Show Target Debuffs", "Target debuffs under the target frame.", true },
    { "Show Raid Aggro Indicator", "A red corner on the member your enemy target attacks.", true },
    { "Show Raid HoT Indicator", "A corner icon for heals over time and shields.", true },
    { "Show Raid Debuff Badges", "Debuff icons inside raid members.", true },
}) do
    FT:register({ title = spec[1], description = spec[2], category = "Unit Frames", enabled = spec[3] })
end

FT.UnitFrames = FT.UnitFrames or {}
local UF = FT.UnitFrames

-- The Modern player, target and target-of-target frames were removed on
-- 2026-10-25 (no character used them). Clear their saved settings once.
function FT.MigrateFrameSettings()
    local cfg = FostercareTweaks_Config
    for _, key in ipairs({ "Show Aura Cooldown Spiral", "Show Aura Duration Text", "Unit Frames (Modern)",
        "Modern Player Frame", "Modern Target Frame", "Modern Combo Points", "Modern Target's Target",
        "Use Standard Player Frame", "Use Standard Target Frame", "Use Standard Target's Target",
        "Show PvP Emblem", "Show Target Level", "Show Target Class", "Show Unit Name",
        "Unit Frame Class Portraits", "Larger Armor Debuffs" }) do
        cfg[key] = nil
    end
    for _, key in ipairs({ "uf_scale", "uf_player_width", "uf_player_height", "uf_target_width",
        "uf_target_height", "uf_tot_width", "uf_tot_height", "uf_power_height", "uf_font_name",
        "uf_font_level", "uf_font_health", "uf_font_power", "uf_health_format", "uf_power_format",
        "uf_aura_size", "uf_armor_debuff_scale" }) do
        cfg.overwrites[key] = nil
    end
    local positions = cfg.unitframe_positions
    if type(positions) == "table" then
        for _, key in ipairs({ "player", "target", "targettarget", "modern_player_buffs",
            "modern_player_debuffs", "modern_target_buffs", "modern_target_debuffs" }) do positions[key] = nil end
    end
end

-- Settings ---------------------------------------------------------------------

function UF:IsShowPlayerBuffs() return FT.IsEnabled("Show Player Buffs", true) end
function UF:IsShowTargetBuffs() return FT.IsEnabled("Show Target Buffs", true) end
function UF:IsShowPlayerDebuffs() return FT.IsEnabled("Show Player Debuffs", true) end
function UF:IsShowTargetDebuffs() return FT.IsEnabled("Show Target Debuffs", true) end
function UF:IsRaidShowAggro() return FT.IsEnabled("Show Raid Aggro Indicator", true) end
function UF:IsRaidShowHoT() return FT.IsEnabled("Show Raid HoT Indicator", true) end
function UF:IsRaidShowDebuffs() return FT.IsEnabled("Show Raid Debuff Badges", true) end
function UF:GetBuffSize() return FT.GetNumber("uf_buff_size", 20, 14, 32) end
function UF:GetDebuffSize() return FT.GetNumber("uf_debuff_size", 20, 14, 32) end
function UF:GetRaidHealthFormat() return FT.GetOverride("raid_health_format", "deficit") end

UF.GetUnitHealthValues = FT.GetUnitHealthValues

function UF.SetFontSize(fontString, size)
    if not fontString or not size then return end
    local fontFile, currentSize, flags = fontString:GetFont()
    if currentSize == size then return end
    fontString:SetFont(fontFile or "Fonts\\FRIZQT__.TTF", size, flags or "")
end

-- Look -------------------------------------------------------------------------

-- Solid black border and fill (Luna style).
UF.backdrop = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
}
UF.backdropBorderColor = { 0.00, 0.00, 0.00, 1.00 }

-- Luna Unit Frames class, power and dispel colors.
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
UF.PowerColors = {
    [0] = { r = 0.30, g = 0.50, b = 0.85 }, -- MANA
    [1] = { r = 0.90, g = 0.20, b = 0.30 }, -- RAGE
    [2] = { r = 1.00, g = 0.50, b = 0.25 }, -- FOCUS
    [3] = { r = 1.00, g = 0.85, b = 0.10 }, -- ENERGY
}
UF.DispelColors = {
    ["Magic"]   = { r = 0.20, g = 0.60, b = 1.00 },
    ["Curse"]   = { r = 0.60, g = 0.00, b = 1.00 },
    ["Disease"] = { r = 0.60, g = 0.40, b = 0.00 },
    ["Poison"]  = { r = 0.00, g = 0.60, b = 0.00 },
    ["None"]    = { r = 0.60, g = 0.15, b = 0.15 },
}

local BAR_TEXTURE = "Interface\\AddOns\\FostercareTweaks\\img\\bar-luna.tga"

-- The bar's background follows its fill at a fifth of the brightness.
local function SetBarColor(bar, r, g, b, a)
    a = a or 1
    if bar.fillR == r and bar.fillG == g and bar.fillB == b and bar.fillA == a then return end
    bar.fillR, bar.fillG, bar.fillB, bar.fillA = r, g, b, a
    bar:SetStatusBarColorNative(r, g, b, a)
    bar.bg:SetVertexColor(r * 0.2, g * 0.2, b * 0.2, 1)
end

-- The engine's own StatusBar draws the fill; ClassicAPI gives it reverse fill
-- and fill styles, which the old Lua-drawn bar existed for.
function UF:CreateBar(name, parent)
    local bar = CreateFrame("StatusBar", name, parent)
    bar:SetStatusBarTexture(BAR_TEXTURE)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints(bar)
    bar.bg:SetTexture(BAR_TEXTURE)
    bar.bg:SetVertexColor(0.08, 0.08, 0.08, 1)
    bar.SetStatusBarColorNative = bar.SetStatusBarColor
    bar.SetStatusBarColor = SetBarColor
    return bar
end

-- Party frames -----------------------------------------------------------------

function UF:SuppressPartyFrames()
    for i = 1, 4 do
        local pf = _G["PartyMemberFrame" .. i]
        if pf then pf:Hide() end
    end
end

function UF:RestorePartyFrames()
    -- The compact native grid owns party visibility when it replaces party UI.
    if GROUP_ENABLED == "1" and GROUP_REPLACE_PARTY == "1" and GroupFrame then return end
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

for i = 1, 4 do
    local pf = _G["PartyMemberFrame" .. i]
    if pf then
        FT.HookScript(pf, "OnShow", function(frame)
            local groupDims = UF.GetGroupDimensions and UF:GetGroupDimensions()
            if groupDims and groupDims.enabled then frame:Hide() end
        end)
    end
end

-- Applying settings --------------------------------------------------------------

function UF:ApplyConfiguration()
    local tick = FT.mods["Show Energy Ticks"]
    if tick and FostercareTweaks_Config["Show Energy Ticks"] ~= 0 then tick:enable() end
    local cast = FT.mods["Enemy Castbars"]
    if cast and FostercareTweaks_Config["Enemy Castbars"] ~= 0 then cast:enable() end

    -- One grid serves party and raid; its own switch lives in groupframe_dimensions.
    if UF:GetGroupDimensions().enabled then
        UF:SuppressPartyFrames()
        UF:EnableRaidFrames()
    else
        UF:DisableRaidFrames()
        UF:RestorePartyFrames()
    end

    if UF.Auras then
        UF.Auras:UpdateBlizzTargetAuras()
        UF.Auras:UpdateBlizzPlayerAuras()
    end
    if FT.RefreshEnergyTick then FT.RefreshEnergyTick() end
    if FT.RefreshTargetCastbar then FT.RefreshTargetCastbar() end
end

if TargetFrame then
    FT.HookScript(TargetFrame, "OnShow", function()
        if UF.Auras then UF.Auras:UpdateBlizzTargetAuras() end
    end)
end

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
FT.SetEventHandler(loginFrame, function() UF:ApplyConfiguration() end)
