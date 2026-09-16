-- FostercareTweaks: mods/target-castbar.lua
-- Shows an enemy castbar on target unit frame using event-driven state (ClassicAPI & SuperWoW)

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Enemy Castbars"],
    description = T["Shows an enemy castbar on target unit frame."],
    category = T["Unit Frames"],
    enabled = true,
})

local castbar = CreateFrame("StatusBar", "FCTweaksTargetCastbar", TargetFrame)
castbar:SetPoint("BOTTOM", TargetFrame, "BOTTOM", -12, -4)
castbar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
castbar:SetStatusBarColor(1, 0.8, 0, 1)
castbar:SetWidth(140)
castbar:SetHeight(10)
castbar:Hide()

castbar.texture = CreateFrame("Frame", nil, castbar)
castbar.texture:SetPoint("RIGHT", castbar, "LEFT", -2, 0)
castbar.texture:SetHeight(20)
castbar.texture:SetWidth(20)

castbar.texture.icon = castbar.texture:CreateTexture(nil, "BACKGROUND")
castbar.texture.icon:SetPoint("CENTER", 0, 0)
castbar.texture.icon:SetWidth(16)
castbar.texture.icon:SetHeight(16)
castbar.texture:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})

castbar.bg = castbar:CreateTexture(nil, "BACKGROUND")
castbar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
castbar.bg:SetVertexColor(0.1, 0.1, 0, 0.8)
castbar.bg:SetAllPoints(true)

castbar.spark = castbar:CreateTexture(nil, "OVERLAY")
castbar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
castbar.spark:SetWidth(20)
castbar.spark:SetHeight(20)
castbar.spark:SetBlendMode("ADD")

castbar.backdrop = CreateFrame("Frame", nil, castbar)
castbar.backdrop:SetFrameStrata("BACKGROUND")
castbar.backdrop:SetPoint("TOPLEFT", castbar, "TOPLEFT", -3, 3)
castbar.backdrop:SetPoint("BOTTOMRIGHT", castbar, "BOTTOMRIGHT", 3, -3)
castbar.backdrop:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
castbar.backdrop:SetBackdropBorderColor(1, 0.8, 0, 1)
castbar.texture:SetBackdropBorderColor(1, 0.8, 0, 1)

castbar.text = castbar:CreateFontString(nil, "HIGH", "GameFontWhite")
castbar.text:SetPoint("CENTER", castbar, "CENTER", 0, 0)
local font, size = castbar.text:GetFont()
castbar.text:SetFont(font, (size or 12) - 2, "THINOUTLINE")

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

local function StopCast()
    if castbar:IsShown() then
        castbar:Hide()
    end
    castbar.cast = nil
    castbar.startTime = nil
    castbar.endTime = nil
    castbar.duration = nil
    castbar.lastSpell = nil
    castbar.lastTexture = nil
    castbar.lastInterruptible = nil
end

local function UpdateAnchor()
    local yOffset = -4
    local targetOfTarget = TargetofTargetFrame and TargetofTargetFrame:IsShown()
    local debuff11 = TargetFrameDebuff11 and TargetFrameDebuff11:IsShown()
    local debuff7 = TargetFrameDebuff7 and TargetFrameDebuff7:IsShown()
    local buff1 = TargetFrameBuff1 and TargetFrameBuff1:IsShown()

    if targetOfTarget then
        if debuff11 and buff1 then
            yOffset = -65
        elseif debuff11 then
            yOffset = -45
        else
            yOffset = -24
        end
    elseif debuff7 then
        yOffset = -24
    end

    if castbar.lastYOffset ~= yOffset then
        castbar:ClearAllPoints()
        castbar:SetPoint("BOTTOM", TargetFrame, "BOTTOM", -12, yOffset)
        castbar.lastYOffset = yOffset
    end
end

local function Castbar_OnUpdate()
    if not castbar.startTime or not castbar.endTime or not castbar.duration then
        StopCast()
        return
    end

    local now = GetTime()
    local cur
    if castbar.isChannel then
        cur = castbar.endTime - now
    else
        cur = now - castbar.startTime
    end

    if cur < 0 then cur = 0 end
    if cur > castbar.duration then cur = castbar.duration end

    castbar:SetValue(cur)

    local percent = (castbar.duration > 0) and (cur / castbar.duration) or 0
    castbar.spark:SetPoint("CENTER", castbar, "LEFT", castbar:GetWidth() * percent, 0)

    if now >= castbar.endTime then
        StopCast()
    end
end

castbar:SetScript("OnUpdate", Castbar_OnUpdate)

