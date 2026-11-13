local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/unitframes/auras.lua
-- Aura buttons for the improved auras under Blizzard's player and target frames
-- and for the raid frames, read with ClassicAPI C_UnitAuras.

local UF = FT.UnitFrames
if not UF then return end

UF.Auras = UF.Auras or {}
local Auras = UF.Auras

-- One policy for player, target, raid and preview aura buttons.
function Auras.StyleBorder(btn, dispelType)
    btn.borderDispelType = dispelType
    local cfg = FostercareTweaks_Config
    local setting = btn.isDebuff and "Show Debuff Borders" or "Show Buff Borders"
    -- Every aura update restyles its button: write only when the look changes.
    local look = cfg[setting] ~= 1 and "off" or btn.isDebuff and (dispelType or "None") or "buff"
    if btn.fctBorderLook == look then return end
    btn.fctBorderLook = look
    if look == "off" then btn.border:Hide(); return end
    if btn.isDebuff then
        local dc = UF.DispelColors[dispelType] or UF.DispelColors["None"]
        btn.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
        btn.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
        btn.border:SetVertexColor(dc.r, dc.g, dc.b, 1)
    else
        btn.border:SetTexture("Interface\\AddOns\\FostercareTweaks\\img\\border-dark.tga")
        btn.border:SetTexCoord(0, 1, 0, 1)
        btn.border:SetVertexColor(0.15, 0.15, 0.15, 1)
    end
    btn.border:Show()
end

local function RefreshRowBorders(buttons)
    for _, btn in ipairs(buttons) do
        if btn:IsShown() then Auras.StyleBorder(btn, btn.borderDispelType) end
    end
end

function Auras:RefreshBorders()
    for _, container in pairs({ UF.blizzPlayerAuras, UF.blizzTargetAuras }) do
        RefreshRowBorders(container.buffButtons)
        RefreshRowBorders(container.debuffButtons)
    end
    UF:RefreshRaidAuraBorders()
end


local function AuraButton_OnEnter()
    if not this.unit or not this.auraIndex then return end
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
    -- Tooltips take the plain polarity index.
    GameTooltip:SetUnitAura(this.unit, this.auraIndex, this.isDebuff and "HARMFUL" or "HELPFUL")
    GameTooltip:Show()
end

local function AuraButton_OnLeave() GameTooltip:Hide() end

local function AuraButton_OnClick()
    if arg1 == "RightButton" and this.unit == "player" and not this.isDebuff and this.spellId then
        C_Spell.CancelSpellByID(this.spellId)
    end
end

local function ResetAuraButton(btn)
    if not btn then return end
    if not btn.unit and not btn.isOccupied and not btn.expirationTime and not btn:IsShown() then return end
    btn.unit = nil
    btn.auraIndex = nil
    btn.spellId = nil
    btn.expirationTime = nil
    btn.duration = nil
    btn.timerUnitGUID, btn.timerSpellID, btn.timerSourceGUID = nil, nil, nil
    btn.sweepStart, btn.sweepDuration = nil, nil
    btn.isOccupied = false

    if btn.countText then
        btn.countText:SetText("")
        btn.countText:Hide()
        btn.fctCount = nil
    end

    if btn.cooldown then
        btn.cooldown:Clear()
    end

    if btn.icon then
        btn.icon:SetTexture(nil)
        btn.fctTexture = nil
    end

    if btn.border then
        btn.border:Hide()
        btn.fctBorderLook = nil
    end

    btn:Hide()
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

    -- Dispel overlay only; ordinary aura icons have no decorative frame.
    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetPoint("CENTER", btn, "CENTER")
    btn.border:SetWidth(size + 2)
    btn.border:SetHeight(size + 2)
    btn.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
    btn.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    btn.border:Hide()

    -- Native cooldown sweep (ClassicAPI); it follows the button's size.
    btn.cooldown = CreateFrame("Cooldown", name .. "CD", btn, "CooldownFrameTemplate")
    btn.cooldown:SetAllPoints(btn)
    btn.cooldown:SetReverse(true)
    btn.cooldown:EnableMouse(false)
    -- No flash at the end. The client counts the time down (CVar
    -- countdownForCooldowns 1) in the addon's one countdown look.
    btn.cooldown:SetDrawBling(false)
    btn.cooldown:SetCountdownFormatter(FT.Countdown)
    local font = STANDARD_TEXT_FONT
    local number = btn.cooldown:GetCountdownFontString()
    number:SetFont(font, (size <= 20 and 9 or 11), "OUTLINE")
    number:SetShadowColor(0, 0, 0, 1)
    number:SetShadowOffset(0.8, -0.8)
    btn.cooldown:Hide()

    -- Overlay text frame (drawn above cooldown)
    btn.textFrame = CreateFrame("Frame", nil, btn)
    btn.textFrame:SetAllPoints(btn)
    btn.textFrame:EnableMouse(false)
    btn.textFrame:SetFrameLevel(btn:GetFrameLevel() + 5)

    btn.countText = btn.textFrame:CreateFontString(nil, "OVERLAY")
    btn.countText:SetFont(font, (size <= 20 and 9 or 10), "OUTLINE")
    btn.countText:SetPoint("BOTTOMRIGHT", btn.textFrame, "BOTTOMRIGHT", -1, 1)
    btn.countText:SetJustifyH("RIGHT")
    btn.countText:SetShadowColor(0, 0, 0, 1)
    btn.countText:SetShadowOffset(0.8, -0.8)
    btn.countText:Hide()

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

