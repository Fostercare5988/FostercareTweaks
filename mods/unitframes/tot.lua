-- FostercareTweaks: mods/unitframes/tot.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Modern Unit Frames Subsystem: Target of Target (ToT) Frame
-- Powered natively by ClassicAPI & SuperWoW

local UF = FostercareTweaks.UnitFrames
if not UF then return end

local totFrame = nil
local lastGuid = nil
local lastHealth = nil
local lastPower = nil

local function UpdateHealth(frame)
    if not frame or not frame:IsShown() or not UnitExists("targettarget") then return end

    local cur, max = UF.GetUnitHealthValues("targettarget")
    frame.healthBar:SetMinMaxValues(0, max)
    frame.healthBar:SetValue(cur)

    -- Bar Coloring (Class color for real players, Reaction color for NPCs)
    local isPlayer = UF.IsRealPlayer and UF.IsRealPlayer("targettarget")
    if isPlayer then
        local _, cls = UnitClass("targettarget")
        local classToken = cls and (FostercareTweaks.NormalizeClass and FostercareTweaks.NormalizeClass(cls) or cls)
        local c = classToken and UF.ClassColors[classToken]
        if c then
            frame.healthBar:SetStatusBarColor(c.r, c.g, c.b, 1)
        else
            frame.healthBar:SetStatusBarColor(0.2, 0.8, 0.2, 1)
        end
    else
        local reaction = UnitReaction("targettarget", "player")
        if UnitCanAttack("player", "targettarget") or (reaction and reaction <= 3) then
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

    -- Name text
    local name = UnitName("targettarget") or "ToT"
    frame.healthBar.nameText:SetText(name)

    -- Health text
    if UnitIsDeadOrGhost("targettarget") then
        frame.healthBar.healthText:SetText(UnitIsGhost("targettarget") and "Ghost" or "Dead")
    elseif max > 0 and cur < max then
        local percent = math.floor((cur / max) * 100 + 0.5)
        frame.healthBar.healthText:SetText(percent .. "%")
    else
        frame.healthBar.healthText:SetText("")
    end
end

local function UpdatePower(frame)
    if not frame or not frame:IsShown() or not UnitExists("targettarget") then return end

    local max = UnitManaMax("targettarget") or 0
    local powerType = UnitPowerType("targettarget") or 0
    local cur = UnitMana("targettarget") or 0

    if max > 0 then
        frame.powerBar:Show()
        frame.powerBar:SetMinMaxValues(0, max)
        frame.powerBar:SetValue(cur)

        local c = UF.PowerColors[powerType] or UF.PowerColors[0]
        frame.powerBar:SetStatusBarColor(c.r, c.g, c.b, 1)
    else
        frame.powerBar:Hide()
    end

    UF:LayoutBars(frame)
end

local function UpdateAll(frame)
    if not frame then return end
    if not UnitExists("target") or not UnitExists("targettarget") then
        frame:Hide()
        return
    end

    frame:Show()
    UpdateHealth(frame)
    UpdatePower(frame)
    UF:LayoutBars(frame)

    if frame.auraContainer and UF.Auras and UF.Auras.UpdateContainer then
        UF.Auras:UpdateContainer(frame.auraContainer)
    end
end

local function ToTFrame_OnClick()
    if FCTweaksUnitFrameUnlocker and FCTweaksUnitFrameUnlocker.movable then
        return
    end
    if not UnitExists("targettarget") then return end
    local button = arg1 or "LeftButton"

    if button == "LeftButton" then
        if SpellIsTargeting and SpellIsTargeting() then
            SpellTargetUnit("targettarget")
        elseif CursorHasItem and CursorHasItem() then
            DropItemOnUnit("targettarget")
        else
            TargetUnit("targettarget")
        end
    end
end

local function ToTFrame_OnEnter()
    if not UnitExists("targettarget") then return end

    if SetMouseoverUnit then
        SetMouseoverUnit("targettarget")
    end

    if SpellIsTargeting and SpellIsTargeting() then
        SetCursor("CAST_CURSOR")
    end

    GameTooltip_SetDefaultAnchor(GameTooltip, this)
    GameTooltip:SetUnit("targettarget")
    local r, g, b = GameTooltip_UnitColor("targettarget")
    if GameTooltipTextLeft1 and r and g and b then
        GameTooltipTextLeft1:SetTextColor(r, g, b)
    end
    GameTooltip:Show()
