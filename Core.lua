-- FostercareTweaks: Core.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Maintainer: Fostercare5988

-- Requires ClassicAPI and SuperWoW, checked as loaded; VanillaForge's
-- UPSTREAM_VERSIONS.json names the versions.
if type(CLASSIC_API_VERSION) ~= "number" or not SUPERWOW_VERSION then
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cffff2020[Fatal Error]|r FostercareTweaks requires ClassicAPI & SuperWoW! Please ensure both DLLs are loaded.",
            1, 0.2, 0.2
        )
    end
    return
end

local coreFrame = CreateFrame("Frame", "FostercareTweaksFrame", UIParent)
local FT = { mods = {}, moduleOrder = {} }
FostercareTweaks = FT

-- Component Registration
FT.register = function(self, mod)
    if not mod or not mod.title then return end
    if not self.mods[mod.title] then
        table.insert(self.moduleOrder, mod.title)
    end
    FT.mods[mod.title] = mod
    return mod
end

-- A character with no saved settings starts from Defaults.lua (the author's own
-- settings). Pixel positions that would fall outside this screen are left out, so
-- a smaller screen never gets a frame it cannot reach.
local function DeepCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, inner in pairs(value) do copy[key] = DeepCopy(inner) end
    return copy
end

local function NewConfig()
    local config = DeepCopy(FostercareTweaks_Defaults)
    if type(config) ~= "table" then return {} end
    local width, height = GetScreenWidth(), GetScreenHeight()
    local positions, minimapFits = config.unitframe_positions or {}, true
    for key, p in pairs(positions) do
        if not (math.abs(p.x) <= width - 20 and p.y > 20 - height and p.y < 150) then
            positions[key] = nil
            if string.find(key, "^minimap") then minimapFits = false end
        end
    end
    -- The minimap and its pieces (zone name, clock, icons) are one layout: all
    -- keep the author's places, or none do and they sit where the game puts them.
    if not minimapFits then
        for key in pairs(positions) do
            if string.find(key, "^minimap") then positions[key] = nil end
        end
    end
    for _, bar in pairs(config.actionbars and config.actionbars.bars or {}) do
        if bar.x and not (bar.y and bar.x >= 0 and bar.x <= width - 20 and bar.y >= 0 and bar.y <= height - 20) then
            bar.x, bar.y = nil, nil
        end
    end
    return config
end

local function EnsureSavedTables()
    if type(FostercareTweaks_Config) ~= "table" then FostercareTweaks_Config = NewConfig() end
    if type(FostercareTweaks_Config.overwrites) ~= "table" then FostercareTweaks_Config.overwrites = {} end
    if type(FostercareTweaks_Cache) ~= "table" then FostercareTweaks_Cache = {} end
end

-- ClassicAPI loads SavedVariables before source; modules also read them at load.
EnsureSavedTables()

-- The saved tables beside the switches, and who owns each.
local SAVED_TABLES = {
    overwrites = true,              -- numbers and choices (Helpers.lua)
    actionbars = true,              -- ActionBars.lua, ExtraActions.lua
    unitframe_positions = true,     -- moved frames (move-unitframes.lua)
    groupframe_dimensions = true,   -- the raid frames (unitframes/raid.lua)
    watched = true,                 -- watched-auras.lua
}

function FT:Initialize()
    if self.initialized then return end
    self.initialized = true
    EnsureSavedTables()
    -- A saved key nothing reads goes, on each character as it logs in: a switch
    -- is a module's title (FT:register), a setting in the overrides table is
    -- in FT.NUMBERS or FT.CHOICES, and SAVED_TABLES are the rest. A retired
    -- switch or setting needs no line of its own here.
    local config = FostercareTweaks_Config
    for key in pairs(config) do
        if not self.mods[key] and not SAVED_TABLES[key] then config[key] = nil end
    end
    for key in pairs(config.overwrites) do
        if not FT.NUMBERS[key] and FT.CHOICES[key] == nil then config.overwrites[key] = nil end
    end

    -- Prepare every default before dependent modules enable. TOC registration
    -- order defines layout and hook order; hash iteration must not decide it.
    for _, title in ipairs(self.moduleOrder) do
        local mod = self.mods[title]
        -- `always` modules have no switch, so they keep no saved key.
        if mod.always then
            FostercareTweaks_Config[title] = nil
        elseif FostercareTweaks_Config[title] == nil then
            FostercareTweaks_Config[title] = mod.enabled and 1 or 0
        end
    end
    for _, title in ipairs(self.moduleOrder) do
        local mod = self.mods[title]
        if (mod.always or FostercareTweaks_Config[title] == 1) and mod.enable then
            -- One module's error does not stop the others, and it reaches the
            -- error handler (!ErrorLog) with its stack.
            xpcall(function() mod:enable() end, geterrorhandler())
        end
    end
    self.ActionBars:Initialize()
end

-- Helpers load before either initialization event is delivered.
local function InitializeOnEvent(first, second)
    local ev = FT.EventArgs(first, second)
    if ev == "VARIABLES_LOADED" or ev == "PLAYER_LOGIN" then FT:Initialize() end
end

coreFrame:RegisterEvent("VARIABLES_LOADED")
coreFrame:RegisterEvent("PLAYER_LOGIN")
coreFrame:SetScript("OnEvent", InitializeOnEvent)

-- /ft opens the settings, or one page (/ft frames, auras, watched, raid, bars). /ft testraid
-- shows the sample raid grid; /ft resetuf puts moved frames back and reloads.
SLASH_FOSTERCARETWEAKS1 = "/ft"
SLASH_FOSTERCARETWEAKS2 = "/ftweaks"
SLASH_FOSTERCARETWEAKS3 = "/fostercaretweaks"
local PAGES = { general = "general", uf = "unit", unit = "unit", frames = "unit", auras = "auras",
    watched = "watched", raid = "raid", bars = "bars" }

SlashCmdList["FOSTERCARETWEAKS"] = function(msg)
    local cmd = string.lower(strsplittable(" ", msg or "")[1] or "")
    if cmd == "resetuf" then
        FostercareTweaks_Config.unitframe_positions = nil
        ReloadUI()
    elseif cmd == "testraid" then
        FT.UnitFrames:ToggleRaidTest()
    else
        FT.OpenSettings(PAGES[cmd])
    end
end
