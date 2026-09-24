-- FostercareTweaks: Options.lua
-- Modern Configuration GUI (Rule C7, C13, AP-28 compliant)

local T = FostercareTweaks.T

local current_config = {}
local max_width = 540
local max_height = 680

local settings = CreateFrame("Frame", "FostercareTweaksSettingsGUI", UIParent)
settings:Hide()

-- Native ESC support (Rule C7)
table.insert(UISpecialFrames, "FostercareTweaksSettingsGUI")
AdvancedSettingsGUI = settings -- backward-compatibility alias

settings:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
settings:SetWidth(max_width)
settings:SetMovable(true)
settings:EnableMouse(true)
settings:RegisterForDrag("LeftButton")
settings:SetScript("OnDragStart", function() this:StartMoving() end)
settings:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
settings:SetFrameStrata("DIALOG")

settings:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

local scrollW = max_width - 48
settings.scrollframe = CreateFrame("ScrollFrame", "FostercareTweaksGUIScrollframe", settings, "UIPanelScrollFrameTemplate")
settings.scrollframe:SetPoint("TOPLEFT", settings, "TOPLEFT", 14, -64)
settings.scrollframe:SetPoint("BOTTOMRIGHT", settings, "BOTTOMRIGHT", -34, 48)
settings.scrollframe:SetWidth(scrollW)
settings.scrollframe:Hide()

settings.container = CreateFrame("Frame", "FostercareTweaksGUIContainer", settings.scrollframe)
settings.container:SetWidth(scrollW)
settings.scrollframe:SetScrollChild(settings.container)

-- Title Header
settings.title = CreateFrame("Frame", "FostercareTweaksGUITitle", settings)
settings.title:SetPoint("TOP", settings, "TOP", 0, 12)
settings.title:SetWidth(280)
settings.title:SetHeight(64)

settings.title.tex = settings.title:CreateTexture(nil, "MEDIUM")
settings.title.tex:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
settings.title.tex:SetAllPoints()

settings.title.text = settings.title:CreateFontString(nil, "HIGH", "GameFontNormal")
settings.title.text:SetText("FostercareTweaks")
settings.title.text:SetPoint("TOP", settings.title, "TOP", 0, -14)

-- Close Button (Rule C13: Circular Highlight, Tactile Bezel)
settings.closeBtn = CreateFrame("Button", "FostercareTweaksCloseButton", settings, "UIPanelCloseButton")
settings.closeBtn:SetPoint("TOPRIGHT", settings, "TOPRIGHT", -8, -8)
settings.closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
settings.closeBtn:SetScript("OnClick", function()
    current_config = {}
    settings:Hide()
end)

-- Bottom Buttons: Cancel, Okay, Defaults
settings.cancel = CreateFrame("Button", "FostercareTweaksCancel", settings, "GameMenuButtonTemplate")
settings.cancel:SetWidth(96)
settings.cancel:SetHeight(24)
settings.cancel:SetPoint("BOTTOMRIGHT", settings, "BOTTOMRIGHT", -16, 16)
settings.cancel:SetText(CANCEL)
settings.cancel:SetScript("OnClick", function()
    current_config = {}
    settings:Hide()
end)

settings.okay = CreateFrame("Button", "FostercareTweaksOkay", settings, "GameMenuButtonTemplate")
settings.okay:SetWidth(96)
settings.okay:SetHeight(24)
-- Centerline relative positioning (Rule C13)
settings.okay:SetPoint("CENTER", settings.cancel, "CENTER", -104, 0)
settings.okay:SetText(OKAY)
settings.okay:SetScript("OnClick", function()
    local reload = false
    local unitFramesChanged = false

    if FostercareTweaks.mods then
        for title, mod in pairs(FostercareTweaks.mods) do
            if current_config[title] ~= nil and current_config[title] ~= FostercareTweaks_Config[title] then
                FostercareTweaks_Config[title] = current_config[title]
                if mod.category == T["Unit Frames"] then
                    unitFramesChanged = true
                elseif mod.apply then
                    local ok, err = pcall(mod.apply, mod, current_config[title] == 1)
                    if not ok then
                        reload = true
                        if DEFAULT_CHAT_FRAME then
                            DEFAULT_CHAT_FRAME:AddMessage("|cffff2020[FostercareTweaks Error]|r Failed to apply '" .. tostring(title) .. "': " .. tostring(err), 1, 0.3, 0.3)
                        end
                    end
                else
                    reload = true
                end
            end
        end
    end

    if unitFramesChanged then
        local UF = FostercareTweaks.UnitFrames
        if UF and UF.ApplyConfiguration then
            UF:ApplyConfiguration()
        end
        if UF and UF.UpdateAllRaidFrames then
            UF:UpdateAllRaidFrames()
        end
    end

    current_config = {}

    if reload then
        ReloadUI()
    else
        settings:Hide()
    end
end)

settings.defaultsBtn = CreateFrame("Button", "FostercareTweaksDefaults", settings, "GameMenuButtonTemplate")
settings.defaultsBtn:SetWidth(96)
settings.defaultsBtn:SetHeight(24)
settings.defaultsBtn:SetPoint("BOTTOMLEFT", settings, "BOTTOMLEFT", 16, 16)
settings.defaultsBtn:SetText(DEFAULTS)
settings.defaultsBtn:SetScript("OnClick", function()
    settings:defaults()
end)

-- Navigation Tabs & Subsystem Pages
settings.tabs = {}

local function EnsureWindowHeight()
    local frameHeight = math.min(UIParent:GetHeight() / UIParent:GetScale() * 0.75, 600)
    if frameHeight < 520 then frameHeight = 520 end
    settings:SetHeight(frameHeight)
end

local function SelectTab(tabId)
    EnsureWindowHeight()
    settings.currentTab = tabId
    for id, tab in ipairs(settings.tabs) do
        if tab.text then
            tab.text:SetFontObject("GameFontNormalSmall")
        end
        if id == tabId then
            tab:Disable()
            if tab.text then tab.text:SetTextColor(1, 0.82, 0) end
        else
            tab:Enable()
            if tab.text then tab.text:SetTextColor(0.85, 0.75, 0.15) end
        end
    end

    if tabId == 1 then
        if settings.unitPage then settings.unitPage:Hide() end
        if settings.raidPage then settings.raidPage:Hide() end
        if settings.scrollframe then settings.scrollframe:Show() end
        if settings.container then settings.container:Show() end
        if settings.cancel then settings.cancel:Show() end
        if settings.okay then settings.okay:Show() end
        if settings.defaultsBtn then settings.defaultsBtn:Show() end
        settings:load()
    elseif tabId == 2 then
        if settings.scrollframe then settings.scrollframe:Hide() end
        if settings.container then settings.container:Hide() end
        if settings.raidPage then settings.raidPage:Hide() end
        if settings.cancel then settings.cancel:Show() end
        if settings.okay then settings.okay:Show() end
        if settings.defaultsBtn then settings.defaultsBtn:Hide() end
        if settings.unitPage then
            settings.unitPage:Show()
            if settings.unitPage.RefreshValues then
                settings.unitPage:RefreshValues()
            end
        end
    elseif tabId == 3 then
        if settings.scrollframe then settings.scrollframe:Hide() end
        if settings.container then settings.container:Hide() end
        if settings.unitPage then settings.unitPage:Hide() end
        if settings.cancel then settings.cancel:Show() end
        if settings.okay then settings.okay:Show() end
        if settings.defaultsBtn then settings.defaultsBtn:Hide() end
        if settings.raidPage then
            settings.raidPage:Show()
            if settings.raidPage.RefreshValues then
                settings.raidPage:RefreshValues()
            end
        end
    end
end
settings.SelectTab = SelectTab