end

local function ToTFrame_OnLeave()
    if SetMouseoverUnit then
        SetMouseoverUnit()
    end
    if SpellIsTargeting and SpellIsTargeting() then
        SetCursor(nil)
    end
    GameTooltip:Hide()
end

local function ToTFrame_OnEvent()
    local ev = event
    local a1 = arg1

    if ev == "PLAYER_TARGET_CHANGED" then
        if not UnitExists("target") then
            if totTicker then totTicker:Hide() end
            if totFrame and totFrame:IsShown() then totFrame:Hide() end
            lastGuid = nil
            lastHealth = nil
            lastPower = nil
        else
            if totTicker then totTicker:Show() end
            if not UnitExists("targettarget") then
                if totFrame and totFrame:IsShown() then totFrame:Hide() end
                lastGuid = nil
                lastHealth = nil
                lastPower = nil
            else
                UpdateAll(totFrame)
            end
        end
    elseif ev == "UNIT_TARGET" then
        if a1 == "target" then
            if not UnitExists("targettarget") then
                if totFrame and totFrame:IsShown() then totFrame:Hide() end
                lastGuid = nil
                lastHealth = nil
                lastPower = nil
            else
                UpdateAll(totFrame)
            end
        end
    elseif not totFrame or not totFrame:IsShown() then
        return
    elseif ev == "UNIT_HEALTH" or ev == "UNIT_MAXHEALTH" then
        if a1 == "targettarget" then UpdateHealth(totFrame) end
    elseif ev == "UNIT_MANA" or ev == "UNIT_RAGE" or ev == "UNIT_ENERGY" or ev == "UNIT_FOCUS" or
           ev == "UNIT_MAXMANA" or ev == "UNIT_MAXRAGE" or ev == "UNIT_MAXENERGY" or ev == "UNIT_DISPLAYPOWER" then
        if a1 == "targettarget" then UpdatePower(totFrame) end
    elseif ev == "UNIT_AURA" then
        if (a1 == "targettarget" or a1 == "target") and totFrame.auraContainer and UF.Auras and UF.Auras.UpdateContainer then
            UF.Auras:UpdateContainer(totFrame.auraContainer)
        end
    elseif ev == "UNIT_LEVEL" or ev == "UNIT_NAME_UPDATE" or ev == "UNIT_FACTION" or ev == "UNIT_CLASSIFICATION_CHANGED" then
        if a1 == "targettarget" then UpdateHealth(totFrame) end
    elseif ev == "PLAYER_ENTERING_WORLD" then
        if UnitExists("target") and UnitExists("targettarget") then
            if totTicker then totTicker:Show() end
            UpdateAll(totFrame)
        else
            if totTicker then totTicker:Hide() end
            if totFrame then totFrame:Hide() end
        end
    end
end

-- Lightweight 150ms ticker for polling ToT health/power/target drift (active only while target exists)
local totTicker = CreateFrame("Frame")
totTicker:Hide()
local lastTickerCheck = 0

totTicker:SetScript("OnUpdate", function()
    local now = GetTime()
    if now - lastTickerCheck < 0.15 then return end
    lastTickerCheck = now

    if not totFrame or not totFrame.enabled or not UnitExists("target") then
        if totFrame and totFrame:IsShown() then
            totFrame:Hide()
            lastGuid = nil
            lastHealth = nil
            lastPower = nil
        end
        totTicker:Hide()
        return
    end

    if not UnitExists("targettarget") then
        if totFrame:IsShown() then
            totFrame:Hide()
            lastGuid = nil
            lastHealth = nil
            lastPower = nil
        end
        return
    end

    local guid = UnitGUID and UnitGUID("targettarget")
    local curH = UnitHealth("targettarget")
    local curP = UnitMana("targettarget")

    if not totFrame:IsShown() or guid ~= lastGuid or curH ~= lastHealth or curP ~= lastPower then
        lastGuid = guid
        lastHealth = curH
        lastPower = curP
        UpdateAll(totFrame)
    end
end)

