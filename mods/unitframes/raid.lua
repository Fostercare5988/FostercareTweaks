-- FostercareTweaks: mods/unitframes/raid.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Modern Unit Frames Subsystem: Unified Group Frames (Party & 40-Player Raid)
-- Primary Donor: LunaUnitFrames-TurtleWoW

local UF = FostercareTweaks.UnitFrames
if not UF then return end

local raidFrame = nil
local groups = {}
local unitToButton = {}
local testMode = false
local wipe = table.wipe or wipe

-- Debuff dispel color mapping (Curse, Disease, Magic, Poison)
local DISPEL_COLORS = {
    ["Magic"]   = { r = 0.20, g = 0.60, b = 1.00 },
    ["Curse"]   = { r = 0.60, g = 0.00, b = 1.00 },
    ["Disease"] = { r = 0.80, g = 0.40, b = 0.10 },
    ["Poison"]  = { r = 0.00, g = 0.80, b = 0.10 },
}

--------------------------------------------------------------------------------
-- 1. Dimension Settings Management
--------------------------------------------------------------------------------

function UF:GetGroupDimensions()
    local cfg = FostercareTweaks_Config and FostercareTweaks_Config.groupframe_dimensions
    local enabled = true
    if cfg and cfg.enabled ~= nil then
        enabled = (cfg.enabled == true or cfg.enabled == 1)
    end
    local w = (cfg and tonumber(cfg.width)) or 64
    local h = (cfg and tonumber(cfg.height)) or 34
    local s = (cfg and tonumber(cfg.scale)) or 1.0
    local spX = (cfg and tonumber(cfg.spacingX)) or 4
    local spY = (cfg and tonumber(cfg.spacingY)) or 3

    if w < 40 then w = 40 end
    if w > 120 then w = 120 end
    if h < 20 then h = 20 end
    if h > 60 then h = 60 end
    if s < 0.5 then s = 0.5 end
    if s > 2.0 then s = 2.0 end
    if spX < 0 then spX = 0 end
    if spX > 20 then spX = 20 end
    if spY < 0 then spY = 0 end
    if spY > 20 then spY = 20 end

    return {
        enabled = enabled,
        width = w,
        height = h,
        scale = s,
        spacingX = spX,
        spacingY = spY,
    }
end

--------------------------------------------------------------------------------
-- 2. Unit Button Update Routines
--------------------------------------------------------------------------------

local function UpdateButtonHealth(btn)
    local unit = btn.unit
    if not unit or not btn:IsShown() then return end

    local cur, max = UF.GetUnitHealthValues(unit)
    btn.healthBar:SetMinMaxValues(0, max)
    btn.healthBar:SetValue(cur)

    -- Class color (Exact Luna colors)
    local _, cls = UnitClass(unit)
    local classToken = cls and (FostercareTweaks.NormalizeClass and FostercareTweaks.NormalizeClass(cls) or cls)
    local c = classToken and UF.ClassColors[classToken]
    if c then
        btn.healthBar:SetStatusBarColor(c.r, c.g, c.b, 1)
    else
        btn.healthBar:SetStatusBarColor(0.2, 0.9, 0.2, 1)
    end

    -- Name text (Centered, up to 10 chars with ellipsis if longer)
    local name = UnitName(unit) or ("Group" .. btn.index)
    if string.len(name) > 11 then
        name = string.sub(name, 1, 10) .. ".."
    end
    btn.nameText:SetText(name)

    -- Health / Status text (Configurable: Deficit, Percentage, Current)
    local isOffline = not UnitIsConnected(unit)
    local isDead = UnitIsDeadOrGhost(unit)
    local isGhost = UnitIsGhost(unit)
    local fmt = (UF.GetRaidHealthFormat and UF:GetRaidHealthFormat()) or "deficit"

    if isOffline then
        btn.healthText:SetText("|cff888888Off|r")
    elseif isDead then
        btn.healthText:SetText(isGhost and "|cffaaaaaaGhost|r" or "|cffff2020Dead|r")
    elseif fmt == "percent" then
        local pct = (max > 0) and math.floor((cur / max) * 100 + 0.5) or 0
        btn.healthText:SetText(pct .. "%")
    elseif fmt == "current" then
        btn.healthText:SetText(FostercareTweaks.Abbreviate(cur))
    else -- "deficit" (Luna standard healer deficit)
        if max > 0 and cur < max then
            local deficit = max - cur
            btn.healthText:SetText("-" .. FostercareTweaks.Abbreviate(deficit))
        else
            btn.healthText:SetText("")
        end
    end
end

local function UpdateButtonPower(btn)
    local unit = btn.unit
    if not unit or not btn:IsShown() then return end

    local max = UnitManaMax(unit) or 0
    local cur = UnitMana(unit) or 0
    local ptype = UnitPowerType(unit) or 0

    btn.powerBar:SetMinMaxValues(0, max > 0 and max or 1)
    btn.powerBar:SetValue(cur)

    local pc = UF.PowerColors[ptype] or UF.PowerColors[0]
    btn.powerBar:SetStatusBarColor(pc.r, pc.g, pc.b, 1)