local function CreateTabButton(id, titleText)
    local tab = CreateFrame("Button", "FCTweaksTab" .. id, settings, "UIPanelButtonTemplate")
    tab:SetWidth(110)
    tab:SetHeight(22)
    tab.id = id
    tab:SetText(titleText)
    tab.text = tab:GetFontString()
    if tab.text then
        tab.text:SetFontObject("GameFontNormalSmall")
        tab.text:SetTextColor(1, 0.82, 0)
    end
    tab:SetScript("OnClick", function()
        SelectTab(this.id)
    end)
    return tab
end

local tab1 = CreateTabButton(1, T["General"])
tab1:SetPoint("TOPLEFT", settings, "TOPLEFT", 18, -36)

local tab2 = CreateTabButton(2, T["Unit Frames"])
tab2:SetPoint("LEFT", tab1, "RIGHT", 4, 0)

local tab3 = CreateTabButton(3, T["Raid Frames"])
tab3:SetPoint("LEFT", tab2, "RIGHT", 4, 0)

settings.tabs = { tab1, tab2, tab3 }

settings:SetScript("OnShow", function()
    SelectTab(settings.currentTab or 1)
end)

local function CreateCheckButton(name, labelText, tooltipText, parent, x, y, buttonText)
    local cb = CreateFrame("CheckButton", name, parent, "OptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetWidth(24)
    cb:SetHeight(24)
    local cbText = _G[name .. "Text"]
    if cbText then
        cbText:SetText(buttonText or labelText)
        cbText:SetFontObject("GameFontNormalSmall")
        cbText:SetTextColor(1, 0.82, 0)
    end
    if tooltipText then
        cb:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(labelText, 1, 1, 1, 1, 1)
            GameTooltip:AddLine(tooltipText, 0.9, 0.9, 0.9, 1, 1)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return cb
end

local function CreateSlider(name, labelText, minVal, maxVal, stepVal, unitSuffix, parent, x, y, width)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetWidth(width or 220)
    slider:SetHeight(16)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(stepVal)

    local lowText = _G[name .. "Low"]
    if lowText then
        lowText:SetText(tostring(minVal) .. unitSuffix)
        lowText:SetFontObject("GameFontHighlightSmall")
    end
    local highText = _G[name .. "High"]
    if highText then
        highText:SetText(tostring(maxVal) .. unitSuffix)
        highText:SetFontObject("GameFontHighlightSmall")
    end

    slider.label = _G[name .. "Text"]
    if slider.label then
        slider.label:SetFontObject("GameFontNormalSmall")
        slider.label:SetTextColor(1, 0.82, 0)
    end
    slider.baseLabel = labelText
    slider.unitSuffix = unitSuffix
    slider.stepVal = stepVal

    return slider
end

local function CreateSectionBox(parent, titleText, height)
    local box = CreateFrame("Frame", nil, parent)
    box:SetHeight(height)
    box:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    if FostercareTweaks.DarkMode then
        box:SetBackdropColor(0.1, 0.1, 0.1, 1)
        box:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    else
        box:SetBackdropColor(0.2, 0.2, 0.2, 1)
        box:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end
    box.title = box:CreateFontString(nil, "HIGH", "GameFontNormalSmall")
    box.title:SetPoint("TOPLEFT", box, "TOPLEFT", 12, -8)
    box.title:SetText(titleText)
    box.title:SetTextColor(1, 0.82, 0)
    return box
end

--------------------------------------------------------------------------------
-- Tab 2: Dedicated Unit Frames Page
--------------------------------------------------------------------------------
local unitPage = CreateFrame("ScrollFrame", "FCTweaksUnitSettingsPage", settings, "UIPanelScrollFrameTemplate")
unitPage:SetPoint("TOPLEFT", settings, "TOPLEFT", 14, -64)
unitPage:SetPoint("BOTTOMRIGHT", settings, "BOTTOMRIGHT", -34, 48)
unitPage:SetWidth(max_width - 48)
unitPage:Hide()
settings.unitPage = unitPage

local unitContainer = CreateFrame("Frame", "FCTweaksUnitSettingsContainer", unitPage)
unitContainer:SetPoint("TOPLEFT", unitPage, "TOPLEFT", 0, 0)
unitContainer:SetWidth(max_width - 48)
unitContainer:SetHeight(580)
unitPage:SetScrollChild(unitContainer)

-- Box 1: Modern Unit Frames
local ufBox = CreateSectionBox(unitContainer, T["Modern Unit Frames"], 230)
ufBox:SetPoint("TOPLEFT", unitContainer, "TOPLEFT", 22, -10)
ufBox:SetPoint("TOPRIGHT", unitContainer, "TOPRIGHT", -22, -10)

-- Column 1
local modernPlayerCB  = CreateCheckButton("FCTweaksModPlayerCB",  T["Modern Player Frame"],       T["Enable the modern FostercareTweaks player unit frame instead of the default Blizzard frame."], ufBox, 16, -24)
local modernTargetCB  = CreateCheckButton("FCTweaksModTargetCB",  T["Modern Target Frame"],       T["Enable the modern FostercareTweaks target unit frame instead of the default Blizzard frame."], ufBox, 16, -48)
local modernToTCB     = CreateCheckButton("FCTweaksModToTCB",     T["Modern Target's Target"],   T["Enable the modern FostercareTweaks Target of Target frame instead of the standard frame."], ufBox, 16, -72)
local moveUFCB        = CreateCheckButton("FCTweaksMoveUFCB",     T["Movable Unit Frames"],       T["Player and Target unit frames can be moved while <Shift> and <Ctrl> are pressed together."], ufBox, 16, -96)
local classColorCB    = CreateCheckButton("FCTweaksClassColorCB", T["Unit Frame Class Colors"],   T["Adds class colors to the player, target and party unit frames."], ufBox, 16, -120)
local classPortraitCB = CreateCheckButton("FCTweaksClassPortCB",  T["Unit Frame Class Portraits"],T["Replace unitframe portraits with class icons."], ufBox, 16, -144)

-- Column 2
local healthNumbersCB = CreateCheckButton("FCTweaksHealthNumCB",  T["Real Health Numbers"],       T["Shows real health numbers on player, pet, and target unit frames."], ufBox, 230, -24)
local energyTickCB    = CreateCheckButton("FCTweaksEnergyTickCB", T["Show Energy Ticks"],         T["Show energy and mana ticks on the player unit frame."], ufBox, 230, -48)
local enemyCastbarCB  = CreateCheckButton("FCTweaksEnemyCastCB",  T["Enemy Castbars"],            T["Shows an enemy castbar on target unit frame."], ufBox, 230, -72)
local uninterruptCB   = CreateCheckButton("FCTweaksUninterruptCB",T["Uninterruptible Castbars"],  T["Changes castbar color to silver for spells that cannot be interrupted (target and nameplates)."], ufBox, 230, -96)
local debuffTimerCB   = CreateCheckButton("FCTweaksDebuffTimerCB",T["Debuff Timer"],              T["Show debuff durations on the target unit frame."], ufBox, 230, -120)
local improvedStandardAurasCB = CreateCheckButton("FCTweaksImpStdAurasCB", T["Improved Standard Auras"], T["Display enhanced buffs and debuffs with timers, spirals and dispel borders on standard Blizzard frames."], ufBox, 230, -144)

-- Slider
local ufScaleSlider   = CreateSlider("FCTweaksUFScaleSlider",     T["Modern Frame Scale"], 0.5, 2.0, 0.05, "x", ufBox, 16, -194, 416)

-- Box 2: Buff Settings
local buffBox = CreateSectionBox(unitContainer, T["Buff Settings"], 130)
buffBox:SetPoint("TOPLEFT", ufBox, "BOTTOMLEFT", 0, -14)
buffBox:SetPoint("TOPRIGHT", ufBox, "BOTTOMRIGHT", 0, -14)

local showBuffsPlayerCB = CreateCheckButton("FCTweaksShowBuffsPlayerCB", T["Show Player Buffs"],         T["Display buff icons above the modern player unit frame."], buffBox, 16, -24)
local showBuffsTargetCB = CreateCheckButton("FCTweaksShowBuffsTargetCB", T["Show Target Buffs"],         T["Display buff icons above the modern target unit frame."], buffBox, 16, -48)
local buffSpinCB        = CreateCheckButton("FCTweaksBuffSpinCB",        T["Show Buff Cooldown Spiral"], T["Display Luna radial clock animation on active buffs."], buffBox, 230, -24)
local buffTextCB        = CreateCheckButton("FCTweaksBuffTextCB",        T["Show Buff Duration Text"],   T["Display remaining cooldown countdown numbers on buffs."], buffBox, 230, -48)

local buffSizeSlider    = CreateSlider("FCTweaksBuffSizeSlider", T["Buff Size"], 14, 32, 1, " px", buffBox, 16, -98, 416)

-- Box 3: Debuff Settings
local debuffBox = CreateSectionBox(unitContainer, T["Debuff Settings"], 154)
debuffBox:SetPoint("TOPLEFT", buffBox, "BOTTOMLEFT", 0, -14)
debuffBox:SetPoint("TOPRIGHT", buffBox, "BOTTOMRIGHT", 0, -14)

local showDebuffsPlayerCB = CreateCheckButton("FCTweaksShowDebuffsPlayerCB", T["Show Player Debuffs"],            T["Display debuff icons on the modern player unit frame."], debuffBox, 16, -24)
local showDebuffsTargetCB = CreateCheckButton("FCTweaksShowDebuffsTargetCB", T["Show Target Debuffs"],            T["Display debuff icons below the modern target unit frame."], debuffBox, 16, -48)
local colorDispelCB       = CreateCheckButton("FCTweaksColorDispelCB",       T["Color Debuffs by Dispel Type"],    T["Color debuff borders according to dispel type (Magic, Curse, Disease, Poison) like Luna."], debuffBox, 16, -72)

local debuffSpinCB        = CreateCheckButton("FCTweaksDebuffSpinCB",        T["Show Debuff Cooldown Spiral"],    T["Display Luna radial clock animation on active debuffs."], debuffBox, 230, -24)
local debuffTextCB        = CreateCheckButton("FCTweaksDebuffTextCB",        T["Show Debuff Duration Text"],      T["Display remaining cooldown countdown numbers on debuffs."], debuffBox, 230, -48)
local onlyMyDebuffsCB     = CreateCheckButton("FCTweaksOnlyMyDebuffsCB",     T["Only Show My Debuffs on Target"], T["Filter target debuffs to only show debuffs applied by you."], debuffBox, 230, -72)

local debuffSizeSlider    = CreateSlider("FCTweaksDebuffSizeSlider", T["Debuff Size"], 14, 32, 1, " px", debuffBox, 16, -122, 416)

-- Action Buttons
local resetPosBtn = CreateFrame("Button", "FCTweaksResetUFPosBtn", unitContainer, "UIPanelButtonTemplate")
resetPosBtn:SetPoint("TOPLEFT", debuffBox, "BOTTOMLEFT", 0, -12)
resetPosBtn:SetWidth(218)
resetPosBtn:SetHeight(24)
resetPosBtn:SetText(T["Reset Frame Positions"])
if resetPosBtn:GetFontString() then resetPosBtn:GetFontString():SetFontObject("GameFontNormalSmall") end
resetPosBtn:SetScript("OnClick", function()
    if FostercareTweaks_Config then
        FostercareTweaks_Config.unitframe_positions = nil
    end
    ReloadUI()
end)

local resetUFDefaultsBtn = CreateFrame("Button", "FCTweaksResetUFDefaultsBtn", unitContainer, "UIPanelButtonTemplate")
resetUFDefaultsBtn:SetPoint("TOPRIGHT", debuffBox, "BOTTOMRIGHT", 0, -12)
resetUFDefaultsBtn:SetWidth(218)
resetUFDefaultsBtn:SetHeight(24)
resetUFDefaultsBtn:SetText(T["Reset to Defaults"])
if resetUFDefaultsBtn:GetFontString() then resetUFDefaultsBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local isUFUpdating = false
local function OnUnitCheckboxClicked()
    if isUFUpdating then return end
    if not FostercareTweaks_Config then FostercareTweaks_Config = {} end

    local modPlayerVal = modernPlayerCB:GetChecked() and 1 or 0
    local modTargetVal = modernTargetCB:GetChecked() and 1 or 0
    local modToTVal    = modernToTCB:GetChecked() and 1 or 0

    local stdPlayerVal = (modPlayerVal == 1) and 0 or 1
    local stdTargetVal = (modTargetVal == 1) and 0 or 1
    local stdToTVal    = (modToTVal == 1) and 0 or 1

    local moveVal      = moveUFCB:GetChecked() and 1 or 0
    local classColVal  = classColorCB:GetChecked() and 1 or 0
    local classPortVal = classPortraitCB:GetChecked() and 1 or 0
    local healthNumVal = healthNumbersCB:GetChecked() and 1 or 0
    local energyVal    = energyTickCB:GetChecked() and 1 or 0
    local castbarVal   = enemyCastbarCB:GetChecked() and 1 or 0
    local uninterrVal  = uninterruptCB:GetChecked() and 1 or 0
    local debuffTmrVal = debuffTimerCB:GetChecked() and 1 or 0

    local pbVal        = showBuffsPlayerCB:GetChecked() and 1 or 0
    local tbVal        = showBuffsTargetCB:GetChecked() and 1 or 0
    local bSpinVal     = buffSpinCB:GetChecked() and 1 or 0
    local bTextVal     = buffTextCB:GetChecked() and 1 or 0
    local pdVal        = showDebuffsPlayerCB:GetChecked() and 1 or 0
    local tdVal        = showDebuffsTargetCB:GetChecked() and 1 or 0
    local dSpinVal     = debuffSpinCB:GetChecked() and 1 or 0
    local dTextVal     = debuffTextCB:GetChecked() and 1 or 0
    local dispelVal    = colorDispelCB:GetChecked() and 1 or 0
    local myDebuffVal  = onlyMyDebuffsCB:GetChecked() and 1 or 0
    local impStdAuraVal = improvedStandardAurasCB:GetChecked() and 1 or 0

    FostercareTweaks_Config[T["Modern Player Frame"]] = modPlayerVal
    FostercareTweaks_Config[T["Modern Target Frame"]] = modTargetVal
    FostercareTweaks_Config[T["Modern Target's Target"]] = modToTVal
    FostercareTweaks_Config[T["Use Standard Player Frame"]] = stdPlayerVal
    FostercareTweaks_Config[T["Use Standard Target Frame"]] = stdTargetVal
    FostercareTweaks_Config[T["Use Standard Target's Target"]] = stdToTVal
    FostercareTweaks_Config[T["Improved Standard Auras"]] = impStdAuraVal

    current_config[T["Modern Player Frame"]] = modPlayerVal
    current_config[T["Modern Target Frame"]] = modTargetVal
    current_config[T["Modern Target's Target"]] = modToTVal
    current_config[T["Use Standard Player Frame"]] = stdPlayerVal
    current_config[T["Use Standard Target Frame"]] = stdTargetVal
    current_config[T["Use Standard Target's Target"]] = stdToTVal
    current_config[T["Improved Standard Auras"]] = impStdAuraVal

    FostercareTweaks_Config[T["Movable Unit Frames"]] = moveVal
    FostercareTweaks_Config[T["Unit Frame Class Colors"]] = classColVal
    FostercareTweaks_Config[T["Unit Frame Class Portraits"]] = classPortVal
    FostercareTweaks_Config[T["Real Health Numbers"]] = healthNumVal
    FostercareTweaks_Config[T["Show Energy Ticks"]] = energyVal
    FostercareTweaks_Config[T["Enemy Castbars"]] = castbarVal
    FostercareTweaks_Config[T["Uninterruptible Castbars"]] = uninterrVal
    FostercareTweaks_Config[T["Debuff Timer"]] = debuffTmrVal

    current_config[T["Movable Unit Frames"]] = moveVal
    current_config[T["Unit Frame Class Colors"]] = classColVal
    current_config[T["Unit Frame Class Portraits"]] = classPortVal
    current_config[T["Real Health Numbers"]] = healthNumVal
    current_config[T["Show Energy Ticks"]] = energyVal
    current_config[T["Enemy Castbars"]] = castbarVal
    current_config[T["Uninterruptible Castbars"]] = uninterrVal
    current_config[T["Debuff Timer"]] = debuffTmrVal

    FostercareTweaks_Config[T["Show Player Buffs"]] = pbVal
    FostercareTweaks_Config[T["Show Target Buffs"]] = tbVal
    FostercareTweaks_Config[T["Show Buff Cooldown Spiral"]] = bSpinVal
    FostercareTweaks_Config[T["Show Buff Duration Text"]] = bTextVal
    FostercareTweaks_Config[T["Show Player Debuffs"]] = pdVal
    FostercareTweaks_Config[T["Show Target Debuffs"]] = tdVal
    FostercareTweaks_Config[T["Show Debuff Cooldown Spiral"]] = dSpinVal
    FostercareTweaks_Config[T["Show Debuff Duration Text"]] = dTextVal
    FostercareTweaks_Config[T["Color Debuffs by Dispel Type"]] = dispelVal
    FostercareTweaks_Config[T["Only Show My Debuffs on Target"]] = myDebuffVal

    current_config[T["Show Player Buffs"]] = pbVal
    current_config[T["Show Target Buffs"]] = tbVal
    current_config[T["Show Buff Cooldown Spiral"]] = bSpinVal
    current_config[T["Show Buff Duration Text"]] = bTextVal
    current_config[T["Show Player Debuffs"]] = pdVal
    current_config[T["Show Target Debuffs"]] = tdVal
    current_config[T["Show Debuff Cooldown Spiral"]] = dSpinVal
    current_config[T["Show Debuff Duration Text"]] = dTextVal
    current_config[T["Color Debuffs by Dispel Type"]] = dispelVal
    current_config[T["Only Show My Debuffs on Target"]] = myDebuffVal

    local UF = FostercareTweaks.UnitFrames
    if UF and UF.ApplyConfiguration then
        UF:ApplyConfiguration()
    end
end

modernPlayerCB:SetScript("OnClick", OnUnitCheckboxClicked)
modernTargetCB:SetScript("OnClick", OnUnitCheckboxClicked)
modernToTCB:SetScript("OnClick", OnUnitCheckboxClicked)
moveUFCB:SetScript("OnClick", OnUnitCheckboxClicked)
classColorCB:SetScript("OnClick", OnUnitCheckboxClicked)
classPortraitCB:SetScript("OnClick", OnUnitCheckboxClicked)
healthNumbersCB:SetScript("OnClick", OnUnitCheckboxClicked)
energyTickCB:SetScript("OnClick", OnUnitCheckboxClicked)
enemyCastbarCB:SetScript("OnClick", OnUnitCheckboxClicked)
uninterruptCB:SetScript("OnClick", OnUnitCheckboxClicked)
debuffTimerCB:SetScript("OnClick", OnUnitCheckboxClicked)
improvedStandardAurasCB:SetScript("OnClick", OnUnitCheckboxClicked)

showBuffsPlayerCB:SetScript("OnClick", OnUnitCheckboxClicked)
showBuffsTargetCB:SetScript("OnClick", OnUnitCheckboxClicked)
buffSpinCB:SetScript("OnClick", OnUnitCheckboxClicked)
buffTextCB:SetScript("OnClick", OnUnitCheckboxClicked)
showDebuffsPlayerCB:SetScript("OnClick", OnUnitCheckboxClicked)
showDebuffsTargetCB:SetScript("OnClick", OnUnitCheckboxClicked)
debuffSpinCB:SetScript("OnClick", OnUnitCheckboxClicked)
debuffTextCB:SetScript("OnClick", OnUnitCheckboxClicked)
colorDispelCB:SetScript("OnClick", OnUnitCheckboxClicked)
onlyMyDebuffsCB:SetScript("OnClick", OnUnitCheckboxClicked)

buffSizeSlider:SetScript("OnValueChanged", function()
    if isUFUpdating then return end
    local val = math.floor(this:GetValue() + 0.5)
    if buffSizeSlider.label then buffSizeSlider.label:SetText(T["Buff Size"] .. ": " .. val .. " px") end
    if not FostercareTweaks_Config then FostercareTweaks_Config = {} end
    if not FostercareTweaks_Config.overwrites then FostercareTweaks_Config.overwrites = {} end
    FostercareTweaks_Config.overwrites["uf_buff_size"] = val
    if FostercareTweaks.overwrites then FostercareTweaks.overwrites["uf_buff_size"] = val end

    local UF = FostercareTweaks.UnitFrames
    if UF and UF.Auras and UF.Auras.ApplyBuffSize then
        if UF.playerFrame and UF.playerFrame.auraContainer then
            UF.Auras:ApplyBuffSize(UF.playerFrame.auraContainer, val)
        end
        if UF.targetFrame and UF.targetFrame.auraContainer then
            UF.Auras:ApplyBuffSize(UF.targetFrame.auraContainer, val)
        end
        if UF.blizzTargetAuras then
            UF.Auras:ApplyBuffSize(UF.blizzTargetAuras, val)
        end
    end
    if UF and UF.ApplyConfiguration then
        UF:ApplyConfiguration()
    end
end)

debuffSizeSlider:SetScript("OnValueChanged", function()
    if isUFUpdating then return end
    local val = math.floor(this:GetValue() + 0.5)
    if debuffSizeSlider.label then debuffSizeSlider.label:SetText(T["Debuff Size"] .. ": " .. val .. " px") end
    if not FostercareTweaks_Config then FostercareTweaks_Config = {} end
    if not FostercareTweaks_Config.overwrites then FostercareTweaks_Config.overwrites = {} end
    FostercareTweaks_Config.overwrites["uf_debuff_size"] = val
    if FostercareTweaks.overwrites then FostercareTweaks.overwrites["uf_debuff_size"] = val end

    local UF = FostercareTweaks.UnitFrames
    if UF and UF.Auras and UF.Auras.ApplyDebuffSize then
        if UF.playerFrame and UF.playerFrame.auraContainer then
            UF.Auras:ApplyDebuffSize(UF.playerFrame.auraContainer, val)
        end
        if UF.targetFrame and UF.targetFrame.auraContainer then
            UF.Auras:ApplyDebuffSize(UF.targetFrame.auraContainer, val)
        end
        if UF.blizzTargetAuras then
            UF.Auras:ApplyDebuffSize(UF.blizzTargetAuras, val)
        end
    end
    if UF and UF.ApplyConfiguration then
        UF:ApplyConfiguration()
    end
end)

ufScaleSlider:SetScript("OnValueChanged", function()
    if isUFUpdating then return end
    local val = math.floor(this:GetValue() * 20 + 0.5) / 20
    if ufScaleSlider.label then ufScaleSlider.label:SetText(T["Modern Frame Scale"] .. ": " .. string.format("%.2f", val) .. "x") end
    if not FostercareTweaks_Config then FostercareTweaks_Config = {} end
    if not FostercareTweaks_Config.overwrites then FostercareTweaks_Config.overwrites = {} end
    FostercareTweaks_Config.overwrites["uf_scale"] = val
    if FostercareTweaks.overwrites then FostercareTweaks.overwrites["uf_scale"] = val end
    local UF = FostercareTweaks.UnitFrames
    if UF and UF.ApplyScale then UF:ApplyScale(val) end
end)

resetUFDefaultsBtn:SetScript("OnClick", function()
    if not FostercareTweaks_Config then FostercareTweaks_Config = {} end
    FostercareTweaks_Config[T["Modern Player Frame"]] = 0
    FostercareTweaks_Config[T["Modern Target Frame"]] = 0
    FostercareTweaks_Config[T["Modern Target's Target"]] = 0
    FostercareTweaks_Config[T["Use Standard Player Frame"]] = 0
    FostercareTweaks_Config[T["Use Standard Target Frame"]] = 0
    FostercareTweaks_Config[T["Use Standard Target's Target"]] = 0
    FostercareTweaks_Config[T["Improved Standard Auras"]] = 1

    FostercareTweaks_Config[T["Movable Unit Frames"]] = 1
    FostercareTweaks_Config[T["Unit Frame Class Colors"]] = 0
    FostercareTweaks_Config[T["Unit Frame Class Portraits"]] = 0
    FostercareTweaks_Config[T["Real Health Numbers"]] = 1
    FostercareTweaks_Config[T["Show Energy Ticks"]] = 1
    FostercareTweaks_Config[T["Enemy Castbars"]] = 1
    FostercareTweaks_Config[T["Uninterruptible Castbars"]] = 1
    FostercareTweaks_Config[T["Debuff Timer"]] = 1

    FostercareTweaks_Config[T["Show Player Buffs"]] = 1
    FostercareTweaks_Config[T["Show Target Buffs"]] = 1
    FostercareTweaks_Config[T["Show Buff Cooldown Spiral"]] = 1
    FostercareTweaks_Config[T["Show Buff Duration Text"]] = 1
    FostercareTweaks_Config[T["Show Player Debuffs"]] = 1
    FostercareTweaks_Config[T["Show Target Debuffs"]] = 1
    FostercareTweaks_Config[T["Show Debuff Cooldown Spiral"]] = 1
    FostercareTweaks_Config[T["Show Debuff Duration Text"]] = 1
    FostercareTweaks_Config[T["Color Debuffs by Dispel Type"]] = 1
    FostercareTweaks_Config[T["Only Show My Debuffs on Target"]] = 0

    current_config[T["Modern Player Frame"]] = 0
    current_config[T["Modern Target Frame"]] = 0
    current_config[T["Modern Target's Target"]] = 0
    current_config[T["Use Standard Player Frame"]] = 0
    current_config[T["Use Standard Target Frame"]] = 0
    current_config[T["Use Standard Target's Target"]] = 0
    current_config[T["Improved Standard Auras"]] = 1

    current_config[T["Movable Unit Frames"]] = 1
    current_config[T["Unit Frame Class Colors"]] = 0
    current_config[T["Unit Frame Class Portraits"]] = 0
    current_config[T["Real Health Numbers"]] = 1
    current_config[T["Show Energy Ticks"]] = 1
    current_config[T["Enemy Castbars"]] = 1
    current_config[T["Uninterruptible Castbars"]] = 1
    current_config[T["Debuff Timer"]] = 1

    current_config[T["Show Player Buffs"]] = 1
    current_config[T["Show Target Buffs"]] = 1
    current_config[T["Show Buff Cooldown Spiral"]] = 1
    current_config[T["Show Buff Duration Text"]] = 1
    current_config[T["Show Player Debuffs"]] = 1
    current_config[T["Show Target Debuffs"]] = 1
    current_config[T["Show Debuff Cooldown Spiral"]] = 1
    current_config[T["Show Debuff Duration Text"]] = 1
    current_config[T["Color Debuffs by Dispel Type"]] = 1
    current_config[T["Only Show My Debuffs on Target"]] = 0

    if not FostercareTweaks_Config.overwrites then FostercareTweaks_Config.overwrites = {} end
    FostercareTweaks_Config.overwrites["uf_scale"] = 1.0
    FostercareTweaks_Config.overwrites["uf_buff_size"] = 20
    FostercareTweaks_Config.overwrites["uf_debuff_size"] = 20
    FostercareTweaks_Config.overwrites["uf_aura_size"] = 20

    if FostercareTweaks.overwrites then
        FostercareTweaks.overwrites["uf_scale"] = 1.0
        FostercareTweaks.overwrites["uf_buff_size"] = 20
        FostercareTweaks.overwrites["uf_debuff_size"] = 20
        FostercareTweaks.overwrites["uf_aura_size"] = 20
    end

    local UF = FostercareTweaks.UnitFrames
    if UF then
        if UF.ApplyScale then UF:ApplyScale(1.0) end
        if UF.Auras and UF.Auras.ApplyBuffSize and UF.Auras.ApplyDebuffSize then
            if UF.playerFrame and UF.playerFrame.auraContainer then
                UF.Auras:ApplyBuffSize(UF.playerFrame.auraContainer, 20)
                UF.Auras:ApplyDebuffSize(UF.playerFrame.auraContainer, 20)
            end
            if UF.targetFrame and UF.targetFrame.auraContainer then
                UF.Auras:ApplyBuffSize(UF.targetFrame.auraContainer, 20)
                UF.Auras:ApplyDebuffSize(UF.targetFrame.auraContainer, 20)
            end
            if UF.blizzTargetAuras then
                UF.Auras:ApplyBuffSize(UF.blizzTargetAuras, 20)
                UF.Auras:ApplyDebuffSize(UF.blizzTargetAuras, 20)
            end
        end
        if UF.ApplyConfiguration then UF:ApplyConfiguration() end
    end
    if unitPage.RefreshValues then unitPage:RefreshValues() end
end)

function unitPage:RefreshValues()
    local UF = FostercareTweaks.UnitFrames
    if not UF then return end
    isUFUpdating = true

    modernPlayerCB:SetChecked(UF:IsModernPlayer() and true or nil)
    modernTargetCB:SetChecked(UF:IsModernTarget() and true or nil)
    modernToTCB:SetChecked(UF:IsModernToT() and true or nil)
    improvedStandardAurasCB:SetChecked(UF:IsImprovedStandardAuras() and true or nil)

    local cfg = FostercareTweaks_Config or {}
    moveUFCB:SetChecked((cfg[T["Movable Unit Frames"]] == nil or cfg[T["Movable Unit Frames"]] == 1) and true or nil)
    classColorCB:SetChecked(cfg[T["Unit Frame Class Colors"]] == 1 and true or nil)
    classPortraitCB:SetChecked(cfg[T["Unit Frame Class Portraits"]] == 1 and true or nil)
    healthNumbersCB:SetChecked((cfg[T["Real Health Numbers"]] == nil or cfg[T["Real Health Numbers"]] == 1) and true or nil)
    energyTickCB:SetChecked((cfg[T["Show Energy Ticks"]] == nil or cfg[T["Show Energy Ticks"]] == 1) and true or nil)
    enemyCastbarCB:SetChecked((cfg[T["Enemy Castbars"]] == nil or cfg[T["Enemy Castbars"]] == 1) and true or nil)
    uninterruptCB:SetChecked((cfg[T["Uninterruptible Castbars"]] == nil or cfg[T["Uninterruptible Castbars"]] == 1) and true or nil)
    debuffTimerCB:SetChecked((cfg[T["Debuff Timer"]] == nil or cfg[T["Debuff Timer"]] == 1) and true or nil)

    showBuffsPlayerCB:SetChecked(UF:IsShowPlayerBuffs() and true or nil)
    showBuffsTargetCB:SetChecked(UF:IsShowTargetBuffs() and true or nil)
    buffSpinCB:SetChecked(UF:IsBuffSpin() and true or nil)
    buffTextCB:SetChecked(UF:IsBuffText() and true or nil)

    showDebuffsPlayerCB:SetChecked(UF:IsShowPlayerDebuffs() and true or nil)
    showDebuffsTargetCB:SetChecked(UF:IsShowTargetDebuffs() and true or nil)
    debuffSpinCB:SetChecked(UF:IsDebuffSpin() and true or nil)
    debuffTextCB:SetChecked(UF:IsDebuffText() and true or nil)
    colorDispelCB:SetChecked(UF:IsColorDebuffsByDispel() and true or nil)
    onlyMyDebuffsCB:SetChecked(UF:IsOnlyMyDebuffs() and true or nil)

    local bsize = UF:GetBuffSize()
    buffSizeSlider:SetValue(bsize)
    if buffSizeSlider.label then
        buffSizeSlider.label:SetText(T["Buff Size"] .. ": " .. bsize .. " px")
    end

    local dsize = UF:GetDebuffSize()
    debuffSizeSlider:SetValue(dsize)
    if debuffSizeSlider.label then
        debuffSizeSlider.label:SetText(T["Debuff Size"] .. ": " .. dsize .. " px")
    end

    local s = UF:GetScale()
    ufScaleSlider:SetValue(s)
    if ufScaleSlider.label then
        ufScaleSlider.label:SetText(T["Modern Frame Scale"] .. ": " .. string.format("%.2f", s) .. "x")
    end
    isUFUpdating = false
end

--------------------------------------------------------------------------------
-- Tab 3: Dedicated Raid Frames Page
--------------------------------------------------------------------------------
local raidPage = CreateFrame("ScrollFrame", "FCTweaksRaidSettingsPage", settings, "UIPanelScrollFrameTemplate")
raidPage:SetPoint("TOPLEFT", settings, "TOPLEFT", 14, -64)
raidPage:SetPoint("BOTTOMRIGHT", settings, "BOTTOMRIGHT", -34, 48)
raidPage:SetWidth(max_width - 48)
raidPage:Hide()
settings.raidPage = raidPage

local raidContainer = CreateFrame("Frame", "FCTweaksRaidSettingsContainer", raidPage)
raidContainer:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 0, 0)
raidContainer:SetWidth(max_width - 48)
raidContainer:SetHeight(400)
raidPage:SetScrollChild(raidContainer)

