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

local GOLD, GREY = { 1, 0.8, 0 }, { 0.65, 0.65, 0.65 }

-- One frame: the bar draws its own backdrop. The icon is a plain texture.
local castbar = CreateFrame("StatusBar", "FCTweaksTargetCastbar", TargetFrame)
castbar:SetWidth(140)
castbar:SetHeight(10)
castbar:SetStatusBarTexture("Interface\TargetingFrame\UI-StatusBar")
castbar:SetStatusBarColor(GOLD[1], GOLD[2], GOLD[3], 1)
castbar:SetBackdrop({ bgFile = "Interface\Buttons\WHITE8X8", edgeFile = "Interface\Buttons\WHITE8X8", edgeSize = 1 })
castbar:SetBackdropColor(0.1, 0.1, 0, 0.8)
castbar:SetBackdropBorderColor(0, 0, 0, 1)
castbar:Hide()

castbar.icon = castbar:CreateTexture(nil, "ARTWORK")
castbar.icon:SetPoint("RIGHT", castbar, "LEFT", -3, 0)
castbar.icon:SetWidth(14)
castbar.icon:SetHeight(14)
castbar.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

-- The bar fills itself from castbar.timer (SetTimerDuration, ClassicAPI), so
-- the spark rides the bar's texture and nothing runs per frame during a cast.
castbar.timer = C_DurationUtil.CreateDuration()
castbar.spark = castbar:CreateTexture(nil, "OVERLAY")
castbar.spark:SetTexture("Interface\CastingBar\UI-CastingBar-Spark")
castbar.spark:SetWidth(20)
castbar.spark:SetHeight(20)
castbar.spark:SetBlendMode("ADD")
castbar.spark:SetPoint("CENTER", castbar:GetStatusBarTexture(), "RIGHT", 0, 0)

castbar.text = castbar:CreateFontString(nil, "OVERLAY", "GameFontWhite")
castbar.text:SetPoint("CENTER", castbar, "CENTER", 0, 0)
local font, size = castbar.text:GetFont()
castbar.text:SetFont(font, (size or 12) - 2, "THINOUTLINE")

local function StopCast()
    -- Ctrl+Shift keeps the bar up so it can be grabbed (move-unitframes.lua).
    if not castbar.fctForcedShown then castbar:Hide() end
    castbar.endSec = nil
    castbar.lastChannel = nil
    castbar.lastSpell = nil
    castbar.lastTexture = nil
    castbar.lastInterruptible = nil
end

-- Default spot under the target frame, lower while target-of-target shows.
-- A position saved by Ctrl+Shift replaces it.
local function UpdateAnchor()
    if castbar.moved then return end
    local yOffset = TargetofTargetFrame:IsShown() and -24 or -4
    if castbar.lastYOffset ~= yOffset then
        castbar.lastYOffset = yOffset
        castbar:ClearAllPoints()
        castbar:SetPoint("BOTTOM", TargetFrame, "BOTTOM", -12, yOffset)
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
        local locked = notInterruptible and true or false
        if castbar.lastInterruptible ~= locked then
            castbar.lastInterruptible = locked
            local c = locked and GREY or GOLD
            castbar:SetStatusBarColor(c[1], c[2], c[3], 1)
        end

        if castbar.lastSpell ~= cast then
            castbar.text:SetText(cast)
            castbar.lastSpell = cast
        end

        if castbar.lastTexture ~= texture then
            if texture then
                castbar.icon:SetTexture(texture)
                castbar.icon:Show()
            else
                castbar.icon:Hide()
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

    FT.hooksecurefunc("TargetofTarget_Update", function()
        if castbar:IsShown() then UpdateAnchor() end
    end)

    -- Ctrl+Shift moves the bar. The position follows the target frame.
    castbar.moved = FT.RestoreFramePosition(castbar, "target_castbar", TargetFrame)
    castbar.fctRestoreShown = function(bar) if not bar.endSec then bar:Hide() end end
    FT.RegisterFrameMover(castbar, "target_castbar", "Cast bar", TargetFrame, function() castbar.moved = true end)
    UpdateAnchor()

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
