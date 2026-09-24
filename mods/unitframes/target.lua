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

    -- Level, Classification, and Name
    local name = UnitName("target") or "Target"
    local level = UnitLevel("target") or 0
    local levelStr = (level > 0) and tostring(level) or "??"
    local classification = UnitClassification("target") or "normal"
    local classTag = ""
    if classification == "worldboss" then
        classTag = "b"
    elseif classification == "rareelite" then
        classTag = "r+"
    elseif classification == "elite" then
        classTag = "+"
    elseif classification == "rare" then
        classTag = "r"
    end

    local typeText = ""
    if isPlayer then
        local _, cls = UnitClass("target")
        typeText = cls or ""
    else
        typeText = UnitCreatureType("target") or ""
    end

    local subInfo = "[" .. levelStr .. classTag .. "]"
    if typeText ~= "" then
        subInfo = subInfo .. " " .. typeText
    end

    if frame.powerBar and frame.powerBar:IsShown() and frame.powerBar.leftText then
        frame.powerBar.leftText:SetText(subInfo)
        frame.healthBar.nameText:SetText(name)
    else
        frame.healthBar.nameText:SetText(subInfo .. " " .. name)
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

local function UpdateAll(frame)
    if not frame then return end
    if not UnitExists("target") then
        frame:Hide()
        return
    end

    frame:Show()
    UpdatePortrait(frame)
    UpdateHealth(frame)
    UpdatePower(frame)
    UF:LayoutBars(frame)
    if frame.auraContainer and UF.Auras and UF.Auras.UpdateContainer then
        UF.Auras:UpdateContainer(frame.auraContainer)
    end
end

local function TargetFrame_OnEvent()
    local ev = event
    local a1 = arg1

    if ev == "PLAYER_TARGET_CHANGED" then
        UpdateAll(targetFrame)
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
        if a1 == "target" and targetFrame.auraContainer and UF.Auras and UF.Auras.UpdateContainer then
            UF.Auras:UpdateContainer(targetFrame.auraContainer)
        end
    elseif ev == "UNIT_LEVEL" or ev == "UNIT_NAME_UPDATE" or ev == "UNIT_FACTION" or ev == "UNIT_CLASSIFICATION_CHANGED" then
        if a1 == "target" then UpdateHealth(targetFrame) end
    elseif ev == "PLAYER_ENTERING_WORLD" then
        UpdateAll(targetFrame)
    end
end

function UF:EnableTargetFrame()
    if not targetFrame then
        targetFrame = UF:CreateUnitFrame("target", "FCTweaksTargetFrame", UIParent)
        targetFrame:SetWidth(240)
        targetFrame:SetHeight(44)
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

        -- Health Bar
        local hb = UF:CreateBar("FCTweaksTargetHealthBar", targetFrame)
        hb.nameText = hb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hb.nameText:SetPoint("LEFT", hb, "LEFT", 4, 0)
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

        -- Aura Container (16 Buffs above, 16 Debuffs below)
        if UF.Auras and UF.Auras.CreateAuraContainer then
            targetFrame.auraContainer = UF.Auras:CreateAuraContainer(targetFrame, "target", 16, 16, {
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
    targetFrame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
    targetFrame:RegisterEvent("UNIT_AURA")
    targetFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    targetFrame:SetScript("OnEvent", TargetFrame_OnEvent)

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
    end
end