-- Box 1: Raid & Group Frames
local rBox1 = CreateSectionBox(raidContainer, T["Raid & Group Frames"], 64)
rBox1:SetPoint("TOPLEFT", raidContainer, "TOPLEFT", 22, -10)
rBox1:SetPoint("TOPRIGHT", raidContainer, "TOPRIGHT", -22, -10)

local enableCB = CreateCheckButton("FCTweaksRaidPageEnableCB", T["Enable Raid Frames"], T["Toggle display of unified party and raid frames."], rBox1, 16, -26)

local fmtLabel = rBox1:CreateFontString(nil, "HIGH", "GameFontNormalSmall")
fmtLabel:SetPoint("TOPLEFT", rBox1, "TOPLEFT", 200, -10)
fmtLabel:SetText(T["Health Display Format:"])
fmtLabel:SetTextColor(1, 0.82, 0)

local fmtDeficitBtn = CreateFrame("Button", "FCTweaksFmtDeficitBtn", rBox1, "UIPanelButtonTemplate")
fmtDeficitBtn:SetWidth(72)
fmtDeficitBtn:SetHeight(22)
fmtDeficitBtn:SetPoint("TOPLEFT", rBox1, "TOPLEFT", 200, -28)
fmtDeficitBtn:SetText(T["Deficit"])
if fmtDeficitBtn:GetFontString() then fmtDeficitBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local fmtPercentBtn = CreateFrame("Button", "FCTweaksFmtPercentBtn", rBox1, "UIPanelButtonTemplate")
fmtPercentBtn:SetWidth(72)
fmtPercentBtn:SetHeight(22)
fmtPercentBtn:SetPoint("LEFT", fmtDeficitBtn, "RIGHT", 4, 0)
fmtPercentBtn:SetText(T["Percent"])
if fmtPercentBtn:GetFontString() then fmtPercentBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local fmtCurrentBtn = CreateFrame("Button", "FCTweaksFmtCurrentBtn", rBox1, "UIPanelButtonTemplate")
fmtCurrentBtn:SetWidth(72)
fmtCurrentBtn:SetHeight(22)
fmtCurrentBtn:SetPoint("LEFT", fmtPercentBtn, "RIGHT", 4, 0)
fmtCurrentBtn:SetText(T["Current"])
if fmtCurrentBtn:GetFontString() then fmtCurrentBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

