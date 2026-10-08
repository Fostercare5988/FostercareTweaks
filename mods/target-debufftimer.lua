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
    return UF and (UF:IsModernTarget() or UF:IsImprovedStandardAuras())
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

module.enable = function(self)
    local function UpdateTargetDebuffTimers()
        -- Skip when Modern Target Frame or Improved Standard Auras manages target auras
        if IsManaged() then UpdateTexts(); return end

        local now, unitGUID = GetTime(), UnitGUID("target")
        for i = 1, MAX_TARGET_DEBUFFS do
            local button = _G["TargetFrameDebuff" .. i]
            if button and button:IsShown() then
                if not button.cd then
                    button.cd = CreateFrame("Model", "TargetFrameDebuff" .. i .. "Cooldown", button, "CooldownFrameTemplate")
                    button.cd.noCooldownCount = true
                    button.cd:SetAllPoints(button)
                    button.cd:SetAlpha(0.8)
                    button.cd:EnableMouse(false)
                end

                local dCount = _G["TargetFrameDebuff" .. i .. "Count"]
                local dBorder = _G["TargetFrameDebuff" .. i .. "Border"]

                -- Strict ClassicAPI v1.15.12 positional unpack
                local name, icon, applications, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = C_UnitAuras.UnitDebuff("target", i, "HARMFUL")

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

                if dBorder and dispelType then
                    local color = DebuffTypeColor[dispelType] or DebuffTypeColor["none"]
                    if color then dBorder:SetVertexColor(color.r, color.g, color.b) end
                end

                local effectiveExpiration = expirationTime

                if duration and duration > 0 and effectiveExpiration and effectiveExpiration > now then
                    local start = effectiveExpiration - duration
                    CreateTextCooldown(button.cd)
                    local sourceGUID = source and UnitGUID(source)
                    local text = button.cd.readable
                    if text.unitGUID ~= unitGUID or text.sourceGUID ~= sourceGUID or
                       text.spellId ~= spellId or text.start ~= start or text.duration ~= duration then
                        CooldownFrame_SetTimer(button.cd, start, duration, 1)
                    end
                    text.unitGUID, text.sourceGUID = unitGUID, sourceGUID
                    button.cd.readable.spellId = spellId
                    button.cd.readable.expirationTime = effectiveExpiration
                    button.cd.readable.start = start
                    button.cd.readable.duration = duration
                    button.cd.readable:Show()
                    button.cd:Show()
                    active[button.cd.readable] = true
                    UpdateText(button.cd.readable, now)
                    if next(active) and not ticker then ticker = C_Timer.NewTicker(0.1, UpdateTexts) end
                else
                    if button.cd and button.cd.readable then
                        button.cd.readable.spellId = nil
                        button.cd.readable.expirationTime = nil
                        StopText(button.cd.readable)
                    end
                    if button.cd then
                        CooldownFrame_SetTimer(button.cd, 0, 0, 0)
                        button.cd:Hide()
                    end
                end
            elseif button and button.cd then
                button.cd:Hide()
                CooldownFrame_SetTimer(button.cd, 0, 0, 0)
                if button.cd.readable then
                    button.cd.readable.spellId = nil
                    button.cd.readable.expirationTime = nil
                    StopText(button.cd.readable)
                end
            end
        end
    end

    FT.hooksecurefunc("TargetDebuffButton_Update", UpdateTargetDebuffTimers)
end
