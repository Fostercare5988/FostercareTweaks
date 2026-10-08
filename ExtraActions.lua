-- Independent actions for Extra Rows 2-7. The 120 native action slots and
-- class/stealth pages remain owned by the client. ClassicAPI 1.15.15 supplies
-- cursor descriptors, button attributes and PreClick/PostClick dispatch.
local FT = FostercareTweaks
if not FT then return end

local EA = { bars = {}, visible = {}, generation = 0 }
FT.ExtraActions = EA
local itemCounts, reagentSpells, castCounts = {}, {}, {}
-- These four signals retain attack state while all rows are hidden. They do
-- no painting, queries or timer work; combat state is not autoattack state.
local stateEvents = {"PLAYER_ENTER_COMBAT", "PLAYER_LEAVE_COMBAT", "START_AUTOREPEAT_SPELL", "STOP_AUTOREPEAT_SPELL"}
local events = {
    "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_ENTER_COMBAT", "PLAYER_LEAVE_COMBAT",
    "START_AUTOREPEAT_SPELL", "STOP_AUTOREPEAT_SPELL", "SPELLS_CHANGED",
    "UPDATE_BINDINGS", "MODIFIER_STATE_CHANGED", "PLAYER_TARGET_CHANGED", "PLAYER_AURAS_CHANGED",
    "ACTIONBAR_UPDATE_STATE", "ACTIONBAR_UPDATE_USABLE", "ACTIONBAR_UPDATE_COOLDOWN",
    "SPELL_UPDATE_COOLDOWN", "BAG_UPDATE_DELAYED", "UNIT_INVENTORY_CHANGED", "ITEM_DATA_LOAD_RESULT", "CURSOR_CHANGED",
}

local function Actions(bar)
    local config = FT.ActionBars:GetSettings(bar.definition.id)
    if type(config.actions) ~= "table" then config.actions = {} end
    return config.actions
end

local function ValidID(value)
    -- Engine item/spell lookup arguments are signed 32-bit integers. Reject
    -- corrupt saved values before they reach DLL/native conversions.
    return type(value) == "number" and value == value and value > 0
        and value < 2147483648 and value == math.floor(value)
end

local function Descriptor(button)
    local action = Actions(button.fctBar)[button:GetID()]
    if type(action) ~= "table" then return nil end
    if (action.kind == "spell" or action.kind == "item") and ValidID(action.id) then return action end
    -- Retain unsupported saved descriptors visibly and fail closed. Native
    -- bars, including Extra Row 1, keep their ordinary macro execution.
    if action.kind == "macro" then return action end
end

local function Visible(bar)
    return FT.ActionBars.enabled and bar.visible and bar.holder:IsVisible()
end

local function SetShown(frame, shown)
    if shown then
        if not frame:IsShown() then frame:Show() end
    elseif frame:IsShown() then frame:Hide() end
end

local function Message(text)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Extra Rows: " .. text) end
end

local function CanArrange()
    if UnitAffectingCombat("player") then
        Message("Change actions after combat.")
        return false
    end
    if LOCK_ACTIONBAR == "1" then
        Message("Unlock action bars to change these actions.")
        return false
    end
    return true
end

local function SpellExecution(id)
    local slot, book = FindSpellBookSlotByID(id)
    if not slot or book ~= "spell" then return nil end
    local name, rank = GetSpellName(slot, book)
    if not name then return nil end
    -- A numeric CastSpellByName string selects the highest known rank. The
    -- exact book name/rank preserves the spell the player actually dropped.
    return rank and rank ~= "" and (name .. "(" .. rank .. ")") or name
end

local function SetAttribute(button, name, value)
    if button:GetAttribute(name) ~= value then button:SetAttribute(name, value) end
end