-- Box 2: Raid Indicators
local rBox2 = CreateSectionBox(raidContainer, T["Raid Indicators"], 80)
rBox2:SetPoint("TOPLEFT", rBox1, "BOTTOMLEFT", 0, -14)
rBox2:SetPoint("TOPRIGHT", rBox1, "BOTTOMRIGHT", 0, -14)

local aggroCB  = CreateCheckButton("FCTweaksRaidAggroCB",  T["Show Aggro Indicator"], T["Display a red threat warning square on unit frames when threat is high."], rBox2, 16, -24)
local hotCB    = CreateCheckButton("FCTweaksRaidHoTCB",    T["Show HoT Indicator"],   T["Display a HoT tracking square on the top-left of friendly frames (Renew, Rejuvenation, Regrowth, PW:S, BoP)."], rBox2, 230, -24)
local debuffCB = CreateCheckButton("FCTweaksRaidDebuffCB", T["Show Debuff Badges"],   T["Display debuff icon badges on the bottom-right of group frames with dispel-colored borders."], rBox2, 16, -48)

-- Box 3: Dimensions & Spacing
local rBox3 = CreateSectionBox(raidContainer, T["Dimensions & Spacing"], 166)
rBox3:SetPoint("TOPLEFT", rBox2, "BOTTOMLEFT", 0, -14)
rBox3:SetPoint("TOPRIGHT", rBox2, "BOTTOMRIGHT", 0, -14)

