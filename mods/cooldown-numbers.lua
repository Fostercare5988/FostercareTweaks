local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/cooldown-numbers.lua
local TimeConvert = FT.TimeConvert

local module = FT:register({
    title = "Cooldown Numbers",
    description = "Show remaining cooldown time; GearRack keeps its own enabled counters.",
    category = "Action Bar",
    enabled = true,
})

local active = {}
local owned = setmetatable({}, { __mode = "k" })
local ticker
local enabled
local function NumberOwner(cooldown)
    local name = cooldown:GetName()
    if not name then return end
    -- Remember native timer state even if GearRack has not finished loading yet.
    if string.match(name,"^GearRackUIInv%d+Cooldown$") or string.match(name,"^GearRackUIMenu%d+Cooldown$")
        or string.match(name,"^GearRackTrinkets_Trinket[01]Cooldown$") or string.match(name,"^GearRackTrinkets_Menu%d+Cooldown$") then
        return name
    end
end
local function OwnerHasNumbers(owner)
    return owner and GearRack and type(GearRack.HasCooldownNumbers)=="function" and GearRack.HasCooldownNumbers(owner)
end
local function StopNumber(frame)
    active[frame] = nil
    frame.lastText = nil
    frame:Hide()
    if ticker and not next(active) then ticker:Cancel(); ticker = nil end
end

