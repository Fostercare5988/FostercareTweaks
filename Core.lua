-- FostercareTweaks: Core.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Maintainer: Fostercare5988

-- Requires ClassicAPI 1.17.11+ (UNIT_AURA_DELTA, Cooldown methods) and SuperWoW 2.2+.
local MIN_CLASSIC_API = 11711
local superMajor, superMinor = string.match(tostring(SUPERWOW_VERSION or ""), "^(%d+)%.(%d+)")
superMajor, superMinor = tonumber(superMajor), tonumber(superMinor)
local hasSuperWoW = superMajor and (superMajor > 2 or (superMajor == 2 and superMinor >= 2))

if type(CLASSIC_API_VERSION) ~= "number" or not hasSuperWoW or
   CLASSIC_API_VERSION < MIN_CLASSIC_API then
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cffff2020[Fatal Error]|r FostercareTweaks requires ClassicAPI (v1.17.11+) & SuperWoW (v2.2+)! Please ensure both DLLs are loaded.",
            1, 0.2, 0.2
        )
    end
    return
end

local coreFrame = CreateFrame("Frame", "FostercareTweaksFrame", UIParent)
local FT = { mods = {}, moduleOrder = {}, overwrites = {} }
FostercareTweaks = FT

-- Component Registration
FT.register = function(self, mod)
    if not mod or not mod.title then return end
    local category = mod.category or "General"
    mod.category = category
    if not self.mods[mod.title] then
        table.insert(self.moduleOrder, mod.title)
    end
    FT.mods[mod.title] = mod
    return mod
end

local function EnsureSavedTables()
    if type(FostercareTweaks_Config) ~= "table" then FostercareTweaks_Config = {} end
    if type(FostercareTweaks_Config.overwrites) ~= "table" then FostercareTweaks_Config.overwrites = {} end
    if type(FostercareTweaks_Cache) ~= "table" then FostercareTweaks_Cache = {} end
    -- Player classes come from ClassicAPI's C_PlayerCache; drop our saved list.
    FostercareTweaks_Cache.players = nil
    -- Retire social-list styling; keep the chat-color choice it carried.
    if FostercareTweaks_Config["Social Colors"] ~= nil then
        if FostercareTweaks_Config["Chat Class Colors"] == nil then
            FostercareTweaks_Config["Chat Class Colors"] = FostercareTweaks_Config["Social Colors"]
        end
        FostercareTweaks_Config["Social Colors"] = nil
    end
    FostercareTweaks_Config["Hide Errors"] = nil
    -- Retired 2026-10-26: no character had them on, or every character had them
    -- on and they are now permanent.
    for _, key in ipairs({ "Hide Default Cast Bar", "Only Show My Debuffs on Target", "Show Bags", "Show Micro Menu",
        "Improved Standard Auras", "Debuff Timer", "Show Buff Cooldown Spiral", "Show Buff Duration Text",
        "Show Debuff Cooldown Spiral", "Show Debuff Duration Text", "Color Debuffs by Dispel Type",
        "Uninterruptible Castbars" }) do
        FostercareTweaks_Config[key] = nil
    end
    FostercareTweaks_Config.overwrites["panelbag.scale"] = nil
    FostercareTweaks_Config.overwrites["panelmicro.scale"] = nil
    -- Nameplates moved to FostercareNameplates (2026-10-12); clear their old settings.
    for _, key in ipairs({ "Nameplate Scale", "Nameplate Details", "Nameplate Class Colors",
        "Nameplate Castbar", "Enemy Nameplate Cooldowns", "nameplatesEnabled", "nameplate_layout_version" }) do
        FostercareTweaks_Config[key] = nil
    end
    for key in pairs(FostercareTweaks_Config.overwrites) do
        if type(key) == "string" and string.sub(key, 1, 10) == "nameplate_" then
            FostercareTweaks_Config.overwrites[key] = nil
        end
    end
end

-- ClassicAPI loads SavedVariables before source; modules also read them at load.
EnsureSavedTables()

function FT:Initialize()
    if self.initialized then return end
    self.initialized = true
    EnsureSavedTables()

    if self.MigrateFrameSettings then self.MigrateFrameSettings() end

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

        if mod.config then
            for name, value in pairs(mod.config) do
                local saved = FostercareTweaks_Config.overwrites[name]
                if saved ~= nil then value = saved; mod.config[name] = saved end
                self.overwrites[name] = value
            end
        end

    end
    for _, title in ipairs(self.moduleOrder) do
        local mod = self.mods[title]
        if (mod.always or FostercareTweaks_Config[title] == 1) and mod.enable then
            local success, err = pcall(mod.enable, mod)
            if not success and DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff2020[FostercareTweaks Error]|r Failed to enable '" .. tostring(title) .. "': " .. tostring(err), 1, 0.3, 0.3)
            end
        end
    end
    if self.ActionBars then self.ActionBars:Initialize() end