local widthSlider    = CreateSlider("FCTweaksRaidWidthSlider",    T["Width"],              40,  120, 1,    " px", rBox3, 16, -34,  196)
local heightSlider   = CreateSlider("FCTweaksRaidHeightSlider",   T["Height"],             20,  60,  1,    " px", rBox3, 236, -34, 196)
local spacingXSlider = CreateSlider("FCTweaksRaidSpacingXSlider", T["Horizontal Spacing"], 0,   20,  1,    " px", rBox3, 16, -82,  196)
local spacingYSlider = CreateSlider("FCTweaksRaidSpacingYSlider", T["Vertical Spacing"],   0,   20,  1,    " px", rBox3, 236, -82, 196)
local scaleSlider    = CreateSlider("FCTweaksRaidScaleSlider",    T["Scale"],              0.5, 2.0, 0.05, "x",   rBox3, 16, -130, 416)

-- Bottom Buttons
local resetBtn = CreateFrame("Button", "FCTweaksRaidPageResetBtn", raidContainer, "UIPanelButtonTemplate")
resetBtn:SetPoint("TOPLEFT", rBox3, "BOTTOMLEFT", 0, -12)
resetBtn:SetWidth(218)
resetBtn:SetHeight(24)
resetBtn:SetText(T["Reset to Defaults"])
if resetBtn:GetFontString() then resetBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local testBtn = CreateFrame("Button", "FCTweaksRaidPageTestBtn", raidContainer, "UIPanelButtonTemplate")
testBtn:SetPoint("TOPRIGHT", rBox3, "BOTTOMRIGHT", 0, -12)
testBtn:SetWidth(218)
testBtn:SetHeight(24)
testBtn:SetText(T["Toggle Test Grid (40)"])
if testBtn:GetFontString() then testBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local isRaidUpdating = false