function Auras:ResetContainer(container)
    for _, btn in ipairs(container.buffButtons) do ResetAuraButton(btn) end
    for _, btn in ipairs(container.debuffButtons) do ResetAuraButton(btn) end
end

local function AnchorAuraButton(btn, frame, index, size, spacing, perRow, growsUp, alignRight)
    local row = math.floor((index - 1) / perRow)
    local col = (index - 1) % perRow
    local point = (growsUp and "BOTTOM" or "TOP") .. (alignRight and "RIGHT" or "LEFT")
    btn:SetPoint(point, frame, point,
        col * (size + spacing) * (alignRight and -1 or 1),
        row * (size + spacing) * (growsUp and 1 or -1))
end

function Auras:CreateAuraContainer(parentFrame, unit, maxBuffs, maxDebuffs, options)
    options = options or {}
    local buffSize, debuffSize = UF:GetBuffSize(), UF:GetDebuffSize()
    local spacing = options.spacing or 3
    local perRow = options.perRow or 8
    local alignRight = options.alignRight
    local side = alignRight and "RIGHT" or "LEFT"

    local container = CreateFrame("Frame", parentFrame:GetName() .. "Auras", parentFrame)
    container.unit = unit
    container.buffButtons = {}
    container.debuffButtons = {}
    container.buffSlots, container.debuffSlots = {}, {}
    container.options = options
    container.buffSize = buffSize
    container.debuffSize = debuffSize

    -- Buff Row
    if maxBuffs and maxBuffs > 0 then
        container.buffFrame = CreateFrame("Frame", container:GetName() .. "Buffs", container)
        container.buffFrame:SetWidth((buffSize + spacing) * perRow - spacing)
        container.buffFrame:SetHeight(buffSize)
        container.buffFrame.fctPositionPoint = alignRight and "TOPRIGHT" or nil

        if options.buffAnchor == "BOTTOM" then
            container.buffFrame:SetPoint("TOP" .. side, parentFrame, "BOTTOM" .. side, 0, -4)
        else
            container.buffFrame:SetPoint("BOTTOM" .. side, parentFrame, "TOP" .. side, 0, 4)
        end

        for i = 1, maxBuffs do
            local btn = CreateAuraButton(container.buffFrame, container.buffFrame:GetName() .. i, buffSize, false)
            AnchorAuraButton(btn, container.buffFrame, i, buffSize, spacing, perRow, options.buffAnchor ~= "BOTTOM", alignRight)
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
        container.debuffFrame.fctPositionPoint = alignRight and "TOPRIGHT" or nil

        if options.debuffAnchor == "TOP" then
            local relative = container.buffFrame or parentFrame
            container.debuffFrame:SetPoint("BOTTOM" .. side, relative, "TOP" .. side, 0, 4)
        else
            local relative = (options.buffAnchor == "BOTTOM" and container.buffFrame) or parentFrame
            container.debuffFrame:SetPoint("TOP" .. side, relative, "BOTTOM" .. side, 0, -4)
        end

        for i = 1, maxDebuffs do
            local btn = CreateAuraButton(container.debuffFrame, container.debuffFrame:GetName() .. i, debuffSize, true)
            AnchorAuraButton(btn, container.debuffFrame, i, debuffSize, spacing, perRow, options.debuffAnchor == "TOP", alignRight)
            btn.unit = unit
            btn.auraIndex = i
            btn.container = container
            container.debuffButtons[i] = btn
        end
    end

    if options.moveKey then
        -- After a drag or a layout change, rows without a saved spot go back
        -- under their frame.
        local function Layout() Auras:LayoutContainer(container) end
        if container.buffFrame then
            FT.RestoreFramePosition(container.buffFrame, options.moveKey .. "_buffs", parentFrame)
            FT.RegisterFrameMover(container.buffFrame, options.moveKey .. "_buffs", "Buffs", parentFrame, Layout)
        end
        if container.debuffFrame then
            FT.RestoreFramePosition(container.debuffFrame, options.moveKey .. "_debuffs", parentFrame)
            FT.RegisterFrameMover(container.debuffFrame, options.moveKey .. "_debuffs", "Debuffs", parentFrame, Layout)
        end
    end
    return container
