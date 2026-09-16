-- FostercareTweaks: mods/cooldown-numbers.lua
local _G = FostercareTweaks.GetGlobalEnv()
local T = FostercareTweaks.T
local TimeConvert = FostercareTweaks.TimeConvert

local module = FostercareTweaks:register({
    title = T["Cooldown Numbers"],
    description = T["Display the remaining duration as text on every cooldown."],
    category = T["Action Bar"],
    enabled = true,
})

local function CooldownOnUpdate()
    local parent = this:GetParent()
    if not parent then
        this:Hide()
        return
    end

    local now = GetTime()
    if (this.tick or 0) > now then return end
    this.tick = now + 0.1

    -- Inherit alpha safely from cooldown model frame
    local alpha = (parent.GetAlpha and parent:GetAlpha()) or 1
    if this.lastAlpha ~= alpha then
        this.lastAlpha = alpha
        this:SetAlpha(alpha)
    end

    if this.start and this.duration then
        local remaining
        if this.start <= now then
            remaining = this.duration - (now - this.start)
        elseif (this.start - now) < 1.0 then
            -- Sub-second floating point jitter at moment of cast
            remaining = this.duration
        else
            -- 32-bit millisecond reboot epoch wrap (WoWUIBugs #47)
            local wallTime = time()
            local startupTime = wallTime - now
            local cdTime = (2 ^ 32) / 1000 - this.start
            local cdStartTime = startupTime - cdTime
            local cdEndTime = cdStartTime + this.duration
            remaining = cdEndTime - wallTime
        end

        if remaining and remaining > 0 and remaining <= (this.duration + 5) then
            local text = TimeConvert(remaining)
            if this.lastText ~= text then
                this.lastText = text
                this.text:SetText(text)
            end
        else
            this.lastText = nil
            this:Hide()
        end
    else
        this.lastText = nil
        this:Hide()
    end
end

local function CreateCoolDown(cooldown, start, duration)
    local parent = cooldown:GetParent()
    if not parent or cooldown.readable then return end

    local parentname = parent.GetName and parent:GetName()
    parentname = parentname or "UnknownCooldownFrame"

    -- Parent directly to cooldown (Model frame) for guaranteed overlay above 3D sweep
    local frameName = parentname .. "CooldownText"
    if not _G[frameName] then
        cooldown.cooldowntext = CreateFrame("Frame", frameName, cooldown)
    else
        cooldown.cooldowntext = _G[frameName]
    end

    cooldown.cooldowntext:SetAllPoints(cooldown)

    local parentLevel = (parent.GetFrameLevel and parent:GetFrameLevel()) or 1
    local cdLevel = (cooldown.GetFrameLevel and cooldown:GetFrameLevel()) or parentLevel
    local frameLevel = (cdLevel > parentLevel and cdLevel or parentLevel) + 2
    cooldown.cooldowntext:SetFrameLevel(frameLevel)
    cooldown.cooldowntext:EnableMouse(false)

    if not cooldown.cooldowntext.text then
        cooldown.cooldowntext.text = cooldown.cooldowntext:CreateFontString(parentname .. "CooldownTextFont", "OVERLAY")
    end

    local size = (parent.GetHeight and parent:GetHeight()) or 0
    size = size > 0 and size * 0.64 or 12
    size = size > 16 and 16 or size

    local font = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    cooldown.cooldowntext.text:SetFont(font, size, "OUTLINE")
    cooldown.cooldowntext.text:SetPoint("CENTER", cooldown.cooldowntext, "CENTER", 0, 0)
    cooldown.cooldowntext:SetScript("OnUpdate", CooldownOnUpdate)
end

local function SetCooldown(cdFrame, start, duration, enable)
    if not cdFrame or cdFrame.noCooldownCount then return end

    if not duration or duration < 2 then
        if cdFrame.cooldowntext then
            cdFrame.cooldowntext:Hide()
        end
        return
    end

    if not cdFrame.cooldowntext then
        CreateCoolDown(cdFrame, start, duration)
    end

    if cdFrame.cooldowntext then
        if start and start > 0 and duration and duration > 0 and (not enable or enable > 0) then
            cdFrame.cooldowntext.start = start
            cdFrame.cooldowntext.duration = duration
            cdFrame.cooldowntext.tick = 0
            cdFrame.cooldowntext:Show()
        else
            cdFrame.cooldowntext:Hide()
        end
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

    -- Sync TrinketMenu worn trinkets if present
    if _G["TrinketMenu_Trinket0Cooldown"] then
        local start, duration, enable = GetInventoryItemCooldown("player", 13)
        if start and duration and duration >= 2 and enable and enable > 0 then
            SetCooldown(_G["TrinketMenu_Trinket0Cooldown"], start, duration, enable)
        end
    end
    if _G["TrinketMenu_Trinket1Cooldown"] then
        local start, duration, enable = GetInventoryItemCooldown("player", 14)
        if start and duration and duration >= 2 and enable and enable > 0 then
            SetCooldown(_G["TrinketMenu_Trinket1Cooldown"], start, duration, enable)
        end
    end
end

module.enable = function(self)
    FostercareTweaks.hooksecurefunc("CooldownFrame_SetTimer", SetCooldown)

    local syncFrame = CreateFrame("Frame", "FCTweaksCooldownSync", UIParent)
    syncFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    syncFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    syncFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    syncFrame:SetScript("OnEvent", function()
        SyncActiveCooldowns()
    end)

    SyncActiveCooldowns()
end
