local FT = FostercareTweaks
if not FT then return end

-- Use the native eight-symbol atlas and authoritative unit/plate identities.
local module = FT:register({
    title = "Clear Raid Target Marks", category = "Unit Frames", enabled = true,
    description = "Readable raid target marks on unit frames.",
    config = { raidmark_size = 22, raidmark_position = "portrait" },
})

function FT.GetRaidMarkSettings(nameplate)
    local key = nameplate and "nameplate_raidmark_" or "raidmark_"
    local size = FT.GetNumber(key .. "size", nameplate and 20 or 22, 12, nameplate and 40 or 36)
    local position = FT.GetOverride(key .. "position")
    if nameplate then position = (position == "above" or position == "right") and position or "left"
    else position = position == "outside" and "outside" or "portrait" end
    return size, position
end

function FT.LayoutRaidMark(frame, icon, native)
    if not frame or not icon then return end
    local size, position = FT.GetRaidMarkSettings()
    icon:ClearAllPoints()
    if position == "outside" then
        if native then icon:SetPoint("LEFT", frame, "RIGHT", 2, 0)
        elseif frame.portraitSide == "left" then icon:SetPoint("RIGHT", frame, "LEFT", -3, 0)
        else icon:SetPoint("LEFT", frame, "RIGHT", 3, 0) end
    elseif native then
        icon:SetPoint("CENTER", TargetPortrait, "CENTER", 0, 0)
    else
        -- Leave the level badge at the bottom of the portrait unobscured.
        size = math.min(size, math.max(12, frame.portrait:GetHeight() - frame.levelBadge:GetHeight() - 2))
        icon:SetPoint("TOP", frame.portrait, "TOP", 0, -1)
    end
    icon:SetWidth(size); icon:SetHeight(size)
    icon:SetVertexColor(1, 1, 1, 1)
end

function FT.RefreshNameplateRaidMarks()
    if FT.Nameplates then FT.Nameplates:RefreshMarks() end
end

function FT:RefreshRaidMarks(includeRaid, skipNameplates)
    local UF = self.UnitFrames
    if UF and UF.targetFrame then self.LayoutRaidMark(UF.targetFrame, UF.targetFrame.raidIcon) end
    if TargetRaidTargetIcon and TargetFrame and TargetPortrait then self.LayoutRaidMark(TargetFrame, TargetRaidTargetIcon, true) end
    if includeRaid ~= false and UF and UF.RefreshRaidMarks then UF:RefreshRaidMarks() end
    if not skipNameplates then self.RefreshNameplateRaidMarks() end
end

module.enable = function(self)
    if self.frame then return end
    local driver = CreateFrame("Frame", "FCTweaksRaidMarks", UIParent)
    self.frame = driver
    FT.hooksecurefunc("TargetFrame_UpdateRaidTargetIcon", function()
        FT.LayoutRaidMark(TargetFrame, TargetRaidTargetIcon, true)
    end)
    driver:RegisterEvent("RAID_TARGET_UPDATE")
    driver:RegisterEvent("PLAYER_ENTERING_WORLD")
    driver:RegisterEvent("UI_SCALE_CHANGED")
    FT.SetEventHandler(driver, function(_, ev)
        FT:RefreshRaidMarks(ev == "UI_SCALE_CHANGED", true)
    end)
    FT:RefreshRaidMarks()
end
