local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/unitframes/raid.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Modern Unit Frames Subsystem: Unified Group Frames (Party & 40-Player Raid)
-- Primary Donor: LunaUnitFrames-TurtleWoW

local UF = FT.UnitFrames
if not UF then return end

local raidFrame = nil
local groups = {}
local unitToButton = {}
local testMode = false
local wipe = table.wipe

--------------------------------------------------------------------------------
-- 1. Dimension Settings Management
--------------------------------------------------------------------------------

local groupLimits = {
    width = {64, 40, 120}, height = {34, 20, 60}, scale = {1, 0.5, 2},
    spacingX = {4, 0, 20}, spacingY = {3, 0, 20},
}
local function GroupNumber(key, value, default)
    local bounds = groupLimits[key]
    return FT.ClampNumber(value, default or bounds[1], bounds[2], bounds[3])
end
function UF:GetGroupDimensions()
    local cfg = FostercareTweaks_Config.groupframe_dimensions
    if type(cfg) ~= "table" then cfg = {} end
    local result = {enabled = cfg.enabled == nil or cfg.enabled == true or cfg.enabled == 1}
    for key in pairs(groupLimits) do result[key] = GroupNumber(key, cfg[key]) end
    return result
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
    local classToken = FT.NormalizeClass(cls) or btn.rosterClass
    local c = classToken and UF.ClassColors[classToken]
    if c then
        btn.healthBar:SetStatusBarColor(c.r, c.g, c.b, 1)
    else
        btn.healthBar:SetStatusBarColor(0.2, 0.9, 0.2, 1)
    end

    -- FontString bounds handle long names at the current size.
    local name = UnitName(unit) or btn.rosterName or ("Group" .. btn.index)
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
        btn.healthText:SetText(FT.Abbreviate(cur))
    else -- "deficit" (Luna standard healer deficit)
        if max > 0 and cur < max then
            local deficit = max - cur
            btn.healthText:SetText("-" .. FT.Abbreviate(deficit))
        else
            btn.healthText:SetText("")
        end
    end
    if UF.LayoutRaidText then UF.LayoutRaidText(btn, btn.auraStripHeight or 0) end
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

local HOT_NAMES = {
    ["Renew"] = true, ["Rejuvenation"] = true, ["Regrowth"] = true,
    ["Power Word: Shield"] = true, ["Flash Heal"] = true, ["Healing Way"] = true,
    ["Blessing of Protection"] = true,
}

function UF:GetRaidBuffSettings()
    local cfg = FostercareTweaks_Config or {}
    local values = cfg.overwrites or {}
    local count = math.max(1, math.min(8, math.floor(tonumber(values.raid_buff_count) or 4)))
    local size = math.max(8, math.min(18, math.floor(tonumber(values.raid_buff_size) or 10)))
    return cfg["Show Raid Buffs"] ~= 0, count, size, cfg["Show All Raid Buffs"] == 1
end

function UF:IsShowGroupLabels()
    return not FostercareTweaks_Config or FostercareTweaks_Config["Show Group Labels"] ~= 0
end

function UF:GetRaidAuraLayout()
    local v = FostercareTweaks_Config and FostercareTweaks_Config.overwrites or {}
    return math.max(8, math.min(18, tonumber(v.raid_debuff_size) or 11)),
        math.max(1, math.min(8, math.floor(tonumber(v.raid_debuff_count) or 3))),
        math.max(0, math.min(6, tonumber(v.raid_aura_spacing) or 2))
end

-- Roster geometry never depends on aura count; hidden headers consume no space.
local function LayoutRaidGroups()
    if not raidFrame then return end
    local dims = UF:GetGroupDimensions()
    local header = UF:IsShowGroupLabels() and 16 or 0
    local maxHeight = header
    for g = 1, 8 do
        local grp = groups[g]
        local y, active = header, 0
        for _, btn in ipairs(grp.buttons) do
            if btn.unit and btn:IsShown() then
                if active > 0 then y = y + dims.spacingY end
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", grp, "TOPLEFT", 0, -y)
                y, active = y + btn:GetHeight(), active + 1
            end
        end
        if active > 0 and header > 0 then grp.title:Show() else grp.title:Hide() end
        grp:SetHeight(math.max(1, y))
        if active > 0 then maxHeight = math.max(maxHeight, y) end
    end
    local raidLayout = testMode or (GetNumRaidMembers() or 0) > 0
    raidFrame:SetWidth(raidLayout and (8 * (dims.width + dims.spacingX) - dims.spacingX) or dims.width)
    raidFrame:SetHeight(math.max(1, maxHeight))