local function UpdateRaidHealthFormatButtons(fmt)
    if fmt == "percent" then
        fmtDeficitBtn:Enable()
        fmtPercentBtn:Disable()
        fmtCurrentBtn:Enable()
    elseif fmt == "current" then
        fmtDeficitBtn:Enable()
        fmtPercentBtn:Enable()
        fmtCurrentBtn:Disable()
    else
        fmtDeficitBtn:Disable()
        fmtPercentBtn:Enable()
        fmtCurrentBtn:Enable()
    end
end

local function SetRaidHealthFormat(fmt)
    if not FostercareTweaks_Config then FostercareTweaks_Config = {} end
    if not FostercareTweaks_Config.overwrites then FostercareTweaks_Config.overwrites = {} end
    FostercareTweaks_Config.overwrites["raid_health_format"] = fmt
    if FostercareTweaks.overwrites then
        FostercareTweaks.overwrites["raid_health_format"] = fmt
    end
    UpdateRaidHealthFormatButtons(fmt)
    local UF = FostercareTweaks.UnitFrames
    if UF and UF.UpdateAllRaidFrames then
        UF:UpdateAllRaidFrames()
    end
end

fmtDeficitBtn:SetScript("OnClick", function() SetRaidHealthFormat("deficit") end)
fmtPercentBtn:SetScript("OnClick", function() SetRaidHealthFormat("percent") end)
fmtCurrentBtn:SetScript("OnClick", function() SetRaidHealthFormat("current") end)

