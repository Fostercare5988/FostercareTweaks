local FT = FostercareTweaks
if not FT then return end

local module = FT:register({
    title = "Show Energy Ticks",
    enabled = true,
})

-- The switch, live: the first time on starts the ticks; later the line shows or hides.
module.apply = function(self, on)
    if not self.frame then
        if on then self:enable() end
    else FT.RefreshEnergyTick() end
end

module.enable = function(self)
    if self.frame then return end
    local driver = CreateFrame("Frame", "FCTweaksEnergyTick", UIParent)
    self.frame = driver
    driver:EnableMouse(false)
    local visuals = {}
    local function HideVisuals()
        if not driver.currentVisuals then return end
        -- Hidden glow and core are shown again by the next layout.
        driver.layout = nil
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
        driver.layout = nil
    end
    SelectVisuals(PlayerFrameManaBar)

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
        local bar = PlayerFrameManaBar
        local active = FostercareTweaks_Config["Show Energy Ticks"] ~= 0 and bar and bar:IsVisible() and
            not UnitIsDeadOrGhost("player") and (power == 0 or power == 3)
        local width, height = 0, 0
        if active then width, height = bar:GetWidth(), bar:GetHeight() end
        active = active and width > 0 and height > 0
        if not active then
            if driver.running then driver.running = nil; driver:SetScript("OnUpdate", nil) end
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
        local coreW = math.min(FT.GetNumber("energytick_width"), sparkW)
        local contrast = FT.GetNumber("energytick_contrast") ~= 0
        -- Most calls are power changes: the widgets are written only when the
        -- bar's size or the settings changed.
        if not driver.layout or driver.layoutW ~= width or driver.layoutH ~= height
            or driver.layoutCore ~= coreW or driver.layoutContrast ~= contrast then
            driver.layout, driver.layoutW, driver.layoutH = true, width, height
            driver.layoutCore, driver.layoutContrast = coreW, contrast
            driver.core:SetWidth(coreW); driver.core:SetHeight(sparkH)
            driver.glow:SetWidth(math.min(coreW + 2, sparkW)); driver.glow:SetHeight(sparkH)
            driver.pulse:SetWidth(width); driver.pulse:SetHeight(math.min(4, height))
            driver.pulse:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
            if contrast then
                driver.spark:SetVertexColor(1, 1, 1, 0.9)
                driver.glow:Show(); driver.core:Show()
            else
                driver.spark:SetVertexColor(1, 1, 1, 1)
                driver.glow:Hide(); driver.core:Hide()
            end
            driver.lastX = nil
        end
        driver.flash = FT.GetNumber("energytick_flash") ~= 0
        if not driver.running then driver.running = true; driver:SetScript("OnUpdate", Render) end
        Render()
        if not driver.pulse:IsShown() then driver.pulse:Show() end
        if not driver.spark:IsShown() then driver.spark:Show() end
    end
    FT.RefreshEnergyTick = Refresh
    Watch(PlayerFrame); Watch(PlayerFrameManaBar)
    local function Reset()
        generation = generation + 1
        power, lastValue = UnitPowerType("player"), UnitMana("player")
        pendingGain, pendingAt, spellGain, spellAt, settling = 0, nil, 0, nil, false
        -- Until a gain shows where the server's tick falls, the line runs a
        -- two-second cycle from now and the edge does not flash. A full bar
        -- gains nothing, so waiting for a gain left the line hidden.
        driver.start, driver.period, driver.manaBlockedUntil, driver.synced = GetTime(), 2, nil, nil
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
            if plausible and driver.synced then
                local phase = (at - driver.start) % 2
                if phase >= 0.35 and phase <= 1.65 then
                    -- Recover from a shifted/delayed server phase only after
                    -- two plausible ticks one normal interval apart.
                    plausible = candidateAt and at - candidateAt >= 1.65 and at - candidateAt <= 2.35
                    candidateAt = at
                else candidateAt = nil end
            end
            if plausible then driver.start, driver.period, candidateAt, driver.synced = at, 2, nil, true end
        elseif power == 0 and (not driver.manaBlockedUntil or at >= driver.manaBlockedUntil) then
            driver.start, driver.period, driver.synced = at, 2, true
        end
    end
    -- A Reset in between (a new generation) drops the gain being settled.
    local settleToken
    local function Settle()
        if not settling or settleToken ~= generation then return end
        settling = false
        local known = spellAt and math.abs(pendingAt - spellAt) <= 0.35 and spellGain or 0
        ObserveGain(pendingAt, math.max(0, pendingGain - known), pendingValue, pendingMax)
        pendingGain, pendingAt, spellGain, spellAt = 0, nil, 0, nil
        Refresh()
    end
    local function SettleGain()
        if settling then return end
        settling, settleToken = true, generation
        C_Timer.After(0.15, Settle)
    end
    FT.SetEventHandler(driver, function(_, ev, unit, caster, spellID, ptype, amount)
        if ev == "SPELL_ENERGIZE_ON_SELF" then
            -- NamPower supplies target, caster, spell, resource, amount.
            if unit == UnitGUID("player") and ptype == power and amount and amount > 0 then
                local now = GetTime()
                if not spellAt or now - spellAt > 0.35 then spellGain = 0 end
                spellGain, spellAt = spellGain + amount, now
            end
            return
        end
        if ev == "UI_SCALE_CHANGED" then Refresh(); return end
        if ev == "PLAYER_ENTERING_WORLD" or ev == "PLAYER_DEAD" or ev == "PLAYER_ALIVE" or
            ev == "PLAYER_UNGHOST" or ev == "UNIT_DISPLAYPOWER" then
            Reset(); return
        end
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
    for _, ev in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST",
        "UI_SCALE_CHANGED"}) do driver:RegisterEvent(ev) end
    -- The player's power only; ClassicAPI also fires these for every group,
    -- nameplate and mark token.
    for _, ev in ipairs({"UNIT_DISPLAYPOWER", "UNIT_POWER_UPDATE"}) do driver:RegisterUnitEvent(ev, "player") end
    driver:RegisterEvent("SPELL_ENERGIZE_ON_SELF")
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
        local alpha = driver.flash and driver.synced and driver.period ~= 5 and elapsed < 0.25 and math.floor((1 - elapsed / 0.25) * 16 + 0.5) / 16 or 0
        if driver.pulseAlpha ~= alpha then
            driver.pulseAlpha = alpha
            driver.pulse:SetAlpha(alpha)
        end
    end
    Reset()
end
