-- FostercareTweaks: mods/auto-stance.lua
-- Automatically switches to the required warrior or druid stance on spell cast

local T = FostercareTweaks.T
local gfind = string.gmatch or string.gfind

local module = FostercareTweaks:register({
    title = T["Auto Stance"],
    description = T["Automatically switch to the required warrior or druid stance on spell cast."],
    expansions = { ["vanilla"] = true, ["tbc"] = nil },
    category = T["General"],
    enabled = true,
})

module.enable = function(self)
    local _, playerClass = UnitClass("player")
    if playerClass ~= "WARRIOR" and playerClass ~= "DRUID" then return end

    local stancedance = CreateFrame("Frame", "FCTweaksStancedance")
    stancedance.scanString = string.gsub(SPELL_FAILED_ONLY_SHAPESHIFT, "%%s", "(.+)")
    stancedance:RegisterEvent("UI_ERROR_MESSAGE")
    stancedance:SetScript("OnEvent", function()
        local msg = _G.arg1
        if not msg then return end
        for stances in gfind(msg, stancedance.scanString) do
            for stance in gfind(stances, "([^,]+)") do
                CastSpellByName(string.gsub(stance, "^%s*(.-)%s*$", "%1"))
            end
        end
    end)
end