local function OnRaidIndicatorClicked()
    if isRaidUpdating then return end
    if not FostercareTweaks_Config then FostercareTweaks_Config = {} end
    local aVal = aggroCB:GetChecked() and 1 or 0
    local hVal = hotCB:GetChecked() and 1 or 0
    local dVal = debuffCB:GetChecked() and 1 or 0

    FostercareTweaks_Config[T["Show Raid Aggro Indicator"]] = aVal
    FostercareTweaks_Config[T["Show Raid HoT Indicator"]] = hVal
    FostercareTweaks_Config[T["Show Raid Debuff Badges"]] = dVal

    current_config[T["Show Raid Aggro Indicator"]] = aVal
    current_config[T["Show Raid HoT Indicator"]] = hVal
    current_config[T["Show Raid Debuff Badges"]] = dVal

    local UF = FostercareTweaks.UnitFrames
    if UF and UF.UpdateAllRaidFrames then
        UF:UpdateAllRaidFrames()
    end
end

aggroCB:SetScript("OnClick", OnRaidIndicatorClicked)
hotCB:SetScript("OnClick", OnRaidIndicatorClicked)
debuffCB:SetScript("OnClick", OnRaidIndicatorClicked)

local function OnRaidSliderValueChanged()
    if isRaidUpdating then return end
    local UF = FostercareTweaks.UnitFrames
    if not UF or not UF.ApplyGroupDimensions then return end

    local w = math.floor(widthSlider:GetValue() + 0.5)
    local h = math.floor(heightSlider:GetValue() + 0.5)
    local s = math.floor(scaleSlider:GetValue() * 100 + 0.5) / 100
    local spX = math.floor(spacingXSlider:GetValue() + 0.5)
    local spY = math.floor(spacingYSlider:GetValue() + 0.5)

    if widthSlider.label then widthSlider.label:SetText(T["Width"] .. ": " .. w .. " px") end
    if heightSlider.label then heightSlider.label:SetText(T["Height"] .. ": " .. h .. " px") end
    if scaleSlider.label then scaleSlider.label:SetText(T["Scale"] .. ": " .. string.format("%.2f", s) .. "x") end
    if spacingXSlider.label then spacingXSlider.label:SetText(T["Horizontal Spacing"] .. ": " .. spX .. " px") end
    if spacingYSlider.label then spacingYSlider.label:SetText(T["Vertical Spacing"] .. ": " .. spY .. " px") end

    local enabled = enableCB:GetChecked() and true or false
    UF:ApplyGroupDimensions(w, h, s, spX, spY, enabled)
end

widthSlider:SetScript("OnValueChanged", OnRaidSliderValueChanged)
heightSlider:SetScript("OnValueChanged", OnRaidSliderValueChanged)
scaleSlider:SetScript("OnValueChanged", OnRaidSliderValueChanged)
spacingXSlider:SetScript("OnValueChanged", OnRaidSliderValueChanged)
spacingYSlider:SetScript("OnValueChanged", OnRaidSliderValueChanged)

enableCB:SetScript("OnClick", function()
    if isRaidUpdating then return end
    local UF = FostercareTweaks.UnitFrames
    if not UF or not UF.ApplyGroupDimensions then return end
    local isChecked = this:GetChecked() and true or false
    UF:ApplyGroupDimensions(nil, nil, nil, nil, nil, isChecked)
end)

resetBtn:SetScript("OnClick", function()
    isRaidUpdating = true
    enableCB:SetChecked(true)
    aggroCB:SetChecked(true)
    hotCB:SetChecked(true)
    debuffCB:SetChecked(true)
    widthSlider:SetValue(64)
    heightSlider:SetValue(34)
    scaleSlider:SetValue(1.0)
    spacingXSlider:SetValue(4)
    spacingYSlider:SetValue(3)
    isRaidUpdating = false

    if widthSlider.label then widthSlider.label:SetText(T["Width"] .. ": 64 px") end
    if heightSlider.label then heightSlider.label:SetText(T["Height"] .. ": 34 px") end
    if scaleSlider.label then scaleSlider.label:SetText(T["Scale"] .. ": 1.00x") end
    if spacingXSlider.label then spacingXSlider.label:SetText(T["Horizontal Spacing"] .. ": 4 px") end
    if spacingYSlider.label then spacingYSlider.label:SetText(T["Vertical Spacing"] .. ": 3 px") end

    if not FostercareTweaks_Config then FostercareTweaks_Config = {} end
    FostercareTweaks_Config[T["Show Raid Aggro Indicator"]] = 1
    FostercareTweaks_Config[T["Show Raid HoT Indicator"]] = 1
    FostercareTweaks_Config[T["Show Raid Debuff Badges"]] = 1
    current_config[T["Show Raid Aggro Indicator"]] = 1
    current_config[T["Show Raid HoT Indicator"]] = 1
    current_config[T["Show Raid Debuff Badges"]] = 1

    SetRaidHealthFormat("deficit")

    local UF = FostercareTweaks.UnitFrames
    if UF and UF.ApplyGroupDimensions then
        UF:ApplyGroupDimensions(64, 34, 1.0, 4, 3, true)
    end
    if UF and UF.UpdateAllRaidFrames then
        UF:UpdateAllRaidFrames()
    end
end)

testBtn:SetScript("OnClick", function()
    local UF = FostercareTweaks.UnitFrames
    if UF and UF.ToggleRaidTest then
        UF:ToggleRaidTest()
    end
end)

function raidPage:RefreshValues()
    local UF = FostercareTweaks.UnitFrames
    if not UF or not UF.GetGroupDimensions then return end
    local dims = UF:GetGroupDimensions()

    isRaidUpdating = true
    enableCB:SetChecked(dims.enabled)
    widthSlider:SetValue(dims.width)
    heightSlider:SetValue(dims.height)
    scaleSlider:SetValue(dims.scale)
    spacingXSlider:SetValue(dims.spacingX)
    spacingYSlider:SetValue(dims.spacingY)

    aggroCB:SetChecked(UF:IsRaidShowAggro() and true or nil)
    hotCB:SetChecked(UF:IsRaidShowHoT() and true or nil)
    debuffCB:SetChecked(UF:IsRaidShowDebuffs() and true or nil)

    local fmt = (UF.GetRaidHealthFormat and UF:GetRaidHealthFormat()) or "deficit"
    UpdateRaidHealthFormatButtons(fmt)

    isRaidUpdating = false

    if widthSlider.label then widthSlider.label:SetText(T["Width"] .. ": " .. dims.width .. " px") end
    if heightSlider.label then heightSlider.label:SetText(T["Height"] .. ": " .. dims.height .. " px") end
    if scaleSlider.label then scaleSlider.label:SetText(T["Scale"] .. ": " .. string.format("%.2f", dims.scale) .. "x") end
    if spacingXSlider.label then spacingXSlider.label:SetText(T["Horizontal Spacing"] .. ": " .. dims.spacingX .. " px") end
    if spacingYSlider.label then spacingYSlider.label:SetText(T["Vertical Spacing"] .. ": " .. dims.spacingY .. " px") end
end