end

local CreateRaidBuffBadge
local MOCK_BUFF_ICONS = {
    "Interface\\Icons\\Spell_Holy_Renew", "Interface\\Icons\\Spell_Nature_Rejuvenation",
    "Interface\\Icons\\Spell_Holy_PowerWordShield", "Interface\\Icons\\Spell_Holy_WordFortitude",
}

local function AuraPriority(a, b)
    if a.priority == b.priority then return a.index < b.index end
    return a.priority < b.priority
end

local function ReadRaidAuras(btn, kind, enabled)
    local list = btn[kind .. "Candidates"]
    local total, hot = 0, nil
    if enabled then
        local count
        if testMode then count = kind == "buff" and 32 or (btn.memberIdx == 2 and 1 or (btn.memberIdx == 3 and 2 or 0))
        else
            local continuation
            continuation, count = C_UnitAuras.GetAuraSlots(btn.unit, kind == "buff" and "HELPFUL" or "HARMFUL", 0, nil, btn[kind .. "Slots"])
        end
        for i = 1, count do
            local name, icon, stacks, dtype, duration, expiration, source, steal, personal, id
            if testMode then
                name, icon, stacks, id = "Preview", MOCK_BUFF_ICONS[((i - 1) % 4) + 1], i == 2 and 3 or 1, i
                dtype = kind == "debuff" and "Magic" or nil
            else
                name, icon, stacks, dtype, duration, expiration, source, steal, personal, id = C_UnitAuras.UnitAuraBySlot(btn.unit, btn[kind .. "Slots"][i])
            end
            if name and icon then
                total = total + 1
                local a = list[total] or {}; list[total] = a
                a.index, a.name, a.icon, a.stacks, a.dtype = i, name, icon, stacks, dtype
                a.duration, a.expiration, a.source, a.id = duration, expiration, source, id
                -- Dispel-type debuffs precede other debuffs; HoTs/shields precede
                -- player/pet buffs, then remaining buffs in native index order.
                if kind == "debuff" then a.priority = dtype and dtype ~= "none" and 1 or 2
                elseif HOT_NAMES[name] then a.priority = 1; hot = hot or icon
                elseif source and (UnitIsUnit(source, "player") or UnitIsUnit(source, "pet")) then a.priority = 2
                else a.priority = 3 end
            end
        end
    end
    for i = #list, total + 1, -1 do list[i] = nil end
    table.sort(list, AuraPriority)
    return total, hot
end

local function LayoutRaidText(btn, strip)
    local hb = btn.healthBar
    local h = hb:GetHeight() - strip
    local markSize = math.min((FT.GetRaidMarkSettings and FT.GetRaidMarkSettings()) or 14, hb:GetHeight() - 2, 20)
    local marker = btn.raidIcon:IsShown() and markSize + 2 or 0
    local leader = btn.leaderIcon:IsShown() and 7 or 0
    local w = math.max(1, hb:GetWidth() - 8 - marker - leader)
    local rows = h >= 16
    local font = math.max(8, math.min(11, rows and math.floor(h / 2) or h))
    UF.SetFontSize(btn.nameText, font); UF.SetFontSize(btn.healthText, font)
    btn.nameText:ClearAllPoints(); btn.healthText:ClearAllPoints()
    btn.nameText:SetPoint("TOPLEFT", hb, "TOPLEFT", 4 + marker, -1)
    btn.healthText:SetPoint("TOPRIGHT", hb, "TOPRIGHT", -4 - leader, rows and -1 - math.floor(h / 2) or -1)
    btn.nameText:SetWidth(rows and w or math.max(1, w * 0.58 - 2))
    btn.healthText:SetWidth(rows and w or math.max(1, w * 0.42 - 2))
    btn.nameText:SetHeight(font); btn.healthText:SetHeight(font)
    btn.nameText:SetJustifyH("LEFT"); btn.healthText:SetJustifyH("RIGHT")
    btn.raidIcon:SetWidth(markSize); btn.raidIcon:SetHeight(markSize)
    btn.raidIcon:ClearAllPoints(); btn.raidIcon:SetPoint("TOPLEFT", hb, "TOPLEFT", 1, -1)