end

-- A new icon size for one row ("buff" or "debuff"): the icons take their grid
-- places again (AnchorAuraButton) and the row its new size.
local function ApplyRowSize(container, kind, size)
    local row = container[kind .. "Frame"]
    if not row then return end
    container[kind .. "Size"] = size
    local options = container.options
    local spacing, perRow = options.spacing or 3, options.perRow or 8
    local growsUp = kind == "buff" and options.buffAnchor ~= "BOTTOM" or kind == "debuff" and options.debuffAnchor == "TOP"
    row:SetWidth((size + spacing) * perRow - spacing)
    row:SetHeight(size)
    for i, btn in ipairs(container[kind .. "Buttons"]) do
        btn:SetWidth(size)
        btn:SetHeight(size)
        btn.border:SetWidth(size + 2)
        btn.border:SetHeight(size + 2)
        btn:ClearAllPoints()
        AnchorAuraButton(btn, row, i, size, spacing, perRow, growsUp, options.alignRight)
    end
    Auras:LayoutContainer(container)
end

function Auras:ApplyBuffSize(container, size)
    if container then ApplyRowSize(container, "buff", tonumber(size) or UF:GetBuffSize()) end
end

function Auras:ApplyDebuffSize(container, size)
    if container then ApplyRowSize(container, "debuff", tonumber(size) or UF:GetDebuffSize()) end
end

-- Preserve a running sweep until its actual aura identity/timing changes.
-- SetCooldown restarts the sweep on every call.
local function UpdateAuraTiming(btn, unitGUID, spellID, source, duration, expiration, now)
    local sourceGUID = source and UnitGUID(source)
    local changedIdentity = btn.timerUnitGUID ~= unitGUID or btn.timerSpellID ~= spellID or
        btn.timerSourceGUID ~= sourceGUID
    btn.timerUnitGUID, btn.timerSpellID, btn.timerSourceGUID = unitGUID, spellID, sourceGUID
    local timed = expiration and expiration > now and duration and duration > 0
    local start = timed and expiration - duration
    if timed then
        if changedIdentity or btn.sweepStart ~= start or btn.sweepDuration ~= duration then
            btn.cooldown:SetCooldown(start, duration)
            btn.sweepStart, btn.sweepDuration = start, duration
        end
        btn.cooldown:Show()
    else
        btn.cooldown:Clear()
        btn.sweepStart, btn.sweepDuration = nil, nil
    end
    -- Presence comes from the aura query. Unknown remote timing stays unknown.
    btn.expirationTime, btn.duration = timed and expiration or 0, timed and duration or 0
end

Auras.UpdateAuraTiming = UpdateAuraTiming

-- Every aura update rewrites its buttons: these write only what changed.
-- ResetAuraButton clears the remembered values with the widgets.
local function SetCount(btn, count)
    if not count or count <= 1 then count = nil end
    if btn.fctCount == count then return end
    btn.fctCount = count
    if count then
        btn.countText:SetText(count)
        btn.countText:Show()
    else
        btn.countText:SetText("")
        btn.countText:Hide()
    end
end
local function SetIcon(btn, icon)
    if btn.fctTexture ~= icon then btn.fctTexture = icon; btn.icon:SetTexture(icon) end
end
Auras.SetCount, Auras.SetIcon = SetCount, SetIcon