end

local function UpdateButtonAuras(btn)
    local unit = btn.unit
    if not unit or not btn:IsShown() then return end

    -- Keep main button border solid black
    btn:SetBackdropBorderColor(0, 0, 0, 1)

    -- HoT / Buff Corner Status Indicator (Top-Left square)
    if btn.hotSquare then
        local showHoT = (UF.IsRaidShowHoT and UF:IsRaidShowHoT())
        local hotTex = nil
        if showHoT then
            local HOT_NAMES = {
                ["Renew"] = true,
                ["Rejuvenation"] = true,
                ["Regrowth"] = true,
                ["Power Word: Shield"] = true,
                ["Flash Heal"] = true,
                ["Healing Way"] = true,
                ["Blessing of Protection"] = true,
            }
            for b = 1, 16 do
                local name, icon = C_UnitAuras.UnitBuff(unit, b, "HELPFUL")
                if not name then break end
                if (name and HOT_NAMES[name]) or (icon and (string.find(icon, "Spell_Holy_Renew") or string.find(icon, "Spell_Nature_Rejuvenation") or string.find(icon, "Spell_Nature_ResistNature") or string.find(icon, "Spell_Holy_PowerWordShield"))) then
                    hotTex = icon
                    break
                elseif b == 1 and not hotTex then
                    hotTex = icon
                end
            end
        end
        if hotTex then
            btn.hotSquare.icon:SetTexture(hotTex)
            btn.hotSquare:Show()
        else
            btn.hotSquare:Hide()
        end
    end

    -- Compact Debuff Indicator Icon Badges (Up to 3, bottom-right)
    local showDebuffs = (UF.IsRaidShowDebuffs and UF:IsRaidShowDebuffs())
    for b = 1, 3 do
        local badge = btn.debuffBadges[b]
        if not showDebuffs then
            badge:Hide()
        else
            local name, icon, count, dispelType = C_UnitAuras.UnitDebuff(unit, b, "HARMFUL")

            if icon then
                badge.icon:SetTexture(icon)
                local dc = (dispelType and UF.DispelColors and UF.DispelColors[dispelType]) or { r = 0.8, g = 0.2, b = 0.2 }
                badge:SetBackdropBorderColor(dc.r, dc.g, dc.b, 1)
                badge:Show()
            else
                badge:Hide()
            end
        end
    end
end

local function UpdateButtonIndicators(btn)
    local unit = btn.unit
    if not unit or not btn:IsShown() then return end

    -- Aggro Indicator (Red corner block on bottom-left)
    if btn.aggroSquare then
        local showAggro = (UF.IsRaidShowAggro and UF:IsRaidShowAggro())
        local hasAggro = false
        if showAggro then
            if Banzai and Banzai.GetUnitAggroByUnitId then
                hasAggro = Banzai:GetUnitAggroByUnitId(unit)
            elseif UnitThreatSituation then
                hasAggro = (UnitThreatSituation(unit) or 0) >= 2
            elseif UnitExists("target") and UnitCanAttack("player", "target") and UnitIsUnit("targettarget", unit) then
                hasAggro = true
            end
        end
        if hasAggro then
            btn.aggroSquare:Show()
        else
            btn.aggroSquare:Hide()
        end
    end

    -- Raid Target Icon
    local targetIndex = GetRaidTargetIndex(unit)
    if targetIndex and targetIndex > 0 and targetIndex <= 8 then
        SetRaidTargetIconTexture(btn.raidIcon, targetIndex)
        btn.raidIcon:Show()
    else
        btn.raidIcon:Hide()
    end

    -- Leader / Assistant Icon
    local rank = btn.rank or 0
    if rank == 2 then
        btn.leaderIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
        btn.leaderIcon:Show()
    elseif rank == 1 then
        btn.leaderIcon:SetTexture("Interface\\GroupFrame\\UI-Group-AssistantIcon")
        btn.leaderIcon:Show()
    else
        btn.leaderIcon:Hide()
    end
end

local function UpdateButtonRange(btn)
    local unit = btn.unit
    if not unit or not btn:IsShown() then return end

    local inRange
    if unit == "player" then
        inRange = true
    elseif UnitInRange then
        local inR, checked = UnitInRange(unit)
        if checked then
            inRange = inR
        else
            inRange = (inR == true or inR == 1)
        end
    elseif UnitDistanceSquared then
        local distSq = UnitDistanceSquared(unit)
        if distSq and distSq > 0 then
            inRange = (distSq <= 1600)
        else
            inRange = true
        end
    else
        inRange = true
    end

    if not UnitIsConnected(unit) then
        btn:SetAlpha(0.4)
    elseif inRange then
        btn:SetAlpha(1.0)
    else
        btn:SetAlpha(0.45)
    end
end

local function UpdateButtonAll(btn)
    UpdateButtonHealth(btn)
    UpdateButtonPower(btn)
    UpdateButtonAuras(btn)
    UpdateButtonIndicators(btn)
    UpdateButtonRange(btn)
