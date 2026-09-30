if not FostercareTweaks then return end

-- FostercareTweaks: mods/unitframes/target.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Modern Unit Frames Subsystem: Target Frame

local UF = FostercareTweaks.UnitFrames
if not UF then return end

local targetFrame = nil

-- Public, read-only anchor contract for optional target-frame integrations.
function FostercareTweaks.GetActiveTargetFrame()
    if UF.enabled and UF:IsModernTarget() then return targetFrame end
    return TargetFrame
end

local function UpdateHealth(frame)
    if not frame or not frame:IsShown() or not UnitExists("target") then return end

    local cur, max = UF.GetUnitHealthValues("target")
    frame.healthBar:SetMinMaxValues(0, max)
    frame.healthBar:SetValue(cur)

    -- Bar Coloring (Class color for real players, Reaction color for NPCs)
    local isPlayer = UF.IsRealPlayer and UF.IsRealPlayer("target")
    if isPlayer then
        local _, cls = UnitClass("target")
        local classToken = cls and (FostercareTweaks.NormalizeClass and FostercareTweaks.NormalizeClass(cls) or cls)
        local c = classToken and UF.ClassColors[classToken]
        if c then
            frame.healthBar:SetStatusBarColor(c.r, c.g, c.b, 1)
        else
            frame.healthBar:SetStatusBarColor(0.2, 0.8, 0.2, 1)
        end
    else
        local reaction = UnitReaction("target", "player")
        if UnitCanAttack("player", "target") or (reaction and reaction <= 3) then
            local c = UF.ReactionColors[1]
            frame.healthBar:SetStatusBarColor(c.r, c.g, c.b, 1)
        elseif reaction and reaction > 4 then
            local c = UF.ReactionColors[5]
            frame.healthBar:SetStatusBarColor(c.r, c.g, c.b, 1)
        else
            local c = UF.ReactionColors[4]
            frame.healthBar:SetStatusBarColor(c.r, c.g, c.b, 1)
        end
    end

    -- Level, Difficulty Color & Classification
    local level = UnitLevel("target") or 0
    local classification = UnitClassification("target") or "normal"
    local classTag = ""
    if classification == "worldboss" then
        classTag = ""
    elseif classification == "rareelite" then
        classTag = "r+"
    elseif classification == "elite" then
        classTag = "+"
    elseif classification == "rare" then
        classTag = "r"
    end

    local showLevel = (not UF.IsShowLevel) or UF:IsShowLevel()
    if showLevel and frame.healthBar.levelText then
        local levelStr = ""
        local r, g, b = 1, 1, 1
        if level <= 0 or classification == "worldboss" then
            levelStr = "??" .. classTag
            r, g, b = 1.0, 0.0, 0.0
        else
            levelStr = tostring(level) .. classTag
            local c = GetDifficultyColor and GetDifficultyColor(level)
            if c then
                r, g, b = c.r, c.g, c.b
            end
        end
        frame.healthBar.levelText:SetText(levelStr)
        frame.healthBar.levelText:SetTextColor(r, g, b, 1)
        frame.healthBar.levelText:Show()

        frame.healthBar.nameText:ClearAllPoints()
        frame.healthBar.nameText:SetPoint("LEFT", frame.healthBar.levelText, "RIGHT", 4, 0)
        frame.healthBar.nameText:SetPoint("RIGHT", frame.healthBar.healthText, "LEFT", -4, 0)
    else
        if frame.healthBar.levelText then frame.healthBar.levelText:Hide() end
        frame.healthBar.nameText:ClearAllPoints()
        frame.healthBar.nameText:SetPoint("LEFT", frame.healthBar, "LEFT", 4, 0)
        frame.healthBar.nameText:SetPoint("RIGHT", frame.healthBar.healthText, "LEFT", -4, 0)
    end

    local name = UnitName("target") or "Target"
    frame.healthBar.nameText:SetText(name)

    -- Optional class / creature type in power bar leftText (never forces [60] ROGUE)
    if frame.powerBar and frame.powerBar.leftText then
        local showClass = UF.IsShowClass and UF:IsShowClass()
        if showClass then
            local typeText = ""
            if isPlayer then
                local className = UnitClass("target")
                typeText = className or ""
            else
                typeText = UnitCreatureType("target") or ""
            end
            frame.powerBar.leftText:SetText(typeText)
            frame.powerBar.leftText:Show()
        else
            frame.powerBar.leftText:SetText("")
            frame.powerBar.leftText:Hide()
        end
    end

    -- Concise Health text (No bloat, no duplicate max, no overlap)
    if UnitIsDeadOrGhost("target") then
        frame.healthBar.healthText:SetText(UnitIsGhost("target") and "Ghost" or "Dead")
    elseif max > 0 then
        local curStr = FostercareTweaks.Abbreviate(cur)
        if cur == max then
            frame.healthBar.healthText:SetText(curStr)
        else
            local maxStr = FostercareTweaks.Abbreviate(max)
            frame.healthBar.healthText:SetText(curStr .. " / " .. maxStr)
        end
    else
        frame.healthBar.healthText:SetText("")
    end
