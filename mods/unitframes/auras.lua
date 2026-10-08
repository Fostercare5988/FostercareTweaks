local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/unitframes/auras.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Shared Unit Frame Aura Subsystem (Player, Target, ToT)
-- Powered natively by ClassicAPI C_UnitAuras and styled after Luna Unit Frames

local UF = FT.UnitFrames
if not UF then return end

UF.Auras = UF.Auras or {}
local Auras = UF.Auras

FT:register({
    title = "Larger Armor Debuffs", category = "Unit Frames", enabled = false,
    description = "Enlarge Sunder Armor, Faerie Fire and Expose Armor on target aura rows.",
    config = { uf_armor_debuff_scale = 1.5 },
})

-- [SOURCE-VERIFIED] Active patch-O.mpq Spell.dbc: physical-resistance
-- Apply Aura records only. Training/unused name matches are excluded.
-- Rank and NPC/custom variants are recorded in tests/deployed-armor-spells.json.
local armorDebuffs = {
    [770]=true, [778]=true, [1069]=true, [2887]=true, [2888]=true, [6950]=true,
    [7386]=true, [7405]=true, [8380]=true, [8647]=true, [8649]=true, [8650]=true,
    [9749]=true, [9907]=true, [11197]=true, [11198]=true, [11596]=true, [11597]=true,
    [11971]=true, [13424]=true, [13444]=true, [13752]=true, [15502]=true, [15572]=true,
    [16145]=true, [16498]=true, [16857]=true, [17390]=true, [17391]=true, [17392]=true,
    [20656]=true, [21081]=true, [21670]=true, [24317]=true, [25051]=true, [27991]=true,
    [30965]=true, [47383]=true,
}
Auras.armorDebuffs = armorDebuffs

function Auras:GetArmorDebuffScale()
    return FT.GetNumber("uf_armor_debuff_scale", 1.5, 1.25, 2)
end

-- One policy for player, target, raid and preview aura buttons.
function Auras.StyleBorder(btn, dispelType, colorDispel)
    btn.borderDispelType, btn.borderColorDispel = dispelType, colorDispel
    local cfg = FostercareTweaks_Config or {}
    local setting = btn.isDebuff and "Show Debuff Borders" or "Show Buff Borders"
    if cfg[setting] ~= 1 then btn.border:Hide(); return end
    if btn.isDebuff and colorDispel then
        local dc = UF.DispelColors[dispelType] or UF.DispelColors["None"]
        btn.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
        btn.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
        btn.border:SetVertexColor(dc.r, dc.g, dc.b, 1)
    else
        btn.border:SetTexture("Interface\\AddOns\\FostercareTweaks\\img\\border-dark.tga")
        btn.border:SetTexCoord(0, 1, 0, 1)
        btn.border:SetVertexColor(0.15, 0.15, 0.15, 1)
    end
    btn.border:Show()
end

function Auras:RefreshBorders()
    for _, key in ipairs({ "playerFrame", "targetFrame", "blizzPlayerAuras", "blizzTargetAuras" }) do
        local frame = UF[key]
        local container = frame and (frame.auraContainer or frame)
        if container then
            for _, kind in ipairs({ "buffButtons", "debuffButtons" }) do
                for _, btn in ipairs(container[kind] or {}) do
                    if btn:IsShown() then Auras.StyleBorder(btn, btn.borderDispelType, btn.borderColorDispel) end
                end
            end
        end
    end
    if UF.RefreshRaidAuraBorders then UF:RefreshRaidAuraBorders() end
end


-- Reverse cooldown animation support (Luna mechanism for auras)
if not CooldownFrame_OnUpdateModel_FCT_Orig then
    local orig_CooldownFrame_OnUpdateModel = CooldownFrame_OnUpdateModel
    CooldownFrame_OnUpdateModel_FCT_Orig = orig_CooldownFrame_OnUpdateModel
    function CooldownFrame_OnUpdateModel()
        if this and this.reverse then
            if this.stopping == 0 and this.start and this.duration and this.duration > 0 then
                local finished = (GetTime() - this.start) / this.duration
                if finished < 1.0 then
                    finished = 1 - finished
                    local time = finished * 1000
                    this:SetSequenceTime(0, time)
                    return
                end
                this.stopping = 1
                this:SetSequence(1)
                this:SetSequenceTime(1, 0)
                return
            else
                this:AdvanceTime()
                return
            end
        end
        if orig_CooldownFrame_OnUpdateModel then
            orig_CooldownFrame_OnUpdateModel()
        end
    end
end

