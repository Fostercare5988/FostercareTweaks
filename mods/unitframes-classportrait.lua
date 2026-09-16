-- FostercareTweaks: mods/unitframes-classportrait.lua
local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Unit Frame Class Portraits"],
    description = T["Replace unitframe portraits with class icons."],
    category = T["Unit Frames"],
    enabled = nil,
})

local addonpath = "Interface\\AddOns\\FostercareTweaks"

local CLASS_ICON_TCOORDS = {
    ["WARRIOR"] = { 0, 0.25, 0, 0.25 },
    ["MAGE"] = { 0.25, 0.49609375, 0, 0.25 },
    ["ROGUE"] = { 0.49609375, 0.7421875, 0, 0.25 },
    ["DRUID"] = { 0.7421875, 0.98828125, 0, 0.25 },
    ["HUNTER"] = { 0, 0.25, 0.25, 0.5 },
    ["SHAMAN"] = { 0.25, 0.49609375, 0.25, 0.5 },
    ["PRIEST"] = { 0.49609375, 0.7421875, 0.25, 0.5 },
    ["WARLOCK"] = { 0.7421875, 0.98828125, 0.25, 0.5 },
    ["PALADIN"] = { 0, 0.25, 0.5, 0.75 },
}

local function UpdatePortraits(frame)
    if not frame or not frame.unit or not frame.portrait then return end

    local _, class = UnitClass(frame.unit)
    class = UnitIsPlayer(frame.unit) and class or nil

    if frame.lastPortraitClass == class then return end
    frame.lastPortraitClass = class

    if class and CLASS_ICON_TCOORDS[class] then
        local coords = CLASS_ICON_TCOORDS[class]
        frame.portrait:SetTexture(addonpath .. "\\img\\UI-Classes-Circles")
        frame.portrait:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    else
        frame.portrait:SetTexCoord(0, 1, 0, 1)
    end
end

module.enable = function(self)
    FostercareTweaks.hooksecurefunc("UnitFrame_Update", function()
        UpdatePortraits(this)
    end)

    local events = CreateFrame("Frame")
    events:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    events:RegisterEvent("PLAYER_TARGET_CHANGED")
    events:RegisterEvent("PARTY_MEMBERS_CHANGED")
    events:SetScript("OnEvent", function()
        UpdatePortraits(PlayerFrame)
        UpdatePortraits(TargetFrame)
        for i = 1, MAX_PARTY_MEMBERS do
            UpdatePortraits(_G["PartyMemberFrame" .. i])
        end
    end)
end