end
UF.UpdateTargetHealth = UpdateHealth

local function UpdatePower(frame)
    if not frame or not frame:IsShown() or not UnitExists("target") then return end

    local max = UnitManaMax("target") or 0
    local powerType = UnitPowerType("target") or 0
    local cur = UnitMana("target") or 0

    if max > 0 then
        frame.powerBar:Show()
        frame.powerBar:SetMinMaxValues(0, max)
        frame.powerBar:SetValue(cur)

        local c = UF.PowerColors[powerType] or UF.PowerColors[0]
        frame.powerBar:SetStatusBarColor(c.r, c.g, c.b, 1)

        if powerType == 1 or powerType == 3 then
            frame.powerBar.powerText:SetText(tostring(cur))
        else
            local curStr = FostercareTweaks.Abbreviate(cur)
            local maxStr = FostercareTweaks.Abbreviate(max)
            frame.powerBar.powerText:SetText(curStr .. " / " .. maxStr)
        end
    else
        frame.powerBar:Hide()
        frame.powerBar.powerText:SetText("")
    end

    UF:LayoutBars(frame)
end

local function UpdatePortrait(frame)
    if not frame or not frame:IsShown() or not frame.portrait or not UnitExists("target") then return end
    SetPortraitTexture(frame.portrait.tex, "target")
    frame.portrait.tex:SetTexCoord(0.14, 0.86, 0.14, 0.86)
end

local COMBO_COLORS = {
    [1] = { r = 1.00, g = 0.82, b = 0.00 },
    [2] = { r = 1.00, g = 0.82, b = 0.00 },
    [3] = { r = 1.00, g = 0.70, b = 0.00 },
    [4] = { r = 1.00, g = 0.50, b = 0.00 },
    [5] = { r = 1.00, g = 0.20, b = 0.20 },
}

local function UpdateComboPoints(frame)
    if not frame or not frame.comboFrame then return end

    if not UnitExists("target") or not frame:IsShown() then
        frame.comboFrame:Hide()
        return
    end

    if UF.IsModernComboPoints and not UF:IsModernComboPoints() then
        frame.comboFrame:Hide()
        return
    end

    local points = GetComboPoints and GetComboPoints() or 0
    if points > 5 then points = 5 end
    if points < 0 then points = 0 end

    if points <= 0 then
        frame.comboFrame:Hide()
        return
    end

    for i = 1, 5 do
        local pip = frame.comboFrame.pips[i]
        if pip then
            if i <= points then
                local c = COMBO_COLORS[i]
                pip.fill:SetVertexColor(c.r, c.g, c.b, 1)
                pip.fill:Show()
            else
                pip.fill:Hide()
            end
        end
    end

    frame.comboFrame:Show()
end
UF.UpdateComboPoints = UpdateComboPoints

local function UpdateRaidTarget(frame)
    if not frame or not frame.raidIcon then return end

    if not UnitExists("target") or not frame:IsShown() then
        frame.raidIcon:Hide()
        return
    end

    local index = GetRaidTargetIndex and GetRaidTargetIndex("target")
    if index and index >= 1 and index <= 8 and SetRaidTargetIconTexture then
        SetRaidTargetIconTexture(frame.raidIcon, index)
        frame.raidIcon:Show()
    else
        frame.raidIcon:Hide()
    end