end

UF.LayoutRaidText = LayoutRaidText

local function ShowRaidAura(btn, badge, a, size, x, y)
    badge:SetWidth(size); badge:SetHeight(size)
    badge.border:SetWidth(size + 2); badge.border:SetHeight(size + 2)
    badge:ClearAllPoints(); badge:SetPoint("TOPLEFT", btn, "TOPLEFT", x, -y)
    badge.unit, badge.auraIndex, badge.spellId = btn.unit, a.index, a.id
    badge.icon:SetTexture(a.icon)
    badge.countText:SetText(a.stacks and a.stacks > 1 and a.stacks or "")
    if a.stacks and a.stacks > 1 then badge.countText:Show() else badge.countText:Hide() end
    local stacked = a.stacks and a.stacks > 1
    -- Keep two labels apart on larger indicators. On tiny indicators preserve
    -- stacks and the sweep; expose remaining seconds in the aura tooltip.
    badge.fctHideDuration = size < 8 or (stacked and size < 14)
    local font = math.min(size, math.max(6, math.min(9, stacked and math.floor(size / 2) or size - 1)))
    UF.SetFontSize(badge.countText, font); UF.SetFontSize(badge.durationText, font)
    badge.countText:ClearAllPoints(); badge.countText:SetPoint("BOTTOMRIGHT", badge, "BOTTOMRIGHT", 0, 0)
    badge.countText:SetWidth(size); badge.countText:SetHeight(font)
    badge.durationText:ClearAllPoints()
    if stacked then badge.durationText:SetPoint("TOP", badge, "TOP", 0, 0)
    else badge.durationText:SetPoint("CENTER", badge, "CENTER", 0, 0) end
    badge.durationText:SetWidth(size); badge.durationText:SetHeight(font)
    badge.cooldown:SetScale(size / 36)
    UF.Auras.UpdateAuraTiming(badge, UnitGUID(btn.unit), a.id, a.source, a.duration, a.expiration,
        badge.isDebuff and UF:IsDebuffSpin() or (not badge.isDebuff and UF:IsBuffSpin()),
        badge.isDebuff and UF:IsDebuffText() or (not badge.isDebuff and UF:IsBuffText()), GetTime())
    UF.Auras.StyleBorder(badge, a.dtype, badge.isDebuff and UF:IsColorDebuffsByDispel())
    badge:Show()
end

