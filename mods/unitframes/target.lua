-- FostercareTweaks: mods/unitframes/target.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Modern Unit Frames Subsystem: Target Frame

local UF = FostercareTweaks.UnitFrames
if not UF then return end

local targetFrame = nil

local function UpdateHealth(frame)
    if not frame or not frame:IsShown() or not UnitExists("target") then return end

    local cur, max = UF.GetUnitHealthValues("target")
    frame.healthBar:SetMinMaxValues(0, max)
    frame.healthBar:SetValue(cur)

    -- Bar Coloring (Class color for players, Reaction color for NPCs)
    if UnitIsPlayer("target") then
        local _, cls = UnitClass("target")
        local c = UF.ClassColors[cls]
        if c then
            frame.healthBar:SetStatusBarColor(c.r, c.g, c.b, 1)
        else
            frame.healthBar:SetStatusBarColor(0.2, 0.8, 0.2, 1)
        end
    else
        local reaction = UnitReaction("target", "player") or 4
        local c = UF.ReactionColors[reaction] or UF.ReactionColors[4]
        frame.healthBar:SetStatusBarColor(c.r, c.g, c.b, 1)
    end

    -- Name, Level, and Classification
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

    frame.healthBar.nameText:SetText("[" .. levelStr .. classTag .. "] " .. name)

    -- Health text
    if UnitIsDeadOrGhost("target") then
        frame.healthBar.healthText:SetText(UnitIsGhost("target") and "Ghost" or "Dead")
    elseif max > 0 then
        local percent = math.floor((cur / max) * 100 + 0.5)
        local curStr = FostercareTweaks.Abbreviate(cur)
        local maxStr = FostercareTweaks.Abbreviate(max)
        frame.healthBar.healthText:SetText(curStr .. " / " .. maxStr .. " (" .. percent .. "%)")
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
        portrait:SetBackdropColor(0, 0, 0, 0.5)
        portrait:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

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
        hb.nameText:SetShadowOffset(1, -1)

        hb.healthText = hb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hb.healthText:SetPoint("RIGHT", hb, "RIGHT", -4, 0)
        hb.healthText:SetJustifyH("RIGHT")
        hb.healthText:SetShadowColor(0, 0, 0, 1)
        hb.healthText:SetShadowOffset(1, -1)

        targetFrame.healthBar = hb

        -- Power Bar
        local pb = UF:CreateBar("FCTweaksTargetPowerBar", targetFrame)
        pb.powerText = pb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        pb.powerText:SetPoint("RIGHT", pb, "RIGHT", -4, 0)
        pb.powerText:SetJustifyH("RIGHT")
        pb.powerText:SetShadowColor(0, 0, 0, 1)
        pb.powerText:SetShadowOffset(1, -1)

        targetFrame.powerBar = pb

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
        targetFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        targetFrame:SetScript("OnEvent", TargetFrame_OnEvent)

        UF.targetFrame = targetFrame
    end

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
