-- FostercareTweaks: mods/nameplate-castbar.lua
-- Adds a castbar to nameplates using native UnitCastingInfo/UnitChannelInfo

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Nameplate Castbar"],
    description = T["Adds a castbar to the nameplate based on unit casting information."],
    expansions = { ["vanilla"] = true, ["tbc"] = false },
    category = T["Nameplates"],
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
        plate.castbar:SetWidth(plate:GetWidth() - 22)
        plate.castbar:SetHeight(10)

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

        plate.castbar.text = plate.castbar:CreateFontString(nil, "HIGH", "GameFontWhite")
        plate.castbar.text:SetPoint("CENTER", plate.castbar, "CENTER", 0, 0)
        local font, size = plate.castbar.text:GetFont()
        plate.castbar.text:SetFont(font, size - 3, "THINOUTLINE")

        plate.castbar:Hide()
    end

    local libnameplate = FostercareTweaks.libnameplate or (ShaguTweaks and ShaguTweaks.libnameplate)
    if not libnameplate then return end

    -- OnShow frame cleanup: eliminates recycled ghost casts from prior units
    table.insert(libnameplate.OnShow, function(plate)
        if plate.castbar then
            plate.castbar:Hide()
            plate.castbar.lastSpell = nil
            plate.castbar.lastMax = nil
            plate.castbar.lastTexture = nil
            plate.castbar.lastSparkX = nil
            plate.castbar.lastInterruptible = nil
        end
    end)

    -- SuperWoW UNIT_CASTEVENT Network Cache: tracks untargeted on-screen mob casts
    local guid_casts = {}

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("UNIT_CASTEVENT")
    eventFrame:SetScript("OnEvent", function(self_or_arg1, ev, a1, a2, a3, a4, a5)
        local guid, target, event_type, spell_id, timer
        if type(self_or_arg1) == "table" and ev then
            guid = a1 or _G.arg1
            target = a2 or _G.arg2
            event_type = a3 or _G.arg3
            spell_id = a4 or _G.arg4
            timer = a5 or _G.arg5
        else
            guid = _G.arg1
            target = _G.arg2
            event_type = _G.arg3
            spell_id = _G.arg4
            timer = _G.arg5
        end

        if not guid or type(guid) ~= "string" then return end

        if event_type == "START" or event_type == "CAST" or event_type == "CHANNEL" then
            local spell, rank, icon
            if SpellInfo and spell_id then
                spell, rank, icon = SpellInfo(spell_id)
            end
            spell = spell or UNKNOWN
            icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark"

            local duration = timer or 0
            local now = GetTime()
            local startTime = now * 1000
            local endTime = startTime + duration

            if not guid_casts[guid] then guid_casts[guid] = {} end
            local entry = guid_casts[guid]
            entry.cast = spell
            entry.texture = icon
            entry.startTime = startTime
            entry.endTime = endTime
            entry.duration = duration / 1000
            entry.isChannel = (event_type == "CHANNEL")
            entry.notInterruptible = false
        elseif event_type == "FAIL" or event_type == "INTERRUPT" then
            if guid_casts[guid] then
                guid_casts[guid].cast = nil
                guid_casts[guid].startTime = nil
                guid_casts[guid].endTime = nil
            end
        end
    end)

    local function GetCastingInfo(unit)
        if not unit then return nil end
        local fn = (C_Spell and C_Spell.UnitCastingInfo) or _G.UnitCastingInfo
        if fn then
            local ok, a, b, c, d, e, f, g, h = pcall(fn, unit)
            if ok then return a, b, c, d, e, f, g, h end
        end
    end

    local function GetChannelInfo(unit)
        if not unit then return nil end
        local fn = (C_Spell and C_Spell.UnitChannelInfo) or _G.UnitChannelInfo
        if fn then
            local ok, a, b, c, d, e, f, g = pcall(fn, unit)
            if ok then return a, b, c, d, e, f, g end
        end
    end

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

        local guid = plate.GetName and plate:GetName(1)
        local isGuid = guid and type(guid) == "string" and string.sub(guid, 1, 2) == "0x"
        local plateName = plate.name and plate.name.GetText and plate.name:GetText()

        local cast, displayName, texture, startTime, endTime, notInterruptible
        local isChannel = false

        -- 0. Check direct ClassicAPI nameplate unit token
        local unitToken = plate.unit or (plate.GetUnit and plate:GetUnit())
        if not cast and unitToken and UnitExists(unitToken) then
            local uCast, uDisplayName, uTexture, uStartTime, uEndTime, isTradeskill, castID, uNotInterruptible = GetCastingInfo(unitToken)
            if uCast then
                cast, displayName, texture, startTime, endTime, notInterruptible = uCast, uDisplayName, uTexture, uStartTime, uEndTime, uNotInterruptible
                isChannel = false
            else
                uCast, uDisplayName, uTexture, uStartTime, uEndTime, isTradeskill, uNotInterruptible = GetChannelInfo(unitToken)
                if uCast then
                    cast, displayName, texture, startTime, endTime, notInterruptible = uCast, uDisplayName, uTexture, uStartTime, uEndTime, uNotInterruptible
                    isChannel = true
                end
            end
        end

        -- 1. Check SuperWoW UNIT_CASTEVENT cache for this plate's GUID
        if not cast and isGuid and guid_casts[guid] then
            local entry = guid_casts[guid]
            if entry.cast and entry.endTime and (GetTime() * 1000) <= entry.endTime then
                cast = entry.cast
                texture = entry.texture
                startTime = entry.startTime
                endTime = entry.endTime
                isChannel = entry.isChannel
                notInterruptible = entry.notInterruptible
            else
                entry.cast = nil
            end
        end

        -- 2. Target matching (native UnitCastingInfo for current target with high precision & uninterruptible flags)
        if UnitExists("target") and plateName and plateName == UnitName("target") and plate:GetAlpha() == 1 then
            local tCast, tDisplayName, tTexture, tStartTime, tEndTime, isTradeskill, castID, tNotInterruptible = GetCastingInfo("target")
            if tCast then
                cast, displayName, texture, startTime, endTime, notInterruptible = tCast, tDisplayName, tTexture, tStartTime, tEndTime, tNotInterruptible
                isChannel = false
            else
                tCast, tDisplayName, tTexture, tStartTime, tEndTime, isTradeskill, tNotInterruptible = GetChannelInfo("target")
                if tCast then
                    cast, displayName, texture, startTime, endTime, notInterruptible = tCast, tDisplayName, tTexture, tStartTime, tEndTime, tNotInterruptible
                    isChannel = true
                end
            end
        end

        -- 3. Mouseover matching (native UnitCastingInfo for hovered unit)
        if not cast and UnitExists("mouseover") and plateName and plateName == UnitName("mouseover") then
            local mCast, mDisplayName, mTexture, mStartTime, mEndTime, isTradeskill, castID, mNotInterruptible = GetCastingInfo("mouseover")
            if mCast then
                cast, displayName, texture, startTime, endTime, notInterruptible = mCast, mDisplayName, mTexture, mStartTime, mEndTime, mNotInterruptible
                isChannel = false
            else
                mCast, mDisplayName, mTexture, mStartTime, mEndTime, isTradeskill, mNotInterruptible = GetChannelInfo("mouseover")
                if mCast then
                    cast, displayName, texture, startTime, endTime, notInterruptible = mCast, mDisplayName, mTexture, mStartTime, mEndTime, mNotInterruptible
                    isChannel = true
                end
            end
        end

        -- 4. Native C_Spell / UnitXP GUID fallback query
        if not cast and isGuid then
            local isTradeskill, castID
            cast, displayName, texture, startTime, endTime, isTradeskill, castID, notInterruptible = GetCastingInfo(guid)
            if not cast then
                cast, displayName, texture, startTime, endTime, isTradeskill, notInterruptible = GetChannelInfo(guid)
                if cast then isChannel = true end
            end
        end

        if cast and startTime and endTime and endTime > startTime then
            local max = (endTime - startTime) / 1000
            local cur
            if isChannel then
                cur = (endTime / 1000) - GetTime()
            else
                cur = GetTime() - (startTime / 1000)
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
            local showUninterruptible = (not FostercareTweaks_Config or FostercareTweaks_Config[T["Uninterruptible Castbars"]] ~= 0)
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
            local width = plate.castbar.barWidth or plate.castbar:GetWidth()
            plate.castbar.barWidth = width
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
end
