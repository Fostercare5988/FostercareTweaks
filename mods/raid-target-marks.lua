local FT = FostercareTweaks
if not FT then return end

-- Use the native eight-symbol atlas and authoritative unit/plate identities.
local module = FT:register({
    title = "Clear Raid Target Marks", category = "Unit Frames", enabled = true,
    description = "Readable raid target marks on unit frames and native nameplates.",
    config = { raidmark_size = 22, raidmark_position = "portrait",
        nameplate_raidmark_size = 20, nameplate_raidmark_position = "left" },
})
local plates = {}

function FT.GetRaidMarkSettings(nameplate)
    local key = nameplate and "nameplate_raidmark_" or "raidmark_"
    local size = FT.GetNumber(key .. "size", nameplate and 20 or 22, 12, nameplate and 32 or 36)
    local position = FT.GetOverride(key .. "position")
    if nameplate then position = position == "above" and "above" or "left"
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

local function UpdatePlate(plate, unit)
    local icon = plate.fctRaidMark
    if not icon then return end
    local valid = unit and C_NamePlate.GetNamePlateForUnit(unit) == plate
    local index = valid and GetRaidTargetIndex(UnitGUID(unit))
    if index and index >= 1 and index <= 8 then
        SetRaidTargetIconTexture(icon, index)
        icon:Show()
    else icon:Hide() end
    local size, position = FT.GetRaidMarkSettings(true)
    if plate.fctMarkSize ~= size or plate.fctMarkPosition ~= position then
        plate.fctMarkSize, plate.fctMarkPosition = size, position
        icon:SetWidth(size); icon:SetHeight(size)
        icon:ClearAllPoints()
        if position == "above" then
            icon:SetPoint("BOTTOM", plate.name or plate, "TOP", 0, 3)
        else icon:SetPoint("RIGHT", plate.healthbar or plate, "LEFT", -4, 0) end
    end
    -- Keep native lifecycle/atlas updates intact while drawing the larger mark.
    if plate.raidicon then plate.raidicon:SetAlpha(0) end
end

function FT.RefreshNameplateRaidMarks()
    for plate in pairs(plates) do UpdatePlate(plate, FT.GetNameplateUnit(plate)) end
end

function FT:RefreshRaidMarks(includeRaid)
    local UF = self.UnitFrames
    if UF and UF.targetFrame then self.LayoutRaidMark(UF.targetFrame, UF.targetFrame.raidIcon) end
    if TargetRaidTargetIcon and TargetFrame and TargetPortrait then self.LayoutRaidMark(TargetFrame, TargetRaidTargetIcon, true) end
    if includeRaid ~= false and UF and UF.RefreshRaidMarks then UF:RefreshRaidMarks() end
    self.RefreshNameplateRaidMarks()
end

module.enable = function(self)
    if self.frame then return end
    local driver = CreateFrame("Frame", "FCTweaksRaidMarks", UIParent)
    self.frame = driver
    FT.hooksecurefunc("TargetFrame_UpdateRaidTargetIcon", function()
        FT.LayoutRaidMark(TargetFrame, TargetRaidTargetIcon, true)
    end)
    if not ShaguPlates then
        local function InitPlate(plate)
            if plate.fctRaidMark then return end
            plates[plate] = true
            plate.fctRaidMark = plate:CreateTexture(nil, "OVERLAY")
            -- Native SetRaidTargetIconTexture sets atlas coordinates only.
            plate.fctRaidMark:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
            plate.fctRaidMark:Hide()
            UpdatePlate(plate, FT.GetNameplateUnit(plate))
        end
        table.insert(FT.libnameplate.OnInit, InitPlate)
        table.insert(FT.libnameplate.OnShow, function(plate) UpdatePlate(plate, FT.GetNameplateUnit(plate)) end)
        for _, guid in ipairs(C_NamePlate.GetNamePlateGUIDs()) do
            local plate = C_NamePlate.GetNamePlateForUnit(guid)
            if plate then InitPlate(plate); UpdatePlate(plate, guid) end
        end
        driver:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        driver:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    end
    driver:RegisterEvent("RAID_TARGET_UPDATE")
    driver:RegisterEvent("PLAYER_ENTERING_WORLD")
    driver:RegisterEvent("UI_SCALE_CHANGED")
    FT.SetEventHandler(driver, function(_, ev, unit)
        if ev == "NAME_PLATE_UNIT_ADDED" then
            local plate = C_NamePlate.GetNamePlateForUnit(unit)
            if plate and plate.fctRaidMark then UpdatePlate(plate, unit) end
        elseif ev == "NAME_PLATE_UNIT_REMOVED" then
            -- The engine may already have removed the old binding; check every
            -- owned plate against the authoritative registry, including reuse.
            for plate in pairs(plates) do UpdatePlate(plate, FT.GetNameplateUnit(plate)) end
        -- The raid owner handles mark and world events itself. Scale/settings
        -- changes need its layout, never another full health/power/aura scan.
        else FT:RefreshRaidMarks(ev == "UI_SCALE_CHANGED") end
    end)
    FT:RefreshRaidMarks()
end
