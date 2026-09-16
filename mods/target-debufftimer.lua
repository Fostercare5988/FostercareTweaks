-- FostercareTweaks: mods/target-debufftimer.lua
local T = FostercareTweaks.T
local TimeConvert = FostercareTweaks.TimeConvert

local module = FostercareTweaks:register({
    title = T["Debuff Timer"],
    description = T["Show debuff durations on the target unit frame."],
    category = T["Unit Frames"],
    enabled = true,
})

local function CreateTextCooldown(cooldown)
    if cooldown.readable then return end

    cooldown.readable = CreateFrame("Frame", "FCTweaksDebuffCooldownText", cooldown:GetParent())
    cooldown.readable:SetAllPoints(cooldown)
    cooldown.readable:SetFrameLevel(cooldown:GetParent():GetFrameLevel() + 1)
    cooldown.readable:EnableMouse(false)

    cooldown.readable.text = cooldown.readable:CreateFontString(nil, "OVERLAY")
    cooldown.readable.text:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    cooldown.readable.text:SetPoint("CENTER", cooldown.readable, "CENTER", 0, 0)

    cooldown.readable:SetScript("OnUpdate", function()
        local parent = this:GetParent()
        if not parent then
            this:Hide()
            return
        end

        local now = GetTime()
        if (this.next or 0) > now then return end
        this.next = now + 0.1

        local alpha = parent:GetAlpha()
        if this.lastAlpha ~= alpha then
            this.lastAlpha = alpha
            this:SetAlpha(alpha)
        end

        if this.duration and this.start then
            local remaining = this.duration - (now - this.start)
            if remaining >= 0 then
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
    end)
end

module.enable = function(self)
    local function UpdateTargetDebuffTimers()

        local auraSlots
        if C_UnitAuras and C_UnitAuras.GetAuraSlots then
            local ok, slots = pcall(C_UnitAuras.GetAuraSlots, "target", "HARMFUL")
            if ok and slots then auraSlots = slots end
        end

        for i = 1, MAX_TARGET_DEBUFFS do
            local button = _G["TargetFrameDebuff" .. i]
            if button then
                if not button.cd then
                    button.cd = CreateFrame("Model", "TargetFrameDebuff" .. i .. "Cooldown", button, "CooldownFrameTemplate")
                    button.cd.noCooldownCount = true
                    button.cd:SetAllPoints()
                    button.cd:SetScale(0.6)
                    button.cd:SetAlpha(0.8)
                    button.cd:EnableMouse(false)
                end

                local dCount = _G["TargetFrameDebuff" .. i .. "Count"]
                local dBorder = _G["TargetFrameDebuff" .. i .. "Border"]

                local name, icon, applications, dispelType, duration, expirationTime
                if auraSlots and auraSlots[i] and C_UnitAuras.GetAuraDataBySlot then
                    local ok, aura = pcall(C_UnitAuras.GetAuraDataBySlot, "target", auraSlots[i])
                    if ok and aura then
                        name = aura.name
                        icon = aura.icon
                        applications = aura.applications
                        dispelType = aura.dispelType
                        duration = aura.duration
                        expirationTime = aura.expirationTime
                    end
                end

                if not name then
                    local tex, count, debuffType = UnitDebuff("target", i)
                    icon = tex
                    applications = count
                    dispelType = debuffType
                end

                if dCount then
                    if not dCount.fixup then
                        dCount.fixup = true
                        dCount:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 6, -3)
                    end
                    if applications and applications > 1 then
                        dCount:SetText("|c0000ff3b" .. applications)
                        dCount:Show()
                    else
                        dCount:Hide()
                    end
                end

                if dBorder and dispelType then
                    local color = DebuffTypeColor[dispelType] or DebuffTypeColor["none"]
                    if color then dBorder:SetVertexColor(color.r, color.g, color.b) end
                end

                if duration and duration > 0 and expirationTime and expirationTime > 0 then
                    local start = expirationTime - duration
                    CreateTextCooldown(button.cd)
                    CooldownFrame_SetTimer(button.cd, start, duration, 1)
                    button.cd.readable.start = start
                    button.cd.readable.duration = duration
                    button.cd.readable:Show()
                    button.cd:Show()
                else
                    if button.cd.readable then button.cd.readable:Hide() end
                    CooldownFrame_SetTimer(button.cd, 0, 0, 0)
                end
            end
        end
    end

    FostercareTweaks.hooksecurefunc("TargetDebuffButton_Update", UpdateTargetDebuffTimers)
end
