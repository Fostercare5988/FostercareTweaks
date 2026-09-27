-- FostercareTweaks: mods/unitframes/auras.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Shared Unit Frame Aura Subsystem (Player, Target, ToT)
-- Powered natively by ClassicAPI C_UnitAuras and styled after Luna Unit Frames

local UF = FostercareTweaks.UnitFrames
if not UF then return end

UF.Auras = UF.Auras or {}
local Auras = UF.Auras

local BORDER_TEXTURE = "Interface\\AddOns\\FostercareTweaks\\img\\border-dark.tga"

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

local function ResetAuraButton(btn)
    if not btn then return end
    btn.unit = nil
    btn.auraIndex = nil
    btn.spellId = nil
    btn.expirationTime = nil
    btn.duration = nil
    btn.lastTimeText = nil
    btn.isOccupied = false
    timedButtons[btn] = nil

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
        btn.border:SetTexture(BORDER_TEXTURE)
        btn.border:SetTexCoord(0, 1, 0, 1)
        btn.border:SetVertexColor(0.15, 0.15, 0.15, 1)
    end

    btn:SetAlpha(1.0)
    btn:Hide()
end

local function UpdateAuraTimes()
    local now = GetTime()
    for btn in pairs(timedButtons) do
        if btn:IsVisible() then
            local remaining = (btn.expirationTime or 0) - now
            local showText = (btn.isDebuff and UF:IsDebuffText()) or
                (not btn.isDebuff and UF:IsBuffText())
            local text = remaining > 0 and showText and FormatAuraTime(remaining) or ""
            if btn.lastTimeText ~= text then
                btn.lastTimeText = text
                btn.durationText:SetText(text)
            end
            if text ~= "" then btn.durationText:Show() else btn.durationText:Hide() end
            if remaining <= 0 then
                timedButtons[btn] = nil
                CooldownFrame_SetTimer(btn.cooldown, 0, 0, 0)
                btn.cooldown:Hide()
            end
        end
    end
end
C_Timer.NewTicker(0.1, UpdateAuraTimes)

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

    -- Border overlay
    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetPoint("CENTER", btn, "CENTER")
    btn.border:SetWidth(size + 2)
    btn.border:SetHeight(size + 2)
    btn.border:SetTexture(BORDER_TEXTURE)
    btn.border:SetTexCoord(0, 1, 0, 1)
    btn.border:SetVertexColor(0.15, 0.15, 0.15, 1)

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

