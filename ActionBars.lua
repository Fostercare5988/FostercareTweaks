-- FostercareTweaks action-bar layouts. Native buttons keep their parents,
-- action slots, scripts and binding names; the main/bonus bar keeps native paging.
local FT = FostercareTweaks
if not FT then return end

local AB = { bars = {}, enabled = false, editing = false, normalButtons = {} }
FT.ActionBars = AB
AB.definitions = {
    { id = "main", title = "Main / Stealth", prefix = "Action", columns = 12 },
    { id = "bottomleft", title = "Bottom Left", prefix = "MultiBarBottomLeft", columns = 12 },
    { id = "bottomright", title = "Bottom Right", prefix = "MultiBarBottomRight", columns = 12 },
    { id = "right", title = "Right", prefix = "MultiBarRight", columns = 1 },
    { id = "left", title = "Left", prefix = "MultiBarLeft", columns = 1 },
    { id = "extra", title = "Extra Row 1", prefix = "FCTweaksExtra", columns = 12, extraIndex = 1 },
}
for row = 2, 7 do
    AB.definitions[#AB.definitions + 1] = {
        id = "extra" .. row, title = "Extra Row " .. row,
        prefix = "FCTweaksExtra" .. row, columns = 12, extraIndex = row, custom = true,
    }
end
local ownedSlots = setmetatable({}, { __mode = "k" })
local nativeGetPagedID

local function Settings()
    if type(FostercareTweaks_Config.actionbars) ~= "table" then
        FostercareTweaks_Config.actionbars = { enabled = false, bars = {} }
    end
    local config = FostercareTweaks_Config.actionbars
    if type(config.bars) ~= "table" then config.bars = {} end
    return config
end

function AB:GetSettings(id)
    local config = Settings()
    if type(config.bars[id]) ~= "table" then config.bars[id] = {} end
    -- Retired direction option: all bars now fill left to right.
    config.bars[id].growLeft = nil
    return config.bars[id]
end

local function WithButton(button, callback)
    local previous = this
    this = button
    local ok, err = pcall(callback)
    this = previous
    if not ok then error(err) end
end

local function Snapshot(button)
    local points = {}
    for i = 1, button:GetNumPoints() do points[i] = { button:GetPoint(i) } end
    return { button = button, points = points, scale = button:GetScale(), width = button:GetWidth(), height = button:GetHeight() }
end

local function Restore(snapshot)
    local button = snapshot.button
    button:SetScale(snapshot.scale)
    button:SetWidth(snapshot.width)
    button:SetHeight(snapshot.height)
    button:ClearAllPoints()
    for _, point in ipairs(snapshot.points) do button:SetPoint(unpack(point)) end
end

local function SetShown(frame, shown)
    if shown and not frame:IsShown() then frame:Show()
    elseif not shown and frame:IsShown() then frame:Hide() end
end

function AB:CanEdit()
    if UnitAffectingCombat("player") then
        if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Action bar editing is available after combat.") end
        return false
    end
    return true
end

function AB:FinishDrag(bar)
    if not bar.dragging then return end
    bar.holder:StopMovingOrSizing()
    bar.dragging = nil
    local ratio = bar.holder:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local config = self:GetSettings(bar.definition.id)
    config.x = bar.holder:GetLeft() * ratio
    config.y = bar.holder:GetTop() * ratio
end

function AB:SetEditing(editing)
    if editing and (not self.enabled or not self:CanEdit()) then return false end
    self.editing = editing and true or false
    for _, bar in pairs(self.bars) do
        if not self.editing then self:FinishDrag(bar) end
        SetShown(bar.handle, self.editing and bar.visible)
    end
    return true
end

