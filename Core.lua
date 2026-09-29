-- FostercareTweaks: Core.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Maintainer: Fostercare5988

-- Strict Engine Dependency Guard (Mandatory ClassicAPI v1.15.15+ & SuperWoW v2.2+)
local MIN_CLASSIC_API = 11515

if type(CLASSIC_API_VERSION) ~= "number" or not SUPERWOW_VERSION or
   CLASSIC_API_VERSION < MIN_CLASSIC_API then
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cffff2020[Fatal Error]|r FostercareTweaks requires ClassicAPI (v1.15.15+) & SuperWoW (v2.2+)! Please ensure both DLLs are loaded.",
            1, 0.2, 0.2
        )
    end
    return
end

local addonName = "FostercareTweaks"

local coreFrame = CreateFrame("Frame", "FostercareTweaksFrame", UIParent)
FostercareTweaks = FostercareTweaks or coreFrame
for k, v in pairs(coreFrame) do
    if not FostercareTweaks[k] then
        FostercareTweaks[k] = v
    end
end

FostercareTweaks.mods = FostercareTweaks.mods or {}
FostercareTweaks.moduleOrder = FostercareTweaks.moduleOrder or {}
FostercareTweaks.overwrites = FostercareTweaks.overwrites or {}
FostercareTweaks.version = "3.1.0"

-- Canonical English string pass-through and class token dictionary
FostercareTweaks.T = setmetatable({}, {
    __index = function(tab, key)
        return key
    end
})

FostercareTweaks.L = {
    class = {
        ["Warlock"] = "WARLOCK",
        ["Warrior"] = "WARRIOR",
        ["Hunter"] = "HUNTER",
        ["Mage"] = "MAGE",
        ["Priest"] = "PRIEST",
        ["Druid"] = "DRUID",
        ["Paladin"] = "PALADIN",
        ["Shaman"] = "SHAMAN",
        ["Rogue"] = "ROGUE",
    }
}

-- Component Registration
FostercareTweaks.register = function(self, mod)
    if not mod or not mod.title then return end
    local category = mod.category or FostercareTweaks.T["General"]
    mod.category = category
    mod.expansions = mod.expansions or { ["vanilla"] = true }
    if not self.mods[mod.title] then
        table.insert(self.moduleOrder, mod.title)
    end
    FostercareTweaks.mods[mod.title] = mod
    return mod
end

-- Backward compatibility alias for modules registering via ShaguTweaks:register
if not ShaguTweaks then
    ShaguTweaks = FostercareTweaks
end

local function EnsureSavedTables()
    if type(FostercareTweaks_Config) ~= "table" then FostercareTweaks_Config = {} end
    if type(FostercareTweaks_Config.overwrites) ~= "table" then FostercareTweaks_Config.overwrites = {} end
    if type(FostercareTweaks_Cache) ~= "table" then FostercareTweaks_Cache = {} end
    if type(FostercareTweaks_Cache.players) ~= "table" then FostercareTweaks_Cache.players = {} end
end

-- ClassicAPI loads SavedVariables before source; modules also read them at load.
EnsureSavedTables()

function FostercareTweaks:Initialize()
    if self.initialized then return end
    self.initialized = true
    EnsureSavedTables()

    -- Prepare every default before dependent modules enable. TOC registration
    -- order defines layout and hook order; hash iteration must not decide it.
    for _, title in ipairs(self.moduleOrder) do
        local mod = self.mods[title]
        if FostercareTweaks_Config[title] == nil then
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
        if FostercareTweaks_Config[title] == 1 and mod.enable then
            local success, err = pcall(mod.enable, mod)
            if not success and DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff2020[FostercareTweaks Error]|r Failed to enable '" .. tostring(title) .. "': " .. tostring(err), 1, 0.3, 0.3)
            end
        end
    end

    -- Standard Blizzard frame class colors are permanent, independent of saved toggles.
    self.EnableStandardClassColors()
end

-- Rule C12 / AP-26 Dual-Mode Event Signature
function FostercareTweaks_OnEvent(arg1_param, arg2_param, arg3_param)
    local ev
    if type(arg1_param) == "table" then
        ev = arg2_param or event
    else
        ev = (type(arg1_param) == "string" and arg1_param) or arg2_param or event
    end

    if ev == "VARIABLES_LOADED" or ev == "PLAYER_LOGIN" then
        FostercareTweaks:Initialize()
    end
end

coreFrame:RegisterEvent("VARIABLES_LOADED")
coreFrame:RegisterEvent("PLAYER_LOGIN")
coreFrame:SetScript("OnEvent", FostercareTweaks_OnEvent)