local function AuraButton_OnEnter()
    if not this.unit or not this.auraIndex then return end
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
    -- Always store the plain polarity index, including with the own-debuff filter.
    GameTooltip:SetUnitAura(this.unit, this.auraIndex, this.isDebuff and "HARMFUL" or "HELPFUL")
    GameTooltip:Show()
end

local function AuraButton_OnLeave() GameTooltip:Hide() end

local function AuraButton_OnClick()
    if arg1 == "RightButton" and this.unit == "player" and not this.isDebuff and this.spellId then
        C_Spell.CancelSpellByID(this.spellId)
    end
end

local function FormatAuraTime(remaining)
    if remaining < 5 then
        return "|cffff4444" .. string.format("%.1f", remaining) .. "|r"
    elseif remaining < 10 then
        return "|cffffff33" .. math.ceil(remaining) .. "|r"
    elseif remaining < 60 then
        return "|cffffffff" .. math.ceil(remaining) .. "|r"
    elseif remaining < 3600 then
        return "|cffffffff" .. math.ceil(remaining / 60) .. "m|r"
    elseif remaining < 86400 then
        return "|cffffffff" .. math.ceil(remaining / 3600) .. "h|r"
    else
        return "|cffffffff" .. math.ceil(remaining / 86400) .. "d|r"
    end
end

local timedButtons = {}
local auraTicker
local tickerGeneration = 0

local function StopIdleAuraTicker()
    if auraTicker and not next(timedButtons) then
        auraTicker:Cancel()
        auraTicker = nil
        tickerGeneration = tickerGeneration + 1
    end
end

local function ResetAuraButton(btn)
    if not btn then return end
    if not btn.unit and not btn.isOccupied and not btn.expirationTime and not btn:IsShown() then return end
    btn.unit = nil
    btn.auraIndex = nil
    btn.spellId = nil
    btn.expirationTime = nil
    btn.duration = nil
    btn.lastTimeText = nil
    btn.timerUnitGUID, btn.timerSpellID, btn.timerSourceGUID = nil, nil, nil
    btn.sweepStart, btn.sweepDuration = nil, nil
    btn.isOccupied = false
    timedButtons[btn] = nil
    StopIdleAuraTicker()

    if btn.durationText then
        btn.durationText:SetText("")
        btn.durationText:Hide()
    end

    if btn.countText then
        btn.countText:SetText("")
        btn.countText:Hide()
    end

    if btn.cooldown then
        CooldownFrame_SetTimer(btn.cooldown, 0, 0, 0)
        btn.cooldown:Hide()
    end

    if btn.icon then
        btn.icon:SetTexture(nil)
        btn.icon:SetVertexColor(1, 1, 1, 1)
    end

    if btn.border then
        btn.border:Hide()
    end

    btn:SetAlpha(1.0)
    btn:Hide()
end

local function UpdateAuraTimes()
    local now = GetTime()
    for btn in pairs(timedButtons) do
        local remaining = (btn.expirationTime or 0) - now
        if remaining <= 0 then
            -- Hidden containers must release expired timers too. Aura presence
            -- still belongs to the next authoritative query, not this clock.
            timedButtons[btn] = nil
            if btn.lastTimeText ~= "" then
                btn.lastTimeText = ""
                btn.durationText:SetText("")
            end
            btn.durationText:Hide()
            CooldownFrame_SetTimer(btn.cooldown, 0, 0, 0)
            btn.cooldown:Hide()
            btn.sweepStart, btn.sweepDuration = nil, nil
        elseif btn:IsVisible() then
            local showText = not btn.fctHideDuration and ((btn.isDebuff and UF:IsDebuffText()) or
                (not btn.isDebuff and UF:IsBuffText()))
            local text = showText and FormatAuraTime(remaining) or ""
            if btn.lastTimeText ~= text then
                btn.lastTimeText = text
                btn.durationText:SetText(text)
            end
            if text ~= "" then btn.durationText:Show() else btn.durationText:Hide() end
        end
    end
    StopIdleAuraTicker()
end

local function EnsureAuraTicker()
    if auraTicker then return end
    tickerGeneration = tickerGeneration + 1
    local generation = tickerGeneration
    auraTicker = C_Timer.NewTicker(0.1, function()
        -- A cancelled callback may already have been dispatched by the host.
        if generation ~= tickerGeneration then return end
        UpdateAuraTimes()
    end)
end

