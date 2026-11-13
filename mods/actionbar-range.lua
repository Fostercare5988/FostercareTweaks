local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/actionbar-range.lua
-- The stock action buttons' range colours without a script per button per
-- frame. FrameXML gives every action button an OnUpdate (ActionButton_OnUpdate)
-- that runs each frame and reads the range every 0.2 s, also while nothing
-- changes. Here ClassicAPI paints the range when it changes
-- (C_ActionBar.EnableActionRangeCheck for each button's slot, then
-- ACTION_RANGE_CHECK_UPDATE), and the stock OnUpdate runs only while a button
-- has the two jobs that need a timer: the auto attack or auto shot flash, and
-- an open tooltip. The colours are the game's own. Extra Row 1 is tracked too
-- (ActionBars.lua).

local module = FT:register({
    title = "Action Button Range",
    always = true,
})

local R = {}
FT.ActionButtonRange = R
local tracked = {}        -- button -> true
local bySlot = {}         -- slot -> { [button] = true }
local state = {}          -- slot -> 1 in range, 0 out of range, nil not checked

-- The stock range look (ActionButton_OnUpdate): the dot of an unbound button
-- shows unless the target is in range; a button with an action has a red key
-- out of range, else grey.
local function Paint(button)
    local hotkey = button.fctHotkey
    local inRange = state[button.fctRangeSlot]
    if hotkey:GetText() == RANGE_INDICATOR then
        if inRange == 1 then hotkey:Hide() else hotkey:Show() end
    end
    if button.rangeTimer then           -- set by ActionButton_Update for a slot with an action
        if inRange == 0 then hotkey:SetVertexColor(1.0, 0.1, 0.1) else hotkey:SetVertexColor(0.6, 0.6, 0.6) end
    end
end

-- The client counts the enables per slot, so each button enables its own slot
-- and gives it back when it shows another one (a page, stance or bonus bar change).
local function Retarget(button)
    local slot = button.action
    local old = button.fctRangeSlot
    if slot == old then return end
    if old then
        bySlot[old][button] = nil
        C_ActionBar.EnableActionRangeCheck(old, false)
    end
    button.fctRangeSlot = slot
    if slot then
        local buttons = bySlot[slot]
        if not buttons then buttons = {}; bySlot[slot] = buttons end
        buttons[button] = true
        -- The next check reports the slot's state, changed or not.
        C_ActionBar.EnableActionRangeCheck(slot, true)
    end
end

-- The stock OnUpdate, only while it has work; it stops itself after.
local function Animate()
    ActionButton_OnUpdate(arg1)
    if this.flashing ~= 1 and not this.updateTooltip then this:SetScript("OnUpdate", nil) end
end

local function Wake(button)
    if tracked[button] and not button:GetScript("OnUpdate") then button:SetScript("OnUpdate", Animate) end
end

function R.Track(button)
    if tracked[button] then return end
    tracked[button] = true
    button.fctHotkey = _G[button:GetName() .. "HotKey"]
    button:SetScript("OnUpdate", nil)
    Retarget(button)
    Paint(button)
    if button.flashing == 1 or button.updateTooltip then Wake(button) end
end

-- FrameXML calls these with the button as `this`.
local function Updated()
    if tracked[this] then Retarget(this); Paint(this) end
end
local function HotkeysUpdated() if tracked[this] then Paint(this) end end
local function NeedsTimer() Wake(this) end

local STOCK = { "Action", "BonusAction", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft" }

module.enable = function()
    local events = CreateFrame("Frame", "FCTweaksActionRange", UIParent)
    events:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")
    FT.SetEventHandler(events, function(_, _, slot, inRange, checksRange)
        state[slot] = checksRange and (inRange and 1 or 0) or nil
        local buttons = bySlot[slot]
        if buttons then for button in pairs(buttons) do Paint(button) end end
    end)
    hooksecurefunc("ActionButton_Update", Updated)
    hooksecurefunc("ActionButton_UpdateHotkeys", HotkeysUpdated)
    hooksecurefunc("ActionButton_StartFlash", NeedsTimer)
    hooksecurefunc("ActionButton_SetTooltip", NeedsTimer)
    for _, prefix in ipairs(STOCK) do
        for i = 1, NUM_ACTIONBAR_BUTTONS do R.Track(_G[prefix .. "Button" .. i]) end
    end
end