end

--------------------------------------------------------------------------------
-- 3. Button Factory & Mouse Interaction
--------------------------------------------------------------------------------

local function RaidButton_OnClick()
    if FCTweaksUnitFrameUnlocker and FCTweaksUnitFrameUnlocker.movable then
        return
    end
    local unit = this.unit
    if not unit then return end
    local button = arg1 or "LeftButton"

    if button == "LeftButton" then
        if SpellIsTargeting and SpellIsTargeting() then
            SpellTargetUnit(unit)
        elseif CursorHasItem and CursorHasItem() then
            DropItemOnUnit(unit)
        else
            TargetUnit(unit)
        end
    elseif button == "RightButton" then
        if UnitIsUnit(unit, "player") then
            ToggleDropDownMenu(1, nil, PlayerFrameDropDown, "cursor")
        else
            HideDropDownMenu(1)
            local name = UnitName(unit)
            local id = string.match(unit, "(%d+)")
            local menuFrame = FriendsDropDown
            if menuFrame then
                menuFrame.displayMode = "MENU"
                menuFrame.initialize = function()
                    local openMenu = (type(UIDROPDOWNMENU_OPEN_MENU) == "string" and getglobal(UIDROPDOWNMENU_OPEN_MENU)) or UIDROPDOWNMENU_OPEN_MENU or menuFrame
                    UnitPopup_ShowMenu(openMenu, "PARTY", unit, name, id)
                end
                ToggleDropDownMenu(1, nil, menuFrame, "cursor")
            end
        end
    end
end

local function RaidButton_OnEnter()
    local unit = this.unit
    if not unit then return end

    if SetMouseoverUnit then
        SetMouseoverUnit(unit)
    end

    if SpellIsTargeting and SpellIsTargeting() then
        SetCursor("CAST_CURSOR")
    end

    GameTooltip_SetDefaultAnchor(GameTooltip, this)
    GameTooltip:SetUnit(unit)
    local r, g, b = GameTooltip_UnitColor(unit)
    if GameTooltipTextLeft1 and r and g and b then
        GameTooltipTextLeft1:SetTextColor(r, g, b)
    end
    GameTooltip:Show()
end

local function RaidButton_OnLeave()
    if SetMouseoverUnit then
        SetMouseoverUnit()
    end
    if SpellIsTargeting and SpellIsTargeting() then
        SetCursor(nil)
    end
    GameTooltip:Hide()
end

