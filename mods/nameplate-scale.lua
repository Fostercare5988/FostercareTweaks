-- FostercareTweaks: mods/nameplate-scale.lua
-- Makes all nameplates honor UI-Scale setting with zero table allocation (Rule D1)

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Nameplate Scale"],
    description = T["Makes all nameplates honor the UI-Scale setting."],
    expansions = { ["vanilla"] = true, ["tbc"] = nil },
    category = T["Nameplates"],
    enabled = true,
})

module.enable = function(self)
    if ShaguPlates then return end

    local libnameplate = FostercareTweaks.libnameplate or (ShaguTweaks and ShaguTweaks.libnameplate)
    if not libnameplate then return end

    local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"

    local function CaptureBaselines(plate)
        if not plate then return end

        if not plate.fctOrigW and plate.GetWidth and plate:GetWidth() > 20 then
            plate.fctOrigW = plate:GetWidth()
            plate.fctOrigH = plate:GetHeight()
        end

        if plate.healthbar and not plate.fctHbOrigW and plate.healthbar.GetWidth and plate.healthbar:GetWidth() > 20 then
            plate.fctHbOrigW = plate.healthbar:GetWidth()
            plate.fctHbOrigH = plate.healthbar:GetHeight()
        end

        if plate.border and not plate.fctBorderOrigW and plate.border.GetWidth and plate.border:GetWidth() > 20 then
            plate.fctBorderOrigW = plate.border:GetWidth()
            plate.fctBorderOrigH = plate.border:GetHeight()
        end

        if plate.glow and not plate.fctGlowOrigW and plate.glow.GetWidth and plate.glow:GetWidth() > 20 then
            plate.fctGlowOrigW = plate.glow:GetWidth()
            plate.fctGlowOrigH = plate.glow:GetHeight()
        end

        if plate.name and not plate.fctNameOrigFont and plate.name.GetFont then
            local font, size, flags = plate.name:GetFont()
            if size and size > 5 then
                plate.fctNameOrigFont = font
                plate.fctNameOrigSize = size
                plate.fctNameOrigFlags = flags
            end
        end

        if plate.level and not plate.fctLevelOrigFont and plate.level.GetFont then
            local font, size, flags = plate.level:GetFont()
            if size and size > 5 then
                plate.fctLevelOrigFont = font
                plate.fctLevelOrigSize = size
                plate.fctLevelOrigFlags = flags
            end
        end
    end

    local function ApplyScale(plate)
        if not plate then return end
        CaptureBaselines(plate)

        local rawScale = UIParent:GetScale() or 1
        local scale = (rawScale > 0.2 and rawScale <= 2.0) and rawScale or 1

        local origW = plate.fctOrigW or 110
        local origH = plate.fctOrigH or 14
        local hbW = plate.fctHbOrigW or 110
        local hbH = plate.fctHbOrigH or 14
        local bW = plate.fctBorderOrigW or 128
        local bH = plate.fctBorderOrigH or 16
        local gW = plate.fctGlowOrigW or 128
        local gH = plate.fctGlowOrigH or 16

        local targetPlateW = math.floor(origW * scale + 0.5)
        local targetPlateH = math.floor(origH * scale + 0.5)
        local targetHbW = math.floor(hbW * scale + 0.5)
        local targetHbH = math.floor(hbH * scale + 0.5)
        local targetBW = math.floor(bW * scale + 0.5)
        local targetBH = math.floor(bH * scale + 0.5)
        local targetGW = math.floor(gW * scale + 0.5)
        local targetGH = math.floor(gH * scale + 0.5)

        plate:SetWidth(targetPlateW)
        plate:SetHeight(targetPlateH)

        if plate.healthbar then
            plate.healthbar:SetWidth(targetHbW)
            plate.healthbar:SetHeight(targetHbH)
            plate.healthbar:ClearAllPoints()
            plate.healthbar:SetPoint("CENTER", plate, "CENTER", 0, 0)
        end

        if plate.border then
            plate.border:SetWidth(targetBW)
            plate.border:SetHeight(targetBH)
            plate.border:ClearAllPoints()
            plate.border:SetPoint("CENTER", plate.healthbar or plate, "CENTER", 0, 0)
        end

        if plate.glow then
            plate.glow:SetWidth(targetGW)
            plate.glow:SetHeight(targetGH)
            plate.glow:ClearAllPoints()
            plate.glow:SetPoint("CENTER", plate.healthbar or plate, "CENTER", 0, 0)
        end

        if plate.name then
            local font = plate.fctNameOrigFont or (NAMEPLATE_FONT or DEFAULT_FONT)
            local origSize = plate.fctNameOrigSize or 11
            local flags = plate.fctNameOrigFlags
            local newSize = math.max(6, math.floor(origSize * scale + 0.5))
            plate.name:SetFont(font, newSize, flags)
            plate.name:ClearAllPoints()
            plate.name:SetPoint("BOTTOM", plate.healthbar or plate, "TOP", 0, math.floor(3 * scale + 0.5))
        end

        if plate.level then
            local font = plate.fctLevelOrigFont or (NAMEPLATE_FONT or DEFAULT_FONT)
            local origSize = plate.fctLevelOrigSize or 10
            local flags = plate.fctLevelOrigFlags
            local newSize = math.max(6, math.floor(origSize * scale + 0.5))
            plate.level:SetFont(font, newSize, flags)
            plate.level:ClearAllPoints()
            plate.level:SetPoint("CENTER", plate.healthbar or plate, "RIGHT", -math.floor(2 * scale + 0.5), 0)
        end

        if plate.levelicon then
            local iconSize = math.max(8, math.floor(11 * scale + 0.5))
            plate.levelicon:SetWidth(iconSize)
            plate.levelicon:SetHeight(iconSize)
            plate.levelicon:ClearAllPoints()
            plate.levelicon:SetPoint("CENTER", plate.healthbar or plate, "RIGHT", -math.floor(2 * scale + 0.5), 0)
        end

        if plate.raidicon then
            local raidSize = math.max(10, math.floor(14 * scale + 0.5))
            plate.raidicon:SetWidth(raidSize)
            plate.raidicon:SetHeight(raidSize)
            plate.raidicon:ClearAllPoints()
            plate.raidicon:SetPoint("CENTER", plate.healthbar or plate, "CENTER", 0, math.floor(18 * scale + 0.5))
        end

        if plate.dragon then
            local dW = math.floor(128 * scale + 0.5)
            local dH = math.floor(64 * scale + 0.5)
            plate.dragon:SetWidth(dW)
            plate.dragon:SetHeight(dH)
            plate.dragon:ClearAllPoints()
            plate.dragon:SetPoint("CENTER", plate.healthbar or plate, "CENTER", 0, 0)
        end
    end

    table.insert(libnameplate.OnInit, function(plate)
        if not plate then return end
        CaptureBaselines(plate)
        ApplyScale(plate)
    end)

    table.insert(libnameplate.OnShow, function(plate)
        if not plate then return end
        ApplyScale(plate)
    end)

    local scaleWatcher = CreateFrame("Frame")
    scaleWatcher:RegisterEvent("UI_SCALE_CHANGED")
    scaleWatcher:SetScript("OnEvent", function()
        if C_NamePlate and C_NamePlate.GetNamePlates then
            local plates = C_NamePlate.GetNamePlates()
            if plates then
                for _, p in ipairs(plates) do
                    if p:IsShown() then
                        ApplyScale(p)
                    end
                end
            end
        end
    end)
end