end
UF.UpdateRaidTarget = UpdateRaidTarget

local function UpdatePvP(frame)
    if not frame or not frame.pvpIcon then return end
    if not UnitExists("target") or not frame:IsShown() then
        frame.pvpIcon:Hide()
        return
    end
    if UF.IsShowPvP and not UF:IsShowPvP() then
        frame.pvpIcon:Hide()
        return
    end
    local factionGroup = UnitFactionGroup and UnitFactionGroup("target")
    if UnitIsPVPFreeForAll and UnitIsPVPFreeForAll("target") then
        frame.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
        frame.pvpIcon:Show()
    elseif factionGroup and UnitIsPVP and UnitIsPVP("target") and (factionGroup == "Alliance" or factionGroup == "Horde") then
        frame.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-" .. factionGroup)
        frame.pvpIcon:Show()
    else
        frame.pvpIcon:Hide()
    end
end
UF.UpdateTargetPvP = UpdatePvP

local function UpdateAll(frame)
    if not frame then return end
    if not UnitExists("target") then
        frame:Hide()
        if frame.comboFrame then frame.comboFrame:Hide() end
        if frame.raidIcon then frame.raidIcon:Hide() end
        if frame.pvpIcon then frame.pvpIcon:Hide() end
        return
    end

    frame:Show()
    UpdatePortrait(frame)
    UpdateHealth(frame)
    UpdatePower(frame)
    UF:LayoutBars(frame)
    if UF.ApplyFonts then UF:ApplyFonts() end
    UpdateComboPoints(frame)
    UpdateRaidTarget(frame)
    UpdatePvP(frame)
    if frame.auraContainer and UF.Auras and UF.Auras.UpdateContainer then
        UF.Auras:UpdateContainer(frame.auraContainer)
    end
end

local function TargetFrame_OnEvent()
    local ev = event
    local a1 = arg1

    if ev == "PLAYER_TARGET_CHANGED" then
        UpdateAll(targetFrame)
    elseif ev == "PLAYER_COMBO_POINTS" then
        if targetFrame and targetFrame:IsShown() then
            UpdateComboPoints(targetFrame)
        end
    elseif not targetFrame or not targetFrame:IsShown() then
        return
    elseif ev == "UNIT_HEALTH" or ev == "UNIT_MAXHEALTH" then
        if a1 == "target" then UpdateHealth(targetFrame) end
    elseif ev == "UNIT_MANA" or ev == "UNIT_RAGE" or ev == "UNIT_ENERGY" or ev == "UNIT_FOCUS" or
           ev == "UNIT_MAXMANA" or ev == "UNIT_MAXRAGE" or ev == "UNIT_MAXENERGY" or ev == "UNIT_DISPLAYPOWER" then
        if a1 == "target" then UpdatePower(targetFrame) end
    elseif ev == "UNIT_PORTRAIT_UPDATE" or ev == "UNIT_MODEL_CHANGED" then
        if a1 == "target" then UpdatePortrait(targetFrame) end
    elseif ev == "UNIT_AURA" then
        if a1 and UnitIsUnit(a1, "target") and targetFrame.auraContainer and UF.Auras and UF.Auras.UpdateContainer then
            UF.Auras:UpdateContainer(targetFrame.auraContainer)
        end
    elseif ev == "UNIT_LEVEL" or ev == "UNIT_NAME_UPDATE" or ev == "UNIT_CLASSIFICATION_CHANGED" then
        if a1 == "target" then UpdateHealth(targetFrame) end
    elseif ev == "UNIT_FACTION" then
        if a1 == "target" then
            UpdateHealth(targetFrame)
            UpdatePvP(targetFrame)
        end
    elseif ev == "PLAYER_FLAGS_CHANGED" then
        UpdatePvP(targetFrame)
    elseif ev == "RAID_TARGET_UPDATE" then
        UpdateRaidTarget(targetFrame)
    elseif ev == "PLAYER_ENTERING_WORLD" then
        UpdateAll(targetFrame)
    end
end

