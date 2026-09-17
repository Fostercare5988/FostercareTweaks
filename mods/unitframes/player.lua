-- FostercareTweaks: mods/unitframes/player.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Modern Unit Frames Subsystem: Player Frame

local UF = FostercareTweaks.UnitFrames
if not UF then return end

local playerFrame = nil
local playerClass = nil

local function UpdateHealth(frame)
    if not frame or not frame:IsShown() then return end

    local cur, max = UF.GetUnitHealthValues("player")
    frame.healthBar:SetMinMaxValues(0, max)
    frame.healthBar:SetValue(cur)

    -- Class color health bar
    local c = UF.ClassColors[playerClass]
    if c then
        frame.healthBar:SetStatusBarColor(c.r, c.g, c.b, 1)
    else
        frame.healthBar:SetStatusBarColor(0.2, 0.8, 0.2, 1)
    end

    -- Health text
    if UnitIsDeadOrGhost("player") then
        frame.healthBar.healthText:SetText(UnitIsGhost("player") and "Ghost" or "Dead")
    elseif max > 0 then
        local percent = math.floor((cur / max) * 100 + 0.5)
        local curStr = FostercareTweaks.Abbreviate(cur)
        local maxStr = FostercareTweaks.Abbreviate(max)
        frame.healthBar.healthText:SetText(curStr .. " / " .. maxStr .. " (" .. percent .. "%)")
    else
        frame.healthBar.healthText:SetText("")
    end

    -- Name text
    local name = UnitName("player") or "Player"
    frame.healthBar.nameText:SetText(name)
end

local function UpdatePower(frame)
    if not frame or not frame:IsShown() then return end

    local powerType = UnitPowerType("player") or 0
    local cur = UnitMana("player") or 0
    local max = UnitManaMax("player") or 0

    frame.powerBar:SetMinMaxValues(0, max)
    frame.powerBar:SetValue(cur)

    local c = UF.PowerColors[powerType] or UF.PowerColors[0]
    frame.powerBar:SetStatusBarColor(c.r, c.g, c.b, 1)

    if max > 0 then
        if powerType == 1 or powerType == 3 then
            frame.powerBar.powerText:SetText(tostring(cur))
        else
            local curStr = FostercareTweaks.Abbreviate(cur)
            local maxStr = FostercareTweaks.Abbreviate(max)
            frame.powerBar.powerText:SetText(curStr .. " / " .. maxStr)
        end
    else
        frame.powerBar.powerText:SetText("")
    end
end

local function UpdatePortrait(frame)
    if not frame or not frame:IsShown() or not frame.portrait then return end
    SetPortraitTexture(frame.portrait.tex, "player")
    frame.portrait.tex:SetTexCoord(0.14, 0.86, 0.14, 0.86)
end

local function UpdateStatusIcons(frame)
    if not frame or not frame:IsShown() then return end

    -- Combat
    if UnitAffectingCombat("player") then
        frame.combatIcon:Show()
    else
        frame.combatIcon:Hide()
    end

    -- Resting
    if IsResting() then
        frame.restIcon:Show()
    else
        frame.restIcon:Hide()
    end

    -- Party Leader
    if UnitIsPartyLeader("player") then
        frame.leaderIcon:Show()
    else
        frame.leaderIcon:Hide()
    end
end

local function UpdateAll(frame)
    if not frame then return end
    if not playerClass then
        local _, cls = UnitClass("player")
        playerClass = cls
    end

    UpdatePortrait(frame)
    UpdateHealth(frame)
    UpdatePower(frame)
    UpdateStatusIcons(frame)
    UF:LayoutBars(frame)
end

local function PlayerFrame_OnEvent()
    local ev = event
    local a1 = arg1

    if ev == "UNIT_HEALTH" or ev == "UNIT_MAXHEALTH" then
        if a1 == "player" then UpdateHealth(playerFrame) end
    elseif ev == "UNIT_MANA" or ev == "UNIT_RAGE" or ev == "UNIT_ENERGY" or ev == "UNIT_FOCUS" or
           ev == "UNIT_MAXMANA" or ev == "UNIT_MAXRAGE" or ev == "UNIT_MAXENERGY" or ev == "UNIT_DISPLAYPOWER" then
        if a1 == "player" then UpdatePower(playerFrame) end
    elseif ev == "PLAYER_REGEN_DISABLED" or ev == "PLAYER_REGEN_ENABLED" or ev == "PLAYER_UPDATE_RESTING" or ev == "PARTY_LEADER_CHANGED" then
        UpdateStatusIcons(playerFrame)
    elseif ev == "UNIT_PORTRAIT_UPDATE" or ev == "UNIT_MODEL_CHANGED" then
        if a1 == "player" then UpdatePortrait(playerFrame) end
    elseif ev == "PLAYER_ENTERING_WORLD" then
        UpdateAll(playerFrame)
    end
end