local function CreateExtraButton(bar, id)
    if not nativeGetPagedID then
        nativeGetPagedID = ActionButton_GetPagedID
        -- Installed only when the extra row is first used. Native/foreign
        -- buttons retain their original parent-name and bonus-page semantics.
        ActionButton_GetPagedID = function(button)
            return ownedSlots[button] or nativeGetPagedID(button)
        end
    end
    local button = CreateFrame("CheckButton", "FCTweaksExtraButton" .. id, bar.holder, "ActionButtonTemplate")
    button:SetID(id)
    button.buttonType = "FCTWEAKSEXTRA"
    ownedSlots[button] = 12 + id
    button:SetScript("OnEvent", function() ActionButton_OnEvent(event) end)
    button:SetScript("OnUpdate", function() ActionButton_OnUpdate(arg1) end)
    button:SetScript("OnClick", function()
        if IsShiftKeyDown() then PickupAction(ActionButton_GetPagedID(this)) else
            if MacroFrame_SaveMacro then MacroFrame_SaveMacro() end
            UseAction(ActionButton_GetPagedID(this), 1)
        end
        ActionButton_UpdateState()
    end)
    button:SetScript("OnDragStart", function()
        if LOCK_ACTIONBAR == "1" then return end
        PickupAction(ActionButton_GetPagedID(this))
        ActionButton_UpdateHotkeys(this.buttonType)
        ActionButton_UpdateState()
        ActionButton_UpdateFlash()
    end)
    button:SetScript("OnReceiveDrag", function()
        if LOCK_ACTIONBAR == "1" then return end
        PlaceAction(ActionButton_GetPagedID(this))
        ActionButton_UpdateHotkeys(this.buttonType)
        ActionButton_UpdateState()
        ActionButton_UpdateFlash()
    end)
    button:SetScript("OnEnter", function() ActionButton_SetTooltip() end)
    button:SetScript("OnLeave", function() this.updateTooltip = nil; GameTooltip:Hide() end)
    WithButton(button, ActionButton_OnLoad)
    if FT.IsEnabled("Floating Actionbar") then
        local texture = _G[button:GetName() .. "NormalTexture"]
        texture:SetWidth(60)
        texture:SetHeight(60)
        texture:SetPoint("CENTER", button, "CENTER", 0, 0)
        FT.AddBorder(button, 3, { r = 0.7, g = 0.7, b = 0.7, a = 1 })
    end
    return button
end