-- Slash Command Registration
SLASH_FOSTERCARETWEAKS1 = "/ft"
SLASH_FOSTERCARETWEAKS2 = "/ftweaks"
SLASH_FOSTERCARETWEAKS3 = "/fostercaretweaks"
SLASH_FOSTERCARETWEAKS4 = "/st"
SLASH_FOSTERCARETWEAKS5 = "/shagutweaks"

SlashCmdList["FOSTERCARETWEAKS"] = function(msg)
    local cmd = { strsplit(" ", msg or "") }
    if cmd[1] == "reset" then
        FostercareTweaks_Config.overwrites = {}
        ReloadUI()
    elseif cmd[1] == "resetuf" or cmd[1] == "ufreset" then
        if FostercareTweaks_Config then
            FostercareTweaks_Config.unitframe_positions = nil
        end
        ReloadUI()
    elseif cmd[1] == "testraid" or cmd[1] == "raidtest" or cmd[1] == "testgroup" or cmd[1] == "grouptest" then
        if FostercareTweaks.UnitFrames and FostercareTweaks.UnitFrames.ToggleRaidTest then
            FostercareTweaks.UnitFrames:ToggleRaidTest()
        end
    elseif cmd[1] == "uf" or cmd[1] == "unitframes" or cmd[1] == "unitframe" then
        if FostercareTweaksSettingsGUI then
            FostercareTweaksSettingsGUI:Show()
            if FostercareTweaksSettingsGUI.SelectTab then
                FostercareTweaksSettingsGUI.SelectTab(2)
            end
        end
    elseif cmd[1] == "groupconfig" or cmd[1] == "groupsettings" or cmd[1] == "gfconfig" or cmd[1] == "raid" or cmd[1] == "raidframes" then
        if FostercareTweaksSettingsGUI then
            FostercareTweaksSettingsGUI:Show()
            if FostercareTweaksSettingsGUI.SelectTab then
                FostercareTweaksSettingsGUI.SelectTab(3)
            end
        elseif FostercareTweaks.UnitFrames and FostercareTweaks.UnitFrames.ToggleGroupFrameSettings then
            FostercareTweaks.UnitFrames:ToggleGroupFrameSettings()
        end
    elseif cmd[1] == "groupsize" then
        local w = tonumber(cmd[2])
        local h = tonumber(cmd[3])
        if w and h and FostercareTweaks.UnitFrames and FostercareTweaks.UnitFrames.ApplyGroupDimensions then
            local dims = FostercareTweaks.UnitFrames:GetGroupDimensions()
            FostercareTweaks.UnitFrames:ApplyGroupDimensions(w, h, dims.scale)
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[FostercareTweaks]|r Group frame size set to " .. w .. "x" .. h, 1, 1, 1)
            end
        elseif DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Usage:|r /ft groupsize <width> <height> (e.g. /ft groupsize 64 34)", 1, 1, 1)
        end
    elseif cmd[1] == "groupscale" then
        local s = tonumber(cmd[2])
        if s and FostercareTweaks.UnitFrames and FostercareTweaks.UnitFrames.ApplyGroupDimensions then
            local dims = FostercareTweaks.UnitFrames:GetGroupDimensions()
            FostercareTweaks.UnitFrames:ApplyGroupDimensions(dims.width, dims.height, s)
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[FostercareTweaks]|r Group frame scale set to " .. s, 1, 1, 1)
            end
        elseif DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Usage:|r /ft groupscale <scale> (e.g. /ft groupscale 1.0)", 1, 1, 1)
        end
    elseif cmd[1] == "options" or cmd[1] == "gui" or cmd[1] == "menu" or cmd[1] == "" then
        if FostercareTweaksSettingsGUI then
            if FostercareTweaksSettingsGUI:IsShown() then
                FostercareTweaksSettingsGUI:Hide()
            else
                FostercareTweaksSettingsGUI:Show()
            end
        end
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

        if not FostercareTweaks.overwrites[index] then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff5555Error:|r Overwrite |cffffcc00" .. index .. "|r does not exist.", 1, 1, 1)
        else
            FostercareTweaks_Config.overwrites[index] = value
            FostercareTweaks.overwrites[index] = value
            if index == "uf_scale" and FostercareTweaks.UnitFrames and FostercareTweaks.UnitFrames.ApplyScale then
                FostercareTweaks.UnitFrames:ApplyScale(value)
            end
            DEFAULT_CHAT_FRAME:AddMessage("Overwrite |cffffcc00" .. index .. "|r is now set to: |cffffcc00" .. input .. "|r", 1, 1, 1)
        end
    end
end