function Auras:CreateAuraContainer(parentFrame, unit, maxBuffs, maxDebuffs, options)
    options = options or {}
    local buffSize = (UF.GetBuffSize and UF:GetBuffSize()) or options.buffSize or options.size or 20
    local debuffSize = (UF.GetDebuffSize and UF:GetDebuffSize()) or options.debuffSize or options.size or 20
    local spacing = options.spacing or 3
    local perRow = options.perRow or 8

    local container = CreateFrame("Frame", parentFrame:GetName() .. "Auras", parentFrame)
    container.unit = unit
    container.buffButtons = {}
    container.debuffButtons = {}
    container.options = options
    container.buffSize = buffSize
    container.debuffSize = debuffSize

    -- Buff Row
    if maxBuffs and maxBuffs > 0 then
        container.buffFrame = CreateFrame("Frame", container:GetName() .. "Buffs", container)
        container.buffFrame:SetWidth((buffSize + spacing) * perRow - spacing)
        container.buffFrame:SetHeight(buffSize)

        if options.buffAnchor == "BOTTOM" then
            container.buffFrame:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 0, -4)
        else
            container.buffFrame:SetPoint("BOTTOMLEFT", parentFrame, "TOPLEFT", 0, 4)
        end

        for i = 1, maxBuffs do
            local btn = CreateAuraButton(container.buffFrame, container.buffFrame:GetName() .. i, buffSize, false)
            local row = math.floor((i - 1) / perRow)
            local col = (i - 1) % perRow
            if options.buffAnchor == "BOTTOM" then
                btn:SetPoint("TOPLEFT", container.buffFrame, "TOPLEFT", col * (buffSize + spacing), -row * (buffSize + spacing))
            else
                btn:SetPoint("BOTTOMLEFT", container.buffFrame, "BOTTOMLEFT", col * (buffSize + spacing), row * (buffSize + spacing))
            end
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

        if options.debuffAnchor == "TOP" then
            local relative = container.buffFrame or parentFrame
            container.debuffFrame:SetPoint("BOTTOMLEFT", relative, "TOPLEFT", 0, 4)
        else
            local relative = (options.buffAnchor == "BOTTOM" and container.buffFrame) or parentFrame
            container.debuffFrame:SetPoint("TOPLEFT", relative, "BOTTOMLEFT", 0, -4)
        end

        for i = 1, maxDebuffs do
            local btn = CreateAuraButton(container.debuffFrame, container.debuffFrame:GetName() .. i, debuffSize, true)
            local row = math.floor((i - 1) / perRow)
            local col = (i - 1) % perRow
            if options.debuffAnchor == "TOP" then
                btn:SetPoint("BOTTOMLEFT", container.debuffFrame, "BOTTOMLEFT", col * (debuffSize + spacing), row * (debuffSize + spacing))
            else
                btn:SetPoint("TOPLEFT", container.debuffFrame, "TOPLEFT", col * (debuffSize + spacing), -row * (debuffSize + spacing))
            end
            btn.unit = unit
            btn.auraIndex = i
            btn.container = container
            container.debuffButtons[i] = btn
        end
    end

    if FostercareTweaks.RegisterFrameMover and options.moveKey then
        if container.buffFrame then
            FostercareTweaks.RestoreFramePosition(container.buffFrame, options.moveKey .. "_buffs", parentFrame)
            FostercareTweaks.RegisterFrameMover(container.buffFrame, options.moveKey .. "_buffs", "Buffs", parentFrame)
        end
        if container.debuffFrame then
            FostercareTweaks.RestoreFramePosition(container.debuffFrame, options.moveKey .. "_debuffs", parentFrame)
            FostercareTweaks.RegisterFrameMover(container.debuffFrame, options.moveKey .. "_debuffs", "Debuffs", parentFrame)
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
        local row = math.floor((i - 1) / perRow)
        local col = (i - 1) % perRow
        btn:ClearAllPoints()
        if container.options and container.options.buffAnchor == "BOTTOM" then
            btn:SetPoint("TOPLEFT", container.buffFrame, "TOPLEFT", col * (newSize + spacing), -row * (newSize + spacing))
        else
            btn:SetPoint("BOTTOMLEFT", container.buffFrame, "BOTTOMLEFT", col * (newSize + spacing), row * (newSize + spacing))
        end
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
        local row = math.floor((i - 1) / perRow)
        local col = (i - 1) % perRow
        btn:ClearAllPoints()
        if container.options and container.options.debuffAnchor == "TOP" then
            btn:SetPoint("BOTTOMLEFT", container.debuffFrame, "BOTTOMLEFT", col * (newSize + spacing), row * (newSize + spacing))
        else
            btn:SetPoint("TOPLEFT", container.debuffFrame, "TOPLEFT", col * (newSize + spacing), -row * (newSize + spacing))
        end
    end
end

function Auras:ApplyAuraSize(container, newSize)
    Auras:ApplyBuffSize(container, newSize)
    Auras:ApplyDebuffSize(container, newSize)
end