settings.load = function(self)
    local frameHeight = math.min(UIParent:GetHeight() / UIParent:GetScale() * 0.75, 600)
    if frameHeight < 520 then frameHeight = 520 end
    settings:SetHeight(frameHeight)

    local scrollW = settings.scrollframe:GetWidth()
    if not scrollW or scrollW <= 0 then
        scrollW = max_width - 48
    end

    settings.scrollframe:ClearAllPoints()
    settings.scrollframe:SetPoint("TOPLEFT", settings, "TOPLEFT", 14, -64)
    settings.scrollframe:SetPoint("BOTTOMRIGHT", settings, "BOTTOMRIGHT", -34, 48)
    settings.scrollframe:SetWidth(scrollW)
    settings.container:SetWidth(scrollW)

    settings.entries = settings.entries or {}

    local gui = {}
    for title, module in pairs(FostercareTweaks.mods) do
        local category = module.category or T["General"]
        if category ~= T["Unit Frames"] then
            gui[category] = gui[category] or {}
            gui[category][title] = module
        end
    end

    local topspace = 10
    local required_height = topspace
    local entrysize = 22
    local previous = nil

    local sortCategories = function(a, b)
        if a == T["General"] then return true end
        if b == T["General"] then return false end
        if a == T["Action Bar"] then return true end
        if b == T["Action Bar"] then return false end
        if a == T["Unit Frames"] then return true end
        if b == T["Unit Frames"] then return false end
        if a == T["Nameplates"] then return true end
        if b == T["Nameplates"] then return false end
        if a == T["World & MiniMap"] then return true end
        if b == T["World & MiniMap"] then return false end
        if a == T["Social & Chat"] then return true end
        if b == T["Social & Chat"] then return false end
        if a == T["Tooltip & Items"] then return true end
        if b == T["Tooltip & Items"] then return false end
        return a < b
    end

    for category, entries in FostercareTweaks.spairs(gui, sortCategories) do
        local entry, spacing = 1, 22
        local height = 0

        settings.category = settings.category or {}
        settings.category[category] = settings.category[category] or CreateFrame("Frame", nil, settings.container)
        settings.category[category]:ClearAllPoints()

        if not previous then
            settings.category[category]:SetPoint("TOPLEFT", settings.container, "TOPLEFT", spacing, -spacing - topspace)
            settings.category[category]:SetPoint("TOPRIGHT", settings.container, "TOPRIGHT", -spacing, -spacing - topspace)
        else
            settings.category[category]:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -spacing)
            settings.category[category]:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -spacing)
        end

        previous = settings.category[category]

        local collapse = function(frame, expand)
            local parent = frame or this.parent
            if expand then
                local h = parent.collapse or parent:GetHeight()
                parent.collapse = h
            end

            if not parent.collapse then
                local h = parent:GetHeight()
                parent.collapse = h
                parent:SetHeight(1)
                for button in pairs(parent.buttons) do button:Hide() end
                parent.button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
                parent.button:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
                parent.button:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
                parent.button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
                parent:SetAlpha(0)
            else
                local h = parent.collapse
                parent.collapse = nil
                parent:SetHeight(h)
                for button in pairs(parent.buttons) do button:Show() end
                parent.button:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
                parent.button:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
                parent.button:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
                parent.button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
                parent:SetAlpha(1)
            end
        end

        settings.category[category].button = settings.category[category].button or CreateFrame("Button", nil, settings.container)
        settings.category[category].button:SetPoint("TOPLEFT", settings.category[category], "TOPLEFT", 0, entrysize - 4)
        settings.category[category].button:SetWidth(22)
        settings.category[category].button:SetHeight(22)
        settings.category[category].button.parent = settings.category[category]
        settings.category[category].button:SetScript("OnClick", collapse)

        settings.category[category].title = settings.category[category].title or CreateFrame("Button", nil, settings.container)
        settings.category[category].title:SetPoint("TOPLEFT", settings.category[category], "TOPLEFT", 22, entrysize - 4)
        settings.category[category].title:SetWidth(220)
        settings.category[category].title:SetHeight(entrysize)
        settings.category[category].title.parent = settings.category[category]
        settings.category[category].title:SetScript("OnClick", collapse)

        settings.category[category]:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 16,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })

        if FostercareTweaks.DarkMode then
            settings.category[category]:SetBackdropColor(0.1, 0.1, 0.1, 1)
            settings.category[category]:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
        else
            settings.category[category]:SetBackdropColor(0.2, 0.2, 0.2, 1)
            settings.category[category]:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        end

        settings.category[category].text = settings.category[category].text or settings.category[category].title:CreateFontString(nil, "HIGH", "GameFontHighlightSmall")
        settings.category[category].text:SetJustifyH("LEFT")
        settings.category[category].text:SetAllPoints()
        settings.category[category].text:SetText(category)

        for title, module in FostercareTweaks.spairs(entries) do
            local cleanTitle = string.gsub(title, "[^%w]", "")
            if not settings.entries[title] then
                settings.entries[title] = CreateFrame("CheckButton", "FCTweaksGUI_" .. cleanTitle, settings.category[category], "OptionsCheckButtonTemplate")
                settings.entries[title]:SetHeight(24)
                settings.entries[title]:SetWidth(24)
            end

            local button = settings.entries[title]
            local text = _G[button:GetName() .. "Text"]

            settings.category[category].buttons = settings.category[category].buttons or {}
            settings.category[category].buttons[button] = true

            button.title = title
            button:SetChecked(current_config[title] == 1 and true or nil)
            button:SetPoint("TOPLEFT", settings.category[category], "TOPLEFT", (entry % 2 == 1) and 16 or 240, math.ceil(entry / 2 - 1) * -entrysize - spacing / 2)

            if entry % 2 == 1 then height = height + entrysize end

            local modTitle = module.title
            local modDesc = module.description
            button:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
                GameTooltip:SetText(modTitle, 1, 1, 1, 1, 1)
                GameTooltip:AddLine(modDesc, 0.9, 0.9, 0.9, 1, 1)
                GameTooltip:Show()
            end)

            button:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            button:SetScript("OnClick", function()
                if this:GetChecked() then
                    current_config[this.title] = 1
                else
                    current_config[this.title] = 0
                end
            end)

            text:SetText(title)
            entry = entry + 1
        end

        height = height + spacing
        settings.category[category]:SetHeight(height)
        if not settings.category[category].collapse then
            collapse(settings.category[category], true)
        end
        required_height = required_height + height + spacing
    end

    settings.container:SetParent(settings.scrollframe)
    settings.container:ClearAllPoints()
    settings.container:SetPoint("TOPLEFT", settings.scrollframe, "TOPLEFT", 0, 0)
    settings.container:SetWidth(scrollW)
    settings.container:SetHeight(required_height)
    settings.container:Show()
    settings.scrollframe:SetScrollChild(settings.container)
    settings.scrollframe:Show()
    if settings.scrollframe.UpdateScrollChildRect then
        settings.scrollframe:UpdateScrollChildRect()
    end
end

function settings:defaults()
    for title, mod in pairs(FostercareTweaks.mods) do
        if mod.category ~= T["Unit Frames"] then
            current_config[title] = mod.enabled and 1 or 0
        end
    end
    settings:load()
end

settings:SetScript("OnShow", function()
    current_config = {}
    if FostercareTweaks_Config and FostercareTweaks.mods then
        for title, mod in pairs(FostercareTweaks.mods) do
            current_config[title] = FostercareTweaks_Config[title]
        end
    end
    SelectTab(settings.currentTab or 1)
end)

-- GameMenu Integration
if GameMenuFrame then
    GameMenuFrame:SetWidth(GameMenuFrame:GetWidth() - 10)
    GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + 10)
    local fcMenuBtn = CreateFrame("Button", "GameMenuButtonFostercareTweaks", GameMenuFrame, "GameMenuButtonTemplate")
    fcMenuBtn:SetPoint("TOP", GameMenuButtonUIOptions, "BOTTOM", 0, -1)
    fcMenuBtn:SetText("FostercareTweaks")
    fcMenuBtn:SetScript("OnClick", function()
        HideUIPanel(GameMenuFrame)
        settings:Show()
    end)

    if GameMenuButtonKeybindings then
        GameMenuButtonKeybindings:ClearAllPoints()
        GameMenuButtonKeybindings:SetPoint("TOP", fcMenuBtn, "BOTTOM", 0, -1)
    end
end