local function CreateRaidButton(groupFrame, groupNum, memberIdx, btnW, btnH)
    local btnName = "FCTweaksRaidUnitG" .. groupNum .. "M" .. memberIdx
    local btn = CreateFrame("Button", btnName, groupFrame)
    btn:SetWidth(btnW)
    btn:SetHeight(btnH)
    btn:SetFrameStrata("LOW")
    btn:SetClampedToScreen(true)

    btn:SetBackdrop(UF.backdrop)
    btn:SetBackdropColor(0, 0, 0, 0.90)
    btn:SetBackdropBorderColor(0, 0, 0, 1.00)

    -- Interaction
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", RaidButton_OnClick)
    btn:SetScript("OnEnter", RaidButton_OnEnter)
    btn:SetScript("OnLeave", RaidButton_OnLeave)

    -- Draggable support when Ctrl+Shift held
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function()
        if raidFrame and FCTweaksUnitFrameUnlocker and FCTweaksUnitFrameUnlocker.movable then
            raidFrame:StartMoving()
        end
    end)
    btn:SetScript("OnDragStop", function()
        if raidFrame then
            raidFrame:StopMovingOrSizing()
            if FostercareTweaks_Config then
                if not FostercareTweaks_Config.unitframe_positions then
                    FostercareTweaks_Config.unitframe_positions = {}
                end
                local point, _, relPoint, x, y = raidFrame:GetPoint()
                FostercareTweaks_Config.unitframe_positions["raid"] = {
                    point = point or "CENTER",
                    relPoint = relPoint or "CENTER",
                    x = x or 0,
                    y = y or 0
                }
            end
        end
    end)

    local powerH = math.max(3, math.floor(btnH * 0.12))
    local healthH = btnH - powerH - 3

    -- Health Bar (Stacked top)
    local hb = UF:CreateBar(btnName .. "HealthBar", btn)
    hb:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    hb:SetWidth(btnW - 2)
    hb:SetHeight(healthH)
    btn.healthBar = hb

    -- Power Bar (Stacked bottom)
    local pb = UF:CreateBar(btnName .. "PowerBar", btn)
    pb:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1 - healthH - 1)
    pb:SetWidth(btnW - 2)
    pb:SetHeight(powerH)
    btn.powerBar = pb

    -- Name text (Centered, upper half)
    btn.nameText = hb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.nameText:SetPoint("CENTER", hb, "CENTER", 0, math.max(3, math.floor(healthH * 0.22)))
    btn.nameText:SetWidth(btnW - 6)
    btn.nameText:SetJustifyH("CENTER")
    btn.nameText:SetShadowColor(0, 0, 0, 1)
    btn.nameText:SetShadowOffset(0.8, -0.8)

    -- Health / Status text (Centered, lower half)
    btn.healthText = hb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.healthText:SetPoint("CENTER", hb, "CENTER", 0, -math.max(3, math.floor(healthH * 0.22)))
    btn.healthText:SetWidth(btnW - 6)
    btn.healthText:SetJustifyH("CENTER")
    btn.healthText:SetShadowColor(0, 0, 0, 1)
    btn.healthText:SetShadowOffset(0.8, -0.8)

    -- Corner Aggro Indicator (Red square on bottom-left)
    btn.aggroSquare = hb:CreateTexture(nil, "OVERLAY")
    btn.aggroSquare:SetWidth(8)
    btn.aggroSquare:SetHeight(8)
    btn.aggroSquare:SetPoint("BOTTOMLEFT", hb, "BOTTOMLEFT", 1, 1)
    btn.aggroSquare:SetTexture(1, 0, 0, 1)
    btn.aggroSquare:Hide()

    -- Corner HoT / Buff Status Indicator (Top-Left square)
    local hot = CreateFrame("Frame", nil, hb)
    hot:SetWidth(10)
    hot:SetHeight(10)
    hot:SetPoint("TOPLEFT", hb, "TOPLEFT", 1, -1)
    hot:SetFrameLevel(hb:GetFrameLevel() + 5)
    hot:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    hot:SetBackdropColor(0, 0, 0, 1)
    hot:SetBackdropBorderColor(0, 0, 0, 1)
    hot.icon = hot:CreateTexture(nil, "ARTWORK")
    hot.icon:SetPoint("TOPLEFT", hot, "TOPLEFT", 1, -1)
    hot.icon:SetPoint("BOTTOMRIGHT", hot, "BOTTOMRIGHT", -1, 1)
    hot.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    hot:Hide()
    btn.hotSquare = hot

    -- Raid Target Icon
    btn.raidIcon = hb:CreateTexture(nil, "OVERLAY")
    btn.raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    btn.raidIcon:SetWidth(14)
    btn.raidIcon:SetHeight(14)
    btn.raidIcon:SetPoint("CENTER", hb, "CENTER", 0, 0)
    btn.raidIcon:Hide()

    -- Leader / Assistant Icon
    btn.leaderIcon = hb:CreateTexture(nil, "OVERLAY")
    btn.leaderIcon:SetWidth(10)
    btn.leaderIcon:SetHeight(10)
    btn.leaderIcon:SetPoint("TOPRIGHT", hb, "TOPRIGHT", -1, -1)
    btn.leaderIcon:Hide()

    -- Compact Debuff Indicator Icon Badges (11x11px, bottom-right)
    btn.debuffBadges = {}
    for b = 1, 3 do
        local badge = CreateFrame("Frame", btnName .. "Debuff" .. b, btn)
        badge:SetWidth(11)
        badge:SetHeight(11)
        badge:SetFrameStrata("LOW")
        badge:SetBackdrop(UF.backdrop)
        badge:SetBackdropColor(0, 0, 0, 0.9)
        badge:SetBackdropBorderColor(0, 0, 0, 1)

        badge.icon = badge:CreateTexture(nil, "ARTWORK")
        badge.icon:SetPoint("TOPLEFT", badge, "TOPLEFT", 1, -1)
        badge.icon:SetPoint("BOTTOMRIGHT", badge, "BOTTOMRIGHT", -1, 1)
        badge.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        badge:SetPoint("BOTTOMRIGHT", hb, "BOTTOMRIGHT", -1 - (b - 1) * 12, 1)
        badge:Hide()
        btn.debuffBadges[b] = badge
    end

    btn.groupNum = groupNum
    btn.memberIdx = memberIdx
    btn:Hide()

    return btn
end

--------------------------------------------------------------------------------
-- 4. Group Grid Construction & Subgroup Layout
--------------------------------------------------------------------------------