local function ApplyExecution(button)
    local action = Descriptor(button)
    local kind, value
    if action and action.kind == "spell" then
        value = SpellExecution(action.id)
        kind = value and "spell"
    elseif action and action.kind == "item" then
        kind, value = "item", "item:" .. action.id
    end
    SetAttribute(button, "spell", kind == "spell" and value or nil)
    SetAttribute(button, "item", kind == "item" and value or nil)
    SetAttribute(button, "macro", nil)
    SetAttribute(button, "macrotext", nil)
    -- Set type after the owned OnClick. ClassicAPI wraps that script and owns
    -- configured clicks, falling through to it only for unconfigured actions.
    SetAttribute(button, "type1", kind)
    SetAttribute(button, "type2", kind)
end

local function SetText(region, text)
    if region.fctText ~= text then region.fctText = text; region:SetText(text) end
end

local function SetTexture(region, texture)
    if region.fctTexture ~= texture then region.fctTexture = texture; region:SetTexture(texture) end
end

local function UpdateTooltip(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if button.fctSpellID then GameTooltip:SetSpellByID(button.fctSpellID)
    elseif button.fctItemID then GameTooltip:SetHyperlink("item:" .. button.fctItemID)
    else GameTooltip:SetText("Extra action") end
    local action = Descriptor(button)
    if not action then GameTooltip:AddLine("Drop a player spell or item here.", 0.8, 0.8, 0.8) end
    if action and action.kind == "macro" then
        GameTooltip:AddLine("Keep macros on native bars, including Extra Row 1.", 1, 0.7, 0.7)
    elseif action and not button:GetAttribute("type1") then
        GameTooltip:AddLine("This player spell or item is unavailable.", 1, 0.7, 0.7)
    end
    GameTooltip:AddLine("Drag between Extra Rows 2-7; Shift-right-click clears.", 0.75, 0.75, 0.75)
    GameTooltip:Show()
end

local function ItemCount(id)
    local count = itemCounts[id]
    if count == nil then count = C_Item.GetItemCount(id, false, true); itemCounts[id] = count end
    return count
end

local function Display(button, full)
    local action = Descriptor(button)
    local spellID, itemID, icon
    if action and action.kind == "spell" then
        spellID = action.id
        if full or button.fctSpellID ~= spellID then
            local _, _, texture = GetSpellInfo(spellID)
            icon = texture
        else icon = button.icon.fctTexture end
    elseif action and action.kind == "item" then
        itemID = action.id
        icon = full and C_Item.GetItemIconByID(itemID) or button.icon.fctTexture
    end
    if spellID ~= button.fctSpellID or itemID ~= button.fctItemID then full = true end
    button.fctSpellID, button.fctItemID = spellID, itemID
    SetTexture(button.icon, icon or (action and "Interface\\Icons\\INV_Misc_QuestionMark"))
    SetShown(button.icon, action ~= nil)
    SetShown(button, action ~= nil or button.fctBar.showEmpty == true)
    local usable, noMana, current, inRange, count = false, false, false, nil, ""
    if spellID then
        usable, noMana = C_Spell.IsSpellUsable(spellID)
        inRange = C_Spell.IsSpellInRange(spellID, "target")
        current = C_Spell.IsCurrentSpell(spellID)
        if C_Spell.IsAutoAttackSpell(spellID) then current = EA.meleeActive == true
        elseif C_Spell.IsRangedAutoAttackSpell(spellID) then current = EA.rangedActive == true end
        if full and FT.IsEnabled("Reagent Counter") then
            if reagentSpells[spellID] == nil then
                local list = C_Spell.GetSpellReagents(spellID)
                reagentSpells[spellID] = list and list[1] and true or false
            end
            if reagentSpells[spellID] then
                local n = castCounts[spellID]
                if n == nil then n = C_Spell.GetSpellCastCount(spellID); castCounts[spellID] = n end
                count = n > 999 and "*" or tostring(n)
            end
        elseif not full then count = button.count.fctText or "" end
    elseif itemID then
        usable, noMana = C_Item.IsUsableItem(itemID)
        inRange = C_Item.IsItemInRange(itemID, "target")
        if full then
            if C_Item.IsConsumableItem(itemID) then
                local n = ItemCount(itemID)
                count = n > 999 and "*" or tostring(n)
            end
        else count = button.count.fctText or "" end
    end
    SetText(button.count, count)
    if current ~= button.fctCurrent then button.fctCurrent = current; button:SetChecked(current and 1 or nil) end
    local color = usable and "usable" or noMana and "mana" or "unusable"
    if color ~= button.fctColor then
        button.fctColor = color
        if usable then button.icon:SetVertexColor(1, 1, 1)
        elseif noMana then button.icon:SetVertexColor(0.5, 0.5, 1)
        else button.icon:SetVertexColor(0.4, 0.4, 0.4) end
    end
    if button.fctInRange ~= inRange then
        button.fctInRange = inRange
        if inRange == false then button.hotkey:SetTextColor(1, 0.1, 0.1)
        else button.hotkey:SetTextColor(0.6, 0.6, 0.6) end
    end
    SetShown(button.flash, current and math.floor(GetTime() / 0.4) % 2 == 0)
    if full then
        local start, duration, enable = 0, 0, 0
        if spellID then
            local slot, book = FindSpellBookSlotByID(spellID)
            if slot then start, duration, enable = GetSpellCooldown(slot, book) end
        elseif itemID then start, duration, enable = GetItemCooldown(itemID) end
        if start ~= button.fctStart or duration ~= button.fctDuration or enable ~= button.fctEnable then
            button.fctStart, button.fctDuration, button.fctEnable = start, duration, enable
            CooldownFrame_SetTimer(button.cooldown, start, duration, enable)
        end
        ApplyExecution(button)
    end
    if GameTooltip:IsOwned(button) then UpdateTooltip(button) end
end

local function UpdateHotkey(button)
    local command = "FCTWEAKSEXTRA" .. button.fctBar.definition.extraIndex .. "_" .. button:GetID()
    local key = GetBindingKey(command)
    SetText(button.hotkey, key and GetBindingText(key, "KEY_", 1) or "")
end

local function NativeCursorPresent()
    return GetCursorInfo() ~= nil or CursorHasItem() or CursorHasSpell() or CursorHasMoney()
end

function EA:CancelDrag()
    self.drag = nil
    if self.dragFrame then
        self.dragFrame:SetScript("OnUpdate", nil)
        self.dragFrame:Hide()
    end
end

function EA:StartDrag(button)
    if not Visible(button.fctBar) or not CanArrange() or NativeCursorPresent() then return false end
    local action = Descriptor(button)
    if not action then return false end
    self:CancelDrag()
    self.drag = { source = button, action = action }
    if not self.dragFrame then
        local frame = CreateFrame("Frame", "FCTweaksExtraActionDrag", UIParent)
        self.dragFrame = frame
        frame:SetWidth(36); frame:SetHeight(36)
        frame:SetFrameStrata("TOOLTIP")
        frame:EnableMouse(false)
        frame.icon = frame:CreateTexture(nil, "OVERLAY")
        frame.icon:SetAllPoints(frame)
        frame:SetScript("OnHide", function() EA:CancelDrag() end)
        table.insert(UISpecialFrames, "FCTweaksExtraActionDrag")
    end
    local frame = self.dragFrame
    frame.icon:SetTexture(button.icon.fctTexture)
    local function FollowCursor()
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        if frame.fctX ~= x or frame.fctY ~= y or frame.fctScale ~= scale then
            frame.fctX, frame.fctY, frame.fctScale = x, y, scale
            frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
        end
    end
    FollowCursor()
    frame:SetScript("OnUpdate", FollowCursor)
    frame:Show()
    GameTooltip:Hide()
    return true
end

local function CursorAction()
    local kind, value, book, spellID = GetCursorInfo()
    if kind == "spell" and book == "spell" and ValidID(spellID)
        and SpellExecution(spellID) and not C_Spell.IsSpellPassive(spellID) then
        return { kind = "spell", id = spellID }
    elseif kind == "item" and ValidID(value) then
        return { kind = "item", id = value }
    end
end

function EA:Receive(button)
    if not Visible(button.fctBar) or not CanArrange() then return false end
    if self.drag and NativeCursorPresent() then self:CancelDrag() end
    if self.drag then
        local drag = self.drag
        local source = drag.source
        if Actions(source.fctBar)[source:GetID()] ~= drag.action or not Visible(source.fctBar) then
            self:CancelDrag(); return false
        end
        if source ~= button then
            local destination = Actions(button.fctBar)
            Actions(source.fctBar)[source:GetID()] = destination[button:GetID()]
            destination[button:GetID()] = drag.action
        end
        self:CancelDrag()
        self:RefreshBar(source.fctBar, true)
        if source.fctBar ~= button.fctBar then self:RefreshBar(button.fctBar, true) end
        return true
    end
    local action = CursorAction()
    if not action then
        if NativeCursorPresent() then Message("Use a player spell or item. Keep macros on native bars, including Extra Row 1.") end
        return false
    end
    -- The DLL's PickupItem moves real equipment/bag items. Do not use it to
    -- manufacture a displaced action icon. Occupied native-cursor imports are
    -- refused; owned drags support exact swaps without inventory side effects.
    if Descriptor(button) then
        Message("Move or clear this extra action before replacing it.")
        return false
    end
    Actions(button.fctBar)[button:GetID()] = action
    ClearCursor()
    self:RefreshBar(button.fctBar, true)
    return true
end

function EA:Clear(button)
    if not Visible(button.fctBar) or not CanArrange() then return false end
    self:CancelDrag()
    Actions(button.fctBar)[button:GetID()] = nil
    self:RefreshBar(button.fctBar, true)
    return true
end

local function RefreshVisible(full)
    for bar in pairs(EA.visible) do
        if Visible(bar) then
            for _, button in ipairs(bar.buttons) do
                if full or Descriptor(button) then Display(button, full) end
            end
        end
    end
end

local function QueueRefresh()
    if EA.pending then return end
    local generation = EA.generation
    EA.pending = true
    C_Timer.After(0, function()
        if generation ~= EA.generation then return end
        EA.pending = nil
        RefreshVisible(true)
    end)
end

local function SyncOwner()
    local anyVisible, anyActions = false, false
    for bar in pairs(EA.visible) do
        if Visible(bar) then
            anyVisible = true
            for _, button in ipairs(bar.buttons) do
                local action = Descriptor(button)
                if action and action.kind ~= "macro" then anyActions = true; break end
            end
        else EA.visible[bar] = nil end
    end
    if anyVisible and not EA.listening then
        EA.listening = true
        for _, ev in ipairs(events) do EA.controller:RegisterEvent(ev) end
        table.wipe(itemCounts)
        table.wipe(castCounts)
    elseif not anyVisible and EA.listening then
        EA.listening = nil
        EA.controller:UnregisterAllEvents()
        for _, ev in ipairs(stateEvents) do EA.controller:RegisterEvent(ev) end
        EA.generation = EA.generation + 1
        EA.pending = nil
        EA:CancelDrag()
    end
    if anyActions and not EA.ticker then
        local generation = EA.generation
        EA.ticker = C_Timer.NewTicker(0.2, function()
            if generation == EA.generation then RefreshVisible(false) end
        end)
    elseif not anyActions and EA.ticker then
        EA.ticker:Cancel(); EA.ticker = nil
        -- Reject a canceled timer callback even if a new timer starts soon.
        EA.generation = EA.generation + 1
        EA.pending = nil
    end
end

function EA:RefreshBar(bar, force)
    if not bar.definition.custom then return end
    self.bars[bar] = true
    if Visible(bar) then
        if not self.visible[bar] then
            -- Hidden rows miss item, cooldown and binding changes.
            -- Reconcile before painting, even if another row kept listening.
            force = true
            table.wipe(itemCounts)
            table.wipe(castCounts)
        end
        self.visible[bar] = true
    else self.visible[bar] = nil end
    if self.drag and self.drag.source.fctBar == bar and not Visible(bar) then self:CancelDrag() end
    for _, button in ipairs(bar.buttons) do
        if not Visible(bar) and button.fctPressed then button.fctPressed = nil; button:SetButtonState("NORMAL") end
        local action = Actions(bar)[button:GetID()]
        if force or button.fctDescriptor ~= action or button.fctShowEmpty ~= bar.showEmpty then
            button.fctDescriptor, button.fctShowEmpty = action, bar.showEmpty
            Display(button, true)
            UpdateHotkey(button)
        end
    end
    SyncOwner()
end

function EA:Binding(bar, index, down)
    local button = bar and bar.buttons[index]
    if not button then return end
    if down then
        if Visible(bar) then button.fctPressed = true; button:SetButtonState("PUSHED") end
    else
        local pressed = button.fctPressed
        button.fctPressed = nil
        button:SetButtonState("NORMAL")
        if pressed and Visible(bar) then
            button.fctBinding = true
            button:Click("LeftButton")
            button.fctBinding = nil
        end
    end
end

local function InitializeController()
    if EA.controller then return end
    EA.controller = CreateFrame("Frame", "FCTweaksExtraActionController", UIParent)
    FT.SetEventHandler(EA.controller, function(_, ev, unit, isPlayer)
        if ev == "PLAYER_ENTER_COMBAT" then EA.meleeActive = true
        elseif ev == "PLAYER_LEAVE_COMBAT" then EA.meleeActive = false
        elseif ev == "START_AUTOREPEAT_SPELL" then EA.rangedActive = true
        elseif ev == "STOP_AUTOREPEAT_SPELL" then EA.rangedActive = false end
        if not EA.listening then return end
        if ev == "UNIT_INVENTORY_CHANGED" and unit ~= "player" and isPlayer ~= 1 and isPlayer ~= true
            and unit ~= UnitGUID("player") then return end
        if ev == "ITEM_DATA_LOAD_RESULT" then
            local used = false
            for bar in pairs(EA.visible) do
                for _, button in ipairs(bar.buttons) do
                    local action = Descriptor(button)
                    if button.fctItemID == unit or (action and action.kind == "item" and action.id == unit) then used = true; break end
                end
                if used then break end
            end
            if not used then return end
        end
        if ev == "PLAYER_REGEN_DISABLED" then EA:CancelDrag()
        elseif ev == "CURSOR_CHANGED" then
            if EA.drag and NativeCursorPresent() then EA:CancelDrag() end
            return
        end
        if ev == "UPDATE_BINDINGS" then
            for bar in pairs(EA.visible) do for _, button in ipairs(bar.buttons) do UpdateHotkey(button) end end
            return
        end
        if ev == "BAG_UPDATE_DELAYED" or ev == "UNIT_INVENTORY_CHANGED" or ev == "PLAYER_ENTERING_WORLD" then
            table.wipe(itemCounts); table.wipe(castCounts)
        end
        QueueRefresh()
    end)
    for _, ev in ipairs(stateEvents) do EA.controller:RegisterEvent(ev) end
end

function EA:CreateButton(bar, id)
    InitializeController()
    if not bar.fctExtraVisibilityHooked then
        bar.fctExtraVisibilityHooked = true
        FT.HookScript(bar.holder, "OnShow", function() EA:RefreshBar(bar) end)
        FT.HookScript(bar.holder, "OnHide", function() EA:RefreshBar(bar) end)
    end
    local name = bar.definition.prefix .. "Button" .. id
    local button = CreateFrame("CheckButton", name, bar.holder)
    button.fctBar, button.fctExtraOwner = bar, self
    button:SetID(id)
    button:SetWidth(36); button:SetHeight(36)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button.icon = button:CreateTexture(name .. "Icon", "BACKGROUND")
    button.icon:SetAllPoints(button)
    button.flash = button:CreateTexture(name .. "Flash", "ARTWORK")
    button.flash:SetAllPoints(button)
    button.flash:SetTexture("Interface\\Buttons\\UI-QuickslotRed")
    button.flash:Hide()
    button.hotkey = button:CreateFontString(name .. "HotKey", "ARTWORK", "NumberFontNormalSmallGray")
    button.hotkey:SetWidth(36); button.hotkey:SetHeight(10)
    button.hotkey:SetPoint("TOPLEFT", button, "TOPLEFT", -2, -2)
    button.hotkey:SetJustifyH("RIGHT")
    button.count = button:CreateFontString(name .. "Count", "ARTWORK", "NumberFontNormal")
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    button.cooldown = CreateFrame("Model", name .. "Cooldown", button, "CooldownFrameTemplate")
    button.cooldown:SetWidth(36); button.cooldown:SetHeight(36)
    button.cooldown:SetPoint("CENTER", button, "CENTER", 0, -1)
    button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
    local normal = button:GetNormalTexture()
    normal:SetWidth(FT.IsEnabled("Floating Actionbar") and 60 or 66)
    normal:SetHeight(FT.IsEnabled("Floating Actionbar") and 60 or 66)
    normal:ClearAllPoints(); normal:SetPoint("CENTER", button, "CENTER", 0, -1)
    button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    button:GetHighlightTexture():SetBlendMode("ADD")
    button:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")
    button:GetCheckedTexture():SetBlendMode("ADD")
    if FT.IsEnabled("Floating Actionbar") then FT.AddBorder(button, 3, {r=0.7,g=0.7,b=0.7,a=1}) end
    button:SetScript("OnClick", function()
        if not Visible(bar) or not button.fctArrangeClick then return end
        if EA.drag or NativeCursorPresent() then EA:Receive(button)
        elseif IsShiftKeyDown() and arg1 == "RightButton" then EA:Clear(button)
        elseif IsShiftKeyDown() then EA:StartDrag(button) end
    end)
    button:SetScript("PreClick", function()
        -- Disable the previous executable action before any fallible lookup.
        SetAttribute(button, "type1", nil); SetAttribute(button, "type2", nil)
        button.fctArrangeClick = not button.fctBinding and (EA.drag ~= nil or NativeCursorPresent() or IsShiftKeyDown())
        if Visible(bar) and not button.fctArrangeClick then ApplyExecution(button) end
    end)
    button:SetScript("PostClick", function()
        button.fctArrangeClick = nil
        SetAttribute(button, "type1", nil); SetAttribute(button, "type2", nil)
        ApplyExecution(button)
        Display(button, false)
        -- Native CheckButton toggles itself before PreClick. Reassert the
        -- authoritative active spell state even if the cached state is equal.
        button:SetChecked(button.fctCurrent and 1 or nil)
    end)
    button:SetScript("OnDragStart", function() EA:StartDrag(button) end)
    button:SetScript("OnReceiveDrag", function() EA:Receive(button) end)
    button:SetScript("OnDragStop", function()
        local destination = GetMouseFocus()
        if destination and destination.fctExtraOwner == EA then EA:Receive(destination) else EA:CancelDrag() end
    end)
    button:SetScript("OnEnter", function() UpdateTooltip(button) end)
    button:SetScript("OnLeave", function() if GameTooltip:IsOwned(button) then GameTooltip:Hide() end end)
    button:SetScript("OnHide", function()
        if button.fctPressed then button:SetButtonState("NORMAL") end
        button.fctPressed = nil
        if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
    end)
    button:Hide()
    return button
end
