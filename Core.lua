-- FostercareTweaks: Core.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Maintainer: Fostercare5988

-- Strict Engine Dependency Guard (Mandatory ClassicAPI v1.15.8+ & SuperWoW v2.2+)
local MIN_CLASSIC_API = 11508

if not (CLASSIC_API_VERSION and SUPERWOW_VERSION) or 
   (type(CLASSIC_API_VERSION) == "number" and CLASSIC_API_VERSION < MIN_CLASSIC_API) then
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cffff2020[Fatal Error]|r FostercareTweaks requires ClassicAPI (v1.15.8+) & SuperWoW (v2.2+)! Please ensure both DLLs are loaded.", 
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
FostercareTweaks.overwrites = FostercareTweaks.overwrites or {}
FostercareTweaks.version = "3.0.0"

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
    FostercareTweaks.mods[mod.title] = mod
    return mod
end

-- Backward compatibility alias for modules registering via ShaguTweaks:register
if not ShaguTweaks then
    ShaguTweaks = FostercareTweaks
end

local function GetConfigValue(conf)
    if type(conf) == "table" and conf.r and conf.g and conf.b then
        return string.format("%s,%s,%s,%s", conf.r, conf.g, conf.b, (conf.a or 1))
    elseif type(conf) == "number" or type(conf) == "string" then
        return conf
    end
    return ""
end

function FostercareTweaks:Initialize()
    if self.initialized then return end
    self.initialized = true

    if not FostercareTweaks_Config then FostercareTweaks_Config = {} end
    if not FostercareTweaks_Config.overwrites then FostercareTweaks_Config.overwrites = {} end
    if not FostercareTweaks_Cache then FostercareTweaks_Cache = {} end
    if not FostercareTweaks_Cache.players then FostercareTweaks_Cache.players = {} end

    -- Register and enable active modules
    for title, mod in pairs(self.mods) do
        if FostercareTweaks_Config[title] == nil then
            FostercareTweaks_Config[title] = mod.enabled and 1 or 0
        end

        if mod.config then
            for name, value in pairs(mod.config) do
                self.overwrites[name] = value
            end
        end

        if mod.config and FostercareTweaks_Config.overwrites then
            for name, value in pairs(FostercareTweaks_Config.overwrites) do
                self.overwrites[name] = value
                mod.config[name] = value
            end
        end

        if FostercareTweaks_Config[title] == 1 and mod.enable then
            local success, err = pcall(mod.enable, mod)
            if not success and DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff2020[FostercareTweaks Error]|r Failed to enable '" .. tostring(title) .. "': " .. tostring(err), 1, 0.3, 0.3)
            end
        end
    end
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
            DEFAULT_CHAT_FRAME:AddMessage("Overwrite |cffffcc00" .. index .. "|r is now set to: |cffffcc00" .. input .. "|r", 1, 1, 1)
        end
    end
end