local function ConstructRaidGrid()
    if raidFrame then return end

    local dims = UF:GetGroupDimensions()
    local btnW = dims.width
    local btnH = dims.height
    local btnSpacingY = dims.spacingY
    local colSpacingX = dims.spacingX

    raidFrame = CreateFrame("Frame", "FCTweaksRaidFrame", UIParent)
    raidFrame:SetWidth(8 * (btnW + colSpacingX) - colSpacingX)
    raidFrame:SetHeight(5 * (btnH + btnSpacingY) - btnSpacingY + 16)
    raidFrame:SetFrameStrata("LOW")
    raidFrame:SetClampedToScreen(true)
    raidFrame:SetMovable(true)
    raidFrame:EnableMouse(false)
    raidFrame:SetScale(dims.scale)

    -- Position restoration or default HUD placement
    raidFrame:ClearAllPoints()
    local savedPos = FostercareTweaks_Config and FostercareTweaks_Config.unitframe_positions and FostercareTweaks_Config.unitframe_positions["raid"]
    if savedPos and savedPos.point and savedPos.relPoint and savedPos.x and savedPos.y then
        raidFrame:SetPoint(savedPos.point, UIParent, savedPos.relPoint, savedPos.x, savedPos.y)
    else
        raidFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -180)
    end

    for g = 1, 8 do
        local grp = CreateFrame("Frame", "FCTweaksRaidGroup" .. g, raidFrame)
        grp:SetWidth(btnW)
        grp:SetHeight(btnH * 5 + btnSpacingY * 4 + 16)
        grp:SetPoint("TOPLEFT", raidFrame, "TOPLEFT", (g - 1) * (btnW + colSpacingX), 0)

        -- Group Title (Party or G1 - G8)
        grp.title = grp:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        grp.title:SetPoint("TOP", grp, "TOP", 0, 0)
        grp.title:SetText("G" .. g)
        grp.title:SetTextColor(0.8, 0.8, 0.8, 0.9)
        grp.title:Hide()

        grp.buttons = {}
        for m = 1, 5 do
            local btn = CreateRaidButton(grp, g, m, btnW, btnH)
            btn:SetPoint("TOPLEFT", grp, "TOPLEFT", 0, -16 - ((m - 1) * (btnH + btnSpacingY)))
            grp.buttons[m] = btn
        end

        groups[g] = grp
    end

    UF.raidFrame = raidFrame
end

--------------------------------------------------------------------------------
-- 5. Live Dimension Recomputation (Width, Height, Scale, Spacing, Enabled)
--------------------------------------------------------------------------------

function UF:ApplyGroupDimensions(width, height, scale, spacingX, spacingY, enabled)
    ConstructRaidGrid()

    local current = UF:GetGroupDimensions()
    width = tonumber(width) or current.width
    height = tonumber(height) or current.height
    scale = tonumber(scale) or current.scale
    spacingX = (spacingX ~= nil and tonumber(spacingX)) or current.spacingX
    spacingY = (spacingY ~= nil and tonumber(spacingY)) or current.spacingY
    if enabled == nil then
        enabled = current.enabled
    else
        enabled = (enabled == true or enabled == 1)
    end

    if width < 40 then width = 40 end
    if width > 120 then width = 120 end
    if height < 20 then height = 20 end
    if height > 60 then height = 60 end
    if scale < 0.5 then scale = 0.5 end
    if scale > 2.0 then scale = 2.0 end
    if spacingX < 0 then spacingX = 0 end
    if spacingX > 20 then spacingX = 20 end
    if spacingY < 0 then spacingY = 0 end
    if spacingY > 20 then spacingY = 20 end

    if FostercareTweaks_Config then
        if not FostercareTweaks_Config.groupframe_dimensions then
            FostercareTweaks_Config.groupframe_dimensions = {}
        end
        local gfd = FostercareTweaks_Config.groupframe_dimensions
        gfd.enabled = enabled
        gfd.width = width
        gfd.height = height
        gfd.scale = scale
        gfd.spacingX = spacingX
        gfd.spacingY = spacingY
    end

    if not enabled then
        if raidFrame then raidFrame:Hide() end
        return
    end

    local btnSpacingY = spacingY
    local colSpacingX = spacingX
    raidFrame:SetWidth(8 * (width + colSpacingX) - colSpacingX)
    raidFrame:SetHeight(5 * (height + btnSpacingY) - btnSpacingY + 16)
    raidFrame:SetScale(scale)
    local powerH = math.max(3, math.floor(height * 0.12))
    local healthH = height - powerH - 3

    for g = 1, 8 do
        local grp = groups[g]
        if grp then
            grp:SetWidth(width)
            grp:SetHeight(height * 5 + btnSpacingY * 4 + 16)
            grp:ClearAllPoints()
            grp:SetPoint("TOPLEFT", raidFrame, "TOPLEFT", (g - 1) * (width + colSpacingX), 0)

            for m = 1, 5 do
                local btn = grp.buttons[m]
                if btn then
                    btn:SetWidth(width)
                    btn:SetHeight(height)
                    btn:ClearAllPoints()
                    btn:SetPoint("TOPLEFT", grp, "TOPLEFT", 0, -16 - ((m - 1) * (height + btnSpacingY)))

                    -- Health Bar
                    btn.healthBar:ClearAllPoints()
                    btn.healthBar:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
                    btn.healthBar:SetWidth(width - 2)
                    btn.healthBar:SetHeight(healthH)

                    -- Power Bar
                    btn.powerBar:ClearAllPoints()
                    btn.powerBar:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1 - healthH - 1)
                    btn.powerBar:SetWidth(width - 2)
                    btn.powerBar:SetHeight(powerH)

                    -- Name and Health text positions (Centered)
                    btn.nameText:SetWidth(width - 6)
                    btn.nameText:ClearAllPoints()
                    btn.nameText:SetPoint("CENTER", btn.healthBar, "CENTER", 0, math.max(3, math.floor(healthH * 0.22)))
                    btn.healthText:SetWidth(width - 6)
                    btn.healthText:ClearAllPoints()
                    btn.healthText:SetPoint("CENTER", btn.healthBar, "CENTER", 0, -math.max(3, math.floor(healthH * 0.22)))

                    -- Debuff Badges (Bottom-Right)
                    for b = 1, 3 do
                        local badge = btn.debuffBadges[b]
                        if badge then
                            badge:ClearAllPoints()
                            badge:SetPoint("BOTTOMRIGHT", btn.healthBar, "BOTTOMRIGHT", -1 - (b - 1) * 12, 1)
                        end
                    end

                    if btn.healthBar.Refresh then btn.healthBar:Refresh() end
                    if btn.powerBar.Refresh then btn.powerBar:Refresh() end
                end
            end
        end
    end

    if testMode then
        raidFrame:SetWidth(8 * (width + colSpacingX) - colSpacingX)
        raidFrame:SetHeight(5 * (height + btnSpacingY) - btnSpacingY + 16)
        raidFrame:Show()
    else
        UF:UpdateGroupRoster()
    end
