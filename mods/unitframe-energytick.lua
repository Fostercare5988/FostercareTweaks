local FT = FostercareTweaks
if not FT then return end

local module = FT:register({
    title = "Show Energy Ticks",
    description = "Show estimated energy ticks and the mana five-second rule on the player power bar.",
    category = "Unit Frames", enabled = true,
    config = { energytick_contrast = 1, energytick_flash = 1, energytick_width = 3 },
})

local function GetActivePowerBar()
    local UF = FT.UnitFrames
    if UF and UF.playerFrame and UF:IsModernPlayer() and UF.playerFrame:IsShown() then
        return UF.playerFrame.powerBar
    end
    return PlayerFrameManaBar
end

module.enable = function(self)
    if self.frame then return end
    local driver = CreateFrame("Frame", "FCTweaksEnergyTick", UIParent)
    self.frame = driver
    driver:EnableMouse(false)
    local visuals = {}
    local function HideVisuals()
        if not driver.currentVisuals then return end
        for _, texture in ipairs(driver.currentVisuals) do
            if texture:IsShown() then texture:Hide() end
        end
        if driver.pulseAlpha ~= 0 then driver.pulse:SetAlpha(0); driver.pulseAlpha = 0 end
    end
    local function SelectVisuals(bar)
        if not bar or driver.currentBar == bar then return end
        HideVisuals()
        local textures = visuals[bar]
        if not textures then
            -- Bar-owned artwork stays below OVERLAY power text. An extra frame
            -- above the bar would paint the brighter marker over its digits.
            local pulse = bar:CreateTexture(nil, "ARTWORK")
            pulse:SetTexture("Interface\\Buttons\\WHITE8X8")
            pulse:SetVertexColor(1, 1, 1); pulse:SetAlpha(0)
            pulse:SetBlendMode("ADD")
            local spark = bar:CreateTexture(nil, "ARTWORK")
            spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark"); spark:SetBlendMode("ADD")
            local glow = bar:CreateTexture(nil, "ARTWORK")
            glow:SetTexture("Interface\\Buttons\\WHITE8X8")
            glow:SetBlendMode("ADD"); glow:SetVertexColor(1, 1, 1, 0.45)
            glow:SetPoint("CENTER", spark, "CENTER", 0, 0)
            local core = bar:CreateTexture(nil, "ARTWORK")
            core:SetTexture("Interface\\Buttons\\WHITE8X8"); core:SetVertexColor(1, 1, 1)
            core:SetPoint("CENTER", spark, "CENTER", 0, 0)
            textures = {pulse, spark, glow, core}
            for _, texture in ipairs(textures) do texture:Hide() end
            visuals[bar] = textures
        end
        driver.currentBar, driver.currentVisuals = bar, textures
        driver.pulse, driver.spark, driver.glow, driver.core = unpack(textures)
        driver.sparkW, driver.sparkH, driver.lastX, driver.pulseAlpha = nil, nil, nil, 0
    end
    SelectVisuals(GetActivePowerBar())

    local generation, power, lastValue = 0, nil, nil
    local pendingGain, pendingAt, pendingMax, pendingValue, settling = 0, nil, 0, 0, false
    local spellGain, spellAt = 0, nil
    local candidateAt
    local watched = {}
    local Refresh, Render
    local function Watch(frame)
        if not frame or watched[frame] then return end
        watched[frame] = true
        for _, script in ipairs({"OnShow", "OnHide", "OnSizeChanged"}) do
            FT.HookScript(frame, script, function() Refresh() end)
        end
    end
    Refresh = function()
        local bar = GetActivePowerBar()
        Watch(PlayerFrame); Watch(PlayerFrameManaBar)
        local UF = FT.UnitFrames
        if UF and UF.playerFrame then Watch(UF.playerFrame); Watch(UF.playerFrame.powerBar) end
        local active = FostercareTweaks_Config["Show Energy Ticks"] ~= 0 and bar and bar:IsVisible() and
            not UnitIsDeadOrGhost("player") and (power == 0 or power == 3) and driver.start
        local width, height = 0, 0
        if active then width, height = bar:GetWidth(), bar:GetHeight() end
        active = active and width > 0 and height > 0
        if not active then
            driver:SetScript("OnUpdate", nil)
            HideVisuals()
            return
        end
        SelectVisuals(bar)
        local sparkW, sparkH = math.min(12, width), math.min(16, height)
        if driver.sparkW ~= sparkW or driver.sparkH ~= sparkH then
            driver.sparkW, driver.sparkH = sparkW, sparkH
            driver.spark:SetWidth(sparkW); driver.spark:SetHeight(sparkH)
        end
        driver.width, driver.halfSpark = width, sparkW / 2
        driver.pixelScale = bar:GetEffectiveScale()
        -- White core and additive glow stay inside even a one-pixel bar.
        local coreW = math.min(FT.GetNumber("energytick_width", 3, 2, 6), sparkW)
        driver.core:SetWidth(coreW); driver.core:SetHeight(sparkH)
        driver.glow:SetWidth(math.min(coreW + 2, sparkW)); driver.glow:SetHeight(sparkH)
        driver.pulse:SetWidth(width); driver.pulse:SetHeight(math.min(4, height))
        driver.pulse:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
        local contrast = FT.GetNumber("energytick_contrast", 1, 0, 1) ~= 0
        if contrast then
            driver.spark:SetVertexColor(1, 1, 1, 0.9)
            driver.glow:Show(); driver.core:Show()
        else
            driver.spark:SetVertexColor(1, 1, 1, 1)
            driver.glow:Hide(); driver.core:Hide()
        end
        driver.flash = FT.GetNumber("energytick_flash", 1, 0, 1) ~= 0
        driver.lastX = nil
        driver:SetScript("OnUpdate", Render)
        Render()
        if not driver.pulse:IsShown() then driver.pulse:Show() end
        if not driver.spark:IsShown() then driver.spark:Show() end
    end
    FT.RefreshEnergyTick = Refresh
    local function Reset()
        generation = generation + 1
        power, lastValue = UnitPowerType("player"), UnitMana("player")
        pendingGain, pendingAt, spellGain, spellAt, settling = 0, nil, 0, nil, false
        driver.start, driver.period, driver.manaBlockedUntil = nil, nil, nil
        candidateAt = nil
        Refresh()
    end
    local function ObserveGain(at, amount, value, maximum)
        if amount <= 0 then return end
        if power == 3 then
            -- Baseline energy regeneration is 20 per 2s; doubled regeneration
            -- and capped final ticks are accepted. Once synchronized, reject
            -- off-phase gains. Spell logs exclude known energizes first.
            -- Server update lag can increase the proportional tick slightly.
            local clipped = value == maximum and amount <= 44
            local plausible = (amount >= 20 and amount <= 22) or (amount >= 40 and amount <= 44) or clipped
            if plausible and driver.start then
                local phase = (at - driver.start) % 2
                if phase >= 0.35 and phase <= 1.65 then
                    -- Recover from a shifted/delayed server phase only after
                    -- two plausible ticks one normal interval apart.
                    plausible = candidateAt and at - candidateAt >= 1.65 and at - candidateAt <= 2.35
                    candidateAt = at
                else candidateAt = nil end
            end
            if plausible then driver.start, driver.period, candidateAt = at, 2, nil end
        elseif power == 0 and (not driver.manaBlockedUntil or at >= driver.manaBlockedUntil) then
            driver.start, driver.period = at, 2
        end
    end
    local function SettleGain()
        if settling then return end
        settling = true
        local token = generation
        C_Timer.After(0.15, function()
            if generation ~= token then return end
            settling = false
            local known = spellAt and math.abs(pendingAt - spellAt) <= 0.35 and spellGain or 0
            ObserveGain(pendingAt, math.max(0, pendingGain - known), pendingValue, pendingMax)
            pendingGain, pendingAt, spellGain, spellAt = 0, nil, 0, nil
            Refresh()
        end)
    end
    FT.SetEventHandler(driver, function(_, ev, unit, caster, spellID, ptype, amount)
        if ev == "SPELL_ENERGIZE_ON_SELF" then
            -- NamPower v4.6.2+ supplies target, caster, spell, resource, amount.
            if unit == UnitGUID("player") and ptype == power and amount and amount > 0 then
                local now = GetTime()
                if not spellAt or now - spellAt > 0.35 then spellGain = 0 end
                spellGain, spellAt = spellGain + amount, now
            end
            return
        end
        if ev == "UI_SCALE_CHANGED" then Refresh(); return end
        if ev == "PLAYER_ENTERING_WORLD" or ev == "PLAYER_DEAD" or ev == "PLAYER_ALIVE" or
            ev == "PLAYER_UNGHOST" or (ev == "UNIT_DISPLAYPOWER" and unit == "player") then
            Reset(); return
        end
        if unit ~= "player" then return end
        local currentPower = UnitPowerType("player")
        if currentPower ~= power then Reset(); return end
        if UnitIsDeadOrGhost("player") then Reset(); return end
        local value = UnitMana("player")
        local diff = value - (lastValue or value)
        lastValue = value
        if power == 0 and diff < 0 then
            driver.start, driver.period = GetTime(), 5
            driver.manaBlockedUntil = driver.start + 5
        elseif (power == 0 or power == 3) and diff > 0 then
            pendingGain, pendingAt = pendingGain + diff, GetTime()
            pendingValue, pendingMax = value, UnitManaMax("player")
            SettleGain()
        end
        Refresh()
    end)
    for _, ev in ipairs({"PLAYER_ENTERING_WORLD", "UNIT_DISPLAYPOWER", "UNIT_ENERGY", "UNIT_MANA",
        "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "UI_SCALE_CHANGED"}) do driver:RegisterEvent(ev) end
    if GetNampowerVersion then
        local major, minor, patch = GetNampowerVersion()
        if type(major) == "number" and type(minor) == "number" and type(patch) == "number" and
            (major > 4 or (major == 4 and (minor > 6 or (minor == 6 and patch >= 2)))) then
            driver:RegisterEvent("SPELL_ENERGIZE_ON_SELF")
        end
    end
    -- Frame-rate independent animation: no resource, visibility or size polling.
    -- Replace the same anchor only when the visible screen pixel changes.
    Render = function()
        local now = GetTime()
        if driver.period == 5 and now >= driver.manaBlockedUntil then
            driver.start, driver.period = driver.manaBlockedUntil, 2
        end
        local elapsed = (now - driver.start) % driver.period
        local progress = elapsed / driver.period
        local x = driver.halfSpark + (driver.width - driver.sparkW) * progress
        x = math.floor(x * driver.pixelScale + 0.5) / driver.pixelScale
        x = math.max(driver.halfSpark, math.min(driver.width - driver.halfSpark, x))
        if driver.lastX ~= x then
            driver.lastX = x
            driver.spark:SetPoint("CENTER", driver.currentBar, "LEFT", x, 0)
        end
        -- A short bottom-edge pulse gives the estimated tick a visible beat
        -- without covering power text. Quantized alpha bounds widget writes.
        local alpha = driver.flash and driver.period ~= 5 and elapsed < 0.25 and math.floor((1 - elapsed / 0.25) * 16 + 0.5) / 16 or 0
        if driver.pulseAlpha ~= alpha then
            driver.pulseAlpha = alpha
            driver.pulse:SetAlpha(alpha)
        end
    end
    Reset()
end