function Auras:UpdateContainer(container)
    if not container or not container.unit then return end
    local unit = container.unit
    if not UnitExists(unit) then
        if container.buffButtons then
            for _, btn in ipairs(container.buffButtons) do
                ResetAuraButton(btn)
            end
        end
        if container.debuffButtons then
            for _, btn in ipairs(container.debuffButtons) do
                ResetAuraButton(btn)
            end
        end
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

    -- Update Buffs
    if container.buffButtons then
        local maxBuffs = table.getn(container.buffButtons)
        if not showBuffs then
            for _, btn in ipairs(container.buffButtons) do
                ResetAuraButton(btn)
            end
        else
            local btnIdx = 1
            for i = 1, 48 do
                if btnIdx > maxBuffs then break end
                local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = C_UnitAuras.UnitBuff(unit, i, "HELPFUL")
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

                        -- Unknown timing stays unknown; never restart a duration on observation.
                        local effectiveExpiration = expirationTime
                        local hasTimer = (effectiveExpiration and effectiveExpiration > now and duration and duration > 0)

                        -- Cooldown model sweep: synchronize timing directly on every timed update (Luna behavior)
                        if hasTimer and showBuffSpin and btn.cooldown then
                            local start = effectiveExpiration - duration
                            CooldownFrame_SetTimer(btn.cooldown, start, duration, 1)
                            btn.cooldown.reverse = true
                            btn.cooldown:Show()
                        elseif btn.cooldown then
                            CooldownFrame_SetTimer(btn.cooldown, 0, 0, 0)
                            btn.cooldown:Hide()
                        end

                        -- Duration text countdown
                        if hasTimer then
                            local remaining = effectiveExpiration - now
                            if remaining > 0 and showBuffText then
                                btn.durationText:SetText(FormatAuraTime(remaining))
                                btn.durationText:Show()
                            else
                                btn.durationText:SetText("")
                                btn.durationText:Hide()
                            end
                            timedButtons[btn] = true
                        else
                            btn.durationText:SetText("")
                            btn.durationText:Hide()
                            timedButtons[btn] = nil
                        end

                        btn.expirationTime = hasTimer and effectiveExpiration or 0
                        btn.duration = hasTimer and duration or 0

                        btn.border:SetTexture(BORDER_TEXTURE)
                        btn.border:SetTexCoord(0, 1, 0, 1)
                        btn.border:SetVertexColor(0.15, 0.15, 0.15, 1)
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
        local maxDebuffs = table.getn(container.debuffButtons)
        if not showDebuffs then
            for _, btn in ipairs(container.debuffButtons) do
                ResetAuraButton(btn)
            end
        else
            local btnIdx = 1
            local filter = "HARMFUL" -- Tooltip requires an index in the unfiltered polarity list.

            for i = 1, 48 do
                if btnIdx > maxDebuffs then break end
                local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer = C_UnitAuras.UnitDebuff(unit, i, filter)
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

                        -- Dispel border coloring
                        if colorDispel and dispelType and UF.DispelColors and UF.DispelColors[dispelType] then
                            local dc = UF.DispelColors[dispelType]
                            btn.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
                            btn.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
                            btn.border:SetVertexColor(dc.r, dc.g, dc.b, 1)
                        elseif colorDispel then
                            local dc = UF.DispelColors and UF.DispelColors["None"] or { r = 0.8, g = 0.2, b = 0.2 }
                            btn.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
                            btn.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
                            btn.border:SetVertexColor(dc.r, dc.g, dc.b, 1)
                        else
                            btn.border:SetTexture(BORDER_TEXTURE)
                            btn.border:SetTexCoord(0, 1, 0, 1)
                            btn.border:SetVertexColor(0.15, 0.15, 0.15, 1)
                        end

                        -- Unknown timing stays unknown; never restart a duration on observation.
                        local effectiveExpiration = expirationTime
                        local hasTimer = (effectiveExpiration and effectiveExpiration > now and duration and duration > 0)

                        -- Cooldown model sweep: synchronize timing directly on every timed update (Luna behavior)
                        if hasTimer and showDebuffSpin and btn.cooldown then
                            local start = effectiveExpiration - duration
                            CooldownFrame_SetTimer(btn.cooldown, start, duration, 1)
                            btn.cooldown.reverse = true
                            btn.cooldown:Show()
                        elseif btn.cooldown then
                            CooldownFrame_SetTimer(btn.cooldown, 0, 0, 0)
                            btn.cooldown:Hide()
                        end

                        -- Duration text countdown
                        if hasTimer then
                            local remaining = effectiveExpiration - now
                            if remaining > 0 and showDebuffText then
                                btn.durationText:SetText(FormatAuraTime(remaining))
                                btn.durationText:Show()
                            else
                                btn.durationText:SetText("")
                                btn.durationText:Hide()
                            end
                            timedButtons[btn] = true
                        else
                            btn.durationText:SetText("")
                            btn.durationText:Hide()
                            timedButtons[btn] = nil
                        end

                        btn.expirationTime = hasTimer and effectiveExpiration or 0
                        btn.duration = hasTimer and duration or 0

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
            row:SetWidth(math.min(perRow, math.max(1, count)) * (size + spacing) - spacing)
            row:SetHeight(math.max(1, math.ceil(count / perRow)) * (size + spacing) - spacing)
        end
    end
    local parent = container:GetParent()
    local key = options.moveKey
    if options.standard then
        if container.buffFrame and not HasSavedPosition(key .. "_buffs") then
            container.buffFrame:ClearAllPoints()
            if container.unit == "player" then
                container.buffFrame:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 5, 12)
            else
                container.buffFrame:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 5, 32)
            end
        end
        if container.debuffFrame and not HasSavedPosition(key .. "_debuffs") then
            container.debuffFrame:ClearAllPoints()
            local buffs = container.buffFrame
            if buffs and buffs:IsShown() and (buffs.occupiedCount or 0) > 0 then
                container.debuffFrame:SetPoint("TOPLEFT", buffs, "BOTTOMLEFT", 0, -4)
            else
                container.debuffFrame:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 5, container.unit == "player" and 12 or 32)
            end
        end
    end