function UF:EnableTargetFrame()
    if not targetFrame then
        targetFrame = UF:CreateUnitFrame("target", "FCTweaksTargetFrame", UIParent)
        targetFrame:SetWidth(UF:GetTargetWidth())
        targetFrame:SetHeight(UF:GetTargetHeight())
        targetFrame:SetScale(UF:GetScale())

        -- Position restoration or default
        targetFrame:ClearAllPoints()
        local savedPos = FostercareTweaks_Config and FostercareTweaks_Config.unitframe_positions and FostercareTweaks_Config.unitframe_positions["target"]
        if savedPos and savedPos.point and savedPos.relPoint and savedPos.x and savedPos.y then
            targetFrame:SetPoint(savedPos.point, UIParent, savedPos.relPoint, savedPos.x, savedPos.y)
        else
            targetFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 175, 140)
        end

        -- Portrait (Right)
        local portrait = CreateFrame("Frame", nil, targetFrame)
        portrait:SetBackdrop(UF.backdrop)
        portrait:SetBackdropColor(0, 0, 0, 0.9)
        portrait:SetBackdropBorderColor(0, 0, 0, 1)

        portrait.tex = portrait:CreateTexture(nil, "ARTWORK")
        portrait.tex:SetPoint("TOPLEFT", portrait, "TOPLEFT", 1, -1)
        portrait.tex:SetPoint("BOTTOMRIGHT", portrait, "BOTTOMRIGHT", -1, 1)

        targetFrame.portrait = portrait
        targetFrame.portraitSide = "right"

        -- Raid Target Icon
        local raidIcon = portrait:CreateTexture(nil, "OVERLAY")
        raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
        raidIcon:SetWidth(22)
        raidIcon:SetHeight(22)
        raidIcon:SetPoint("CENTER", portrait, "CENTER", 0, 0)
        raidIcon:Hide()
        targetFrame.raidIcon = raidIcon

        -- PvP Emblem
        local pvpIcon = portrait:CreateTexture(nil, "OVERLAY")
        pvpIcon:SetWidth(22)
        pvpIcon:SetHeight(22)
        pvpIcon:SetPoint("TOPRIGHT", portrait, "TOPRIGHT", 6, 6)
        pvpIcon:Hide()
        targetFrame.pvpIcon = pvpIcon

        -- Health Bar
        local hb = UF:CreateBar("FCTweaksTargetHealthBar", targetFrame)
        hb.levelText = hb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hb.levelText:SetPoint("LEFT", hb, "LEFT", 4, 0)
        hb.levelText:SetJustifyH("LEFT")
        hb.levelText:SetShadowColor(0, 0, 0, 1)
        hb.levelText:SetShadowOffset(0.8, -0.8)

        hb.nameText = hb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hb.nameText:SetPoint("LEFT", hb.levelText, "RIGHT", 4, 0)
        hb.nameText:SetJustifyH("LEFT")
        hb.nameText:SetShadowColor(0, 0, 0, 1)
        hb.nameText:SetShadowOffset(0.8, -0.8)

        hb.healthText = hb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hb.healthText:SetPoint("RIGHT", hb, "RIGHT", -4, 0)
        hb.healthText:SetJustifyH("RIGHT")
        hb.healthText:SetShadowColor(0, 0, 0, 1)
        hb.healthText:SetShadowOffset(0.8, -0.8)

        targetFrame.healthBar = hb

        -- Power Bar
        local pb = UF:CreateBar("FCTweaksTargetPowerBar", targetFrame)
        pb.leftText = pb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        pb.leftText:SetPoint("LEFT", pb, "LEFT", 4, 0)
        pb.leftText:SetJustifyH("LEFT")
        pb.leftText:SetShadowColor(0, 0, 0, 1)
        pb.leftText:SetShadowOffset(1, -1)

        pb.powerText = pb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        pb.powerText:SetPoint("RIGHT", pb, "RIGHT", -4, 0)
        pb.powerText:SetJustifyH("RIGHT")
        pb.powerText:SetShadowColor(0, 0, 0, 1)
        pb.powerText:SetShadowOffset(1, -1)

        targetFrame.powerBar = pb

        -- Combo Points (5 pips anchored above the portrait)
        local comboFrame = CreateFrame("Frame", "FCTweaksTargetComboFrame", targetFrame)
        comboFrame:SetWidth(42)
        comboFrame:SetHeight(9)
        comboFrame:SetPoint("BOTTOMLEFT", portrait, "TOPLEFT", 0, 2)
        comboFrame:SetBackdrop(UF.backdrop)
        comboFrame:SetBackdropColor(0, 0, 0, 0.9)
        comboFrame:SetBackdropBorderColor(0, 0, 0, 1)

        comboFrame.pips = {}
        local pipWidth = 7
        local pipHeight = 7
        local pipSpacing = 1
        local leftOffset = 1

        for i = 1, 5 do
            local pip = CreateFrame("Frame", nil, comboFrame)
            pip:SetWidth(pipWidth)
            pip:SetHeight(pipHeight)
            pip:SetPoint("LEFT", comboFrame, "LEFT", leftOffset + (i - 1) * (pipWidth + pipSpacing), 0)

            pip.bg = pip:CreateTexture(nil, "BACKGROUND")
            pip.bg:SetAllPoints(pip)
            pip.bg:SetTexture(UF.defaultBarTexture)
            pip.bg:SetVertexColor(0.15, 0.15, 0.15, 0.8)

            pip.fill = pip:CreateTexture(nil, "ARTWORK")
            pip.fill:SetAllPoints(pip)
            pip.fill:SetTexture(UF.defaultBarTexture)
            pip.fill:Hide()

            comboFrame.pips[i] = pip
        end

        comboFrame:Hide()
        targetFrame.comboFrame = comboFrame

        -- Aura Container (up to 32 buffs and 48 harmful auras)
        if UF.Auras and UF.Auras.CreateAuraContainer then
            targetFrame.auraContainer = UF.Auras:CreateAuraContainer(targetFrame, "target", 32, 48, {
                moveKey = "modern_target",
                size = 20,
                spacing = 3,
                perRow = 8,
                buffAnchor = "TOP",
                debuffAnchor = "BOTTOM",
            })
        end

        UF.targetFrame = targetFrame
    end

    -- Event Registration
    targetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    targetFrame:RegisterEvent("PLAYER_COMBO_POINTS")
    targetFrame:RegisterEvent("UNIT_HEALTH")
    targetFrame:RegisterEvent("UNIT_MAXHEALTH")
    targetFrame:RegisterEvent("UNIT_MANA")
    targetFrame:RegisterEvent("UNIT_RAGE")
    targetFrame:RegisterEvent("UNIT_ENERGY")
    targetFrame:RegisterEvent("UNIT_FOCUS")
    targetFrame:RegisterEvent("UNIT_MAXMANA")
    targetFrame:RegisterEvent("UNIT_MAXRAGE")
    targetFrame:RegisterEvent("UNIT_MAXENERGY")
    targetFrame:RegisterEvent("UNIT_DISPLAYPOWER")
    targetFrame:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    targetFrame:RegisterEvent("UNIT_MODEL_CHANGED")
    targetFrame:RegisterEvent("UNIT_LEVEL")
    targetFrame:RegisterEvent("UNIT_NAME_UPDATE")
    targetFrame:RegisterEvent("UNIT_FACTION")
    targetFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
    targetFrame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
    targetFrame:RegisterEvent("UNIT_AURA")
    targetFrame:RegisterEvent("RAID_TARGET_UPDATE")
    targetFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    targetFrame:SetScript("OnEvent", TargetFrame_OnEvent)

    targetFrame:SetWidth(UF:GetTargetWidth())
    targetFrame:SetHeight(UF:GetTargetHeight())

    if UnitExists("target") then
        UpdateAll(targetFrame)
    else
        targetFrame:Hide()
    end
end

function UF:DisableTargetFrame()
    if targetFrame then
        targetFrame:Hide()
        targetFrame:UnregisterAllEvents()
        if targetFrame.comboFrame then
            targetFrame.comboFrame:Hide()
        end
        if targetFrame.raidIcon then
            targetFrame.raidIcon:Hide()
        end
        if targetFrame.pvpIcon then
            targetFrame.pvpIcon:Hide()
        end
    end
end
