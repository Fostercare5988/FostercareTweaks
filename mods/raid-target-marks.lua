local FT = FostercareTweaks
if not FT then return end

-- Use the native eight-symbol atlas and authoritative unit identities.
local module = FT:register({
    title = "Clear Raid Target Marks", always = true,
})

function FT.GetRaidMarkSettings()
    local size = FT.GetNumber("raidmark_size")
    return size, FT.GetOverride("raidmark_position") == "outside" and "outside" or "portrait"
end

-- The target frame's mark: on the portrait, or beside the frame.
local function LayoutTargetMark()
    local icon = TargetRaidTargetIcon
    local size, position = FT.GetRaidMarkSettings()
    icon:ClearAllPoints()
    if position == "outside" then icon:SetPoint("LEFT", TargetFrame, "RIGHT", 2, 0)
    else icon:SetPoint("CENTER", TargetPortrait, "CENTER", 0, 0) end
    icon:SetWidth(size); icon:SetHeight(size)
    icon:SetVertexColor(1, 1, 1, 1)
end

function FT:RefreshRaidMarks(includeRaid)
    LayoutTargetMark()
    if includeRaid ~= false then self.UnitFrames:RefreshRaidMarks() end
end

-- Solo, the server refuses raid marks. NamPower's SetRaidTarget then sets a
-- local mark that only this client sees (NP_EnableLocalSetRaidTarget, on by
-- default), so the mark keys and menu work alone too.
-- Until RAID_TARGET_UPDATE is known to fire for local marks, a solo mark
-- redraws the target and raid frames itself.
-- UNVERIFIED: test in game: solo, press a raid mark key on your target; the mark shows on the target frame and the same key clears it
local function RedrawSoloMark()
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        TargetFrame_UpdateRaidTargetIcon()
        FT:RefreshRaidMarks()
    end
end

module.enable = function(self)
    if self.frame then return end
    hooksecurefunc("SetRaidTarget", RedrawSoloMark)
    local driver = CreateFrame("Frame", "FCTweaksRaidMarks", UIParent)
    self.frame = driver
    hooksecurefunc("TargetFrame_UpdateRaidTargetIcon", LayoutTargetMark)
    driver:RegisterEvent("RAID_TARGET_UPDATE")
    driver:RegisterEvent("PLAYER_ENTERING_WORLD")
    driver:RegisterEvent("UI_SCALE_CHANGED")
    FT.SetEventHandler(driver, function(_, ev)
        FT:RefreshRaidMarks(ev == "UI_SCALE_CHANGED")
    end)
    FT:RefreshRaidMarks()
end
