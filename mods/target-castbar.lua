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
-- The bar fills itself from castbar.timer (SetTimerDuration, ClassicAPI), so
-- the spark rides the bar's texture and nothing runs per frame during a cast.
castbar.spark:SetPoint("CENTER", castbar:GetStatusBarTexture(), "RIGHT", 0, 0)
castbar.timer = C_DurationUtil.CreateDuration()

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

local function StopCast()
    if castbar:IsShown() then
        castbar:Hide()
    end
    castbar.endSec = nil
    castbar.lastChannel = nil
    castbar.lastSpell = nil
    castbar.lastTexture = nil
    castbar.lastInterruptible = nil
end

local function UpdateAnchor()
    if castbar:GetParent() ~= TargetFrame then castbar:SetParent(TargetFrame); castbar.lastYOffset = nil end
    castbar:SetWidth(140)
    -- Blizzard's own target auras are always replaced by the improved ones, so
    -- only the target-of-target frame moves the bar down.
    local yOffset = TargetofTargetFrame and TargetofTargetFrame:IsShown() and -24 or -4

    if castbar.lastYOffset ~= yOffset then
        castbar:ClearAllPoints()
        castbar:SetPoint("BOTTOM", TargetFrame, "BOTTOM", -12, yOffset)
        castbar.lastYOffset = yOffset
    end
end

local function UpdateCast()
    if FostercareTweaks_Config["Enemy Castbars"] == 0 then StopCast(); return end
    if not UnitExists("target") or UnitIsDeadOrGhost("target") then
        StopCast()
        return
    end

    local cast, displayName, texture, startTime, endTime, notInterruptible
    local isChannel = false

    local isTradeskill, castID
    cast, displayName, texture, startTime, endTime, isTradeskill, castID, notInterruptible = C_Spell.UnitCastingInfo("target")

    if not cast then
        cast, displayName, texture, startTime, endTime, isTradeskill, notInterruptible = C_Spell.UnitChannelInfo("target")
        if cast then isChannel = true end
    end

    if cast and startTime and endTime and endTime > startTime and endTime > GetTime() * 1000 then
        local endSec = endTime / 1000
        castbar.timer:SetTimeSpan(startTime / 1000, endSec)
        if castbar.lastChannel ~= isChannel then
            castbar.lastChannel = isChannel
            castbar:SetTimerDuration(castbar.timer, Enum.StatusBarInterpolation.Immediate,
                isChannel and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime)
        end
        -- The stop event normally ends the cast; this covers a missed one.
        if castbar.endSec ~= endSec then
            castbar.endSec = endSec
            C_Timer.After(endSec - GetTime() + 0.05, function()
                if castbar.endSec == endSec and GetTime() >= endSec then StopCast() end
            end)
        end

        -- Casts you cannot interrupt show in grey.
        local isUninterruptible = notInterruptible and true or false

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
    else
        StopCast()
    end
end

-- ClassicAPI fires these once per token pointing at the caster; the "target"
-- copy is the one this bar shows. INTERRUPTIBLE / NOT_INTERRUPTIBLE re-read
-- notInterruptible when it flips mid-cast. DELAYED, CHANNEL_UPDATE and FAILED
-- never fire for other units (the server sends pushback to the caster only).
local CAST_EVENTS = {
    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_STOP",
    "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
}
local STOP_EVENTS = { UNIT_SPELLCAST_STOP = true, UNIT_SPELLCAST_INTERRUPTED = true,
    UNIT_SPELLCAST_CHANNEL_STOP = true }

module.enable = function(self)
    if self.frame then self:apply(); return end
    FT.RefreshTargetCastbar = function() self:apply() end
    FT.LayoutTargetCastbar = UpdateAnchor
    local eventFrame = CreateFrame("Frame", "FCTweaksTargetCastbarEvents", UIParent)
    self.frame = eventFrame

    -- Cast events arrive for the "target" token only (module.apply).
    FT.SetEventHandler(eventFrame, function(_, ev)
        if STOP_EVENTS[ev] then StopCast() else UpdateCast() end
    end)

    if TargetofTarget_Update then
        FT.hooksecurefunc("TargetofTarget_Update", function()
            if castbar:IsShown() then UpdateAnchor() end
        end)
    end

    self:apply()
end

-- Switching this view off removes its subscriptions and animation immediately.
module.apply = function(self)
    if not self.frame then
        if FT.IsEnabled(self.title) then self:enable() end
        return
    end
    local active = FT.IsEnabled(self.title)
    if self.listening ~= active then
        self.listening = active
        self.frame:UnregisterAllEvents()
        if active then
            self.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
            self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
            for _, ev in ipairs(CAST_EVENTS) do self.frame:RegisterUnitEvent(ev, "target") end
        end
    end
    UpdateCast()
end
end