end

--------------------------------------------------------------------------------
-- 6. Roster Update & Unified Group Dispatcher (Party + Raid)
--------------------------------------------------------------------------------

function UF:UpdateGroupRoster()
    if not raidFrame then return end
    if testMode then return end

    if wipe then wipe(unitToButton) end
    local groupCounters = { 0, 0, 0, 0, 0, 0, 0, 0 }

    local numRaid = GetNumRaidMembers() or 0
    local numParty = GetNumPartyMembers() or 0

    local isRaid = numRaid > 0
    local isParty = not isRaid and numParty > 0

    local dims = UF:GetGroupDimensions()
    if not dims.enabled then
        raidFrame:Hide()
        return
    end

    local btnW = dims.width
    local btnH = dims.height
    local btnSpacingY = dims.spacingY
    local colSpacingX = dims.spacingX

    if isRaid then
        for g = 1, 8 do
            groups[g].title:SetText("G" .. g)
        end

        for i = 1, numRaid do
            local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
            subgroup = subgroup or 1
            if subgroup >= 1 and subgroup <= 8 then
                local slot = groupCounters[subgroup] + 1
                if slot <= 5 then
                    groupCounters[subgroup] = slot
                    local btn = groups[subgroup].buttons[slot]
                    local unit = "raid" .. i

                    btn.unit = unit
                    btn.index = i
                    btn.rank = rank
                    unitToButton[unit] = btn

                    btn:Show()
                    UpdateButtonAll(btn)
                end
            end
        end

        raidFrame:SetWidth(8 * (btnW + colSpacingX) - colSpacingX)
        raidFrame:SetHeight(5 * (btnH + btnSpacingY) - btnSpacingY + 16)
    elseif isParty then
        -- Unified Party layout: Group 1 displays party members vertically
        groups[1].title:SetText("Party")

        local slot = 1
        local pbtn = groups[1].buttons[slot]
        pbtn.unit = "player"
        pbtn.index = 0
        pbtn.rank = UnitIsPartyLeader("player") and 2 or 0
        unitToButton["player"] = pbtn
        pbtn:Show()
        UpdateButtonAll(pbtn)
        groupCounters[1] = 1

        for i = 1, numParty do
            slot = slot + 1
            if slot <= 5 then
                local btn = groups[1].buttons[slot]
                local unit = "party" .. i
                btn.unit = unit
                btn.index = i
                btn.rank = 0
                unitToButton[unit] = btn
                btn:Show()
                UpdateButtonAll(btn)
                groupCounters[1] = slot
            end
        end

        -- In party mode, container width is 1 column
        raidFrame:SetWidth(btnW)
        raidFrame:SetHeight((groupCounters[1] * (btnH + btnSpacingY)) + 16)
    end

    -- Update group headers & unused button visibility
    local totalActive = 0
    for g = 1, 8 do
        local activeCount = groupCounters[g]
        totalActive = totalActive + activeCount
        if activeCount > 0 then
            groups[g].title:Show()
            groups[g]:Show()
        else
            groups[g].title:Hide()
            groups[g]:Hide()
        end
        for m = activeCount + 1, 5 do
            local btn = groups[g].buttons[m]
            btn.unit = nil
            btn:Hide()
        end
    end

    if totalActive > 0 then
        raidFrame:Show()
    else
        raidFrame:Hide()
    end
end

local function RaidFrame_OnEvent()
    local ev = event
    local a1 = arg1

    if ev == "RAID_ROSTER_UPDATE" or ev == "PARTY_MEMBERS_CHANGED" or ev == "PLAYER_ENTERING_WORLD" then
        UF:UpdateGroupRoster()
    elseif ev == "RAID_TARGET_UPDATE" or ev == "PARTY_LEADER_CHANGED" then
        for _, btn in pairs(unitToButton) do
            UpdateButtonIndicators(btn)
        end
    elseif a1 and unitToButton[a1] then
        local btn = unitToButton[a1]
        if ev == "UNIT_HEALTH" or ev == "UNIT_MAXHEALTH" then
            UpdateButtonHealth(btn)
            UpdateButtonRange(btn)
        elseif ev == "UNIT_MANA" or ev == "UNIT_RAGE" or ev == "UNIT_ENERGY" or ev == "UNIT_FOCUS" or
               ev == "UNIT_MAXMANA" or ev == "UNIT_DISPLAYPOWER" then
            UpdateButtonPower(btn)
        elseif ev == "UNIT_AURA" then
            UpdateButtonAuras(btn)
        elseif ev == "UNIT_NAME_UPDATE" or ev == "UNIT_LEVEL" then
            UpdateButtonHealth(btn)
        end
    end