end

function Auras:AttachToTargetFrame()
    if UF.blizzTargetAuras then return UF.blizzTargetAuras end
    if not TargetFrame then return nil end

    local buffSize = (UF.GetBuffSize and UF:GetBuffSize()) or 20
    local debuffSize = (UF.GetDebuffSize and UF:GetDebuffSize()) or 20

    -- Standard TargetFrame accommodates 5 auras per row cleanly without overlapping TargetofTargetFrame
    local container = Auras:CreateAuraContainer(TargetFrame, "target", 32, 48, {
        standard = true, moveKey = "standard_target",
        buffSize = buffSize,
        debuffSize = debuffSize,
        spacing = 3,
        perRow = 5,
        buffAnchor = "BOTTOM",
        debuffAnchor = "BOTTOM",
    })
    container:ClearAllPoints()
    container:SetPoint("TOPLEFT", TargetFrame, "BOTTOMLEFT", 5, 32)
    container:SetFrameStrata("LOW")

    UF.blizzTargetAuras = container
    return container
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
            if not enabled and targetShown and not isModernTarget and TargetFrame_UpdateAuras then
                TargetFrame_UpdateAuras()
            end
        end
        isUpdatingBlizzAuras = false
        return
    end

    -- Suppress stock Blizzard target aura buttons
    local _G = _G or getfenv(0)
    for i = 1, 5 do
        local b = _G["TargetFrameBuff" .. i]
        if b then b:Hide() end
    end
    for i = 1, 16 do
        local d = _G["TargetFrameDebuff" .. i]
        if d then d:Hide() end
    end

    container:Show()
    Auras:UpdateContainer(container)

    isUpdatingBlizzAuras = false
end

-- Secure hook TargetFrame_UpdateAuras so stock target frame aura changes are captured in real time
if TargetFrame and FostercareTweaks.hooksecurefunc then
    FostercareTweaks.hooksecurefunc("TargetFrame_UpdateAuras", function()
        if Auras.UpdateBlizzTargetAuras then
            Auras:UpdateBlizzTargetAuras()
        end
    end)
end

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
        return
    end
    container:Show()
    Auras:UpdateContainer(container)
end

auraEventFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
auraEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
auraEventFrame:SetScript("OnEvent", function()
    if event == "PLAYER_TARGET_CHANGED" or (event == "UNIT_AURA" and arg1 == "target") then
        Auras:UpdateBlizzTargetAuras()
    elseif event == "PLAYER_AURAS_CHANGED" or (event == "UNIT_AURA" and arg1 == "player") then
        Auras:UpdateBlizzPlayerAuras()
    elseif event == "PLAYER_ENTERING_WORLD" then
        Auras:UpdateBlizzPlayerAuras()
        Auras:UpdateBlizzTargetAuras()
    end
end)
