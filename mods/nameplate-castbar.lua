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

local initialized, active
local CAST_EVENTS = {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_CASTEVENT"}
local function SyncEvents()
    if not module.events then return end
    if module.listening == active then return end
    module.listening = active
    module.events:UnregisterAllEvents()
    if active then
        for _, ev in ipairs(CAST_EVENTS) do module.events:RegisterEvent(ev) end
    end
end
module.enable = function(self)
    active = FT.IsEnabled(module.title) and FT.OwnsNameplates()
    for plate in pairs(FT.libnameplate.plates) do
        if plate.fctCastbar then
            plate.fctCastbar.nextQuery = nil
            if not active then plate.fctCastbar:Hide() end
        end
    end
    SyncEvents()
    if initialized then return end
    initialized = true

    local backdrop = {
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    }

    local function create_castbar(plate)
        plate.fctCastbar = CreateFrame("StatusBar", nil, plate)
        plate.castbar = plate.fctCastbar -- compatibility alias; ownership stays explicit
        plate.fctCastbar:EnableMouse(false)
        plate.fctCastbar:SetPoint("BOTTOM", plate, "BOTTOM", 8, -11)
        plate.fctCastbar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        plate.fctCastbar:SetStatusBarColor(1, 0.8, 0, 1)
        plate.fctCastbar:SetWidth(math.max(12, plate:GetWidth() - 22))
        plate.fctCastbar:SetHeight(10)
        FT.HookScript(plate, "OnSizeChanged", function()
            if FT.LayoutNameplateCastbar then FT.LayoutNameplateCastbar(plate) end
        end)

        plate.fctCastbar.texture = CreateFrame("Frame", nil, plate.fctCastbar)
        plate.fctCastbar.texture:EnableMouse(false)
        plate.fctCastbar.texture:SetPoint("RIGHT", plate.fctCastbar, "LEFT", 0, 0)
        plate.fctCastbar.texture:SetHeight(18)
        plate.fctCastbar.texture:SetWidth(18)
        plate.fctCastbar.texture.icon = plate.fctCastbar.texture:CreateTexture(nil, "BACKGROUND")
        plate.fctCastbar.texture.icon:SetPoint("CENTER", 0, 0)
        plate.fctCastbar.texture.icon:SetWidth(12)
        plate.fctCastbar.texture.icon:SetHeight(12)
        plate.fctCastbar.texture:SetBackdrop(backdrop)
        plate.fctCastbar.texture:SetBackdropBorderColor(1, 0.8, 0)

        plate.fctCastbar.bg = plate.fctCastbar:CreateTexture(nil, "BACKGROUND")
        plate.fctCastbar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        plate.fctCastbar.bg:SetVertexColor(0.1, 0.1, 0, 0.8)
        plate.fctCastbar.bg:SetAllPoints(true)

        plate.fctCastbar.spark = plate.fctCastbar:CreateTexture(nil, "OVERLAY")
        plate.fctCastbar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        plate.fctCastbar.spark:SetWidth(20)
        plate.fctCastbar.spark:SetHeight(20)
        plate.fctCastbar.spark:SetBlendMode("ADD")

        plate.fctCastbar.backdrop = CreateFrame("Frame", nil, plate.fctCastbar)
        plate.fctCastbar.backdrop:EnableMouse(false)
        plate.fctCastbar.backdrop:SetFrameLevel(plate.fctCastbar:GetFrameLevel())
        plate.fctCastbar.backdrop:SetPoint("TOPLEFT", plate.fctCastbar, "TOPLEFT", -3, 3)
        plate.fctCastbar.backdrop:SetPoint("BOTTOMRIGHT", plate.fctCastbar, "BOTTOMRIGHT", 3, -3)
        plate.fctCastbar.backdrop:SetBackdrop(backdrop)
        plate.fctCastbar.backdrop:SetBackdropBorderColor(1, 0.8, 0)

        plate.fctCastbar.text = plate.fctCastbar:CreateFontString(nil, "OVERLAY", "GameFontWhite")
        plate.fctCastbar.text:SetPoint("CENTER", plate.fctCastbar, "CENTER", 0, 0)
        local font, size = plate.fctCastbar.text:GetFont()
        plate.fctCastbar.text:SetFont(font, size - 3, "THINOUTLINE")

        plate.fctCastbar:Hide()
        if FT.LayoutNameplateCastbar then FT.LayoutNameplateCastbar(plate) end
        if FT.Nameplates then FT.Nameplates:LayoutExtras(plate) end
    end

    local libnameplate = FT.libnameplate

    -- Lifecycle cleanup touches only our castbar, even if another addon
    -- subsequently uses the shared native plate.fctCastbar field.
    local function Reset(plate)
        local cb = plate.fctCastbar
        if cb then
            cb:Hide()
            cb.lastSpell, cb.lastMax, cb.lastTexture, cb.lastSparkX = nil, nil, nil, nil
            cb.lastInterruptible, cb.castUnit, cb.nextQuery = nil, nil, nil
        end
    end
    table.insert(libnameplate.OnShow, function(plate)
        if plate.fctCastbar and plate.fctCastbar.castUnit ~= plate.fctUnitGUID then Reset(plate) end
    end)
    table.insert(libnameplate.OnAdded, Reset)
    table.insert(libnameplate.OnRemoved, Reset)

    table.insert(libnameplate.OnUpdate, function(plate, unit, now)
        if not active then return end
        if not plate.fctCastbar then create_castbar(plate) end

        if not plate:IsShown() then
            if plate.fctCastbar:IsShown() then
                plate.fctCastbar:Hide()
                plate.fctCastbar.lastSpell = nil
                plate.fctCastbar.lastMax = nil
                plate.fctCastbar.lastTexture = nil
                plate.fctCastbar.lastSparkX = nil
                plate.fctCastbar.lastInterruptible = nil
            end
            return
        end

        local cb = plate.fctCastbar
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
            cb.castUnit, cb.nextQuery = unit, now + (cast and 0.1 or 0.2)
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

            if not plate.fctCastbar:IsShown() then
                plate.fctCastbar:Show()
            end

            if plate.fctCastbar.lastMax ~= max then
                plate.fctCastbar.lastMax = max
                plate.fctCastbar:SetMinMaxValues(0, max)
            end

            -- Visual styling for interruptible vs uninterruptible casts
            local showUninterruptible = (not FostercareTweaks_Config or FostercareTweaks_Config["Uninterruptible Castbars"] ~= 0)
            local isUninterruptible = showUninterruptible and notInterruptible

            if plate.fctCastbar.lastInterruptible ~= isUninterruptible then
                plate.fctCastbar.lastInterruptible = isUninterruptible
                if isUninterruptible then
                    plate.fctCastbar:SetStatusBarColor(0.65, 0.65, 0.65, 1)
                    plate.fctCastbar.backdrop:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
                    plate.fctCastbar.texture:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
                else
                    plate.fctCastbar:SetStatusBarColor(1, 0.8, 0, 1)
                    plate.fctCastbar.backdrop:SetBackdropBorderColor(1, 0.8, 0, 1)
                    plate.fctCastbar.texture:SetBackdropBorderColor(1, 0.8, 0, 1)
                end
            end

            plate.fctCastbar:SetValue(cur)

            local percent = max > 0 and (cur / max) or 0
            local width = plate.fctCastbar:GetWidth()
            local sparkX = math.floor(width * percent)
            if plate.fctCastbar.lastSparkX ~= sparkX then
                plate.fctCastbar.lastSparkX = sparkX
                plate.fctCastbar.spark:SetPoint("CENTER", plate.fctCastbar, "LEFT", sparkX, 0)
            end

            if plate.fctCastbar.lastSpell ~= cast then
                plate.fctCastbar.lastSpell = cast
                plate.fctCastbar.text:SetText(cast)
            end

            if plate.fctCastbar.lastTexture ~= texture then
                plate.fctCastbar.lastTexture = texture
                if texture then
                    plate.fctCastbar.texture.icon:SetTexture(texture)
                    plate.fctCastbar.texture.icon:Show()
                else
                    plate.fctCastbar.texture.icon:Hide()
                end
            end

        else
            if plate.fctCastbar:IsShown() then
                plate.fctCastbar:Hide()
                plate.fctCastbar.lastSpell = nil
                plate.fctCastbar.lastMax = nil
                plate.fctCastbar.lastTexture = nil
                plate.fctCastbar.lastSparkX = nil
                plate.fctCastbar.lastInterruptible = nil
            end
        end
    end)

    local events = CreateFrame("Frame", "FCTweaksNameplateCastEvents", UIParent)
    module.events = events
    SyncEvents()
    FT.SetEventHandler(events, function(_, ev, unit)
        if not active or not FT.OwnsNameplates() or not unit then return end
        local plate = C_NamePlate.GetNamePlateForUnit(unit)
        if plate and plate.fctCastbar then plate.fctCastbar.nextQuery = nil end
    end)
end