end

--------------------------------------------------------------------------------
-- 7. Range Check Ticker
--------------------------------------------------------------------------------

local rangeTicker = CreateFrame("Frame")
local lastRangeCheck = 0

rangeTicker:SetScript("OnUpdate", function()
    local now = GetTime()
    if now - lastRangeCheck < 0.25 then return end
    lastRangeCheck = now

    if testMode or not raidFrame or not raidFrame:IsShown() then return end
    for _, btn in pairs(unitToButton) do
        UpdateButtonRange(btn)
    end
end)

--------------------------------------------------------------------------------
-- 8. Test Mode (Mock 40-Player Grid)
--------------------------------------------------------------------------------

local MOCK_CLASSES = { "WARRIOR", "PRIEST", "MAGE", "ROGUE", "DRUID", "HUNTER", "WARLOCK", "SHAMAN" }
local MOCK_DEBUFF_ICONS = {
    { icon = "Interface\\Icons\\Spell_Shadow_CurseOfTounges", dtype = "Curse" },
    { icon = "Interface\\Icons\\Spell_Nature_NullifyPoison", dtype = "Poison" },
    { icon = "Interface\\Icons\\Spell_Holy_Renew", dtype = "Magic" },
}

function UF:ToggleRaidTest()
    ConstructRaidGrid()
    testMode = not testMode

    local bc = UF.backdropBorderColor or { 0.15, 0.15, 0.15, 0.9 }
    local dims = UF:GetGroupDimensions()
    local btnW = dims.width
    local btnH = dims.height
    local btnSpacingY = 3
    local colSpacingX = 4

    if testMode then
        if wipe then wipe(unitToButton) end
        raidFrame:SetWidth(8 * (btnW + colSpacingX) - colSpacingX)
        raidFrame:SetHeight(5 * (btnH + btnSpacingY) - btnSpacingY + 16)
        raidFrame:Show()

        for g = 1, 8 do
            groups[g]:Show()
            groups[g].title:SetText("G" .. g)
            groups[g].title:Show()
            for m = 1, 5 do
                local btn = groups[g].buttons[m]
                btn.unit = "player"
                btn.index = (g - 1) * 5 + m
                btn.rank = (m == 1 and g == 1) and 2 or 0

                -- Static clean border
                btn:SetBackdropBorderColor(bc[1], bc[2], bc[3], bc[4] or 0.9)

                -- Mock class & name
                local cls = MOCK_CLASSES[((g + m) % 8) + 1]
                local c = UF.ClassColors[cls]
                btn.healthBar:SetStatusBarColor(c.r, c.g, c.b, 1)
                btn.nameText:SetText(string.sub(cls, 1, 1) .. cls:sub(2):lower() .. m)

                -- Mock health variations
                local max = 4000
                local cur = max
                if m == 2 then
                    cur = 2500
                    btn.healthText:SetText("-1.5k")
                elseif m == 3 then
                    cur = 3400
                    btn.healthText:SetText("-600")
                elseif m == 4 then
                    cur = 0
                    btn.healthText:SetText("|cffff2020Dead|r")
                elseif m == 5 and g == 8 then
                    cur = 0
                    btn.healthText:SetText("|cff888888Off|r")
                else
                    btn.healthText:SetText("")
                end
                btn.healthBar:SetMinMaxValues(0, max)
                btn.healthBar:SetValue(cur)

                -- Mock power bar
                btn.powerBar:SetMinMaxValues(0, 3000)
                btn.powerBar:SetValue(2100)
                btn.powerBar:SetStatusBarColor(0.3, 0.52, 0.9, 1)

                -- Mock debuff badges (no colored borders on the unit button)
                if m == 2 then
                    local d = MOCK_DEBUFF_ICONS[1]
                    btn.debuffBadges[1].icon:SetTexture(d.icon)
                    local dc = DISPEL_COLORS[d.dtype]
                    btn.debuffBadges[1]:SetBackdropBorderColor(dc.r, dc.g, dc.b, 1)
                    btn.debuffBadges[1]:Show()
                    btn.debuffBadges[2]:Hide()
                    btn.debuffBadges[3]:Hide()
                elseif m == 3 then
                    for b = 1, 2 do
                        local d = MOCK_DEBUFF_ICONS[b + 1]
                        btn.debuffBadges[b].icon:SetTexture(d.icon)
                        local dc = DISPEL_COLORS[d.dtype]
                        btn.debuffBadges[b]:SetBackdropBorderColor(dc.r, dc.g, dc.b, 1)
                        btn.debuffBadges[b]:Show()
                    end
                    btn.debuffBadges[3]:Hide()
                else
                    for b = 1, 3 do btn.debuffBadges[b]:Hide() end
                end

                -- Mock indicators
                if m == 1 and g == 1 then
                    btn.leaderIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
                    btn.leaderIcon:Show()
                else
                    btn.leaderIcon:Hide()
                end

                if m == 1 then
                    SetRaidTargetIconTexture(btn.raidIcon, g)
                    btn.raidIcon:Show()
                else
                    btn.raidIcon:Hide()
                end

                -- Mock range
                btn:SetAlpha(m == 5 and 0.45 or 1.0)
                btn:Show()
            end
        end

        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[FostercareTweaks]|r Group Frames test mode ENABLED (40 players shown). Hold Ctrl+Shift to move.", 1, 1, 1)
        end
    else
        for g = 1, 8 do
            for m = 1, 5 do
                local btn = groups[g].buttons[m]
                btn.unit = nil
                btn:SetBackdropBorderColor(bc[1], bc[2], bc[3], bc[4] or 0.9)
                for b = 1, 3 do btn.debuffBadges[b]:Hide() end
                btn:Hide()
            end
        end
        UF:UpdateGroupRoster()
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[FostercareTweaks]|r Group Frames test mode DISABLED.", 1, 1, 1)
        end
    end