function UF:EnablePlayerFrame()
    if not playerFrame then
        playerFrame = UF:CreateUnitFrame("player", "FCTweaksPlayerFrame", UIParent)
        playerFrame:SetWidth(240)
        playerFrame:SetHeight(44)
        playerFrame:SetScale(UF:GetScale())

        -- Position restoration or default
        playerFrame:ClearAllPoints()
        local savedPos = FostercareTweaks_Config and FostercareTweaks_Config.unitframe_positions and FostercareTweaks_Config.unitframe_positions["player"]
        if savedPos and savedPos.point and savedPos.relPoint and savedPos.x and savedPos.y then
            playerFrame:SetPoint(savedPos.point, UIParent, savedPos.relPoint, savedPos.x, savedPos.y)
        else
            playerFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", -175, 140)
        end

        -- Portrait (Left)
        local portrait = CreateFrame("Frame", nil, playerFrame)
        portrait:SetBackdrop(UF.backdrop)
        portrait:SetBackdropColor(0, 0, 0, 0.5)
        portrait:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

        portrait.tex = portrait:CreateTexture(nil, "ARTWORK")
        portrait.tex:SetPoint("TOPLEFT", portrait, "TOPLEFT", 1, -1)
        portrait.tex:SetPoint("BOTTOMRIGHT", portrait, "BOTTOMRIGHT", -1, 1)

        playerFrame.portrait = portrait
        playerFrame.portraitSide = "left"

        -- Health Bar
        local hb = UF:CreateBar("FCTweaksPlayerHealthBar", playerFrame)
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

        playerFrame.healthBar = hb

        -- Power Bar
        local pb = UF:CreateBar("FCTweaksPlayerPowerBar", playerFrame)
        pb.powerText = pb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        pb.powerText:SetPoint("RIGHT", pb, "RIGHT", -4, 0)
        pb.powerText:SetJustifyH("RIGHT")
        pb.powerText:SetShadowColor(0, 0, 0, 1)
        pb.powerText:SetShadowOffset(1, -1)

        playerFrame.powerBar = pb

        -- Status Indicators
        playerFrame.combatIcon = playerFrame:CreateTexture(nil, "OVERLAY")
        playerFrame.combatIcon:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        playerFrame.combatIcon:SetTexCoord(0.5, 1.0, 0.0, 0.48)
        playerFrame.combatIcon:SetWidth(16)
        playerFrame.combatIcon:SetHeight(16)
        playerFrame.combatIcon:SetPoint("CENTER", portrait, "BOTTOMRIGHT", -2, 2)
        playerFrame.combatIcon:Hide()

        playerFrame.restIcon = playerFrame:CreateTexture(nil, "OVERLAY")
        playerFrame.restIcon:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        playerFrame.restIcon:SetTexCoord(0.0, 0.5, 0.0, 0.42)
        playerFrame.restIcon:SetWidth(16)
        playerFrame.restIcon:SetHeight(16)
        playerFrame.restIcon:SetPoint("TOPLEFT", portrait, "TOPLEFT", -2, 2)
        playerFrame.restIcon:Hide()

        playerFrame.leaderIcon = playerFrame:CreateTexture(nil, "OVERLAY")
        playerFrame.leaderIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
        playerFrame.leaderIcon:SetWidth(14)
        playerFrame.leaderIcon:SetHeight(14)
        playerFrame.leaderIcon:SetPoint("TOPLEFT", portrait, "TOPLEFT", -2, 2)
        playerFrame.leaderIcon:Hide()

        -- Event Registration
        playerFrame:RegisterEvent("UNIT_HEALTH")
        playerFrame:RegisterEvent("UNIT_MAXHEALTH")
        playerFrame:RegisterEvent("UNIT_MANA")
        playerFrame:RegisterEvent("UNIT_RAGE")
        playerFrame:RegisterEvent("UNIT_ENERGY")
        playerFrame:RegisterEvent("UNIT_FOCUS")
        playerFrame:RegisterEvent("UNIT_MAXMANA")
        playerFrame:RegisterEvent("UNIT_MAXRAGE")
        playerFrame:RegisterEvent("UNIT_MAXENERGY")
        playerFrame:RegisterEvent("UNIT_DISPLAYPOWER")
        playerFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        playerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        playerFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
        playerFrame:RegisterEvent("PARTY_LEADER_CHANGED")
        playerFrame:RegisterEvent("UNIT_PORTRAIT_UPDATE")
        playerFrame:RegisterEvent("UNIT_MODEL_CHANGED")
        playerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        playerFrame:SetScript("OnEvent", PlayerFrame_OnEvent)

        UF.playerFrame = playerFrame
    end

    playerFrame:Show()
    UpdateAll(playerFrame)
end

function UF:DisablePlayerFrame()
    if playerFrame then
        playerFrame:Hide()
        playerFrame:UnregisterAllEvents()
    end
end