function UF:EnableToTFrame()
    if not totFrame then
        totFrame = UF:CreateUnitFrame("targettarget", "FCTweaksToTFrame", UIParent)
        totFrame:SetWidth(120)
        totFrame:SetHeight(28)
        totFrame:SetScale(UF:GetScale())

        -- Position restoration or anchor to Target Frame
        totFrame:ClearAllPoints()
        local savedPos = FostercareTweaks_Config and FostercareTweaks_Config.unitframe_positions and FostercareTweaks_Config.unitframe_positions["targettarget"]
        if savedPos and savedPos.point and savedPos.relPoint and savedPos.x and savedPos.y then
            totFrame:SetPoint(savedPos.point, UIParent, savedPos.relPoint, savedPos.x, savedPos.y)
        elseif UF.targetFrame then
            totFrame:SetPoint("TOPLEFT", UF.targetFrame, "TOPRIGHT", 6, 0)
        else
            totFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 305, 140)
        end

        totFrame:SetBackdrop(UF.backdrop)
        totFrame:SetBackdropColor(UF.backdropColor[1], UF.backdropColor[2], UF.backdropColor[3], UF.backdropColor[4])
        totFrame:SetBackdropBorderColor(UF.backdropBorderColor[1], UF.backdropBorderColor[2], UF.backdropBorderColor[3], UF.backdropBorderColor[4])

        -- Interaction
        totFrame:RegisterForClicks("LeftButtonUp")
        totFrame:SetScript("OnClick", ToTFrame_OnClick)
        totFrame:SetScript("OnEnter", ToTFrame_OnEnter)
        totFrame:SetScript("OnLeave", ToTFrame_OnLeave)

        -- Health Bar
        local hb = UF:CreateBar("FCTweaksToTHealthBar", totFrame)
        hb.nameText = hb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hb.nameText:SetPoint("LEFT", hb, "LEFT", 3, 0)
        hb.nameText:SetJustifyH("LEFT")
        hb.nameText:SetShadowColor(0, 0, 0, 1)
        hb.nameText:SetShadowOffset(0.8, -0.8)

        hb.healthText = hb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hb.healthText:SetPoint("RIGHT", hb, "RIGHT", -3, 0)
        hb.healthText:SetJustifyH("RIGHT")
        hb.healthText:SetShadowColor(0, 0, 0, 1)
        hb.healthText:SetShadowOffset(0.8, -0.8)

        totFrame.healthBar = hb

        -- Power Bar
        local pb = UF:CreateBar("FCTweaksToTPowerBar", totFrame)
        totFrame.powerBar = pb

        -- Auras: 4 compact debuffs below ToT frame
        if UF.Auras and UF.Auras.CreateAuraContainer then
            totFrame.auraContainer = UF.Auras:CreateAuraContainer(totFrame, "targettarget", 0, 4, {
                size = 14,
                spacing = 2,
                perRow = 4,
                debuffAnchor = "BOTTOM",
            })
        end

        UF.totFrame = totFrame
    end

    -- Events
    totFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    totFrame:RegisterEvent("UNIT_TARGET")
    totFrame:RegisterEvent("UNIT_HEALTH")
    totFrame:RegisterEvent("UNIT_MAXHEALTH")
    totFrame:RegisterEvent("UNIT_MANA")
    totFrame:RegisterEvent("UNIT_RAGE")
    totFrame:RegisterEvent("UNIT_ENERGY")
    totFrame:RegisterEvent("UNIT_FOCUS")
    totFrame:RegisterEvent("UNIT_MAXMANA")
    totFrame:RegisterEvent("UNIT_DISPLAYPOWER")
    totFrame:RegisterEvent("UNIT_LEVEL")
    totFrame:RegisterEvent("UNIT_NAME_UPDATE")
    totFrame:RegisterEvent("UNIT_FACTION")
    totFrame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
    totFrame:RegisterEvent("UNIT_AURA")
    totFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    totFrame:SetScript("OnEvent", ToTFrame_OnEvent)

    totFrame.enabled = true
    if UnitExists("target") then
        if totTicker then totTicker:Show() end
        if UnitExists("targettarget") then
            UpdateAll(totFrame)
        else
            totFrame:Hide()
        end
    else
        if totTicker then totTicker:Hide() end
        totFrame:Hide()
    end
end

function UF:DisableToTFrame()
    if totTicker then totTicker:Hide() end
    if totFrame then
        totFrame.enabled = false
        totFrame:Hide()
        totFrame:UnregisterAllEvents()
    end
end
