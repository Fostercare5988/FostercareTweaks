-- FostercareTweaks: mods/unitframes/auras.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Shared Unit Frame Aura Subsystem (Player, Target, ToT)
-- Powered natively by ClassicAPI C_UnitAuras and styled after Luna Unit Frames

local UF = FostercareTweaks.UnitFrames
if not UF then return end

UF.Auras = UF.Auras or {}
local Auras = UF.Auras

local BORDER_TEXTURE = "Interface\\AddOns\\FostercareTweaks\\img\\border-dark.tga"

-- Reverse cooldown animation support (Luna style for auras)
if not CooldownFrame_OnUpdateModel_FCT_Orig then
    local orig_CooldownFrame_OnUpdateModel = CooldownFrame_OnUpdateModel
    CooldownFrame_OnUpdateModel_FCT_Orig = orig_CooldownFrame_OnUpdateModel
    function CooldownFrame_OnUpdateModel()
        if this and this.reverse and this.stopping == 0 and this.start and this.duration and this.duration > 0 then
            local finished = (GetTime() - this.start) / this.duration
            if finished < 1.0 then
                finished = 1.0 - finished
                this:SetSequenceTime(0, finished * 1000)
                return
            end
            this.stopping = 1
            this:SetSequence(1)
            this:SetSequenceTime(1, 0)
            return
        end
        if orig_CooldownFrame_OnUpdateModel then
            orig_CooldownFrame_OnUpdateModel()
        end
    end
end

local function AuraButton_OnEnter()
    local unit = this.unit
    local index = this.auraIndex
    local isDebuff = this.isDebuff
    if not unit or not index then return end

    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
    if unit == "player" and not isDebuff then
        if GetPlayerBuff then
            local buffIndex = GetPlayerBuff(index - 1, "HELPFUL")
            if buffIndex and buffIndex >= 0 then
                GameTooltip:SetPlayerBuff(buffIndex) -- vanillaforge-ignore: AP-01
                GameTooltip:Show()
                return
            end
        end
        GameTooltip:SetPlayerBuff(index) -- vanillaforge-ignore: AP-01
    elseif isDebuff then
        GameTooltip:SetUnitDebuff(unit, index) -- vanillaforge-ignore: AP-01
    else
        GameTooltip:SetUnitBuff(unit, index)
    end
    GameTooltip:Show()
end

local function AuraButton_OnLeave()
    GameTooltip:Hide()
end

local function AuraButton_OnClick()
    if arg1 == "RightButton" and this.unit == "player" and not this.isDebuff and this.auraIndex then
        if GetPlayerBuff then
            local buffIndex = GetPlayerBuff(this.auraIndex - 1, "HELPFUL")
            if buffIndex and buffIndex >= 0 then
                CancelPlayerBuff(buffIndex)
                return
            end
        end
        CancelPlayerBuff(this.auraIndex)
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