local function CreateAuraButton(parent, name, size, isDebuff)
    local btn = CreateFrame("Button", name, parent)
    btn:SetWidth(size)
    btn:SetHeight(size)
    btn:SetFrameStrata("LOW")
    btn:EnableMouse(true)

    -- Icon texture (cropped 7% around edges for modern clean square look)
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints(btn)
    btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    btn.icon:SetVertexColor(1, 1, 1, 1)

    -- Dispel overlay only; ordinary aura icons have no decorative frame.
    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetPoint("CENTER", btn, "CENTER")
    btn.border:SetWidth(size + 2)
    btn.border:SetHeight(size + 2)
    btn.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
    btn.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    btn.border:Hide()

    -- Cooldown radial sweep
    btn.cooldown = CreateFrame("Model", name .. "CD", btn, "CooldownFrameTemplate")
    btn.cooldown:ClearAllPoints()
    btn.cooldown:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    btn.cooldown:SetWidth(36)
    btn.cooldown:SetHeight(36)
    btn.cooldown:SetScale((size + 0.7) / 36)
    btn.cooldown:EnableMouse(false)
    btn.cooldown.reverse = true
    btn.cooldown.noCooldownCount = true
    btn.cooldown:Hide()

    -- Overlay text frame (drawn above cooldown)
    btn.textFrame = CreateFrame("Frame", nil, btn)
    btn.textFrame:SetAllPoints(btn)
    btn.textFrame:EnableMouse(false)
    btn.textFrame:SetFrameLevel(btn:GetFrameLevel() + 5)

    btn.durationText = btn.textFrame:CreateFontString(nil, "OVERLAY")
    local font = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    btn.durationText:SetFont(font, (size <= 20 and 9 or 11), "OUTLINE")
    btn.durationText:SetPoint("CENTER", btn.textFrame, "CENTER", 0, 0)
    btn.durationText:SetJustifyH("CENTER")
    btn.durationText:SetShadowColor(0, 0, 0, 1)
    btn.durationText:SetShadowOffset(0.8, -0.8)

    btn.countText = btn.textFrame:CreateFontString(nil, "OVERLAY")
    btn.countText:SetFont(font, (size <= 20 and 9 or 10), "OUTLINE")
    btn.countText:SetPoint("BOTTOMRIGHT", btn.textFrame, "BOTTOMRIGHT", -1, 1)
    btn.countText:SetJustifyH("RIGHT")
    btn.countText:SetShadowColor(0, 0, 0, 1)
    btn.countText:SetShadowOffset(0.8, -0.8)

    btn.isDebuff = isDebuff
    btn:RegisterForClicks("RightButtonUp")
    btn:SetScript("OnEnter", AuraButton_OnEnter)
    btn:SetScript("OnLeave", AuraButton_OnLeave)
    btn:SetScript("OnClick", AuraButton_OnClick)

    btn:Hide()
    return btn
end

Auras.CreateAuraButton = CreateAuraButton
Auras.ResetAuraButton = ResetAuraButton

function Auras:ResetContainer(container)
    if not container then return end
    for _, btn in ipairs(container.buffButtons or {}) do ResetAuraButton(btn) end
    for _, btn in ipairs(container.debuffButtons or {}) do ResetAuraButton(btn) end
end

local function AnchorAuraButton(btn, frame, index, size, spacing, perRow, growsUp, alignRight)
    local row = math.floor((index - 1) / perRow)
    local col = (index - 1) % perRow
    local point = (growsUp and "BOTTOM" or "TOP") .. (alignRight and "RIGHT" or "LEFT")
    btn:SetPoint(point, frame, point,
        col * (size + spacing) * (alignRight and -1 or 1),
        row * (size + spacing) * (growsUp and 1 or -1))
end