end

-- Helpers load before either initialization event is delivered.
local function InitializeOnEvent(first, second)
    local ev = FT.EventArgs(first, second)
    if ev == "VARIABLES_LOADED" or ev == "PLAYER_LOGIN" then FT:Initialize() end
end

coreFrame:RegisterEvent("VARIABLES_LOADED")
coreFrame:RegisterEvent("PLAYER_LOGIN")
coreFrame:SetScript("OnEvent", InitializeOnEvent)

-- Slash Command Registration
SLASH_FOSTERCARETWEAKS1 = "/ft"
SLASH_FOSTERCARETWEAKS2 = "/ftweaks"
SLASH_FOSTERCARETWEAKS3 = "/fostercaretweaks"

SlashCmdList["FOSTERCARETWEAKS"] = function(msg)
    local cmd = strsplittable(" ", msg or "")
    if cmd[1] == "reset" then
        FostercareTweaks_Config.overwrites = {}
        ReloadUI()
    elseif cmd[1] == "resetuf" or cmd[1] == "ufreset" then
        if FostercareTweaks_Config then
            FostercareTweaks_Config.unitframe_positions = nil
        end
        ReloadUI()
    elseif cmd[1] == "testraid" or cmd[1] == "raidtest" or cmd[1] == "testgroup" or cmd[1] == "grouptest" then
        if FT.UnitFrames and FT.UnitFrames.ToggleRaidTest then
            FT.UnitFrames:ToggleRaidTest()
        end
    elseif cmd[1] == "bars" or cmd[1] == "actionbars" then
        FT.OpenSettings("bars")
    elseif cmd[1] == "uf" or cmd[1] == "unitframes" or cmd[1] == "unitframe" then
        FT.OpenSettings("unit")
    elseif cmd[1] == "auras" then
        FT.OpenSettings("auras")
    elseif cmd[1] == "groupconfig" or cmd[1] == "groupsettings" or cmd[1] == "gfconfig" or cmd[1] == "raid" or cmd[1] == "raidframes" then
        FT.OpenSettings("raid")
    elseif cmd[1] == "groupsize" then
        local w = tonumber(cmd[2])
        local h = tonumber(cmd[3])
        if w and h and FT.UnitFrames and FT.UnitFrames.ApplyGroupDimensions then
            local dims = FT.UnitFrames:GetGroupDimensions()
            FT.UnitFrames:ApplyGroupDimensions(w, h, dims.scale)
            dims = FT.UnitFrames:GetGroupDimensions()
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[FostercareTweaks]|r Group frame size set to " .. dims.width .. "x" .. dims.height, 1, 1, 1)
            end
        elseif DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Usage:|r /ft groupsize <width> <height> (e.g. /ft groupsize 64 34)", 1, 1, 1)
        end
    elseif cmd[1] == "groupscale" then
        local s = tonumber(cmd[2])
        if s and FT.UnitFrames and FT.UnitFrames.ApplyGroupDimensions then
            local dims = FT.UnitFrames:GetGroupDimensions()
            FT.UnitFrames:ApplyGroupDimensions(dims.width, dims.height, s)
            dims = FT.UnitFrames:GetGroupDimensions()
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[FostercareTweaks]|r Group frame scale set to " .. dims.scale, 1, 1, 1)
            end
        elseif DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Usage:|r /ft groupscale <scale> (e.g. /ft groupscale 1.0)", 1, 1, 1)
        end
    elseif cmd[1] == "options" or cmd[1] == "gui" or cmd[1] == "menu" or cmd[1] == "" then
        FT.OpenSettings()
    elseif cmd[1] then
        local index = cmd[1]
        local input = cmd[2] or ""

        local value
        local _, _, r, g, b, a = string.find(input, "(.+),(.+),(.+),(.+)")

        if r and g and b and a then
            value = { r = tonumber(r), g = tonumber(g), b = tonumber(b), a = tonumber(a) }
        elseif tonumber(input) then
            value = tonumber(input)
        else
            value = input
        end

        if FT.overwrites[index] == nil then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff5555Error:|r Overwrite |cffffcc00" .. index .. "|r does not exist.", 1, 1, 1)
        else
            FT.SetOverride(index, value)
            DEFAULT_CHAT_FRAME:AddMessage("Overwrite |cffffcc00" .. index .. "|r is now set to: |cffffcc00" .. input .. "|r", 1, 1, 1)
        end
    end
end