-- Mark/leader changes only alter the space available to already-read auras.
-- Keep layout separate from authoritative aura reads and HoT selection.
local function LayoutButtonAuras(btn)
    if not btn.unit or not btn:IsShown() then return end
    local enabled, count, size, all = UF:GetRaidBuffSettings()
    local dsize, dcount, spacing = UF:GetRaidAuraLayout()
    local btotal, dtotal = #btn.buffCandidates, #btn.debuffCandidates
    local bn = enabled and math.min(btotal, all and btotal or count) or 0
    local dn = math.min(dtotal, dcount)
    -- Keep two readable 8 px text rows whenever height permits, including
    -- the default grid. Minimum-height frames retain a single identity lane.
    local maxSize = math.max(4, btn.healthBar:GetHeight() - 18)
    size, dsize = math.min(size, maxSize), math.min(dsize, maxSize)
    local markSpace = btn.raidIcon:IsShown() and math.min((FT.GetRaidMarkSettings and FT.GetRaidMarkSettings()) or 14, btn.healthBar:GetHeight() - 2, 20) + 2 or 0
    local width = btn:GetWidth() - 4 - markSpace
    local overflow = bn * (size + spacing) + dn * (dsize + spacing) - spacing > width
    local available = width - (overflow and 12 or 0)
    local shownB, shownD, used = 0, 0, 0
    -- Debuffs take priority, but reserve one buff when both types fit.
    local reserve = bn > 0 and (size + spacing) or 0
    for i = 1, dn do
        if used + dsize > available - reserve then break end
        shownD, used = shownD + 1, used + dsize + spacing
    end
    for i = 1, bn do
        if used + size > available then break end
        shownB, used = shownB + 1, used + size + spacing
    end
    local strip = (shownB + shownD > 0 or overflow) and math.max(size, dsize) + 2 or 0
    local y = 1 + btn.healthBar:GetHeight() - math.max(size, dsize)
    for i = 1, shownB do ShowRaidAura(btn, btn.buffBadges[i] or CreateRaidBuffBadge(btn, i), btn.buffCandidates[i], size, 2 + markSpace + (i - 1) * (size + spacing), y) end
    local x = 2 + markSpace + shownB * (size + spacing)
    for i = 1, shownD do ShowRaidAura(btn, btn.debuffBadges[i], btn.debuffCandidates[i], dsize, x + (i - 1) * (dsize + spacing), y) end
    for i = shownB + 1, #btn.buffBadges do UF.Auras.ResetAuraButton(btn.buffBadges[i]) end
    for i = shownD + 1, #btn.debuffBadges do UF.Auras.ResetAuraButton(btn.debuffBadges[i]) end
    btn.auraOverflowCount = bn + dn - shownB - shownD
    btn.auraOverflow:SetText(btn.auraOverflowCount > 0 and ("+" .. btn.auraOverflowCount) or "")
    btn.auraOverflow:ClearAllPoints(); btn.auraOverflow:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -2, -y)
    UF.SetFontSize(btn.auraOverflow, math.max(6, math.min(9, maxSize)))
    if btn.auraOverflowCount > 0 then btn.auraOverflow:Show() else btn.auraOverflow:Hide() end
    btn.auraStripHeight = strip
    LayoutRaidText(btn, strip)
end

local function UpdateButtonAuras(btn)
    if not btn.unit or not btn:IsShown() then return end
    local enabled = UF:GetRaidBuffSettings()
    local _, hot = ReadRaidAuras(btn, "buff", enabled or UF:IsRaidShowHoT())
    ReadRaidAuras(btn, "debuff", UF:IsRaidShowDebuffs())
    if hot and UF:IsRaidShowHoT() then btn.hotSquare.icon:SetTexture(hot); btn.hotSquare:Show() else btn.hotSquare:Hide() end
    LayoutButtonAuras(btn)
end

local function UpdateButtonAggro(btn, nativeFallback, targetTargetGUID)
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
            elseif nativeFallback then
                hasAggro = targetTargetGUID and UnitGUID(unit) == targetTargetGUID
            elseif UnitExists("target") and UnitCanAttack("player", "target") and UnitIsUnit("targettarget", unit) then
                hasAggro = true
            end
        end
        if hasAggro then
            if not btn.aggroSquare:IsShown() then btn.aggroSquare:Show() end
        elseif btn.aggroSquare:IsShown() then
            btn.aggroSquare:Hide()
        end
    end
end

local function UpdateButtonIndicators(btn)
    local unit = btn.unit
    if not unit or not btn:IsShown() then return end
    UpdateButtonAggro(btn)

    -- Raid Target Icon
    local targetIndex = testMode and (btn.memberIdx == 1 and btn.groupNum or nil) or (not testMode and GetRaidTargetIndex(unit))
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
    LayoutRaidText(btn, btn.auraStripHeight or 0)
end

local function UpdateButtonRange(btn)
    local unit = btn.unit
    if not unit or not btn:IsShown() then return end

    local inRange = unit == "player" or UnitInRange(unit)
    local alpha = not UnitIsConnected(unit) and 0.4 or inRange and 1 or 0.45
    if btn.rangeAlpha ~= alpha then btn.rangeAlpha = alpha; btn:SetAlpha(alpha) end