local function UpdateNumber(frame, now)
    local parent = frame:GetParent()
    if not parent then
        StopNumber(frame)
        return
    end
    if parent.noCooldownCount or parent.readable or OwnerHasNumbers(frame.numberOwner) then
        StopNumber(frame)
        return
    end
    if frame.start and frame.duration then
        local remaining
        if frame.start <= now then
            remaining = frame.duration - (now - frame.start)
        elseif (frame.start - now) < 1.0 then
            -- Sub-second floating point jitter at moment of cast
            remaining = frame.duration
        else
            -- 32-bit millisecond reboot epoch wrap (WoWUIBugs #47)
            remaining = frame.duration - (now + (2 ^ 32) / 1000 - frame.start)
        end

        if remaining and remaining > 0 and remaining <= (frame.duration + 5) then
            if not frame:IsVisible() then return end
            local alpha = parent:GetAlpha()
            if frame.lastAlpha ~= alpha then frame.lastAlpha = alpha; frame:SetAlpha(alpha) end
            local text = TimeConvert(remaining)
            if frame.lastText ~= text then
                frame.lastText = text
                frame.text:SetText(text)
            end
        else
            StopNumber(frame)
        end
    else
        StopNumber(frame)
    end
end

local function UpdateNumbers()
    local now = GetTime()
    for frame in pairs(active) do UpdateNumber(frame, now) end
end

local function CreateCoolDown(cooldown)
    local parent = cooldown:GetParent()
    if not parent or cooldown.readable then return end

    -- Each cooldown owns its overlay, including unnamed/recycled widgets.
    cooldown.cooldowntext = CreateFrame("Frame", nil, cooldown)

    cooldown.cooldowntext:SetAllPoints(cooldown)

    local parentLevel = (parent.GetFrameLevel and parent:GetFrameLevel()) or 1
    local cdLevel = (cooldown.GetFrameLevel and cooldown:GetFrameLevel()) or parentLevel
    local frameLevel = (cdLevel > parentLevel and cdLevel or parentLevel) + 2
    cooldown.cooldowntext:SetFrameLevel(frameLevel)
    cooldown.cooldowntext:EnableMouse(false)

    if not cooldown.cooldowntext.text then
        cooldown.cooldowntext.text = cooldown.cooldowntext:CreateFontString(nil, "OVERLAY")
    end

    local size = (parent.GetHeight and parent:GetHeight()) or 0
    size = size > 0 and size * 0.64 or 12
    size = size > 16 and 16 or size

    local font = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    cooldown.cooldowntext.text:SetFont(font, size, "OUTLINE")
    cooldown.cooldowntext.text:SetPoint("CENTER", cooldown.cooldowntext, "CENTER", 0, 0)
end

local function SetCooldown(cdFrame, start, duration, enable)
    if not cdFrame then return end
    local owner = NumberOwner(cdFrame)
    if owner then
        -- Remember only native cooldown arguments, never another addon's queue
        -- or text. A live option change can hand the same timer back to us.
        local state = owned[cdFrame]
        if not state then state = {}; owned[cdFrame] = state end
        state.owner, state.start, state.duration, state.enable = owner, start, duration, enable
    end
    if cdFrame.noCooldownCount or cdFrame.readable or OwnerHasNumbers(owner) then
        if cdFrame.cooldowntext then StopNumber(cdFrame.cooldowntext) end
        return
    end

    if not duration or duration < 2 then
        if cdFrame.cooldowntext then
            StopNumber(cdFrame.cooldowntext)
        end
        return
    end

    if not cdFrame.cooldowntext then
        CreateCoolDown(cdFrame)
    end

    if cdFrame.cooldowntext then
        cdFrame.cooldowntext.numberOwner = owner
        if start and start > 0 and duration and duration > 0 and (not enable or enable > 0) then
            cdFrame.cooldowntext.start = start
            cdFrame.cooldowntext.duration = duration
            active[cdFrame.cooldowntext] = true
            cdFrame.cooldowntext:Show()
            UpdateNumber(cdFrame.cooldowntext, GetTime())
            if next(active) and not ticker then ticker = C_Timer.NewTicker(0.1, UpdateNumbers) end
        else
            StopNumber(cdFrame.cooldowntext)
        end
    end
end

local function ReconcileOwner()
    for cooldown, state in pairs(owned) do
        SetCooldown(cooldown, state.start, state.duration, state.enable)
    end
end

local ACTION_BAR_BUTTON_PREFIXES = {
    "ActionButton",
    "BonusActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
}

local function SyncActiveCooldowns()
    for _, bar in ipairs(ACTION_BAR_BUTTON_PREFIXES) do
        for i = 1, 12 do
            local btn = _G[bar .. i]
            if btn and btn:IsVisible() then
                local cd = _G[bar .. i .. "Cooldown"]
                local slot = ActionButton_GetPagedID and ActionButton_GetPagedID(btn)
                if cd and slot and HasAction(slot) then
                    local start, duration, enable = GetActionCooldown(slot)
                    if start and duration and duration >= 2 and enable and enable > 0 then
                        SetCooldown(cd, start, duration, enable)
                    end
                end
            end
        end
    end

    -- Sync GearRack trinket buttons when GearRack delegates number rendering.
    if _G["GearRackTrinkets_Trinket0Cooldown"] and not OwnerHasNumbers("GearRackTrinkets_Trinket0Cooldown") then
        local start, duration, enable = GetInventoryItemCooldown("player", 13)
        if start and duration and duration >= 2 and enable and enable > 0 then
            SetCooldown(_G["GearRackTrinkets_Trinket0Cooldown"], start, duration, enable)
        end
    end
    if _G["GearRackTrinkets_Trinket1Cooldown"] and not OwnerHasNumbers("GearRackTrinkets_Trinket1Cooldown") then
        local start, duration, enable = GetInventoryItemCooldown("player", 14)
        if start and duration and duration >= 2 and enable and enable > 0 then
            SetCooldown(_G["GearRackTrinkets_Trinket1Cooldown"], start, duration, enable)
        end
    end
end

module.enable = function(self)
    if enabled then return end
    enabled = true
    FT.hooksecurefunc("CooldownFrame_SetTimer", SetCooldown)
    FT.HookAddonOrVariable("GearRack", function()
        if type(GearRack.CooldownOptionsChanged)=="function" then
            FT.hooksecurefunc(GearRack,"CooldownOptionsChanged",ReconcileOwner)
        end
        ReconcileOwner()
    end)

    local syncFrame = CreateFrame("Frame", "FCTweaksCooldownSync", UIParent)
    syncFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    syncFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    syncFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    FT.SetEventHandler(syncFrame, function()
        SyncActiveCooldowns()
    end)

    SyncActiveCooldowns()
end
