local FT = FostercareTweaks
if not FT then return end

-- Related modules; settings remain independent.

do
-- Shows an enemy castbar on target unit frame using event-driven state (ClassicAPI & SuperWoW)


local module = FT:register({
    title = "Enemy Castbars",
    description = "Shows an enemy castbar on target unit frame.",
    category = "Unit Frames",
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

castbar.text = castbar:CreateFontString(nil, "OVERLAY", "GameFontWhite")
castbar.text:SetPoint("CENTER", castbar, "CENTER", 0, 0)
local font, size = castbar.text:GetFont()
castbar.text:SetFont(font, (size or 12) - 2, "THINOUTLINE")

local function GetCastingInfo(unit)
    return C_Spell.UnitCastingInfo(unit)
end

local function GetChannelInfo(unit)
    return C_Spell.UnitChannelInfo(unit)
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
    castbar.lastSparkX = nil
    castbar:SetScript("OnUpdate", nil)
end

local function UpdateAnchor()
    local UF = FT.UnitFrames
    local owner = UF and UF:IsModernTarget() and UF.targetFrame or TargetFrame
    if castbar:GetParent() ~= owner then castbar:SetParent(owner); castbar.lastYOffset = nil end
    if owner ~= TargetFrame then
        local row = owner.auraContainer and owner.auraContainer.debuffFrame
        local anchor = row and row:IsShown() and (row.occupiedCount or 0) > 0 and row or owner
        castbar:SetWidth(math.max(24, owner:GetWidth() - 28))
        castbar:ClearAllPoints()
        castbar:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", -3, -7)
        return
    end
    castbar:SetWidth(140)
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
    local sparkX = math.floor(castbar:GetWidth() * percent + 0.5)
    if castbar.lastSparkX ~= sparkX then
        castbar.lastSparkX = sparkX
        castbar.spark:SetPoint("CENTER", castbar, "LEFT", sparkX, 0)
    end

    if now >= castbar.endTime then
        StopCast()
    end
end

local function UpdateCast()
    if FostercareTweaks_Config["Enemy Castbars"] == 0 then StopCast(); return end
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
        local showUninterruptible = (not FostercareTweaks_Config or FostercareTweaks_Config["Uninterruptible Castbars"] ~= 0)
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
        castbar:SetScript("OnUpdate", Castbar_OnUpdate)

        if not castbar:IsShown() then
            castbar:Show()
        end
        Castbar_OnUpdate()
    else
        StopCast()
    end
end

module.enable = function(self)
    if self.frame then return end
    FT.RefreshTargetCastbar = UpdateCast
    FT.LayoutTargetCastbar = UpdateAnchor
    local eventFrame = CreateFrame("Frame", "FCTweaksTargetCastbarEvents", UIParent)
    self.frame = eventFrame
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    eventFrame:RegisterEvent("UNIT_CASTEVENT")

    FT.SetEventHandler(eventFrame, function(_, ev, a1, a2, a3, a4, a5)
        if not ev then return end

        if ev == "PLAYER_TARGET_CHANGED" or ev == "PLAYER_ENTERING_WORLD" then
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
            if a1 == "target" or (a1 and (a1 == UnitGUID("target") or UnitIsUnit(a1, "target"))) then
                if ev == "UNIT_SPELLCAST_STOP" or ev == "UNIT_SPELLCAST_FAILED" or ev == "UNIT_SPELLCAST_INTERRUPTED" or ev == "UNIT_SPELLCAST_CHANNEL_STOP" then
                    StopCast()
                else
                    UpdateCast()
                end
            end
        end
    end)

    FT.hooksecurefunc("TargetDebuffButton_Update", function()
        if castbar:IsShown() then UpdateAnchor() end
    end)

    if TargetofTarget_Update then
        FT.hooksecurefunc("TargetofTarget_Update", function()
            if castbar:IsShown() then UpdateAnchor() end
        end)
    end

    UpdateCast()
end
end

do
-- Configuration toggle for uninterruptible castbar styling (Rule AP-10, Rule C3 compliant)


local module = FT:register({
    title = "Uninterruptible Castbars",
    description = "Changes castbar color to silver for spells that cannot be interrupted (target and nameplates).",
    category = "Unit Frames",
    enabled = true,
})
end