function Auras:CreateAuraContainer(parentFrame, unit, maxBuffs, maxDebuffs, options)
    options = options or {}
    local buffSize = (UF.GetBuffSize and UF:GetBuffSize()) or options.buffSize or options.size or 20
    local debuffSize = (UF.GetDebuffSize and UF:GetDebuffSize()) or options.debuffSize or options.size or 20
    local spacing = options.spacing or 3
    local perRow = options.perRow or 8
    local alignRight = options.alignRight
    local side = alignRight and "RIGHT" or "LEFT"

    local container = CreateFrame("Frame", parentFrame:GetName() .. "Auras", parentFrame)
    container.unit = unit
    container.buffButtons = {}
    container.debuffButtons = {}
    container.buffSlots, container.debuffSlots = {}, {}
    container.options = options
    container.buffSize = buffSize
    container.debuffSize = debuffSize

    -- Buff Row
    if maxBuffs and maxBuffs > 0 then
        container.buffFrame = CreateFrame("Frame", container:GetName() .. "Buffs", container)
        container.buffFrame:SetWidth((buffSize + spacing) * perRow - spacing)
        container.buffFrame:SetHeight(buffSize)
        container.buffFrame.fctPositionPoint = alignRight and "TOPRIGHT" or nil

        if options.buffAnchor == "BOTTOM" then
            container.buffFrame:SetPoint("TOP" .. side, parentFrame, "BOTTOM" .. side, 0, -4)
        else
            container.buffFrame:SetPoint("BOTTOM" .. side, parentFrame, "TOP" .. side, 0, 4)
        end

        for i = 1, maxBuffs do
            local btn = CreateAuraButton(container.buffFrame, container.buffFrame:GetName() .. i, buffSize, false)
            AnchorAuraButton(btn, container.buffFrame, i, buffSize, spacing, perRow, options.buffAnchor ~= "BOTTOM", alignRight)
            btn.unit = unit
            btn.auraIndex = i
            btn.container = container
            container.buffButtons[i] = btn
        end
    end

    -- Debuff Row
    if maxDebuffs and maxDebuffs > 0 then
        container.debuffFrame = CreateFrame("Frame", container:GetName() .. "Debuffs", container)
        container.debuffFrame:SetWidth((debuffSize + spacing) * perRow - spacing)
        container.debuffFrame:SetHeight(debuffSize)
        container.debuffFrame.fctPositionPoint = alignRight and "TOPRIGHT" or nil

        if options.debuffAnchor == "TOP" then
            local relative = container.buffFrame or parentFrame
            container.debuffFrame:SetPoint("BOTTOM" .. side, relative, "TOP" .. side, 0, 4)
        else
            local relative = (options.buffAnchor == "BOTTOM" and container.buffFrame) or parentFrame
            container.debuffFrame:SetPoint("TOP" .. side, relative, "BOTTOM" .. side, 0, -4)
        end

        for i = 1, maxDebuffs do
            local btn = CreateAuraButton(container.debuffFrame, container.debuffFrame:GetName() .. i, debuffSize, true)
            AnchorAuraButton(btn, container.debuffFrame, i, debuffSize, spacing, perRow, options.debuffAnchor == "TOP", alignRight)
            btn.unit = unit
            btn.auraIndex = i
            btn.container = container
            container.debuffButtons[i] = btn
        end
    end

    if FT.RegisterFrameMover and options.moveKey then
        if container.buffFrame then
            FT.RestoreFramePosition(container.buffFrame, options.moveKey .. "_buffs", parentFrame)
            FT.RegisterFrameMover(container.buffFrame, options.moveKey .. "_buffs", "Buffs", parentFrame, function() Auras:LayoutContainer(container) end)
        end
        if container.debuffFrame then
            FT.RestoreFramePosition(container.debuffFrame, options.moveKey .. "_debuffs", parentFrame)
            FT.RegisterFrameMover(container.debuffFrame, options.moveKey .. "_debuffs", "Debuffs", parentFrame, function() Auras:LayoutContainer(container) end)
        end
    end
    return container
end

function Auras:ApplyBuffSize(container, newSize)
    if not container or not container.buffFrame or not container.buffButtons then return end
    newSize = tonumber(newSize) or (UF.GetBuffSize and UF:GetBuffSize()) or 20
    container.buffSize = newSize
    local spacing = (container.options and container.options.spacing) or 3
    local perRow = (container.options and container.options.perRow) or 8

    container.buffFrame:SetWidth((newSize + spacing) * perRow - spacing)
    container.buffFrame:SetHeight(newSize)
    for i, btn in ipairs(container.buffButtons) do
        btn:SetWidth(newSize)
        btn:SetHeight(newSize)
        btn.border:SetWidth(newSize + 2)
        btn.border:SetHeight(newSize + 2)
        if btn.cooldown then
            btn.cooldown:ClearAllPoints()
            btn.cooldown:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
            btn.cooldown:SetWidth(36)
            btn.cooldown:SetHeight(36)
            btn.cooldown:SetScale((newSize + 0.7) / 36)
        end
        btn:ClearAllPoints()
        AnchorAuraButton(btn, container.buffFrame, i, newSize, spacing, perRow,
            container.options and container.options.buffAnchor ~= "BOTTOM", container.options and container.options.alignRight)
    end
end