function AB:CreateBar(definition)
    local bar = { definition = definition, buttons = {}, snapshots = {} }
    self.bars[definition.id] = bar
    local holder = CreateFrame("Frame", "FCTweaksBar_" .. definition.id, UIParent)
    bar.holder = holder
    holder:SetMovable(true)
    holder:SetClampedToScreen(true)
    holder:SetWidth(36)
    holder:SetHeight(36)
    holder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 150)
    local handle = CreateFrame("Button", nil, holder)
    bar.handle = handle
    handle:SetAllPoints(holder)
    handle:SetFrameStrata("DIALOG")
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true,
        tileSize = 8, edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    handle:SetBackdropColor(0.16, 0.10, 0.21, 0.85)
    handle:SetBackdropBorderColor(0.70, 0.55, 0.85, 1)
    local label = handle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", handle, "CENTER", 0, 0)
    label:SetText(definition.title)
    label:SetTextColor(0.88, 0.78, 1)
    handle:SetScript("OnDragStart", function()
        if not AB.editing or not AB:CanEdit() then return end
        bar.dragging = true
        holder:StartMoving()
    end)
    handle:SetScript("OnDragStop", function() AB:FinishDrag(bar) end)
    handle:Hide()

    if definition.extraIndex then
        for i = 1, 12 do
            if definition.custom then bar.buttons[i] = FT.ExtraActions:CreateButton(bar, i)
            else bar.buttons[i] = CreateExtraButton(bar, i) end
        end
        bar.nativeX, bar.nativeY, bar.nativeVisible = 100, 210 + (definition.extraIndex - 1) * 48, false
    else
        for i = 1, 12 do
            local button = _G[definition.prefix .. "Button" .. i]
            if button then bar.buttons[#bar.buttons + 1] = button end
        end
        bar.frame = definition.id == "main" and MainMenuBar or _G[definition.prefix]
        bar.nativeVisible = bar.frame and bar.frame:IsShown() and true or false
        local first = bar.buttons[1]
        if first then
            local ratio = first:GetEffectiveScale() / UIParent:GetEffectiveScale()
            bar.nativeX = (first:GetLeft() or 100) * ratio
            bar.nativeY = (first:GetTop() or 100) * ratio
        end
        if definition.id == "main" then
            for _, button in ipairs(bar.buttons) do self.normalButtons[button] = true end
            for i = 1, 12 do
                local button = _G["BonusActionButton" .. i]
                if button then bar.buttons[#bar.buttons + 1] = button end
            end
        end
    end
    return bar
end

function AB:SyncMainVisibility()
    local bonusShown = self.enabled and BonusActionBarFrame:IsShown()
    for button in pairs(self.normalButtons) do
        if bonusShown then
            if button:IsShown() then button:Hide() end
        else WithButton(button, ActionButton_Update) end
    end
end

function AB:UpdateGrid(bar, showEmpty)
    if bar.definition.custom then
        bar.showEmpty = showEmpty and true or false
        return
    end
    for _, button in ipairs(bar.buttons) do
        if showEmpty and not button.fctLayoutGrid then
            ActionButton_ShowGrid(button)
            button.fctLayoutGrid = true
        elseif not showEmpty and button.fctLayoutGrid then
            ActionButton_HideGrid(button)
            button.fctLayoutGrid = nil
        end
    end
end

function AB:Apply()
    if not self.enabled or not self.ready or self.applying then return end
    self.applying = true
    if not self.backgroundMouse then
        self.backgroundMouse = {}
        for _, frame in ipairs({ MainMenuBar, BonusActionBarFrame }) do
            self.backgroundMouse[#self.backgroundMouse + 1] = { frame = frame, enabled = frame:IsMouseEnabled() }
            -- Their native mouse rectangles stay at the old layout. Individual
            -- action buttons retain their own input and their native parents.
            frame:EnableMouse(false)
        end
    end
    for _, definition in ipairs(self.definitions) do
        local config = self:GetSettings(definition.id)
        local bar = self.bars[definition.id]
        -- Avoid constructing another twelve native event/animation owners until
        -- the extra row is actually requested.
        if not definition.extraIndex or config.visible == true or bar then
            bar = bar or self:CreateBar(definition)
            if not bar.captured and not definition.extraIndex then
                bar.snapshots = {}
                for _, button in ipairs(bar.buttons) do bar.snapshots[#bar.snapshots + 1] = Snapshot(button) end
                bar.frameSnapshot = bar.frame and definition.id ~= "main" and Snapshot(bar.frame)
                bar.nativeVisible = bar.frame and bar.frame:IsShown() and true or false
                local first = bar.buttons[1]
                if first then
                    local ratio = first:GetEffectiveScale() / UIParent:GetEffectiveScale()
                    bar.nativeX = (first:GetLeft() or 100) * ratio
                    bar.nativeY = (first:GetTop() or 100) * ratio
                end
                bar.captured = true
                bar.layoutDirty = true
            end
            local columns = math.floor(FT.ClampNumber(config.columns, definition.columns, 1, 12))
            local spacing = FT.ClampNumber(config.spacing, 6, 0, 20)
            local scale = FT.ClampNumber(config.scale, 1, 0.5, 2)
            local rows = math.ceil(12 / columns)
            bar.visible = definition.id == "main" or config.visible == true
                or (config.visible == nil and bar.nativeVisible)
            local x = FT.ClampNumber(config.x, bar.nativeX or 100, -10000, 10000)
            local y = FT.ClampNumber(config.y, bar.nativeY or 100, -10000, 10000)
            local parentScale = bar.buttons[1] and bar.buttons[1]:GetParent():GetEffectiveScale()
            local layoutChanged = bar.layoutDirty or bar.columns ~= columns or bar.spacing ~= spacing
                or bar.scale ~= scale or bar.x ~= x or bar.y ~= y or bar.parentScale ~= parentScale
                or bar.growUp ~= config.growUp
            if not bar.dragging and layoutChanged then
                bar.holder:SetScale(scale)
                bar.holder:SetWidth(columns * 36 + (columns - 1) * spacing)
                bar.holder:SetHeight(rows * 36 + (rows - 1) * spacing)
                bar.holder:ClearAllPoints()
                bar.holder:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
                    x / scale, y / scale)
                for index, button in ipairs(bar.buttons) do
                    local id = (index - 1) % 12
                    local column, row = id % columns, math.floor(id / columns)
                    if config.growUp == true then row = rows - 1 - row end
                    button:SetScale(bar.holder:GetEffectiveScale() / button:GetParent():GetEffectiveScale())
                    button:ClearAllPoints()
                    button:SetPoint("TOPLEFT", bar.holder, "TOPLEFT",
                        column * (36 + spacing), -row * (36 + spacing))
                end
                bar.columns, bar.spacing, bar.scale, bar.x, bar.y = columns, spacing, scale, x, y
                bar.parentScale, bar.growUp = parentScale, config.growUp
                bar.layoutDirty = nil
            end
            SetShown(bar.holder, bar.visible)
            if bar.frame and definition.id ~= "main" then
                -- Native pet/stance/cast placement uses these frame bounds.
                -- Keep the frame parent/name but align its bounds with its buttons.
                local ratio = bar.holder:GetEffectiveScale() / bar.frame:GetEffectiveScale()
                local point, relative, relativePoint, offsetX, offsetY = bar.frame:GetPoint(1)
                if point ~= "TOPLEFT" or relative ~= bar.holder or relativePoint ~= "TOPLEFT" or offsetX ~= 0 or offsetY ~= 0 then
                    bar.frame:ClearAllPoints()
                    bar.frame:SetPoint("TOPLEFT", bar.holder, "TOPLEFT", 0, 0)
                end
                local width, height = bar.holder:GetWidth() * ratio, bar.holder:GetHeight() * ratio
                if bar.frame:GetWidth() ~= width then bar.frame:SetWidth(width) end
                if bar.frame:GetHeight() ~= height then bar.frame:SetHeight(height) end
                SetShown(bar.frame, bar.visible)
            end
            self:UpdateGrid(bar, config.showEmpty == true or (config.showEmpty == nil and definition.extraIndex ~= nil))
            SetShown(bar.handle, self.editing and bar.visible)
            if definition.custom then FT.ExtraActions:RefreshBar(bar) end
        end
    end
    if BonusActionBarFrame:IsShown() then
        for button in pairs(self.normalButtons) do if button:IsShown() then button:Hide() end end
    end
    self.applying = nil
end

function AB:SetEnabled(enabled)
    if not self:CanEdit() then return false end
    Settings().enabled = enabled and true or false
    if self.enabled == (enabled and true or false) then return true end
    self.enabled = enabled and true or false
    if self.enabled then self:Apply() else
        self:SetEditing(false)
        for _, bar in pairs(self.bars) do
            self:UpdateGrid(bar, false)
            for _, snapshot in ipairs(bar.snapshots) do Restore(snapshot) end
            if bar.frameSnapshot then Restore(bar.frameSnapshot) end
            bar.captured = nil
            bar.holder:Hide()
            if bar.definition.custom then FT.ExtraActions:RefreshBar(bar) end
            if bar.frame and bar.definition.id ~= "main" then SetShown(bar.frame, bar.nativeVisible) end
        end
        self:SyncMainVisibility()
        if self.backgroundMouse then
            for _, state in ipairs(self.backgroundMouse) do
                if not state.frame:IsMouseEnabled() then state.frame:EnableMouse(state.enabled) end
            end
            self.backgroundMouse = nil
        end
        -- Existing FostercareTweaks layout owners resume their normal positions.
        UIParent_ManageFramePositions()
        MultiActionBar_Update()
    end
    return true
end

function AB:SetValue(id, key, value)
    if not self:CanEdit() then return false end
    if key ~= "columns" and key ~= "spacing" and key ~= "scale" and key ~= "visible" and key ~= "showEmpty"
        and key ~= "growUp" then return false end
    self:GetSettings(id)[key] = value
    self:Apply()
    return true
end

function AB:ResetBar(id)
    if not self:CanEdit() then return false end
    local bar = self.bars[id]
    if bar then self:FinishDrag(bar) end
    -- Layout reset must retain the independent actions stored by custom rows.
    local actions = self:GetSettings(id).actions
    Settings().bars[id] = type(actions) == "table" and { actions = actions } or {}
    self:Apply()
    return true
end

function AB:GetExtraButtons(row)
    local bar = self.bars[(not row or row == 1) and "extra" or "extra" .. row]
    return bar and bar.buttons
end

-- No binding is assigned or removed automatically. Root Bindings.xml exposes
-- these commands in the client's ordinary Key Bindings window.
function FCTweaks_ExtraBinding(id, down, row)
    local bar = AB.bars[(not row or row == 1) and "extra" or "extra" .. row]
    local button = bar and bar.buttons[id]
    if not AB.enabled or not bar or not bar.visible or not button then
        -- Releasing a key after hiding/disabling its bar must not leave a
        -- pressed visual state or execute an action from a hidden owner.
        if button and not down then button:SetButtonState("NORMAL") end
        return
    end
    if bar.definition.custom then FT.ExtraActions:Binding(bar, id, down)
    elseif down then MultiActionButtonDown("FCTweaksExtra", id)
    else MultiActionButtonUp("FCTweaksExtra", id) end
end

BINDING_HEADER_FCTWEAKSACTIONBARS = "FostercareTweaks Action Bars"
for i = 1, 12 do _G["BINDING_NAME_FCTWEAKSEXTRA" .. i] = "Extra Row 1 Button " .. i end
for row = 2, 7 do
    for i = 1, 12 do
        _G["BINDING_NAME_FCTWEAKSEXTRA" .. row .. "_" .. i] = "Extra Row " .. row .. " Button " .. i
    end
end

function AB:Initialize()
    if self.initialized then return end
    self.initialized = true
    FT.hooksecurefunc("UIParent_ManageFramePositions", function() AB:Apply() end)
    FT.hooksecurefunc("MultiActionBar_Update", function() AB:Apply() end)
    local function HideCoveredMain(button)
        button = button or this
        if AB.enabled and BonusActionBarFrame:IsShown() and AB.normalButtons[button] then button:Hide() end
    end
    FT.hooksecurefunc("ActionButton_Update", HideCoveredMain)
    FT.hooksecurefunc("ActionButton_ShowGrid", HideCoveredMain)
    FT.HookScript(BonusActionBarFrame, "OnShow", function() if AB.enabled then AB:SyncMainVisibility() end end)
    FT.HookScript(BonusActionBarFrame, "OnHide", function() if AB.enabled then AB:SyncMainVisibility() end end)
    local controller = CreateFrame("Frame", "FCTweaksActionBarController", UIParent)
    controller:RegisterEvent("PLAYER_ENTERING_WORLD")
    controller:RegisterEvent("PLAYER_REGEN_DISABLED")
    FT.SetEventHandler(controller, function(_, ev)
        if ev == "PLAYER_REGEN_DISABLED" then AB:SetEditing(false)
        elseif not AB.worldPending then
            -- UIParent restores saved Blizzard bar toggles on this event.
            -- Capture only after all native entering-world handlers finish.
            AB.worldPending = true
            C_Timer.After(0, function()
                AB.worldPending = nil
                AB.ready = true
                AB:Apply()
            end)
        end
    end)
    self.enabled = Settings().enabled == true
end
