if not FostercareTweaks then return end

-- Standard Blizzard player/target name backgrounds and party names always use class colors.
local function ClassColor(unit)
    local _, class = UnitClass(unit)
    local colors = FostercareTweaks.UnitFrames and FostercareTweaks.UnitFrames.ClassColors
    return class and colors and rawget(colors, class)
end

local function ColorTarget()
    if not UnitIsPlayer("target") or not TargetFrameNameBackground then return end
    local color = ClassColor("target")
    if color then TargetFrameNameBackground:SetVertexColor(color.r, color.g, color.b, 1) end
end

local function ColorParty()
    for id = 1, MAX_PARTY_MEMBERS do
        local name = _G["PartyMemberFrame" .. id .. "Name"]
        local color = ClassColor("party" .. id)
        if name and color then name:SetTextColor(color.r, color.g, color.b, 1) end
    end
end

local function ColorPlayer()
    local color = ClassColor("player")
    if not color then return end
    if not PlayerFrameNameBackground then
        PlayerFrameNameBackground = PlayerFrame:CreateTexture(nil, "BACKGROUND")
        PlayerFrameNameBackground:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground")
        PlayerFrameNameBackground:SetWidth(119)
        PlayerFrameNameBackground:SetHeight(19)
        PlayerFrameNameBackground:SetPoint("TOPLEFT", 106, -22)
    end
    PlayerFrameNameBackground:SetVertexColor(color.r, color.g, color.b, 1)
    PlayerFrameNameBackground:Show()
end

local hooksInstalled = false
function FostercareTweaks.EnableStandardClassColors()
    if not hooksInstalled then
        FostercareTweaks.hooksecurefunc("TargetFrame_CheckFaction", ColorTarget)
        FostercareTweaks.hooksecurefunc("PartyMemberFrame_UpdateMember", ColorParty)
        hooksInstalled = true
        local worldRefresh = CreateFrame("Frame")
        worldRefresh:RegisterEvent("PLAYER_ENTERING_WORLD")
        worldRefresh:SetScript("OnEvent", function()
            ColorPlayer()
            if UnitExists("target") and TargetFrame_CheckFaction then TargetFrame_CheckFaction() end
            ColorParty()
        end)
    end
    ColorPlayer()
    if UnitExists("target") and TargetFrame_CheckFaction then TargetFrame_CheckFaction() end
    ColorParty()
end