function Auras:ApplyDebuffSize(container, newSize)
    if not container or not container.debuffFrame or not container.debuffButtons then return end
    newSize = tonumber(newSize) or (UF.GetDebuffSize and UF:GetDebuffSize()) or 20
    container.debuffSize = newSize
    local spacing = (container.options and container.options.spacing) or 3
    local perRow = (container.options and container.options.perRow) or 8

    container.debuffFrame:SetWidth((newSize + spacing) * perRow - spacing)
    container.debuffFrame:SetHeight(newSize)
    for i, btn in ipairs(container.debuffButtons) do
        btn:SetWidth(newSize)
        btn:SetHeight(newSize)
        btn.border:SetWidth(newSize + 2)
        btn.border:SetHeight(newSize + 2)
        if btn.cooldown then
            btn.cooldown:ClearAllPoints()
            btn.cooldown:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
            btn.cooldown:SetWidth(36)
            btn.cooldown:SetHeight(36)
            btn.cooldown:SetScale((newSize + 0.7) / 36)
        end
        btn:ClearAllPoints()
        AnchorAuraButton(btn, container.debuffFrame, i, newSize, spacing, perRow,
            container.options and container.options.debuffAnchor == "TOP", container.options and container.options.alignRight)
    end
    Auras:LayoutContainer(container)
end

function Auras:ApplyAuraSize(container, newSize)
    Auras:ApplyBuffSize(container, newSize)
    Auras:ApplyDebuffSize(container, newSize)
end

-- Preserve a running model until its actual aura identity/timing changes.
-- Native CooldownFrame_SetTimer restarts the animation sequence on every call.
local function UpdateAuraTiming(btn, unitGUID, spellID, source, duration, expiration, spin, text, now)
    local sourceGUID = source and UnitGUID(source)
    local changedIdentity = btn.timerUnitGUID ~= unitGUID or btn.timerSpellID ~= spellID or
        btn.timerSourceGUID ~= sourceGUID
    btn.timerUnitGUID, btn.timerSpellID, btn.timerSourceGUID = unitGUID, spellID, sourceGUID
    local timed = expiration and expiration > now and duration and duration > 0
    local start = timed and expiration - duration
    if timed and spin then
        if changedIdentity or btn.sweepStart ~= start or btn.sweepDuration ~= duration then
            CooldownFrame_SetTimer(btn.cooldown, start, duration, 1)
            btn.sweepStart, btn.sweepDuration = start, duration
        end
        btn.cooldown:Show()
    else
        if btn.sweepStart then CooldownFrame_SetTimer(btn.cooldown, 0, 0, 0) end
        btn.sweepStart, btn.sweepDuration = nil, nil
        btn.cooldown:Hide()
    end
    -- Presence comes from the aura query. Unknown remote timing stays unknown.
    local label = timed and text and not btn.fctHideDuration and FormatAuraTime(expiration - now) or ""
    if btn.lastTimeText ~= label then
        btn.lastTimeText = label
        btn.durationText:SetText(label)
    end
    if label ~= "" then btn.durationText:Show() else btn.durationText:Hide() end
    btn.expirationTime, btn.duration = timed and expiration or 0, timed and duration or 0
    timedButtons[btn] = timed and true or nil
    if timed then EnsureAuraTicker() else StopIdleAuraTicker() end
end

Auras.UpdateAuraTiming = UpdateAuraTiming

