local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/nameplate-castbar.lua
-- Adds a castbar to nameplates using ClassicAPI C_Spell cast/channel queries


local module = FT:register({
    title = "Nameplate Castbar",
    description = "Adds a castbar to the nameplate based on unit casting information.",
    category = "Nameplates",
    enabled = true,
})

module.enable = function(self)
    if ShaguPlates then return end

    local backdrop = {
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    }

    local function create_castbar(plate)
        plate.castbar = CreateFrame("StatusBar", nil, plate)
        plate.castbar:SetPoint("BOTTOM", plate, "BOTTOM", 8, -11)
        plate.castbar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        plate.castbar:SetStatusBarColor(1, 0.8, 0, 1)
        plate.castbar:SetWidth(math.max(12, plate:GetWidth() - 22))
        plate.castbar:SetHeight(10)
        FT.HookScript(plate, "OnSizeChanged", function()
            local width = math.max(12, plate:GetWidth() - 22)
            if plate.castbar:GetWidth() ~= width then plate.castbar:SetWidth(width) end
        end)

        plate.castbar.texture = CreateFrame("Frame", nil, plate.castbar)
        plate.castbar.texture:SetPoint("RIGHT", plate.castbar, "LEFT", 0, 0)
        plate.castbar.texture:SetHeight(18)
        plate.castbar.texture:SetWidth(18)
        plate.castbar.texture.icon = plate.castbar.texture:CreateTexture(nil, "BACKGROUND")
        plate.castbar.texture.icon:SetPoint("CENTER", 0, 0)
        plate.castbar.texture.icon:SetWidth(12)
        plate.castbar.texture.icon:SetHeight(12)
        plate.castbar.texture:SetBackdrop(backdrop)
        plate.castbar.texture:SetBackdropBorderColor(1, 0.8, 0)

        plate.castbar.bg = plate.castbar:CreateTexture(nil, "BACKGROUND")
        plate.castbar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        plate.castbar.bg:SetVertexColor(0.1, 0.1, 0, 0.8)
        plate.castbar.bg:SetAllPoints(true)

        plate.castbar.spark = plate.castbar:CreateTexture(nil, "OVERLAY")
        plate.castbar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        plate.castbar.spark:SetWidth(20)
        plate.castbar.spark:SetHeight(20)
        plate.castbar.spark:SetBlendMode("ADD")

        plate.castbar.backdrop = CreateFrame("Frame", nil, plate.castbar)
        plate.castbar.backdrop:SetFrameLevel(plate.castbar:GetFrameLevel())
        plate.castbar.backdrop:SetPoint("TOPLEFT", plate.castbar, "TOPLEFT", -3, 3)
        plate.castbar.backdrop:SetPoint("BOTTOMRIGHT", plate.castbar, "BOTTOMRIGHT", 3, -3)
        plate.castbar.backdrop:SetBackdrop(backdrop)
        plate.castbar.backdrop:SetBackdropBorderColor(1, 0.8, 0)

        plate.castbar.text = plate.castbar:CreateFontString(nil, "OVERLAY", "GameFontWhite")
        plate.castbar.text:SetPoint("CENTER", plate.castbar, "CENTER", 0, 0)
        local font, size = plate.castbar.text:GetFont()
        plate.castbar.text:SetFont(font, size - 3, "THINOUTLINE")

        plate.castbar:Hide()
    end

    local libnameplate = FT.libnameplate

    -- OnShow frame cleanup: eliminates recycled ghost casts from prior units
    table.insert(libnameplate.OnShow, function(plate)
        if plate.castbar then
            plate.castbar:Hide()
            plate.castbar.lastSpell = nil
            plate.castbar.lastMax = nil
            plate.castbar.lastTexture = nil
            plate.castbar.lastSparkX = nil
            plate.castbar.lastInterruptible = nil
            plate.castbar.castUnit = nil
            plate.castbar.nextQuery = nil
        end
    end)

    table.insert(libnameplate.OnUpdate, function(plate)
        if not plate.castbar then create_castbar(plate) end

        if not plate:IsShown() then
            if plate.castbar:IsShown() then
                plate.castbar:Hide()
                plate.castbar.lastSpell = nil
                plate.castbar.lastMax = nil
                plate.castbar.lastTexture = nil
                plate.castbar.lastSparkX = nil
                plate.castbar.lastInterruptible = nil
            end
            return
        end

        local unit = FT.GetNameplateUnit(plate)
        local cb = plate.castbar
        local now = GetTime()
        -- Events invalidate immediately; bounded reconciliation covers remote
        -- casts whose event telemetry may be incomplete. Animation stays smooth.
        if unit ~= cb.castUnit or not cb.nextQuery or now >= cb.nextQuery then
            local cast, displayName, texture, startTime, endTime, notInterruptible
            local isChannel = false
            if unit then
                local isTradeskill, castID
                cast, displayName, texture, startTime, endTime, isTradeskill, castID, notInterruptible = C_Spell.UnitCastingInfo(unit)
                if not cast then
                    cast, displayName, texture, startTime, endTime, isTradeskill, notInterruptible = C_Spell.UnitChannelInfo(unit)
                    isChannel = cast ~= nil
                end
            end
            cb.castUnit, cb.nextQuery = unit, now + 0.1
            cb.cast, cb.castTexture, cb.startTime, cb.endTime = cast, texture, startTime, endTime
            cb.notInterruptible, cb.isChannel = notInterruptible, isChannel
        end
        local cast, texture, startTime, endTime = cb.cast, cb.castTexture, cb.startTime, cb.endTime
        local notInterruptible, isChannel = cb.notInterruptible, cb.isChannel

        if unit and cast and startTime and endTime and endTime > startTime and endTime > now * 1000 then
            local max = (endTime - startTime) / 1000
            local cur
            if isChannel then
                cur = (endTime / 1000) - now
            else
                cur = now - (startTime / 1000)
            end

            cur = cur > max and max or (cur < 0 and 0 or cur)

            if not plate.castbar:IsShown() then
                plate.castbar:Show()
            end

            if plate.castbar.lastMax ~= max then
                plate.castbar.lastMax = max
                plate.castbar:SetMinMaxValues(0, max)
            end

            -- Visual styling for interruptible vs uninterruptible casts
            local showUninterruptible = (not FostercareTweaks_Config or FostercareTweaks_Config["Uninterruptible Castbars"] ~= 0)
            local isUninterruptible = showUninterruptible and notInterruptible

            if plate.castbar.lastInterruptible ~= isUninterruptible then
                plate.castbar.lastInterruptible = isUninterruptible
                if isUninterruptible then
                    plate.castbar:SetStatusBarColor(0.65, 0.65, 0.65, 1)
                    plate.castbar.backdrop:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
                    plate.castbar.texture:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
                else
                    plate.castbar:SetStatusBarColor(1, 0.8, 0, 1)
                    plate.castbar.backdrop:SetBackdropBorderColor(1, 0.8, 0, 1)
                    plate.castbar.texture:SetBackdropBorderColor(1, 0.8, 0, 1)
                end
            end

            plate.castbar:SetValue(cur)

            local percent = max > 0 and (cur / max) or 0
            local width = plate.castbar:GetWidth()
            local sparkX = math.floor(width * percent)
            if plate.castbar.lastSparkX ~= sparkX then
                plate.castbar.lastSparkX = sparkX
                plate.castbar.spark:SetPoint("CENTER", plate.castbar, "LEFT", sparkX, 0)
            end

            if plate.castbar.lastSpell ~= cast then
                plate.castbar.lastSpell = cast
                plate.castbar.text:SetText(cast)
            end

            if plate.castbar.lastTexture ~= texture then
                plate.castbar.lastTexture = texture
                if texture then
                    plate.castbar.texture.icon:SetTexture(texture)
                    plate.castbar.texture.icon:Show()
                else
                    plate.castbar.texture.icon:Hide()
                end
            end

            local alpha = plate:GetAlpha()
            if plate.castbar.lastAlpha ~= alpha then
                plate.castbar.lastAlpha = alpha
                plate.castbar:SetAlpha(alpha)
            end
        else
            if plate.castbar:IsShown() then
                plate.castbar:Hide()
                plate.castbar.lastSpell = nil
                plate.castbar.lastMax = nil
                plate.castbar.lastTexture = nil
                plate.castbar.lastSparkX = nil
                plate.castbar.lastInterruptible = nil
            end
        end
    end)

    local events = CreateFrame("Frame", "FCTweaksNameplateCastEvents", UIParent)
    for _, ev in ipairs({"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED",
        "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START",
        "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_CASTEVENT"}) do
        events:RegisterEvent(ev)
    end
    FT.SetEventHandler(events, function(_, ev, unit)
        if not unit then return end
        local plate = C_NamePlate.GetNamePlateForUnit(unit)
        if plate and plate.castbar then plate.castbar.nextQuery = nil end
    end)
end