-- One row: the unit's auras of one kind (filter) in its buttons, in the plain
-- polarity order the tooltips use. A hidden aura takes no button.
local function FillRow(unit, buttons, slots, filter, shown, unitGUID, now)
    local used = 0
    if shown then
        local _, count = C_UnitAuras.GetAuraSlots(unit, filter, 48, nil, slots)
        for i = 1, count do
            if used >= #buttons then break end
            local name, icon, stacks, dispelType, duration, expirationTime, source, _, _, spellId =
                C_UnitAuras.UnitAuraBySlot(unit, slots[i])
            if not name then break end
            if icon and not FT.IsAuraHidden(name, unit, nil, source) then
                used = used + 1
                local btn = buttons[used]
                btn.unit, btn.auraIndex, btn.spellId, btn.isOccupied = unit, i, spellId, true
                SetIcon(btn, icon)
                SetCount(btn, stacks)
                UpdateAuraTiming(btn, unitGUID, spellId, source, duration, expirationTime, now)
                Auras.StyleBorder(btn, filter == "HARMFUL" and dispelType or nil)
                btn:Show()
            end
        end
    end
    for j = used + 1, #buttons do ResetAuraButton(buttons[j]) end
end

function Auras:UpdateContainer(container)
    local unit = container.unit
    if not UnitExists(unit) then
        self:ResetContainer(container)
        return
    end
    local showBuffs, showDebuffs
    if unit == "player" then showBuffs, showDebuffs = UF:IsShowPlayerBuffs(), UF:IsShowPlayerDebuffs()
    else showBuffs, showDebuffs = UF:IsShowTargetBuffs(), UF:IsShowTargetDebuffs() end
    if showBuffs then container.buffFrame:Show() else container.buffFrame:Hide() end
    if showDebuffs then container.debuffFrame:Show() else container.debuffFrame:Hide() end
    local now, unitGUID = GetTime(), UnitGUID(unit)
    FillRow(unit, container.buffButtons, container.buffSlots, "HELPFUL", showBuffs, unitGUID, now)
    FillRow(unit, container.debuffButtons, container.debuffSlots, "HARMFUL", showDebuffs, unitGUID, now)
    Auras:LayoutContainer(container)
end

local function HasSavedPosition(key)
    local positions = FostercareTweaks_Config.unitframe_positions
    return positions and positions[key]
end

local function IsAreaDragging(frame)
    return frame and frame.fctMover and frame.fctMover.dragging
end

local KINDS = { "buff", "debuff" }
-- The icons keep their grid places; each row takes the size of the icons it
-- shows (not while it is being dragged).
function Auras:LayoutContainer(container)
    local options = container.options
    local spacing, perRow = options.spacing or 3, options.perRow or 8
    for _, kind in ipairs(KINDS) do
        local row = container[kind .. "Frame"]
        if row then
            local count = 0
            for _, btn in ipairs(container[kind .. "Buttons"]) do if btn.isOccupied then count = count + 1 end end
            local size = container[kind .. "Size"]
            row.occupiedCount = count
            if not IsAreaDragging(row) then
                row:SetWidth(math.min(perRow, math.max(1, count)) * (size + spacing) - spacing)
                row:SetHeight(math.max(1, math.ceil(count / perRow)) * (size + spacing) - spacing)
            end
        end
    end
    local parent = container:GetParent()
    local key = options.moveKey
    if options.standard then
        local side = options.alignRight and "RIGHT" or "LEFT"
        local x = options.alignRight and -5 or 5
        -- The native ToT and FT castbar occupy the area below the target portrait.
        local y = options.alignRight and -34 or 12
        if container.buffFrame and not IsAreaDragging(container.buffFrame) and not HasSavedPosition(key .. "_buffs") then
            container.buffFrame:ClearAllPoints()
            container.buffFrame:SetPoint("TOP" .. side, parent, "BOTTOM" .. side, x, y)
        end
        if container.debuffFrame and not IsAreaDragging(container.debuffFrame) and not HasSavedPosition(key .. "_debuffs") then
            container.debuffFrame:ClearAllPoints()
            local buffs = container.buffFrame
            if buffs and buffs:IsShown() and (buffs.occupiedCount or 0) > 0 then
                container.debuffFrame:SetPoint("TOP" .. side, buffs, "BOTTOM" .. side, 0, -4)
            else
                container.debuffFrame:SetPoint("TOP" .. side, parent, "BOTTOM" .. side, x, y)
            end
        end
    end
    if container.unit == "target" and FT.LayoutTargetCastbar then
        FT.LayoutTargetCastbar()
    end