function Auras:UpdateContainer(container)
    if not container or not container.unit then return end
    local unit = container.unit
    local owner = container:GetParent()
    -- Explicit modern-frame ownership, not visibility: alt-Z and refresh before
    -- Show must still retain/refresh authoritative aura state.
    if (owner and owner.enabled == false) or not UnitExists(unit) then
        self:ResetContainer(container)
        return
    end

    local showBuffs = true
    if unit == "player" and UF.IsShowPlayerBuffs and not UF:IsShowPlayerBuffs() then
        showBuffs = false
    elseif unit == "target" and UF.IsShowTargetBuffs and not UF:IsShowTargetBuffs() then
        showBuffs = false
    end

    if container.buffFrame then
        if not showBuffs then
            container.buffFrame:Hide()
        else
            container.buffFrame:Show()
        end
    end

    local showBuffSpin = (UF.IsBuffSpin and UF:IsBuffSpin())
    local showBuffText = (UF.IsBuffText and UF:IsBuffText())

    local showDebuffs = true
    if unit == "player" and UF.IsShowPlayerDebuffs and not UF:IsShowPlayerDebuffs() then
        showDebuffs = false
    elseif unit == "target" and UF.IsShowTargetDebuffs and not UF:IsShowTargetDebuffs() then
        showDebuffs = false
    end

    if container.debuffFrame then
        if not showDebuffs then
            container.debuffFrame:Hide()
        else
            container.debuffFrame:Show()
        end
    end

    local showDebuffSpin = (UF.IsDebuffSpin and UF:IsDebuffSpin())
    local showDebuffText = (UF.IsDebuffText and UF:IsDebuffText())
    local colorDispel = (UF.IsColorDebuffsByDispel and UF:IsColorDebuffsByDispel())
    local onlyMine = (unit == "target" and UF.IsOnlyMyDebuffs and UF:IsOnlyMyDebuffs())

    local now = GetTime()
    local unitGUID = UnitGUID(unit)

    -- Update Buffs
    if container.buffButtons then
        local maxBuffs = #container.buffButtons
        if not showBuffs then
            for _, btn in ipairs(container.buffButtons) do
                ResetAuraButton(btn)
            end
        else
            local btnIdx = 1
            -- Slots are ordered like the plain polarity index. Refill this
            -- scratch buffer on every refresh; opaque slots are not identities.
            local slots = container.buffSlots
            local countSlots = 0
            if maxBuffs > 0 then
                local continuation
                continuation, countSlots = C_UnitAuras.GetAuraSlots(unit, "HELPFUL", 48, nil, slots)
            end
            for i = 1, countSlots do
                if btnIdx > maxBuffs then break end
                local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = C_UnitAuras.UnitAuraBySlot(unit, slots[i])
                if not name then break end -- end of buffs

                if icon then
                    local btn = container.buffButtons[btnIdx]
                    if btn then
                        btn.unit = unit
                        btn.auraIndex = i
                        btn.spellId = spellId
                        btn.isOccupied = true

                        btn.icon:SetTexture(icon)
                        btn.icon:SetVertexColor(1, 1, 1, 1)
                        btn:SetAlpha(1.0)

                        if count and count > 1 then
                            btn.countText:SetText(count)
                            btn.countText:Show()
                        else
                            btn.countText:SetText("")
                            btn.countText:Hide()
                        end

                        UpdateAuraTiming(btn, unitGUID, spellId, source, duration, expirationTime,
                            showBuffSpin, showBuffText, now)

                        Auras.StyleBorder(btn)
                        btn:Show()

                        btnIdx = btnIdx + 1
                    end
                end
            end

            for j = btnIdx, maxBuffs do
                ResetAuraButton(container.buffButtons[j])
            end
        end
    end

    -- Update Debuffs
    if container.debuffButtons then
        local maxDebuffs = #container.debuffButtons
        if not showDebuffs then
            for _, btn in ipairs(container.debuffButtons) do
                ResetAuraButton(btn)
            end
        else
            local btnIdx = 1
            local filter = "HARMFUL" -- Tooltip requires an index in the unfiltered polarity list.

            local slots = container.debuffSlots
            local countSlots = 0
            if maxDebuffs > 0 then
                local continuation
                continuation, countSlots = C_UnitAuras.GetAuraSlots(unit, filter, 48, nil, slots)
            end
            for i = 1, countSlots do
                if btnIdx > maxDebuffs then break end
                local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer = C_UnitAuras.UnitAuraBySlot(unit, slots[i])
                if not name then break end -- end of debuffs


                local isMine = source and (UnitIsUnit(source, "player") or UnitIsUnit(source, "pet"))
                if icon and (not onlyMine or isMine) then
                    local btn = container.debuffButtons[btnIdx]
                    if btn then
                        btn.unit = unit
                        btn.auraIndex = i
                        btn.spellId = spellId
                        btn.isOccupied = true

                        btn.icon:SetTexture(icon)
                        btn.icon:SetVertexColor(1, 1, 1, 1)
                        btn:SetAlpha(1.0)

                        if count and count > 1 then
                            btn.countText:SetText(count)
                            btn.countText:Show()
                        else
                            btn.countText:SetText("")
                            btn.countText:Hide()
                        end

                        Auras.StyleBorder(btn, dispelType, colorDispel)

                        UpdateAuraTiming(btn, unitGUID, spellId, source, duration, expirationTime,
                            showDebuffSpin, showDebuffText, now)

                        btn:Show()
                        btnIdx = btnIdx + 1
                    end
                end
            end

            for j = btnIdx, maxDebuffs do
                ResetAuraButton(container.debuffButtons[j])
            end
        end
    end
    Auras:LayoutContainer(container)
end

local function HasSavedPosition(key)
    local positions = FostercareTweaks_Config and FostercareTweaks_Config.unitframe_positions
    return key and positions and positions[key]
end

