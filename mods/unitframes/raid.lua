-- FostercareTweaks: mods/unitframes/raid.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Modern Unit Frames Subsystem: Raid Frames (40-Player Grid, Groups 1-8)
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

local function GetUnitDispelDebuff(unit)
    if not unit or not UnitExists(unit) then return nil end

    if C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex then
        for i = 1, 16 do
            local data = C_UnitAuras.GetDebuffDataByIndex(unit, i)
            if not data then break end
            local dtype = data.dispelName or data.dispelType or data.debuffType
            if dtype and DISPEL_COLORS[dtype] then
                return dtype
            end
        end
        return nil
    end

    for i = 1, 16 do
        local _, _, dtype = UnitDebuff(unit, i)
        if not dtype and not UnitDebuff(unit, i) then break end
        if dtype and DISPEL_COLORS[dtype] then
            return dtype
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- 1. Unit Button Update Routines
--------------------------------------------------------------------------------

local function UpdateButtonHealth(btn)
    local unit = btn.unit
    if not unit or not btn:IsShown() then return end

    local cur, max = UF.GetUnitHealthValues(unit)
    btn.healthBar:SetMinMaxValues(0, max)
    btn.healthBar:SetValue(cur)

    -- Class color
    local _, cls = UnitClass(unit)
    local classToken = cls and (FostercareTweaks.NormalizeClass and FostercareTweaks.NormalizeClass(cls) or cls)
    local c = classToken and UF.ClassColors[classToken]
    if c then
        btn.healthBar:SetStatusBarColor(c.r, c.g, c.b, 1)
    else
        btn.healthBar:SetStatusBarColor(0.2, 0.8, 0.2, 1)
    end

    -- Name text
    local name = UnitName(unit) or ("Raid" .. btn.index)
    local shortName = string.sub(name, 1, 6)
    btn.nameText:SetText(shortName)

    -- Health / Status text
    local isOffline = not UnitIsConnected(unit)
    local isDead = UnitIsDeadOrGhost(unit)
    local isGhost = UnitIsGhost(unit)

    if isOffline then
        btn.healthText:SetText("|cff888888Off|r")
    elseif isDead then
        btn.healthText:SetText(isGhost and "|cffaaaaaaGhost|r" or "|cffff2020Dead|r")
    elseif max > 0 and cur < max then
        local deficit = max - cur
        btn.healthText:SetText("-" .. FostercareTweaks.Abbreviate(deficit))
    else
        btn.healthText:SetText("")
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

    local debuffType = GetUnitDispelDebuff(unit)
    if debuffType and DISPEL_COLORS[debuffType] then
        local dc = DISPEL_COLORS[debuffType]
        btn:SetBackdropBorderColor(dc.r, dc.g, dc.b, 1)
    else
        btn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    end
end

local function UpdateButtonIndicators(btn)
    local unit = btn.unit
    if not unit or not btn:IsShown() then return end

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
-- 2. Button Factory & Mouse Interaction
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

local function CreateRaidButton(groupFrame, groupNum, memberIdx)
    local btnName = "FCTweaksRaidUnitG" .. groupNum .. "M" .. memberIdx
    local btn = CreateFrame("Button", btnName, groupFrame)
    btn:SetWidth(64)
    btn:SetHeight(34)
    btn:SetFrameStrata("LOW")
    btn:SetClampedToScreen(true)

    btn:SetBackdrop(UF.backdrop)
    btn:SetBackdropColor(0.08, 0.08, 0.08, 0.85)
    btn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

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

    -- Health Bar (Stacked top)
    local hb = UF:CreateBar(btnName .. "HealthBar", btn)
    hb:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    hb:SetWidth(62)
    hb:SetHeight(27)
    btn.healthBar = hb

    -- Power Bar (Stacked bottom)
    local pb = UF:CreateBar(btnName .. "PowerBar", btn)
    pb:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -29)
    pb:SetWidth(62)
    pb:SetHeight(4)
    btn.powerBar = pb

    -- Name text
    btn.nameText = hb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.nameText:SetPoint("TOPLEFT", hb, "TOPLEFT", 2, -2)
    btn.nameText:SetJustifyH("LEFT")
    btn.nameText:SetShadowColor(0, 0, 0, 1)
    btn.nameText:SetShadowOffset(1, -1)

    -- Health / Status text
    btn.healthText = hb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.healthText:SetPoint("BOTTOMRIGHT", hb, "BOTTOMRIGHT", -2, 2)
    btn.healthText:SetJustifyH("RIGHT")
    btn.healthText:SetShadowColor(0, 0, 0, 1)
    btn.healthText:SetShadowOffset(1, -1)

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

    btn.groupNum = groupNum
    btn.memberIdx = memberIdx
    btn:Hide()

    return btn
end

--------------------------------------------------------------------------------
-- 3. Raid Grid Construction & Subgroup Layout
--------------------------------------------------------------------------------