end

function Auras:AttachToTargetFrame()
    if UF.blizzTargetAuras then return UF.blizzTargetAuras end

    -- Match the standard player row capacity; target rows grow from the portrait side.
    local container = Auras:CreateAuraContainer(TargetFrame, "target", 32, 48, {
        standard = true, moveKey = "standard_target", alignRight = true,
        spacing = 3,
        perRow = 8,
        buffAnchor = "BOTTOM",
        debuffAnchor = "BOTTOM",
    })
    container:ClearAllPoints()
    container:SetPoint("TOPRIGHT", TargetFrame, "BOTTOMRIGHT", -5, -34)
    container:SetFrameStrata("LOW")

    UF.blizzTargetAuras = container
    return container
end

local function SuppressBlizzTargetAuras()
    for i = 1, 5 do
        local btn = _G["TargetFrameBuff" .. i]
        if btn and btn:IsShown() then btn:Hide() end
    end
    for i = 1, 16 do
        local btn = _G["TargetFrameDebuff" .. i]
        if btn and btn:IsShown() then btn:Hide() end
    end
end

function Auras:UpdateBlizzTargetAuras()
    local container = Auras:AttachToTargetFrame()
    if not TargetFrame:IsShown() or not UnitExists("target") then
        if container:IsShown() then
            container:Hide()
            Auras:ResetContainer(container)
        end
        return
    end
    SuppressBlizzTargetAuras()
    container:Show()
    Auras:UpdateContainer(container)
end

-- Native TargetofTarget_Update also calls this updater on its render path.
-- Only suppress its stock buttons here; aura scans belong to unit events.
hooksecurefunc("TargetDebuffButton_Update", SuppressBlizzTargetAuras)

-- Independent event dispatcher for standard target aura updating
local auraEventFrame = CreateFrame("Frame", "FCTweaksAuraEventFrame", UIParent)
auraEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
-- UNIT_AURA_DELTA comes once per unit token with the changed aura instance
-- IDs. The unit filter drops the target's raid, nameplate and mark copies.
auraEventFrame:RegisterUnitEvent("UNIT_AURA_DELTA", "player", "target")

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
    container:Show()
    Auras:UpdateContainer(container)
end

-- A refresh or stack change rewrites only its own button. A new or lost aura
-- moves the others, so the row is read again; so is a change with no button.
local deltaAura = {}
local NO_BUTTONS = {}
local function UpdateChangedAuras(container, unit, ids)
    local now, unitGUID = GetTime(), UnitGUID(unit)
    for i = 1, #ids do
        local d = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, ids[i], deltaAura)
        if not d then return false end
        -- A hidden aura has no button; its refresh changes nothing here.
        local found = FT.IsAuraHidden(d.name, unit, nil, d.sourceUnit)
        for _, btn in ipairs(found and NO_BUTTONS or d.isHelpful and container.buffButtons or container.debuffButtons) do
            if btn.isOccupied and btn.spellId == d.spellId and btn.timerSourceGUID == d.sourceGUID then
                SetCount(btn, d.applications)
                UpdateAuraTiming(btn, unitGUID, d.spellId, d.sourceUnit, d.duration, d.expirationTime, now)
                found = true
                break
            end
        end
        if not found then return false end
    end
    return true
end

auraEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
FT.SetEventHandler(auraEventFrame, function(_, ev, unit, info)
    if ev == "UNIT_AURA_DELTA" then
        local container = unit == "player" and UF.blizzPlayerAuras or UF.blizzTargetAuras
        local updated = info.updatedAuraInstanceIDs
        if container and container:IsShown() and updated and not info.isFullUpdate
            and not info.addedAuraInstanceIDs and not info.removedAuraInstanceIDs
            and UpdateChangedAuras(container, unit, updated) then return end
        if unit == "player" then Auras:UpdateBlizzPlayerAuras() else Auras:UpdateBlizzTargetAuras() end
    elseif ev == "PLAYER_TARGET_CHANGED" then
        Auras:UpdateBlizzTargetAuras()
    elseif ev == "PLAYER_ENTERING_WORLD" then
        Auras:UpdateBlizzPlayerAuras()
        Auras:UpdateBlizzTargetAuras()
    end
end)