local function NormalizeRightAnchor(frame, key, parent)
    local p = HasSavedPosition(key)
    if not p or p.point ~= "TOPLEFT" or not p.relPoint or not tonumber(p.x) or not tonumber(p.y) then return end
    -- Preserve the current rectangle, then let future count/size changes grow left.
    p.point = "TOPRIGHT"
    p.x = tonumber(p.x) + frame:GetWidth()
    frame:ClearAllPoints()
    frame:SetPoint(p.point, parent, p.relPoint, p.x, p.y)
end

local function IsAreaDragging(frame)
    return frame and frame.fctMover and frame.fctMover.dragging
end

function Auras:LayoutContainer(container)
    if not container then return end
    local options = container.options or {}
    local spacing, perRow = options.spacing or 3, options.perRow or 8
    for _, kind in ipairs({ "buff", "debuff" }) do
        local row, buttons = container[kind .. "Frame"], container[kind .. "Buttons"]
        if row then
            local count = 0
            for _, btn in ipairs(buttons) do if btn.isOccupied then count = count + 1 end end
            local size = container[kind .. "Size"]
            row.occupiedCount = count
            local mixed = kind == "debuff" and container.unit == "target" and
                FostercareTweaks_Config["Larger Armor Debuffs"] == 1
            local rowW, rowH = math.min(perRow, math.max(1, count)) * (size + spacing) - spacing,
                math.max(1, math.ceil(count / perRow)) * (size + spacing) - spacing
            if kind == "debuff" then
                local limit = mixed and math.max(size, math.min(perRow * (size + spacing) - spacing,
                    container:GetParent():GetWidth())) or perRow * (size + spacing) - spacing
                local x, y, lineH, widest = 0, 0, 0, 0
                for i, btn in ipairs(buttons) do
                    local iconSize = mixed and armorDebuffs[btn.spellId] and size * Auras:GetArmorDebuffScale() or size
                    if btn:GetWidth() ~= iconSize then
                        btn:SetWidth(iconSize); btn:SetHeight(iconSize)
                        btn.border:SetWidth(iconSize + 2); btn.border:SetHeight(iconSize + 2)
                        btn.cooldown:SetScale(iconSize / 36)
                    end
                    if btn.isOccupied then
                        if x > 0 and x + iconSize > limit then y, x, lineH = y + lineH + spacing, 0, 0 end
                        local point = (options.debuffAnchor == "TOP" and "BOTTOM" or "TOP") .. (options.alignRight and "RIGHT" or "LEFT")
                        btn:ClearAllPoints()
                        btn:SetPoint(point, row, point, options.alignRight and -x or x,
                            options.debuffAnchor == "TOP" and y or -y)
                        lineH = math.max(lineH, iconSize)
                        widest = math.max(widest, x + iconSize)
                        x = x + iconSize + spacing
                    end
                end
                rowW, rowH = math.max(size, widest), math.max(size, y + lineH)
            end
            -- Refresh aura identity while the pointer owns the area's geometry.
            -- The mover reconciles current bounds immediately after saving the drop.
            if not IsAreaDragging(row) then
                row:SetWidth(rowW)
                row:SetHeight(rowH)
                if options.alignRight and options.moveKey then
                    NormalizeRightAnchor(row, options.moveKey .. "_" .. kind .. "s", container:GetParent())
                end
            end
        end
    end
    local parent = container:GetParent()
    local key = options.moveKey
    if options.standard then
        local side = options.alignRight and "RIGHT" or "LEFT"
        local x = options.alignRight and -5 or 5
        -- The native ToT and FT castbar occupy the area below the target portrait.
        local y = options.alignRight and -34 or 12
        if container.buffFrame and not IsAreaDragging(container.buffFrame) and not HasSavedPosition(key .. "_buffs") then
            container.buffFrame:ClearAllPoints()
            container.buffFrame:SetPoint("TOP" .. side, parent, "BOTTOM" .. side, x, y)
        end
        if container.debuffFrame and not IsAreaDragging(container.debuffFrame) and not HasSavedPosition(key .. "_debuffs") then
            container.debuffFrame:ClearAllPoints()
            local buffs = container.buffFrame
            if buffs and buffs:IsShown() and (buffs.occupiedCount or 0) > 0 then
                container.debuffFrame:SetPoint("TOP" .. side, buffs, "BOTTOM" .. side, 0, -4)
            else
                container.debuffFrame:SetPoint("TOP" .. side, parent, "BOTTOM" .. side, x, y)
            end
        end
    end
    if container.unit == "target" and FT.LayoutTargetCastbar then
        FT.LayoutTargetCastbar()
    end
end

