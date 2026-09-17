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

        if plate.fctLastAppliedScale == scale and plate:GetWidth() == targetPlateW then
            return
        end
        plate.fctLastAppliedScale = scale

        plate:SetWidth(targetPlateW)
        plate:SetHeight(targetPlateH)

        -- Do not ClearAllPoints or re-center healthbar/border:
        -- preserve native C++ anchor offsets to maintain vertical separation from name text.
        if plate.healthbar then
            plate.healthbar:SetWidth(targetHbW)
            plate.healthbar:SetHeight(targetHbH)
        end

        if plate.border then
            plate.border:SetWidth(targetBW)
            plate.border:SetHeight(targetBH)
        end

        if plate.glow then
            plate.glow:SetWidth(targetGW)
            plate.glow:SetHeight(targetGH)
        end

        if plate.name and plate.name.SetScale then
            plate.name:SetScale(scale)
        end

        if plate.level and plate.level.SetScale then
            plate.level:SetScale(scale)
        end

        if plate.levelicon then
            local iconSize = math.max(8, math.floor(11 * scale + 0.5))
            plate.levelicon:SetWidth(iconSize)
            plate.levelicon:SetHeight(iconSize)
        end

        if plate.raidicon then
            local raidSize = math.max(10, math.floor(14 * scale + 0.5))
            plate.raidicon:SetWidth(raidSize)
            plate.raidicon:SetHeight(raidSize)
        end

        if plate.dragon then
            local dW = math.floor(128 * scale + 0.5)
            local dH = math.floor(64 * scale + 0.5)
            plate.dragon:SetWidth(dW)
            plate.dragon:SetHeight(dH)
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

    table.insert(libnameplate.OnUpdate, function(plate)
        if not plate then return end
        local rawScale = UIParent:GetScale() or 1
        local scale = (rawScale > 0.2 and rawScale <= 2.0) and rawScale or 1
        if plate.fctLastAppliedScale ~= scale then
            ApplyScale(plate)
        end
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