end

--------------------------------------------------------------------------------
-- 9. Group Frame Size Settings Dialog (Sliders)
--------------------------------------------------------------------------------

function UF:UpdateAllRaidFrames()
    if not raidFrame or not raidFrame:IsShown() then return end
    if testMode then
        local fmt = (UF.GetRaidHealthFormat and UF:GetRaidHealthFormat()) or "deficit"
        for g = 1, 8 do
            if groups[g] then
                for m = 1, 5 do
                    local btn = groups[g].buttons[m]
                    if btn and btn:IsShown() then
                        local cur = btn.healthBar:GetValue()
                        local _, max = btn.healthBar:GetMinMaxValues()
                        if fmt == "percent" then
                            local pct = (max > 0) and math.floor((cur / max) * 100 + 0.5) or 0
                            btn.healthText:SetText(pct .. "%")
                        elseif fmt == "current" then
                            btn.healthText:SetText(FostercareTweaks.Abbreviate(cur))
                        else
                            if max > 0 and cur < max then
                                btn.healthText:SetText("-" .. FostercareTweaks.Abbreviate(max - cur))
                            else
                                btn.healthText:SetText("")
                            end
                        end
                        UpdateButtonIndicators(btn)
                        if not (UF.IsRaidShowDebuffs and UF:IsRaidShowDebuffs()) then
                            for b = 1, 3 do btn.debuffBadges[b]:Hide() end
                        end
                    end
                end
            end
        end
        return
    end
    for _, btn in pairs(unitToButton) do
        if btn and btn:IsShown() then
            UpdateButtonAll(btn)
        end
    end
end

function UF:ToggleGroupFrameSettings()
    if FostercareTweaksSettingsGUI then
        if FostercareTweaksSettingsGUI:IsShown() and FostercareTweaksSettingsGUI.currentTab == 3 then
            FostercareTweaksSettingsGUI:Hide()
        else
            FostercareTweaksSettingsGUI:Show()
            if FostercareTweaksSettingsGUI.SelectTab then
                FostercareTweaksSettingsGUI.SelectTab(3)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- 10. Subsystem Lifecycle & Event Registration
--------------------------------------------------------------------------------

function UF:EnableRaidFrames()
    local dims = UF:GetGroupDimensions()
    if not dims.enabled then
        if raidFrame then raidFrame:Hide() end
        return
    end

    ConstructRaidGrid()
    raidFrame:Show()

    raidFrame:RegisterEvent("RAID_ROSTER_UPDATE")
    raidFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    raidFrame:RegisterEvent("PARTY_LEADER_CHANGED")
    raidFrame:RegisterEvent("RAID_TARGET_UPDATE")
    raidFrame:RegisterEvent("UNIT_HEALTH")
    raidFrame:RegisterEvent("UNIT_MAXHEALTH")
    raidFrame:RegisterEvent("UNIT_MANA")
    raidFrame:RegisterEvent("UNIT_RAGE")
    raidFrame:RegisterEvent("UNIT_ENERGY")
    raidFrame:RegisterEvent("UNIT_MAXMANA")
    raidFrame:RegisterEvent("UNIT_DISPLAYPOWER")
    raidFrame:RegisterEvent("UNIT_AURA")
    raidFrame:RegisterEvent("UNIT_NAME_UPDATE")
    raidFrame:RegisterEvent("UNIT_LEVEL")
    raidFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    raidFrame:SetScript("OnEvent", RaidFrame_OnEvent)

    UF:UpdateGroupRoster()
end

function UF:DisableRaidFrames()
    if raidFrame then
        raidFrame:Hide()
        raidFrame:UnregisterAllEvents()
    end
end