local function UpdateCast()
    if not UnitExists("target") or (UnitIsDeadOrGhost and UnitIsDeadOrGhost("target")) then
        StopCast()
        return
    end

    local cast, displayName, texture, startTime, endTime, notInterruptible
    local isChannel = false

    local isTradeskill, castID
    cast, displayName, texture, startTime, endTime, isTradeskill, castID, notInterruptible = GetCastingInfo("target")

    if not cast then
        cast, displayName, texture, startTime, endTime, isTradeskill, notInterruptible = GetChannelInfo("target")
        if cast then isChannel = true end
    end

    if cast and startTime and endTime and endTime > startTime then
        local duration = (endTime - startTime) / 1000
        castbar.duration = duration
        castbar.startTime = startTime / 1000
        castbar.endTime = endTime / 1000
        castbar.isChannel = isChannel

        castbar:SetMinMaxValues(0, duration)

        -- Visual styling for interruptible vs uninterruptible casts
        local showUninterruptible = (not FostercareTweaks_Config or FostercareTweaks_Config[T["Uninterruptible Castbars"]] ~= 0)
        local isUninterruptible = showUninterruptible and notInterruptible

        if castbar.lastInterruptible ~= isUninterruptible then
            castbar.lastInterruptible = isUninterruptible
            if isUninterruptible then
                castbar:SetStatusBarColor(0.65, 0.65, 0.65, 1)
                castbar.backdrop:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
                castbar.texture:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
            else
                castbar:SetStatusBarColor(1, 0.8, 0, 1)
                castbar.backdrop:SetBackdropBorderColor(1, 0.8, 0, 1)
                castbar.texture:SetBackdropBorderColor(1, 0.8, 0, 1)
            end
        end

        if castbar.lastSpell ~= cast then
            castbar.text:SetText(cast)
            castbar.lastSpell = cast
        end

        if castbar.lastTexture ~= texture then
            if texture then
                castbar.texture.icon:SetTexture(texture)
                castbar.texture.icon:Show()
            else
                castbar.texture.icon:Hide()
            end
            castbar.lastTexture = texture
        end

        UpdateAnchor()

        if not castbar:IsShown() then
            castbar:Show()
        end
        Castbar_OnUpdate()
    else
        StopCast()
    end
end

module.enable = function(self)
    local eventFrame = CreateFrame("Frame", "FCTweaksTargetCastbarEvents", UIParent)
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    eventFrame:RegisterEvent("UNIT_CASTEVENT")

    eventFrame:SetScript("OnEvent", function(arg1_param, arg2_param, arg3_param, arg4_param, arg5_param, arg6_param, arg7_param)
        local ev, a1, a2, a3, a4, a5
        if type(arg1_param) == "table" and type(arg2_param) == "string" then
            ev = arg2_param
            a1 = arg3_param
            a2 = arg4_param
            a3 = arg5_param
            a4 = arg6_param
            a5 = arg7_param
        else
            ev = (type(arg1_param) == "string" and arg1_param) or event or _G.event
            a1 = (type(arg1_param) == "string" and arg2_param) or arg1 or _G.arg1
            a2 = (type(arg1_param) == "string" and arg3_param) or arg2 or _G.arg2
            a3 = (type(arg1_param) == "string" and arg4_param) or arg3 or _G.arg3
            a4 = (type(arg1_param) == "string" and arg5_param) or arg4 or _G.arg4
            a5 = (type(arg1_param) == "string" and arg6_param) or arg5 or _G.arg5
        end

        if not ev then return end

        if ev == "PLAYER_TARGET_CHANGED" then
            UpdateCast()
        elseif ev == "UNIT_CASTEVENT" then
            local targetGUID = UnitGUID and UnitGUID("target")
            if targetGUID and a1 == targetGUID then
                if a3 == "START" or a3 == "CHANNEL" then
                    UpdateCast()
                elseif a3 == "FAIL" or a3 == "INTERRUPT" then
                    StopCast()
                end
            end
        elseif string.find(ev, "^UNIT_SPELLCAST_") then
            if a1 == "target" then
                if ev == "UNIT_SPELLCAST_STOP" or ev == "UNIT_SPELLCAST_FAILED" or ev == "UNIT_SPELLCAST_INTERRUPTED" or ev == "UNIT_SPELLCAST_CHANNEL_STOP" then
                    StopCast()
                else
                    UpdateCast()
                end
            end
        end
    end)

    if FostercareTweaks.hooksecurefunc then
        FostercareTweaks.hooksecurefunc("TargetFrame_UpdateAuras", function()
            if castbar:IsShown() then
                UpdateAnchor()
            end
        end)

        if TargetofTarget_Update then
            FostercareTweaks.hooksecurefunc("TargetofTarget_Update", function()
                if castbar:IsShown() then
                    UpdateAnchor()
                end
            end)
        end
    end

    UpdateCast()
end
