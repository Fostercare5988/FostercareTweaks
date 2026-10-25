local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/target-debufftimer.lua
local TimeConvert = FT.TimeConvert

local module = FT:register({
    title = "Debuff Timer",
    description = "Show debuff durations on the target unit frame.",
    category = "Unit Frames",
    enabled = true,
})

local active = {}
local ticker
local function StopText(text)
    active[text] = nil
    text.lastText = nil
    text:Hide()
    if ticker and not next(active) then ticker:Cancel(); ticker = nil end
end

local function IsManaged()
    local UF = FT.UnitFrames
    return UF and UF:IsImprovedStandardAuras()
end

local function UpdateText(text, now)
    local parent = text:GetParent()
    local remaining = text.start and text.duration and text.duration - (now - text.start)
    if not parent or not parent:IsShown() or not remaining or remaining <= 0 then
        StopText(text)
    elseif text:IsVisible() then
        local alpha = parent:GetAlpha()
        if text.lastAlpha ~= alpha then text.lastAlpha = alpha; text:SetAlpha(alpha) end
        local label = TimeConvert(remaining)
        if text.lastText ~= label then text.lastText = label; text.text:SetText(label) end
    end
end

local function UpdateTexts()
    local now, managed = GetTime(), IsManaged()
    for text in pairs(active) do
        if managed then StopText(text); text:GetParent():Hide()
        else UpdateText(text, now) end
    end
end

local function CreateTextCooldown(cooldown)
    if cooldown.readable then return end

    cooldown.readable = CreateFrame("Frame", nil, cooldown)
    cooldown.readable:SetAllPoints(cooldown)
    cooldown.readable:SetFrameLevel(cooldown:GetFrameLevel() + 5)
    cooldown.readable:EnableMouse(false)

    cooldown.readable.text = cooldown.readable:CreateFontString(nil, "OVERLAY")
    cooldown.readable.text:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    cooldown.readable.text:SetPoint("CENTER", cooldown.readable, "CENTER", 0, 0)

end

local function ClearTimer(button)
    if not button.cd then return end
    CooldownFrame_SetTimer(button.cd, 0, 0, 0)
    button.cd:Hide()
    if button.cd.readable then
        button.cd.readable.spellId = nil
        StopText(button.cd.readable)
    end
end

local slots = {}

module.enable = function(self)
    -- Blizzard's update fills TargetFrameDebuff1..n in aura order and colors
    -- their borders; this adds the sweep, the countdown and the stack count.
    local function UpdateTargetDebuffTimers()
        if IsManaged() then UpdateTexts(); return end

        local now, unitGUID = GetTime(), UnitGUID("target")
        -- One walk of the aura list; slot i is the aura native button i shows.
        local _, count = C_UnitAuras.GetAuraSlots("target", "HARMFUL", nil, nil, slots)
        for i = 1, MAX_TARGET_DEBUFFS do
            local button = _G["TargetFrameDebuff" .. i]
            if button and button:IsShown() and i <= (count or 0) then
                if not button.cd then
                    button.cd = CreateFrame("Cooldown", "TargetFrameDebuff" .. i .. "Cooldown", button, "CooldownFrameTemplate")
                    button.cd.noCooldownCount = true
                    button.cd:SetAllPoints(button)
                    button.cd:SetAlpha(0.8)
                    button.cd:EnableMouse(false)
                end

                local _, _, applications, _, duration, expirationTime, source, _, _, spellId =
                    C_UnitAuras.UnitAuraBySlot("target", slots[i])

                local dCount = _G["TargetFrameDebuff" .. i .. "Count"]
                if dCount then
                    if not dCount.fixup then
                        dCount.fixup = true
                        dCount:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 6, -3)
                    end
                    if applications and applications > 1 then
                        dCount:SetText("|cff00ff3b" .. applications .. "|r")
                        dCount:Show()
                    else
                        dCount:Hide()
                    end
                end

                if duration and duration > 0 and expirationTime and expirationTime > now then
                    local start = expirationTime - duration
                    CreateTextCooldown(button.cd)
                    local sourceGUID = source and UnitGUID(source)
                    local text = button.cd.readable
                    if text.unitGUID ~= unitGUID or text.sourceGUID ~= sourceGUID or
                       text.spellId ~= spellId or text.start ~= start or text.duration ~= duration then
                        CooldownFrame_SetTimer(button.cd, start, duration, 1)
                    end
                    text.unitGUID, text.sourceGUID, text.spellId = unitGUID, sourceGUID, spellId
                    text.start, text.duration = start, duration
                    text:Show()
                    button.cd:Show()
                    active[text] = true
                    UpdateText(text, now)
                    if not ticker then ticker = C_Timer.NewTicker(0.1, UpdateTexts) end
                else
                    ClearTimer(button)
                end
            elseif button then
                ClearTimer(button)
            end
        end
    end

    FT.hooksecurefunc("TargetDebuffButton_Update", UpdateTargetDebuffTimers)
end
