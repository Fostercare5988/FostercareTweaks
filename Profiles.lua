local FT = FostercareTweaks
if not FT then return end

-- Layouts by zone: the open world, battlegrounds, and dungeons and raids each
-- keep their own frame positions, raid frames, aura sizes, raid marks, minimap
-- size and action bar layouts. The live settings always hold the active
-- layout; a switch stores them and loads the next one, after the loading
-- screen (or after combat). The extra rows' spells and items stay shared.
local module = FT:register({
    title = "Zone Layouts",
    enabled = true,
})

local KIND = { none = "world", pvp = "bg", arena = "bg", party = "instance", raid = "instance" }
FT.LAYOUT_NAMES = { world = "World", bg = "Battlegrounds", instance = "Dungeons and raids" }

-- Switches and overrides that belong to a layout.
local SWITCHES = { "Show Raid Buffs", "Show All Raid Buffs", "Show Raid Debuff Badges", "Show Raid HoT Indicator",
    "Show Raid Aggro Indicator", "Show Group Labels", "Show Player Buffs", "Show Player Debuffs",
    "Show Target Buffs", "Show Target Debuffs" }
local VALUES = { "raid_buff_count", "raid_buff_size", "raid_debuff_count", "raid_debuff_size", "raid_aura_spacing",
    "raid_health_format", "uf_buff_size", "uf_debuff_size", "raidmark_size", "raidmark_position", "minimap_scale" }

local function Copy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, inner in pairs(value) do copy[key] = Copy(inner) end
    return copy
end

-- The live layout as a stored record. Bar records leave out their actions.
local function Capture()
    local cfg = FostercareTweaks_Config
    local record = { switches = {}, values = {}, positions = Copy(cfg.unitframe_positions),
        group = Copy(cfg.groupframe_dimensions), bars = {} }
    for _, key in ipairs(SWITCHES) do record.switches[key] = cfg[key] end
    for _, key in ipairs(VALUES) do record.values[key] = cfg.overwrites[key] end
    local bars = type(cfg.actionbars) == "table" and cfg.actionbars or {}
    record.barsEnabled = bars.enabled
    for id, bar in pairs(type(bars.bars) == "table" and bars.bars or {}) do
        local copy = Copy(bar)
        copy.actions = nil
        record.bars[id] = copy
    end
    return record
end
FT.CaptureLayout = Capture

local function Load(record)
    local cfg = FostercareTweaks_Config
    for _, key in ipairs(SWITCHES) do cfg[key] = record.switches[key] end
    for _, key in ipairs(VALUES) do
        -- Every reader carries its own default, so nil is a real value here.
        cfg.overwrites[key] = record.values[key]
        if FT.overwrites then FT.overwrites[key] = record.values[key] end
    end
    cfg.unitframe_positions = Copy(record.positions)
    cfg.groupframe_dimensions = Copy(record.group)
    if type(cfg.actionbars) ~= "table" then cfg.actionbars = {} end
    local live = type(cfg.actionbars.bars) == "table" and cfg.actionbars.bars or {}
    local bars = {}
    for id, bar in pairs(record.bars) do bars[id] = Copy(bar) end
    for id, bar in pairs(live) do
        if bar.actions then
            bars[id] = bars[id] or {}
            bars[id].actions = bar.actions
        end
    end
    cfg.actionbars.bars = bars
    cfg.actionbars.enabled = record.barsEnabled
end

-- Puts the loaded layout on screen, module by module.
local function Show()
    local AB, UF = FT.ActionBars, FT.UnitFrames
    if AB then
        local enabled = FostercareTweaks_Config.actionbars.enabled == true
        if AB.enabled ~= enabled then AB:SetEnabled(enabled)
        else
            for _, bar in pairs(AB.bars) do bar.layoutDirty = true end
            AB:Apply()
        end
    end
    if FT.RestoreFramePositions then FT.RestoreFramePositions() end
    if UF then
        if UF.ApplyGroupDimensions then UF:ApplyGroupDimensions() end
        if UF.Auras then
            for _, key in ipairs({ "blizzPlayerAuras", "blizzTargetAuras" }) do
                UF.Auras:ApplyBuffSize(UF[key], UF:GetBuffSize())
                UF.Auras:ApplyDebuffSize(UF[key], UF:GetDebuffSize())
            end
        end
        UF:ApplyConfiguration()
        if UF.UpdateAllRaidFrames then UF:UpdateAllRaidFrames() end
    end
    if FT.ApplyMinimapScale then FT.ApplyMinimapScale(FT.GetNumber("minimap_scale", 1, 0.7, 1.6)) end
    FT:RefreshRaidMarks()
    if FT.RefreshSettings then FT.RefreshSettings() end
end

local waiting = CreateFrame("Frame")
local pending

function FT.SwitchLayout(name)
    local cfg = FostercareTweaks_Config
    if type(cfg.profiles) ~= "table" then cfg.profiles = {} end
    local active = cfg.profile
    if not active then cfg.profile = name; return end        -- the live layout is this one
    if name == active then return end
    -- Bars and frames are not rearranged in combat.
    if UnitAffectingCombat("player") then
        pending = name
        waiting:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    pending = nil
    cfg.profiles[active] = Capture()
    cfg.profile = name
    local record = cfg.profiles[name]
    if record then
        Load(record)
        Show()
    end
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff9e38FostercareTweaks:|r " .. FT.LAYOUT_NAMES[name] .. " layout.")
    end
end

-- The active layout goes to all three.
function FT.CopyLayoutToAll()
    local cfg = FostercareTweaks_Config
    cfg.profiles = {}
    for name in pairs(FT.LAYOUT_NAMES) do cfg.profiles[name] = Capture() end
end

function FT.ZoneLayout()
    local _, kind = GetInstanceInfo()
    return KIND[kind] or "world"
end

FT.SetEventHandler(waiting, function()
    waiting:UnregisterEvent("PLAYER_REGEN_ENABLED")
    if pending and FT.IsEnabled("Zone Layouts") then FT.SwitchLayout(pending) end
end)

module.enable = function()
    local zone = CreateFrame("Frame")
    zone:RegisterEvent("PLAYER_ENTERING_WORLD")
    FT.SetEventHandler(zone, function()
        if FT.IsEnabled("Zone Layouts") then FT.SwitchLayout(FT.ZoneLayout()) end
    end)
end