local function AuraButton_OnUpdate()
    local exp = this.expirationTime
    if not exp or exp <= 0 then
        if this.durationText then this.durationText:Hide() end
        if this.cooldown then this.cooldown:Hide() end
        this:SetScript("OnUpdate", nil)
        return
    end

    local now = GetTime()
    if (this.nextUpdate or 0) > now then return end
    this.nextUpdate = now + 0.15

    local remaining = exp - now
    if remaining <= 0 then
        if this.durationText then this.durationText:Hide() end
        if this.cooldown then this.cooldown:Hide() end
        this:SetScript("OnUpdate", nil)
        return
    end

    local showText = false
    if this.isDebuff then
        showText = (UF.IsDebuffText and UF:IsDebuffText())
    else
        showText = (UF.IsBuffText and UF:IsBuffText())
    end

    if this.durationText and showText then
        this.durationText:SetText(FormatAuraTime(remaining))
        this.durationText:Show()
    else
        if this.durationText then this.durationText:Hide() end
    end
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
    btn.cooldown:SetWidth(size)
    btn.cooldown:SetHeight(size)
    btn.cooldown:SetScale(size / 36)
    btn.cooldown.reverse = true
    btn.cooldown.noCooldownCount = true
    btn.cooldown:Hide()

    -- Overlay text frame (drawn above cooldown)
    btn.textFrame = CreateFrame("Frame", nil, btn)
    btn.textFrame:SetAllPoints(btn)
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
            container.debuffButtons[i] = btn
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
            btn.cooldown:SetWidth(newSize)
            btn.cooldown:SetHeight(newSize)
            btn.cooldown:SetScale(newSize / 36)
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
            btn.cooldown:SetWidth(newSize)
            btn.cooldown:SetHeight(newSize)
            btn.cooldown:SetScale(newSize / 36)
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
                btn.expirationTime = nil
                btn.duration = nil
                if btn.durationText then btn.durationText:Hide() end
                if btn.cooldown then btn.cooldown:Hide() end
                btn:SetScript("OnUpdate", nil)
                btn:Hide()
            end
        end
        if container.debuffButtons then
            for _, btn in ipairs(container.debuffButtons) do
                btn.expirationTime = nil
                btn.duration = nil
                if btn.durationText then btn.durationText:Hide() end
                if btn.cooldown then btn.cooldown:Hide() end
                btn:SetScript("OnUpdate", nil)
                btn:Hide()
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

    -- Update Buffs
    if container.buffButtons then
        for i, btn in ipairs(container.buffButtons) do
            btn.unit = unit
            if not showBuffs then
                btn.expirationTime = nil
                btn.duration = nil
                if btn.durationText then btn.durationText:Hide() end
                if btn.cooldown then
                    btn.cooldown:Hide()
                    CooldownFrame_SetTimer(btn.cooldown, 0, 0, 0)
                end
                btn:SetScript("OnUpdate", nil)
                btn:Hide()
            else
                local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster
                if C_UnitAuras and C_UnitAuras.UnitAura then
                    name, rank, icon, count, debuffType, duration, expirationTime, unitCaster = C_UnitAuras.UnitAura(unit, i, "HELPFUL")
                elseif C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
                    local aura = C_UnitAuras.GetBuffDataByIndex(unit, i)
                    if aura then
                        name = aura.name
                        icon = aura.icon
                        count = aura.applications or aura.count
                        duration = aura.duration
                        expirationTime = aura.expirationTime
                    end
                elseif UnitBuff then
                    local tex, cnt = UnitBuff(unit, i)
                    icon = tex
                    count = cnt
                end

                if icon then
                    btn.icon:SetTexture(icon)
                    btn.icon:SetVertexColor(1, 1, 1, 1)
                    btn:SetAlpha(1.0)

                    if count and count > 1 then
                        btn.countText:SetText(count)
                        btn.countText:Show()
                    else
                        btn.countText:Hide()
                    end

                    btn.expirationTime = expirationTime
                    btn.duration = duration

                    -- Cooldown model sweep
                    if expirationTime and expirationTime > 0 and (duration or 0) > 0 and showBuffSpin and btn.cooldown then
                        btn.cooldown.reverse = true
                        btn.cooldown:Show()
                        CooldownFrame_SetTimer(btn.cooldown, expirationTime - duration, duration, 1)
                    elseif btn.cooldown then
                        btn.cooldown:Hide()
                        CooldownFrame_SetTimer(btn.cooldown, 0, 0, 0)
                    end

                    -- Duration text countdown
                    if expirationTime and expirationTime > 0 then
                        local remaining = expirationTime - GetTime()
                        if remaining > 0 and showBuffText then
                            btn.durationText:SetText(FormatAuraTime(remaining))
                            btn.durationText:Show()
                        else
                            btn.durationText:Hide()
                        end
                        btn.nextUpdate = 0
                        btn:SetScript("OnUpdate", AuraButton_OnUpdate)
                    else
                        btn.durationText:Hide()
                        btn:SetScript("OnUpdate", nil)
                    end

                    btn.border:SetTexture(BORDER_TEXTURE)
                    btn.border:SetTexCoord(0, 1, 0, 1)
                    btn.border:SetVertexColor(0.15, 0.15, 0.15, 1)
                    btn:Show()
                else
                    btn.expirationTime = nil
                    btn.duration = nil
                    if btn.durationText then btn.durationText:Hide() end
                    if btn.cooldown then
                        btn.cooldown:Hide()
                        CooldownFrame_SetTimer(btn.cooldown, 0, 0, 0)
                    end
                    btn:SetScript("OnUpdate", nil)
                    btn:Hide()
                end
            end
        end
    end

    -- Update Debuffs
    if container.debuffButtons then
        local targetDebuffSlot = 1
        for i, btn in ipairs(container.debuffButtons) do
            btn.unit = unit
            if not showDebuffs then
                btn.expirationTime = nil
                btn.duration = nil
                if btn.durationText then btn.durationText:Hide() end
                if btn.cooldown then
                    btn.cooldown:Hide()
                    CooldownFrame_SetTimer(btn.cooldown, 0, 0, 0)
                end
                btn:SetScript("OnUpdate", nil)
                btn:Hide()
            else
                local name, rank, icon, count, dispelType, duration, expirationTime, unitCaster
                local found = false

                if C_UnitAuras and C_UnitAuras.UnitAura then
                    local filter = onlyMine and "HARMFUL|PLAYER" or "HARMFUL"
                    name, rank, icon, count, dispelType, duration, expirationTime, unitCaster = C_UnitAuras.UnitAura(unit, i, filter)
                    if icon then
                        btn.auraIndex = i
                        found = true
                    end
                else
                    -- Fallback scanner
                    while targetDebuffSlot <= 40 do
                        local aura = nil
                        if C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex then
                            aura = C_UnitAuras.GetDebuffDataByIndex(unit, targetDebuffSlot)
                        elseif C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
                            aura = C_UnitAuras.GetAuraDataByIndex(unit, targetDebuffSlot, "HARMFUL")
                        end

                        if aura then
                            local isMine = not onlyMine or aura.isCastByPlayer or (aura.sourceUnit == "player") or (aura.caster == "player")
                            if isMine then
                                icon = aura.icon
                                count = aura.applications or aura.count
                                dispelType = aura.dispelName or aura.dispelType or aura.debuffType
                                duration = aura.duration
                                expirationTime = aura.expirationTime
                                btn.auraIndex = targetDebuffSlot
                                found = true
                                targetDebuffSlot = targetDebuffSlot + 1
                                break
                            end
                        elseif UnitDebuff then
                            local tex, cnt, dtype = UnitDebuff(unit, targetDebuffSlot)
                            if tex then
                                icon = tex
                                count = cnt
                                dispelType = dtype
                                btn.auraIndex = targetDebuffSlot
                                found = true
                                targetDebuffSlot = targetDebuffSlot + 1
                                break
                            else
                                break
                            end
                        else
                            break
                        end
                        targetDebuffSlot = targetDebuffSlot + 1
                    end
                end

                if found and icon then
                    btn.icon:SetTexture(icon)
                    btn.icon:SetVertexColor(1, 1, 1, 1)
                    btn:SetAlpha(1.0)

                    if count and count > 1 then
                        btn.countText:SetText(count)
                        btn.countText:Show()
                    else
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

                    btn.expirationTime = expirationTime
                    btn.duration = duration

                    -- Cooldown model sweep
                    if expirationTime and expirationTime > 0 and (duration or 0) > 0 and showDebuffSpin and btn.cooldown then
                        btn.cooldown.reverse = true
                        btn.cooldown:Show()
                        CooldownFrame_SetTimer(btn.cooldown, expirationTime - duration, duration, 1)
                    elseif btn.cooldown then
                        btn.cooldown:Hide()
                        CooldownFrame_SetTimer(btn.cooldown, 0, 0, 0)
                    end

                    -- Duration text countdown
                    if expirationTime and expirationTime > 0 then
                        local remaining = expirationTime - GetTime()
                        if remaining > 0 and showDebuffText then
                            btn.durationText:SetText(FormatAuraTime(remaining))
                            btn.durationText:Show()
                        else
                            btn.durationText:Hide()
                        end
                        btn.nextUpdate = 0
                        btn:SetScript("OnUpdate", AuraButton_OnUpdate)
                    else
                        btn.durationText:Hide()
                        btn:SetScript("OnUpdate", nil)
                    end

                    btn:Show()
                else
                    btn.expirationTime = nil
                    btn.duration = nil
                    if btn.durationText then btn.durationText:Hide() end
                    if btn.cooldown then
                        btn.cooldown:Hide()
                        CooldownFrame_SetTimer(btn.cooldown, 0, 0, 0)
                    end
                    btn:SetScript("OnUpdate", nil)
                    btn:Hide()
                end
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
    local container = Auras:CreateAuraContainer(TargetFrame, "target", 16, 16, {
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

    -- Dynamic vertical alignment of debuffs below active buffs
    local visibleBuffs = 0
    if container.buffButtons then
        for _, btn in ipairs(container.buffButtons) do
            if btn:IsShown() then
                visibleBuffs = visibleBuffs + 1
            end
        end
    end

    local perRow = (container.options and container.options.perRow) or 5
    local buffSize = container.buffSize or 20
    local spacing = (container.options and container.options.spacing) or 3

    if container.buffFrame then
        container.buffFrame:ClearAllPoints()
        container.buffFrame:SetPoint("TOPLEFT", TargetFrame, "BOTTOMLEFT", 5, 32)
    end

    if container.debuffFrame then
        container.debuffFrame:ClearAllPoints()
        if visibleBuffs > 0 and container.buffFrame and container.buffFrame:IsShown() then
            local rows = math.ceil(visibleBuffs / perRow)
            local offset = 32 - (rows * (buffSize + spacing)) - 2
            container.debuffFrame:SetPoint("TOPLEFT", TargetFrame, "BOTTOMLEFT", 5, offset)
        else
            container.debuffFrame:SetPoint("TOPLEFT", TargetFrame, "BOTTOMLEFT", 5, 32)
        end
    end

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
