-- FostercareTweaks: mods/unitframes-classcolor.lua
local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Unit Frame Class Colors"],
    description = T["Adds class colors to the player, target and party unit frames."],
    category = T["Unit Frames"],
    enabled = nil,
})

local defaultClassColor = { r = 0.5, g = 0.5, b = 0.5, a = 1 }

local partycolors = function()
    for id = 1, MAX_PARTY_MEMBERS do
        local name = _G['PartyMemberFrame' .. id .. 'Name']
        local _, class = UnitClass("party" .. id)
        local c = RAID_CLASS_COLORS[class] or defaultClassColor
        if name then name:SetTextColor(c.r, c.g, c.b, 1) end
    end
end

module.enable = function(self)
    FostercareTweaks.hooksecurefunc("TargetFrame_CheckFaction", function(s)
        local reaction = UnitReaction("target", "player")

        if UnitIsPlayer("target") then
            local _, class = UnitClass("target")
            local c = RAID_CLASS_COLORS[class] or defaultClassColor
            if TargetFrameNameBackground then
                TargetFrameNameBackground:SetVertexColor(c.r, c.g, c.b, 1)
                if not TargetFrameNameBackground:IsShown() then TargetFrameNameBackground:Show() end
            end
        elseif reaction and reaction > 4 then
            if TargetFrameNameBackground and TargetFrameNameBackground:IsShown() then TargetFrameNameBackground:Hide() end
        else
            if TargetFrameNameBackground and not TargetFrameNameBackground:IsShown() then TargetFrameNameBackground:Show() end
        end
    end)

    local _, class = UnitClass("player")
    local c = RAID_CLASS_COLORS[class] or defaultClassColor

    if not PlayerFrameNameBackground then
        PlayerFrameNameBackground = PlayerFrame:CreateTexture(nil, "BACKGROUND")
        PlayerFrameNameBackground:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground")
        PlayerFrameNameBackground:SetWidth(119)
        PlayerFrameNameBackground:SetHeight(19)
        PlayerFrameNameBackground:SetPoint("TOPLEFT", 106, -22)
    end
    PlayerFrameNameBackground:SetVertexColor(c.r, c.g, c.b, 1)

    local wait = CreateFrame("Frame")
    wait:RegisterEvent("PLAYER_ENTERING_WORLD")
    wait:SetScript("OnEvent", function()
        local _, pClass = UnitClass("player")
        local pc = RAID_CLASS_COLORS[pClass] or defaultClassColor
        if PlayerFrameNameBackground then
            PlayerFrameNameBackground:SetVertexColor(pc.r, pc.g, pc.b, 1)
        end
        this:UnregisterAllEvents()
    end)

    FostercareTweaks.hooksecurefunc("PartyMemberFrame_UpdateMember", partycolors)
end
