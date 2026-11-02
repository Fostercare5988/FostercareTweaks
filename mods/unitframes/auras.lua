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
    local cfg = FostercareTweaks_Config or {}
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

function Auras:RefreshBorders()
    for _, key in ipairs({ "blizzPlayerAuras", "blizzTargetAuras" }) do
        local container = UF[key]
        if container then
            for _, kind in ipairs({ "buffButtons", "debuffButtons" }) do
                for _, btn in ipairs(container[kind] or {}) do
                    if btn:IsShown() then Auras.StyleBorder(btn, btn.borderDispelType) end
                end
            end
        end
    end
    if UF.RefreshRaidAuraBorders then UF:RefreshRaidAuraBorders() end
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
    btn.cooldown.noCooldownCount = true
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
    if not container then return end
    for _, btn in ipairs(container.buffButtons or {}) do ResetAuraButton(btn) end
    for _, btn in ipairs(container.debuffButtons or {}) do ResetAuraButton(btn) end
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
            FT.RegisterFrameMover(container.buffFrame, options.moveKey .. "_buffs", "Buffs", parentFrame, Layout, Layout)
        end
        if container.debuffFrame then
            FT.RestoreFramePosition(container.debuffFrame, options.moveKey .. "_debuffs", parentFrame)
            FT.RegisterFrameMover(container.debuffFrame, options.moveKey .. "_debuffs", "Debuffs", parentFrame, Layout, Layout)
        end
    end
    return container
end

function Auras:ApplyBuffSize(container, newSize)
    if not container or not container.buffFrame or not container.buffButtons then return end
    newSize = tonumber(newSize) or UF:GetBuffSize()
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
        btn:ClearAllPoints()
        AnchorAuraButton(btn, container.buffFrame, i, newSize, spacing, perRow,
            container.options and container.options.buffAnchor ~= "BOTTOM", container.options and container.options.alignRight)
    end
end

function Auras:ApplyDebuffSize(container, newSize)
    if not container or not container.debuffFrame or not container.debuffButtons then return end
    newSize = tonumber(newSize) or UF:GetDebuffSize()
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
        btn:ClearAllPoints()
        AnchorAuraButton(btn, container.debuffFrame, i, newSize, spacing, perRow,
            container.options and container.options.debuffAnchor == "TOP", container.options and container.options.alignRight)
    end
    Auras:LayoutContainer(container)
end

function Auras:ApplyAuraSize(container, newSize)
    Auras:ApplyBuffSize(container, newSize)
    Auras:ApplyDebuffSize(container, newSize)
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

function Auras:UpdateContainer(container)
    if not container or not container.unit then return end
    local unit = container.unit
    if not UnitExists(unit) then
        self:ResetContainer(container)
        return
    end

    local showBuffs = true
    if unit == "player" and not UF:IsShowPlayerBuffs() then
        showBuffs = false
    elseif unit == "target" and not UF:IsShowTargetBuffs() then
        showBuffs = false
    end

    if container.buffFrame then
        if not showBuffs then
            container.buffFrame:Hide()
        else
            container.buffFrame:Show()
        end
    end

    local showDebuffs = true
    if unit == "player" and not UF:IsShowPlayerDebuffs() then
        showDebuffs = false
    elseif unit == "target" and not UF:IsShowTargetDebuffs() then
        showDebuffs = false
    end

    if container.debuffFrame then
        if not showDebuffs then
            container.debuffFrame:Hide()
        else
            container.debuffFrame:Show()
        end
    end


    local now = GetTime()
    local unitGUID = UnitGUID(unit)

    -- Update Buffs
    if container.buffButtons then
        local maxBuffs = #container.buffButtons
        if not showBuffs then
            for _, btn in ipairs(container.buffButtons) do
                ResetAuraButton(btn)
            end
        else
            local btnIdx = 1
            -- Slots are ordered like the plain polarity index. Refill this
            -- scratch buffer on every refresh; opaque slots are not identities.
            local slots = container.buffSlots
            local countSlots = 0
            if maxBuffs > 0 then
                local continuation
                continuation, countSlots = C_UnitAuras.GetAuraSlots(unit, "HELPFUL", 48, nil, slots)
            end
            for i = 1, countSlots do
                if btnIdx > maxBuffs then break end
                local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = C_UnitAuras.UnitAuraBySlot(unit, slots[i])
                if not name then break end -- end of buffs

                if icon and not FT.IsAuraHidden(name, unit) then
                    local btn = container.buffButtons[btnIdx]
                    if btn then
                        btn.unit = unit
                        btn.auraIndex = i
                        btn.spellId = spellId
                        btn.isOccupied = true

                        SetIcon(btn, icon)
                        SetCount(btn, count)
                        UpdateAuraTiming(btn, unitGUID, spellId, source, duration, expirationTime, now)

                        Auras.StyleBorder(btn)
                        btn:Show()

                        btnIdx = btnIdx + 1
                    end
                end
            end

            for j = btnIdx, maxBuffs do
                ResetAuraButton(container.buffButtons[j])
            end
        end
    end

    -- Update Debuffs
    if container.debuffButtons then
        local maxDebuffs = #container.debuffButtons
        if not showDebuffs then
            for _, btn in ipairs(container.debuffButtons) do
                ResetAuraButton(btn)
            end
        else
            local btnIdx = 1
            local filter = "HARMFUL" -- Tooltip requires an index in the unfiltered polarity list.

            local slots = container.debuffSlots
            local countSlots = 0
            if maxDebuffs > 0 then
                local continuation
                continuation, countSlots = C_UnitAuras.GetAuraSlots(unit, filter, 48, nil, slots)
            end
            for i = 1, countSlots do
                if btnIdx > maxDebuffs then break end
                local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer = C_UnitAuras.UnitAuraBySlot(unit, slots[i])
                if not name then break end -- end of debuffs

                if icon and not FT.IsAuraHidden(name, unit) then
                    local btn = container.debuffButtons[btnIdx]
                    if btn then
                        btn.unit = unit
                        btn.auraIndex = i
                        btn.spellId = spellId
                        btn.isOccupied = true

                        SetIcon(btn, icon)
                        SetCount(btn, count)
                        Auras.StyleBorder(btn, dispelType)

                        UpdateAuraTiming(btn, unitGUID, spellId, source, duration, expirationTime, now)

                        btn:Show()
                        btnIdx = btnIdx + 1
                    end
                end
            end

            for j = btnIdx, maxDebuffs do
                ResetAuraButton(container.debuffButtons[j])
            end
        end
    end
    Auras:LayoutContainer(container)