local function ConstructRaidGrid()
    if raidFrame then return end

    raidFrame = CreateFrame("Frame", "FCTweaksRaidFrame", UIParent)
    raidFrame:SetWidth(540)
    raidFrame:SetHeight(205)
    raidFrame:SetFrameStrata("LOW")
    raidFrame:SetClampedToScreen(true)
    raidFrame:SetMovable(true)
    raidFrame:EnableMouse(false)
    raidFrame:SetScale(UF:GetScale())

    -- Position restoration or default HUD placement
    raidFrame:ClearAllPoints()
    local savedPos = FostercareTweaks_Config and FostercareTweaks_Config.unitframe_positions and FostercareTweaks_Config.unitframe_positions["raid"]
    if savedPos and savedPos.point and savedPos.relPoint and savedPos.x and savedPos.y then
        raidFrame:SetPoint(savedPos.point, UIParent, savedPos.relPoint, savedPos.x, savedPos.y)
    else
        raidFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -180)
    end

    local btnW = 64
    local btnH = 34
    local btnSpacingY = 3
    local colSpacingX = 4

    for g = 1, 8 do
        local grp = CreateFrame("Frame", "FCTweaksRaidGroup" .. g, raidFrame)
        grp:SetWidth(btnW)
        grp:SetHeight(btnH * 5 + btnSpacingY * 4 + 16)
        grp:SetPoint("TOPLEFT", raidFrame, "TOPLEFT", (g - 1) * (btnW + colSpacingX), 0)

        -- Group Title (G1 - G8)
        grp.title = grp:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        grp.title:SetPoint("TOP", grp, "TOP", 0, 0)
        grp.title:SetText("G" .. g)
        grp.title:SetTextColor(0.8, 0.8, 0.8, 0.9)
        grp.title:Hide()

        grp.buttons = {}
        for m = 1, 5 do
            local btn = CreateRaidButton(grp, g, m)
            btn:SetPoint("TOPLEFT", grp, "TOPLEFT", 0, -16 - ((m - 1) * (btnH + btnSpacingY)))
            grp.buttons[m] = btn
        end

        groups[g] = grp
    end

    UF.raidFrame = raidFrame
end

--------------------------------------------------------------------------------
-- 4. Roster Update & Event Dispatcher
--------------------------------------------------------------------------------

local function UpdateRoster()
    if not raidFrame then return end
    if testMode then return end

    -- Reset mappings
    if wipe then wipe(unitToButton) end
    local groupCounters = { 0, 0, 0, 0, 0, 0, 0, 0 }

    local numRaid = GetNumRaidMembers() or 0
    local numParty = GetNumPartyMembers() or 0

    if numRaid > 0 then
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
    elseif numParty > 0 then
        -- 5-man party mode: Map player and party1..party4 to Group 1
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
    end

    -- Update group headers & unused button visibility
    local totalActive = 0
    for g = 1, 8 do
        local activeCount = groupCounters[g]
        totalActive = totalActive + activeCount
        if activeCount > 0 then
            groups[g].title:Show()
        else
            groups[g].title:Hide()
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
        UpdateRoster()
    elseif ev == "RAID_TARGET_UPDATE" then
        for _, btn in pairs(unitToButton) do
            UpdateButtonIndicators(btn)
        end
    elseif ev == "PARTY_LEADER_CHANGED" then
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
-- 5. Range Check Ticker
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
-- 6. Test Mode (Mock 40-Player Grid)
--------------------------------------------------------------------------------

local MOCK_CLASSES = { "WARRIOR", "PRIEST", "MAGE", "ROGUE", "DRUID", "HUNTER", "WARLOCK", "SHAMAN" }
local MOCK_DEBUFFS = { "Magic", "Curse", "Poison", "Disease", nil }

function UF:ToggleRaidTest()
    ConstructRaidGrid()
    testMode = not testMode

    if testMode then
        if wipe then wipe(unitToButton) end
        raidFrame:Show()

        for g = 1, 8 do
            groups[g].title:Show()
            for m = 1, 5 do
                local btn = groups[g].buttons[m]
                btn.unit = "player" -- Allows hover & target queries safely
                btn.index = (g - 1) * 5 + m
                btn.rank = (m == 1 and g == 1) and 2 or 0

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

                -- Mock debuffs
                local debuff = MOCK_DEBUFFS[m]
                if debuff and DISPEL_COLORS[debuff] then
                    local dc = DISPEL_COLORS[debuff]
                    btn:SetBackdropBorderColor(dc.r, dc.g, dc.b, 1)
                else
                    btn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
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
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[FostercareTweaks]|r Raid Frames test mode ENABLED (40 players shown). Hold Ctrl+Shift to move.", 1, 1, 1)
        end
    else
        for g = 1, 8 do
            for m = 1, 5 do
                local btn = groups[g].buttons[m]
                btn.unit = nil
                btn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
                btn:Hide()
            end
        end
        UpdateRoster()
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[FostercareTweaks]|r Raid Frames test mode DISABLED.", 1, 1, 1)
        end
    end
end

--------------------------------------------------------------------------------
-- 7. Subsystem Lifecycle & Hooking
--------------------------------------------------------------------------------

function UF:EnableRaidFrames()
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

    UpdateRoster()
end

function UF:DisableRaidFrames()
    if raidFrame then
        raidFrame:Hide()
        raidFrame:UnregisterAllEvents()
    end
end