end

local function UpdateButtonAll(btn)
    UpdateButtonHealth(btn)
    UpdateButtonPower(btn)
    UpdateButtonIndicators(btn)
    UpdateButtonAuras(btn)
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
                    local openMenu = (type(UIDROPDOWNMENU_OPEN_MENU) == "string" and _G[UIDROPDOWNMENU_OPEN_MENU]) or UIDROPDOWNMENU_OPEN_MENU or menuFrame
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

local function BindRaidAuraInteraction(badge)
    badge:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    badge:SetScript("OnClick", RaidButton_OnClick)
    local enter, leave = badge:GetScript("OnEnter"), badge:GetScript("OnLeave")
    badge:SetScript("OnEnter", function()
        if this.unit then SetMouseoverUnit(this.unit) end
        enter()
        if this.fctHideDuration and this.expirationTime and this.expirationTime > GetTime() then
            GameTooltip:AddLine("Time remaining: " .. string.format("%.1fs", this.expirationTime - GetTime()), 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    badge:SetScript("OnLeave", function()
        SetMouseoverUnit()
        leave()
    end)
end

CreateRaidBuffBadge = function(btn, index)
    -- Keep the cache contiguous even if an intervening aura has no icon yet.
    for b = #btn.buffBadges + 1, index do
        local badge = UF.Auras.CreateAuraButton(btn, btn:GetName() .. "Buff" .. b, 10, false)
        BindRaidAuraInteraction(badge)
        btn.buffBadges[b] = badge
    end
    return btn.buffBadges[index]
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

    -- The container mover owns all Ctrl+Shift dragging and persistence.

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
    btn.aggroSquare:SetWidth(3)
    btn.aggroSquare:SetHeight(3)
    btn.aggroSquare:SetPoint("BOTTOMLEFT", hb, "BOTTOMLEFT", 1, 1)
    btn.aggroSquare:SetTexture(1, 0, 0, 1)
    btn.aggroSquare:Hide()

    -- Corner HoT / Buff Status Indicator (Top-Left square)
    local hot = CreateFrame("Frame", nil, hb)
    hot:SetWidth(4)
    hot:SetHeight(4)
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
    btn.leaderIcon:SetWidth(6)
    btn.leaderIcon:SetHeight(6)
    btn.leaderIcon:SetPoint("TOPRIGHT", hb, "TOPRIGHT", -1, -1)
    btn.leaderIcon:Hide()

    -- Compact Debuff Indicator Icon Badges (11x11px, bottom-right)
    btn.debuffBadges = {}
    for b = 1, 8 do
        local badge = UF.Auras.CreateAuraButton(btn, btnName .. "Debuff" .. b, 11, true)
        BindRaidAuraInteraction(badge)
        badge:SetPoint("BOTTOMRIGHT", hb, "BOTTOMRIGHT", -1 - (b - 1) * 12, 1)
        badge:Hide()
        btn.debuffBadges[b] = badge
    end

    btn.buffBadges = {}
    btn.buffSlots, btn.debuffSlots = {}, {}
    btn.buffCandidates, btn.debuffCandidates = {}, {}
    btn.auraOverflow = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.auraOverflow:Hide()
    for b = 1, 8 do CreateRaidBuffBadge(btn, b) end
    btn.groupNum = groupNum
    btn.memberIdx = memberIdx
    btn:Hide()

    return btn
end

--------------------------------------------------------------------------------
-- 4. Group Grid Construction & Subgroup Layout
--------------------------------------------------------------------------------

local rangeTicker
local function CheckRanges()
    local nativeFallback = not (Banzai and Banzai.GetUnitAggroByUnitId) and not UnitThreatSituation
    local targetTargetGUID
    if nativeFallback and UF:IsRaidShowAggro() and UnitExists("target") and UnitCanAttack("player", "target") then
        -- The current enemy and its target are shared by this synchronous pass.
        targetTargetGUID = UnitGUID("targettarget")
    end
    for _, button in pairs(unitToButton) do
        UpdateButtonRange(button)
        -- Aggro can change without a roster, leader or raid-mark event. Reuse
        -- the visible group's bounded reconciliation; do not reflow its text.
        UpdateButtonAggro(button, nativeFallback, targetTargetGUID)
    end
end
local function SyncRangeTicker()
    if raidFrame and raidFrame:IsShown() and not testMode then
        if not rangeTicker then rangeTicker = C_Timer.NewTicker(0.25, CheckRanges) end
    elseif rangeTicker then rangeTicker:Cancel(); rangeTicker = nil end
end

local function ConstructRaidGrid()
    if raidFrame then return end

    local dims = UF:GetGroupDimensions()
    local btnW = dims.width
    local btnH = dims.height
    local btnSpacingY = dims.spacingY
    local colSpacingX = dims.spacingX

    raidFrame = CreateFrame("Frame", "FCTweaksRaidFrame", UIParent)
    raidFrame:SetScript("OnShow", SyncRangeTicker)
    raidFrame:SetScript("OnHide", SyncRangeTicker)
    raidFrame:SetWidth(8 * (btnW + colSpacingX) - colSpacingX)
    raidFrame:SetHeight(5 * (btnH + btnSpacingY) - btnSpacingY + 16)
    raidFrame:SetFrameStrata("LOW")
    raidFrame:SetClampedToScreen(true)
    raidFrame:SetMovable(true)
    FT.RegisterFrameMover(raidFrame, "raid", "Raid Frames")
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
    width = GroupNumber("width", width, current.width)
    height = GroupNumber("height", height, current.height)
    scale = GroupNumber("scale", scale, current.scale)
    spacingX = GroupNumber("spacingX", spacingX, current.spacingX)
    spacingY = GroupNumber("spacingY", spacingY, current.spacingY)
    if enabled == nil then
        enabled = current.enabled
    else
        enabled = (enabled == true or enabled == 1)
    end

    if FostercareTweaks_Config then
        if type(FostercareTweaks_Config.groupframe_dimensions) ~= "table" then
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
        UF:DisableRaidFrames()
        UF:RestorePartyFrames()
        return
    end

    UF:SuppressPartyFrames()
    UF:EnableRaidFrames(true)
    local colSpacingX = spacingX
    raidFrame:SetScale(scale)
    local powerH = math.max(3, math.floor(height * 0.12))
    local healthH = height - powerH - 3

    for g = 1, 8 do
        local grp = groups[g]
        if grp then
            grp:SetWidth(width)
            grp:ClearAllPoints()
            grp:SetPoint("TOPLEFT", raidFrame, "TOPLEFT", (g - 1) * (width + colSpacingX), 0)

            for m = 1, 5 do
                local btn = grp.buttons[m]
                if btn then
                    btn:SetWidth(width)
                    btn:SetHeight(height)

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

                    if btn.healthBar.Refresh then btn.healthBar:Refresh() end
                    if btn.powerBar.Refresh then btn.powerBar:Refresh() end
                end
            end
        end
    end

    if testMode then
        raidFrame:Show()
        UF:UpdateAllRaidFrames()
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

                    btn.rangeAlpha = nil
                    btn.unit = unit
                    btn.rosterName, btn.rosterClass = name, FT.NormalizeClass(fileName or class)
                    btn.index = i
                    btn.rank = rank
                    unitToButton[unit] = btn

                    btn:Show()
                    UpdateButtonAll(btn)
                end
            end
        end

    elseif isParty then
        -- Unified Party layout: Group 1 displays party members vertically
        groups[1].title:SetText("Party")

        local slot = 1
        local pbtn = groups[1].buttons[slot]
        pbtn.rangeAlpha = nil
        pbtn.unit = "player"
        pbtn.rosterName, pbtn.rosterClass = nil, nil
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
                btn.rangeAlpha = nil
                btn.unit = unit
                btn.rosterName, btn.rosterClass = nil, nil
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
            groups[g]:Show()
        else
            groups[g].title:Hide()
            groups[g]:Hide()
        end
        for m = activeCount + 1, 5 do
            local btn = groups[g].buttons[m]
            btn.unit = nil
            btn.rosterName, btn.rosterClass = nil, nil
            for _, badge in ipairs(btn.buffBadges) do UF.Auras.ResetAuraButton(badge) end
            for _, badge in ipairs(btn.debuffBadges) do UF.Auras.ResetAuraButton(badge) end
            btn:Hide()
        end
    end

    LayoutRaidGroups()
    if totalActive > 0 then
        raidFrame:Show()
    else
        raidFrame:Hide()
    end
    SyncRangeTicker()
end

local function RaidFrame_OnEvent(_, ev, a1)

    if ev == "RAID_ROSTER_UPDATE" or ev == "PARTY_MEMBERS_CHANGED" or ev == "PLAYER_ENTERING_WORLD" then
        UF:UpdateGroupRoster()
    elseif ev == "RAID_TARGET_UPDATE" or ev == "PARTY_LEADER_CHANGED" then
        for _, btn in pairs(unitToButton) do
            UpdateButtonIndicators(btn)
            LayoutButtonAuras(btn)
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
-- 8. Test Mode (Mock 40-Player Grid)
--------------------------------------------------------------------------------

local MOCK_CLASSES = { "WARRIOR", "PRIEST", "MAGE", "ROGUE", "DRUID", "HUNTER", "WARLOCK", "SHAMAN" }

function UF:ToggleRaidTest()
    ConstructRaidGrid()
    testMode = not testMode
    SyncRangeTicker()

    local bc = UF.backdropBorderColor or { 0.15, 0.15, 0.15, 0.9 }

    if testMode then
        if wipe then wipe(unitToButton) end
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
                UpdateButtonAuras(btn)
            end
        end

        LayoutRaidGroups()
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[FostercareTweaks]|r Group Frames test mode ENABLED (40 players shown). Hold Ctrl+Shift to move.", 1, 1, 1)
        end
    else
        for g = 1, 8 do
            for m = 1, 5 do
                local btn = groups[g].buttons[m]
                btn.unit = nil
                btn:SetBackdropBorderColor(bc[1], bc[2], bc[3], bc[4] or 0.9)
                for _, badge in ipairs(btn.buffBadges) do UF.Auras.ResetAuraButton(badge) end
                for _, badge in ipairs(btn.debuffBadges) do UF.Auras.ResetAuraButton(badge) end
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

function UF:RefreshRaidAuraBorders()
    for _, group in pairs(groups) do
        for _, btn in ipairs(group.buttons) do
            for _, kind in ipairs({ "buffBadges", "debuffBadges" }) do
                for _, badge in ipairs(btn[kind]) do
                    if badge:IsShown() then
                        UF.Auras.StyleBorder(badge, badge.borderDispelType, badge.borderColorDispel)
                    end
                end
            end
        end
    end
end

function UF:RefreshRaidMarks()
    if not raidFrame or not raidFrame:IsShown() then return end
    for _, group in pairs(groups) do
        for _, btn in ipairs(group.buttons) do
            if btn.unit and btn:IsShown() then
                UpdateButtonIndicators(btn)
                LayoutButtonAuras(btn)
            end
        end
    end
end

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
                            btn.healthText:SetText(FT.Abbreviate(cur))
                        else
                            if max > 0 and cur < max then
                                btn.healthText:SetText("-" .. FT.Abbreviate(max - cur))
                            else
                                btn.healthText:SetText("")
                            end
                        end
                        UpdateButtonIndicators(btn)
                        UpdateButtonAuras(btn)
                    end
                end
            end
        end
        LayoutRaidGroups()
        return
    end
    for _, btn in pairs(unitToButton) do
        if btn and btn:IsShown() then
            UpdateButtonAll(btn)
        end
    end
    LayoutRaidGroups()
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

function UF:EnableRaidFrames(deferRoster)
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
    FT.SetEventHandler(raidFrame, RaidFrame_OnEvent)

    -- Dimension edits must size the buttons before refreshing the roster once.
    if not deferRoster then UF:UpdateGroupRoster() end
end

function UF:DisableRaidFrames()
    if raidFrame then
        raidFrame:Hide()
        raidFrame:UnregisterAllEvents()
    end
end