end

local function HasSavedPosition(key)
    local positions = FostercareTweaks_Config and FostercareTweaks_Config.unitframe_positions
    return key and positions and positions[key]
end

local function NormalizeRightAnchor(frame, key, parent)
    local p = HasSavedPosition(key)
    if not p or p.point ~= "TOPLEFT" or not p.relPoint or not tonumber(p.x) or not tonumber(p.y) then return end
    -- Preserve the current rectangle, then let future count/size changes grow left.
    p.point = "TOPRIGHT"
    p.x = tonumber(p.x) + frame:GetWidth()
    frame:ClearAllPoints()
    frame:SetPoint(p.point, parent, p.relPoint, p.x, p.y)
end

local function IsAreaDragging(frame)
    return frame and frame.fctMover and frame.fctMover.dragging
end

local KINDS = { "buff", "debuff" }
function Auras:LayoutContainer(container)
    if not container then return end
    local options = container.options or {}
    local spacing, perRow = options.spacing or 3, options.perRow or 8
    for _, kind in ipairs(KINDS) do
        local row, buttons = container[kind .. "Frame"], container[kind .. "Buttons"]
        if row then
            local count = 0
            for _, btn in ipairs(buttons) do if btn.isOccupied then count = count + 1 end end
            local size = container[kind .. "Size"]
            row.occupiedCount = count
            local rowW, rowH = math.min(perRow, math.max(1, count)) * (size + spacing) - spacing,
                math.max(1, math.ceil(count / perRow)) * (size + spacing) - spacing
            if kind == "debuff" then
                local limit = perRow * (size + spacing) - spacing
                local x, y, lineH, widest = 0, 0, 0, 0
                for i, btn in ipairs(buttons) do
                    local iconSize = size
                    if btn:GetWidth() ~= iconSize then
                        btn:SetWidth(iconSize); btn:SetHeight(iconSize)
                        btn.border:SetWidth(iconSize + 2); btn.border:SetHeight(iconSize + 2)
                    end
                    if btn.isOccupied then
                        if x > 0 and x + iconSize > limit then y, x, lineH = y + lineH + spacing, 0, 0 end
                        local point = (options.debuffAnchor == "TOP" and "BOTTOM" or "TOP") .. (options.alignRight and "RIGHT" or "LEFT")
                        btn:ClearAllPoints()
                        btn:SetPoint(point, row, point, options.alignRight and -x or x,
                            options.debuffAnchor == "TOP" and y or -y)
                        lineH = math.max(lineH, iconSize)
                        widest = math.max(widest, x + iconSize)
                        x = x + iconSize + spacing
                    end
                end
                rowW, rowH = math.max(size, widest), math.max(size, y + lineH)
            end
            -- Refresh aura identity while the pointer owns the area's geometry.
            -- The mover reconciles current bounds immediately after saving the drop.
            if not IsAreaDragging(row) then
                row:SetWidth(rowW)
                row:SetHeight(rowH)
                if options.alignRight and options.moveKey then
                    NormalizeRightAnchor(row, options.moveKey .. "_" .. kind .. "s", container:GetParent())
                end
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
        local found = FT.IsAuraHidden(d.name, unit)
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