function Auras:AttachToTargetFrame()
    if UF.blizzTargetAuras then return UF.blizzTargetAuras end
    if not TargetFrame then return nil end

    local buffSize = (UF.GetBuffSize and UF:GetBuffSize()) or 20
    local debuffSize = (UF.GetDebuffSize and UF:GetDebuffSize()) or 20

    -- Match the standard player row capacity; target rows grow from the portrait side.
    local container = Auras:CreateAuraContainer(TargetFrame, "target", 32, 48, {
        standard = true, moveKey = "standard_target", alignRight = true,
        buffSize = buffSize,
        debuffSize = debuffSize,
        spacing = 3,
        perRow = 8,
        buffAnchor = "BOTTOM",
        debuffAnchor = "BOTTOM",
    })
    container:ClearAllPoints()
    container:SetPoint("TOPRIGHT", TargetFrame, "BOTTOMRIGHT", -5, -34)
    container:SetFrameStrata("LOW")

    UF.blizzTargetAuras = container
    return container
end

local function SuppressBlizzTargetAuras()
    if not UF:IsImprovedStandardAuras() and not UF:IsModernTarget() then return end
    for i = 1, 5 do
        local btn = _G["TargetFrameBuff" .. i]
        if btn and btn:IsShown() then btn:Hide() end
    end
    for i = 1, 16 do
        local btn = _G["TargetFrameDebuff" .. i]
        if btn and btn:IsShown() then btn:Hide() end
    end
end

local isUpdatingBlizzAuras = false
function Auras:UpdateBlizzTargetAuras()
    if isUpdatingBlizzAuras then return end
    isUpdatingBlizzAuras = true

    local container = UF.blizzTargetAuras
    if not container then
        container = Auras:AttachToTargetFrame()
    end

    local enabled = (UF.IsImprovedStandardAuras and UF:IsImprovedStandardAuras())
    local targetShown = TargetFrame and TargetFrame:IsShown() and UnitExists("target")
    local isModernTarget = (UF.IsModernTarget and UF:IsModernTarget())

    if not container or not enabled or not targetShown or isModernTarget then
        if container and container:IsShown() then
            container:Hide()
            for _, btn in ipairs(container.buffButtons) do ResetAuraButton(btn) end
            for _, btn in ipairs(container.debuffButtons) do ResetAuraButton(btn) end
            if not enabled and targetShown and not isModernTarget and TargetDebuffButton_Update then
                TargetDebuffButton_Update()
            end
        end
        isUpdatingBlizzAuras = false
        return
    end

    SuppressBlizzTargetAuras()

    container:Show()
    Auras:UpdateContainer(container)

    isUpdatingBlizzAuras = false
end

-- Native TargetofTarget_Update also calls this updater on its render path.
-- Only suppress its stock buttons here; aura scans belong to unit events.
FT.hooksecurefunc("TargetDebuffButton_Update", SuppressBlizzTargetAuras)

-- Independent event dispatcher for standard target aura updating
local auraEventFrame = CreateFrame("Frame", "FCTweaksAuraEventFrame", UIParent)
auraEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
auraEventFrame:RegisterEvent("UNIT_AURA")

function Auras:UpdateBlizzPlayerAuras()
    if not PlayerFrame then return end
    local container = UF.blizzPlayerAuras
    if not container then
        container = Auras:CreateAuraContainer(PlayerFrame, "player", 32, 48, {
            standard = true, moveKey = "standard_player", perRow = 8, spacing = 3,
            buffAnchor = "BOTTOM", debuffAnchor = "BOTTOM",
        })
        UF.blizzPlayerAuras = container
    end
    if UF:IsModernPlayer() or not UF:IsImprovedStandardAuras() then
        container:Hide()
        for _, btn in ipairs(container.buffButtons) do ResetAuraButton(btn) end
        for _, btn in ipairs(container.debuffButtons) do ResetAuraButton(btn) end
        return
    end
    container:Show()
    Auras:UpdateContainer(container)
end

auraEventFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
auraEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
FT.SetEventHandler(auraEventFrame, function(_, ev, unit)
    if ev == "PLAYER_TARGET_CHANGED" then
        Auras:UpdateBlizzTargetAuras()
    elseif ev == "UNIT_AURA" then
        if unit and UnitIsUnit(unit, "target") then Auras:UpdateBlizzTargetAuras() end
        if unit and UnitIsUnit(unit, "player") then Auras:UpdateBlizzPlayerAuras() end
    elseif ev == "PLAYER_AURAS_CHANGED" then
        Auras:UpdateBlizzPlayerAuras()
    elseif ev == "PLAYER_ENTERING_WORLD" then
        Auras:UpdateBlizzPlayerAuras()
        Auras:UpdateBlizzTargetAuras()
    end
end)
