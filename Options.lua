local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: Options.lua
-- Shared settings window: staged general switches and live subsystem pages.


local Theme = FT.SettingsTheme
local current_config = {}
local max_width = 540

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

Theme.Panel(settings, "background")

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
settings.title:SetPoint("TOP", settings, "TOP", 0, -8)
settings.title:SetWidth(380)
settings.title:SetHeight(24)
settings.title.text = Theme.Font(settings.title, "OVERLAY", "GameFontNormal", "heading")
settings.title.text:SetText("FostercareTweaks")
settings.title.text:SetPoint("CENTER", settings.title, "CENTER", 0, 0)

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
Theme.Button(settings.cancel)
settings.cancel:SetWidth(96)
settings.cancel:SetHeight(24)
settings.cancel:SetPoint("BOTTOMRIGHT", settings, "BOTTOMRIGHT", -16, 16)
settings.cancel:SetText(CANCEL)
settings.cancel:SetScript("OnClick", function()
    current_config = {}
    settings:Hide()
end)

settings.okay = CreateFrame("Button", "FostercareTweaksOkay", settings, "GameMenuButtonTemplate")
Theme.Button(settings.okay)
settings.okay:SetWidth(96)
settings.okay:SetHeight(24)
-- Centerline relative positioning (Rule C13)
settings.okay:SetPoint("CENTER", settings.cancel, "CENTER", -104, 0)
settings.okay:SetText(OKAY)
settings.okay:SetScript("OnClick", function()
    local reload = false
    local unitFramesChanged = false

    if FT.mods then
        for title, mod in pairs(FT.mods) do
            if current_config[title] ~= nil and current_config[title] ~= FostercareTweaks_Config[title] then
                FostercareTweaks_Config[title] = current_config[title]
                if mod.category == "Unit Frames" then
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
        local UF = FT.UnitFrames
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
Theme.Button(settings.defaultsBtn)
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

local pageNames = { "scrollframe", "unitPage", "raidPage", "actionPage" }

local function SelectTab(tabId)
    EnsureWindowHeight()
    settings.currentTab = tabId
    for id, tab in ipairs(settings.tabs) do
        if id == tabId then tab:Disable() else tab:Enable() end
        Theme.SelectButton(tab, id == tabId)
    end
    for id, name in ipairs(pageNames) do
        local page = settings[name]
        if page then
            if id == tabId then page:Show() else page:Hide() end
        end
    end
    local general = tabId == 1
    if general then settings.container:Show() else settings.container:Hide() end
    settings.cancel:Show()
    settings.cancel:SetText(general and CANCEL or CLOSE)
    if general then
        settings.okay:Show()
        settings.defaultsBtn:Show()
        settings:load()
    else
        settings.okay:Hide()
        settings.defaultsBtn:Hide()
        local page = settings[pageNames[tabId]]
        if page and page.RefreshValues then page:RefreshValues() end
    end
end
settings.SelectTab = SelectTab

local function CreateTabButton(id, titleText)
    local tab = CreateFrame("Button", "FCTweaksTab" .. id, settings, "UIPanelButtonTemplate")
    tab:SetWidth(110)
    tab:SetHeight(22)
    tab.id = id
    tab:SetText(titleText)
    Theme.Button(tab)
    tab.text = tab:GetFontString()
    if tab.text then
        tab.text:SetFontObject("GameFontNormalSmall")
        Theme.Text(tab.text)
    end
    tab:SetScript("OnClick", function()
        SelectTab(this.id)
    end)
    return tab
end

local tab1 = CreateTabButton(1, "General")
tab1:SetPoint("TOPLEFT", settings, "TOPLEFT", 18, -36)

local tab2 = CreateTabButton(2, "Unit Frames")
tab2:SetPoint("LEFT", tab1, "RIGHT", 4, 0)

local tab3 = CreateTabButton(3, "Raid Frames")
tab3:SetPoint("LEFT", tab2, "RIGHT", 4, 0)

local tab4 = CreateTabButton(4, "Action Bars")
tab4:SetPoint("LEFT", tab3, "RIGHT", 4, 0)
settings.tabs = { tab1, tab2, tab3, tab4 }

local function CreateCheckButton(name, labelText, tooltipText, parent, x, y, buttonText)
    local cb = CreateFrame("CheckButton", name, parent, "OptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetWidth(24)
    cb:SetHeight(24)
    Theme.CheckButton(cb)
    local cbText = _G[name .. "Text"]
    if cbText then
        cbText:SetText(buttonText or labelText)
        cbText:SetFontObject("GameFontNormalSmall")
        Theme.Text(cbText)
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
    Theme.Slider(slider)

    local lowText = _G[name .. "Low"]
    if lowText then
        lowText:SetText(tostring(minVal) .. unitSuffix)
        lowText:SetFontObject("GameFontHighlightSmall")
        Theme.Text(lowText, "muted")
    end
    local highText = _G[name .. "High"]
    if highText then
        highText:SetText(tostring(maxVal) .. unitSuffix)
        highText:SetFontObject("GameFontHighlightSmall")
        Theme.Text(highText, "muted")
    end

    slider.label = _G[name .. "Text"]
    if slider.label then
        slider.label:SetFontObject("GameFontNormalSmall")
        Theme.Text(slider.label)
    end
    slider.baseLabel = labelText
    slider.unitSuffix = unitSuffix
    slider.stepVal = stepVal

    return slider
end

local function CreateSectionBox(parent, titleText, height)
    local box = CreateFrame("Frame", nil, parent)
    box:SetHeight(height)
    Theme.Panel(box)
    box.title = Theme.Font(box, "OVERLAY", "GameFontNormalSmall")
    box.title:SetPoint("TOPLEFT", box, "TOPLEFT", 12, -8)
    box.title:SetText(titleText)
    Theme.Text(box.title, "heading")
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
unitContainer:SetHeight(1920)
unitPage:SetScrollChild(unitContainer)

-- One style control per frame; unchecked uses the standard Blizzard frame.
local ufBox = CreateSectionBox(unitContainer, "Modern Unit Frames", 180)
ufBox:SetPoint("TOPLEFT", unitContainer, "TOPLEFT", 22, -10)
ufBox:SetPoint("TOPRIGHT", unitContainer, "TOPRIGHT", -22, -10)
local modernPlayerCB = CreateCheckButton("FCTweaksModPlayerCB", "Modern Player Frame", "Replace the Blizzard player frame with a modern frame.", ufBox, 16, -24)
local modernTargetCB = CreateCheckButton("FCTweaksModTargetCB", "Modern Target Frame", "Replace the Blizzard target frame with a modern frame.", ufBox, 16, -48)
local modernToTCB = CreateCheckButton("FCTweaksModToTCB", "Modern Target's Target", "Replace the Blizzard target-of-target frame with a modern frame.", ufBox, 16, -72)
local modernComboCB = CreateCheckButton("FCTweaksModComboCB", "Modern Combo Points", "Display combo points on the modern target unit frame.", ufBox, 16, -96)
local modernPvPCB = CreateCheckButton("FCTweaksModPvPCB", "Show PvP Emblem", "Display faction PvP emblem on modern unit frames.", ufBox, 230, -24)
local modernLevelCB = CreateCheckButton("FCTweaksModLevelCB", "Show Level Badge", "Show player level and target difficulty. Bosses use the native skull.", ufBox, 230, -48)
local modernClassCB = CreateCheckButton("FCTweaksModClassCB", "Show Class or Creature Type", "Show player class and target class or creature type in a separate text lane.", ufBox, 230, -72)
local styleHint = Theme.Font(ufBox, "OVERLAY", "GameFontHighlightSmall")
styleHint:SetPoint("TOPLEFT", ufBox, "TOPLEFT", 24, -118)
styleHint:SetText("Unchecked frames use Blizzard artwork. Changes apply immediately.")
Theme.Text(styleHint, "hint")
local ufScaleSlider = CreateSlider("FCTweaksUFScaleSlider", "Modern Frame Scale", 0.5, 2.0, 0.05, "x", ufBox, 16, -146, 416)

local dimBox = CreateSectionBox(unitContainer, "Modern Frame Dimensions", 215)
dimBox:SetPoint("TOPLEFT", ufBox, "BOTTOMLEFT", 0, -14)
dimBox:SetPoint("TOPRIGHT", ufBox, "BOTTOMRIGHT", 0, -14)
local ufPlayerWSlider = CreateSlider("FCTweaksUFPlayerWSlider", "Player Width", 140, 350, 2, " px", dimBox, 16, -30, 195)
local ufPlayerHSlider = CreateSlider("FCTweaksUFPlayerHSlider", "Player Height", 30, 80, 1, " px", dimBox, 230, -30, 195)
local ufTargetWSlider = CreateSlider("FCTweaksUFTargetWSlider", "Target Width", 140, 350, 2, " px", dimBox, 16, -78, 195)
local ufTargetHSlider = CreateSlider("FCTweaksUFTargetHSlider", "Target Height", 30, 80, 1, " px", dimBox, 230, -78, 195)
local ufToTWSlider = CreateSlider("FCTweaksUFToTWSlider", "ToT Width", 80, 220, 2, " px", dimBox, 16, -126, 195)
local ufToTHSlider = CreateSlider("FCTweaksUFToTHSlider", "ToT Height", 20, 50, 1, " px", dimBox, 230, -126, 195)
local ufPowerHSlider = CreateSlider("FCTweaksUFPowerHSlider", "Power Bar Height", 4, 20, 1, " px", dimBox, 16, -174, 416)

local fontBox = CreateSectionBox(unitContainer, "Modern Frame Fonts", 125)
fontBox:SetPoint("TOPLEFT", dimBox, "BOTTOMLEFT", 0, -14)
fontBox:SetPoint("TOPRIGHT", dimBox, "BOTTOMRIGHT", 0, -14)
local ufFontNameSlider = CreateSlider("FCTweaksUFFontNameSlider", "Name Font Size", 8, 18, 1, " pt", fontBox, 16, -30, 195)
local ufFontLevelSlider = CreateSlider("FCTweaksUFFontLevelSlider", "Level / Class Font Size", 8, 16, 1, " pt", fontBox, 230, -30, 195)
local ufFontHealthSlider = CreateSlider("FCTweaksUFFontHealthSlider", "Health Font Size", 8, 18, 1, " pt", fontBox, 16, -78, 195)
local ufFontPowerSlider = CreateSlider("FCTweaksUFFontPowerSlider", "Power Font Size", 8, 16, 1, " pt", fontBox, 230, -78, 195)

local formatBox = CreateSectionBox(unitContainer, "Modern Frame Text Content & Formatting", 136)
formatBox:SetPoint("TOPLEFT", fontBox, "BOTTOMLEFT", 0, -14)
formatBox:SetPoint("TOPRIGHT", fontBox, "BOTTOMRIGHT", 0, -14)

local healthFmtLabel = Theme.Font(formatBox, "OVERLAY", "GameFontNormalSmall")
healthFmtLabel:SetPoint("TOPLEFT", formatBox, "TOPLEFT", 16, -26)
healthFmtLabel:SetText("Health Format:")

local fmtHpCurMaxBtn = CreateFrame("Button", "FCTweaksFmtHpCurMaxBtn", formatBox, "UIPanelButtonTemplate")
Theme.Button(fmtHpCurMaxBtn)
fmtHpCurMaxBtn:SetWidth(72); fmtHpCurMaxBtn:SetHeight(22)
fmtHpCurMaxBtn:SetPoint("LEFT", healthFmtLabel, "RIGHT", 10, 0)
fmtHpCurMaxBtn:SetText("Smart")
if fmtHpCurMaxBtn:GetFontString() then fmtHpCurMaxBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local fmtHpCurBtn = CreateFrame("Button", "FCTweaksFmtHpCurBtn", formatBox, "UIPanelButtonTemplate")
Theme.Button(fmtHpCurBtn)
fmtHpCurBtn:SetWidth(64); fmtHpCurBtn:SetHeight(22)
fmtHpCurBtn:SetPoint("LEFT", fmtHpCurMaxBtn, "RIGHT", 4, 0)
fmtHpCurBtn:SetText("Current")
if fmtHpCurBtn:GetFontString() then fmtHpCurBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local fmtHpPctBtn = CreateFrame("Button", "FCTweaksFmtHpPctBtn", formatBox, "UIPanelButtonTemplate")
Theme.Button(fmtHpPctBtn)
fmtHpPctBtn:SetWidth(60); fmtHpPctBtn:SetHeight(22)
fmtHpPctBtn:SetPoint("LEFT", fmtHpCurBtn, "RIGHT", 4, 0)
fmtHpPctBtn:SetText("Percent")
if fmtHpPctBtn:GetFontString() then fmtHpPctBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local fmtHpDefBtn = CreateFrame("Button", "FCTweaksFmtHpDefBtn", formatBox, "UIPanelButtonTemplate")
Theme.Button(fmtHpDefBtn)
fmtHpDefBtn:SetWidth(58); fmtHpDefBtn:SetHeight(22)
fmtHpDefBtn:SetPoint("LEFT", fmtHpPctBtn, "RIGHT", 4, 0)
fmtHpDefBtn:SetText("Deficit")
if fmtHpDefBtn:GetFontString() then fmtHpDefBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local fmtHpHideBtn = CreateFrame("Button", "FCTweaksFmtHpHideBtn", formatBox, "UIPanelButtonTemplate")
Theme.Button(fmtHpHideBtn)
fmtHpHideBtn:SetWidth(56); fmtHpHideBtn:SetHeight(22)
fmtHpHideBtn:SetPoint("LEFT", fmtHpDefBtn, "RIGHT", 4, 0)
fmtHpHideBtn:SetText("Hidden")
if fmtHpHideBtn:GetFontString() then fmtHpHideBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local powerFmtLabel = Theme.Font(formatBox, "OVERLAY", "GameFontNormalSmall")
powerFmtLabel:SetPoint("TOPLEFT", formatBox, "TOPLEFT", 16, -60)
powerFmtLabel:SetText("Power Format:")

local fmtPwCurMaxBtn = CreateFrame("Button", "FCTweaksFmtPwCurMaxBtn", formatBox, "UIPanelButtonTemplate")
Theme.Button(fmtPwCurMaxBtn)
fmtPwCurMaxBtn:SetWidth(72); fmtPwCurMaxBtn:SetHeight(22)
fmtPwCurMaxBtn:SetPoint("LEFT", powerFmtLabel, "RIGHT", 12, 0)
fmtPwCurMaxBtn:SetText("Smart")
if fmtPwCurMaxBtn:GetFontString() then fmtPwCurMaxBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local fmtPwCurBtn = CreateFrame("Button", "FCTweaksFmtPwCurBtn", formatBox, "UIPanelButtonTemplate")
Theme.Button(fmtPwCurBtn)
fmtPwCurBtn:SetWidth(64); fmtPwCurBtn:SetHeight(22)
fmtPwCurBtn:SetPoint("LEFT", fmtPwCurMaxBtn, "RIGHT", 4, 0)
fmtPwCurBtn:SetText("Current")
if fmtPwCurBtn:GetFontString() then fmtPwCurBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local fmtPwPctBtn = CreateFrame("Button", "FCTweaksFmtPwPctBtn", formatBox, "UIPanelButtonTemplate")
Theme.Button(fmtPwPctBtn)
fmtPwPctBtn:SetWidth(60); fmtPwPctBtn:SetHeight(22)
fmtPwPctBtn:SetPoint("LEFT", fmtPwCurBtn, "RIGHT", 4, 0)
fmtPwPctBtn:SetText("Percent")
if fmtPwPctBtn:GetFontString() then fmtPwPctBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local fmtPwHideBtn = CreateFrame("Button", "FCTweaksFmtPwHideBtn", formatBox, "UIPanelButtonTemplate")
Theme.Button(fmtPwHideBtn)
fmtPwHideBtn:SetWidth(56); fmtPwHideBtn:SetHeight(22)
fmtPwHideBtn:SetPoint("LEFT", fmtPwPctBtn, "RIGHT", 4, 0)
fmtPwHideBtn:SetText("Hidden")
if fmtPwHideBtn:GetFontString() then fmtPwHideBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local modernNameCB = CreateCheckButton("FCTweaksModernNameCB", "Show Unit Name", "Display unit name on modern unit frames.", formatBox, 16, -98)

local markBox = CreateSectionBox(unitContainer, "Raid Target Marks", 148)
markBox:SetPoint("TOPLEFT", formatBox, "BOTTOMLEFT", 0, -14)
markBox:SetPoint("TOPRIGHT", formatBox, "BOTTOMRIGHT", 0, -14)
local markSizeSlider = CreateSlider("FCTweaksMarkSizeSlider", "Unit Frame Mark Size", 12, 36, 1, " px", markBox, 16, -32, 196)
local plateMarkSizeSlider = CreateSlider("FCTweaksPlateMarkSizeSlider", "Nameplate Mark Size", 12, 32, 1, " px", markBox, 236, -32, 196)
local markOutsideCB = CreateCheckButton("FCTweaksMarkOutsideCB", "Marks Beside Portraits", "Place unit frame marks outside the portrait. Raid marks keep a reserved column inside member frames.", markBox, 16, -62)
local plateMarkAboveCB = CreateCheckButton("FCTweaksPlateMarkAboveCB", "Marks Above Nameplates", "Place marks above the name. Otherwise they sit beside the health bar. ShaguPlates keeps its own marks.", markBox, 236, -62)
local markHint = Theme.Font(markBox, "OVERLAY", "GameFontHighlightSmall")
markHint:SetPoint("TOPLEFT", markBox, "TOPLEFT", 24, -104)
markHint:SetWidth(400); markHint:SetJustifyH("LEFT")
markHint:SetText("Marks fit portrait space; fonts fit each lane. Smart text shows maximum values when useful. Power text hides below 8 px bar height.")

local sharedBox = CreateSectionBox(unitContainer, "Shared Frame Features", 188)
sharedBox:SetPoint("TOPLEFT", markBox, "BOTTOMLEFT", 0, -14)
sharedBox:SetPoint("TOPRIGHT", markBox, "BOTTOMRIGHT", 0, -14)
local moveUFCB = CreateCheckButton("FCTweaksMoveUFCB", "Movable Unit Frames", "Hold Ctrl+Shift to move frames and separate buff/debuff areas.", sharedBox, 16, -24)
local classColorCB = CreateCheckButton("FCTweaksClassColorCB", "Unit Frame Class Colors", "Class colors on standard player and target name backgrounds.", sharedBox, 16, -48)
local classPortraitCB = CreateCheckButton("FCTweaksClassPortCB", "Unit Frame Class Portraits", "Class portraits on standard Blizzard frames.", sharedBox, 16, -72)
local healthNumbersCB = CreateCheckButton("FCTweaksHealthNumCB", "Real Health Numbers", "Real health values on standard unit frames.", sharedBox, 230, -24)
local energyTickCB = CreateCheckButton("FCTweaksEnergyTickCB", "Show Energy Ticks", "Estimated two-second energy ticks; mana spending shows the five-second rule. Spell gains are excluded when NamPower v4.6.2+ is available.", sharedBox, 230, -48)
local enemyCastbarCB = CreateCheckButton("FCTweaksEnemyCastCB", "Enemy Castbars", "Castbar on the active target frame.", sharedBox, 230, -72)
local uninterruptCB = CreateCheckButton("FCTweaksUninterruptCB", "Uninterruptible Castbars", "Highlight uninterruptible target/nameplate casts.", sharedBox, 16, -96)
local debuffTimerCB = CreateCheckButton("FCTweaksDebuffTimerCB", "Debuff Timer", "Timers on original target debuff icons when Improved Standard Auras is disabled.", sharedBox, 230, -96)
local improvedStandardAurasCB = CreateCheckButton("FCTweaksImpStdAurasCB", "Improved Standard Auras", "Show enhanced auras on standard frames. Hold Ctrl+Shift to move each aura area.", sharedBox, 16, -120)
local reloadFrameFeaturesBtn = CreateFrame("Button", "FCTweaksReloadFrameFeaturesBtn", sharedBox, "UIPanelButtonTemplate")
Theme.Button(reloadFrameFeaturesBtn)
reloadFrameFeaturesBtn:SetPoint("TOPLEFT", sharedBox, "TOPLEFT", 16, -150)
reloadFrameFeaturesBtn:SetWidth(200); reloadFrameFeaturesBtn:SetHeight(22)
reloadFrameFeaturesBtn:SetText("Apply Features / Reload UI")
reloadFrameFeaturesBtn:SetScript("OnClick", function() ReloadUI() end)

local energyBox = CreateSectionBox(unitContainer, "Energy Tick Visibility", 106)
energyBox:SetPoint("TOPLEFT", sharedBox, "BOTTOMLEFT", 0, -14)
energyBox:SetPoint("TOPRIGHT", sharedBox, "BOTTOMRIGHT", 0, -14)
local energyContrastCB = CreateCheckButton("FCTweaksEnergyContrastCB", "Bright Tick Line", "Add a white center and glow so ticks stand out against the power bar.", energyBox, 16, -24)
local energyFlashCB = CreateCheckButton("FCTweaksEnergyFlashCB", "Flash on Tick", "Briefly light the bottom edge at each estimated tick, including the end of the mana five-second rule.", energyBox, 230, -24)
local energyWidthSlider = CreateSlider("FCTweaksEnergyWidthSlider", "Tick Line Width", 2, 6, 1, " px", energyBox, 16, -68, 416)
local energyHint = Theme.Font(energyBox, "OVERLAY", "GameFontDisableSmall")
energyHint:SetPoint("TOPLEFT", energyBox, "TOPLEFT", 16, -87)
energyHint:SetText("Applies live to both frame styles. Width affects the bright tick line.")

-- Box 2: Buff Settings
local buffBox = CreateSectionBox(unitContainer, "Buff Settings", 130)
buffBox:SetPoint("TOPLEFT", energyBox, "BOTTOMLEFT", 0, -14)
buffBox:SetPoint("TOPRIGHT", energyBox, "BOTTOMRIGHT", 0, -14)

local showBuffsPlayerCB = CreateCheckButton("FCTweaksShowBuffsPlayerCB", "Show Player Buffs",         "Display buff icons on the active player unit frame.", buffBox, 16, -24)
local showBuffsTargetCB = CreateCheckButton("FCTweaksShowBuffsTargetCB", "Show Target Buffs",         "Display buff icons on the active target unit frame.", buffBox, 16, -48)
local buffSpinCB        = CreateCheckButton("FCTweaksBuffSpinCB",        "Show Buff Cooldown Spiral", "Display Luna radial clock animation on active buffs.", buffBox, 230, -24)
local buffTextCB        = CreateCheckButton("FCTweaksBuffTextCB",        "Show Buff Duration Text",   "Display remaining cooldown countdown numbers on buffs.", buffBox, 230, -48)

local buffSizeSlider    = CreateSlider("FCTweaksBuffSizeSlider", "Buff Size", 14, 32, 1, " px", buffBox, 16, -98, 416)

-- Debuff display and target armor emphasis
local debuffBox = CreateSectionBox(unitContainer, "Debuff Settings", 216)
debuffBox:SetPoint("TOPLEFT", buffBox, "BOTTOMLEFT", 0, -14)
debuffBox:SetPoint("TOPRIGHT", buffBox, "BOTTOMRIGHT", 0, -14)

local showDebuffsPlayerCB = CreateCheckButton("FCTweaksShowDebuffsPlayerCB", "Show Player Debuffs",            "Display debuff icons on the active player unit frame.", debuffBox, 16, -24)
local showDebuffsTargetCB = CreateCheckButton("FCTweaksShowDebuffsTargetCB", "Show Target Debuffs",            "Display debuff icons on the active target unit frame.", debuffBox, 16, -48)
local colorDispelCB       = CreateCheckButton("FCTweaksColorDispelCB",       "Color Debuffs by Dispel Type",    "Color debuff borders according to dispel type (Magic, Curse, Disease, Poison) like Luna.", debuffBox, 16, -72)

local debuffSpinCB        = CreateCheckButton("FCTweaksDebuffSpinCB",        "Show Debuff Cooldown Spiral",    "Display Luna radial clock animation on active debuffs.", debuffBox, 230, -24)
local debuffTextCB        = CreateCheckButton("FCTweaksDebuffTextCB",        "Show Debuff Duration Text",      "Display remaining cooldown countdown numbers on debuffs.", debuffBox, 230, -48)
local onlyMyDebuffsCB     = CreateCheckButton("FCTweaksOnlyMyDebuffsCB",     "Only Show My Debuffs on Target", "Filter target debuffs to only show debuffs applied by you.", debuffBox, 230, -72)

local debuffSizeSlider    = CreateSlider("FCTweaksDebuffSizeSlider", "Debuff Size", 14, 32, 1, " px", debuffBox, 16, -122, 416)
local armorDebuffCB = CreateCheckButton("FCTweaksArmorDebuffCB", "Larger Armor Debuffs", "Enlarge Sunder Armor, Faerie Fire and Expose Armor on enhanced target aura rows. Your debuff filter still applies.", debuffBox, 16, -150)
local armorScaleSlider = CreateSlider("FCTweaksArmorScaleSlider", "Armor Debuff Size", 1.25, 2, 0.05, "x", debuffBox, 236, -181, 196)


-- Styling is independent of aura visibility and inventory border settings.
local borderBox = CreateSectionBox(unitContainer, "Blizzard & Frame Aura Borders", 96)
borderBox:SetPoint("TOPLEFT", debuffBox, "BOTTOMLEFT", 0, -14)
borderBox:SetPoint("TOPRIGHT", debuffBox, "BOTTOMRIGHT", 0, -14)
local auraBorderChecks = {}
for i, spec in ipairs({
    { "FCTweaksBuffBordersCB", "Show Buff Borders", 0, "Border around top-right Blizzard buffs and player, target and raid buffs." },
    { "FCTweaksDebuffBordersCB", "Show Debuff Borders", 0, "Border around top-right Blizzard debuffs and player, target and raid debuffs. Dispel colors follow their own setting." },
    { "FCTweaksEnchantBordersCB", "Show Weapon Enchant Borders", 1, "Item-quality border around top-right Blizzard weapon enchants, independent of Item Rarity Borders." },
}) do
    local cb = CreateCheckButton(spec[1], spec[2], spec[4], borderBox, 16, -24 * i)
    cb.setting, cb.defaultValue = spec[2], spec[3]
    cb:SetScript("OnClick", function()
        local value = this:GetChecked() and 1 or 0
        FostercareTweaks_Config[this.setting] = value
        current_config[this.setting] = value
        if FT.ApplyStandardAuraSettings then FT.ApplyStandardAuraSettings() end
        local UF = FT.UnitFrames
        if UF and UF.Auras then UF.Auras:RefreshBorders() end
    end)
    table.insert(auraBorderChecks, cb)
end

-- Independent of the enhanced player-frame aura controls above.
local nativeAuraBox = CreateSectionBox(unitContainer, "Top-right Blizzard Auras", 120)
nativeAuraBox:SetPoint("TOPLEFT", borderBox, "BOTTOMLEFT", 0, -14)
nativeAuraBox:SetPoint("TOPRIGHT", borderBox, "BOTTOMRIGHT", 0, -14)
local nativeAuraChecks = {}
for i, spec in ipairs({
    { "FCTweaksNativeBuffsCB", "Show Standard Buffs" },
    { "FCTweaksNativeDebuffsCB", "Show Standard Debuffs" },
    { "FCTweaksNativeEnchantsCB", "Show Weapon Enchants" },
}) do
    local cb = CreateCheckButton(spec[1], spec[2], "Show this original Blizzard aura area. Player-frame auras are unaffected.", nativeAuraBox, 16, -24 * i)
    cb.setting = spec[2]
    cb:SetScript("OnClick", function()
        local value = this:GetChecked() and 1 or 0
        FostercareTweaks_Config[this.setting] = value
        current_config[this.setting] = value
        if FT.ApplyStandardAuraSettings then FT.ApplyStandardAuraSettings() end
    end)
    table.insert(nativeAuraChecks, cb)
end
local nativeAuraHint = Theme.Font(nativeAuraBox, "OVERLAY", "GameFontHighlightSmall")
nativeAuraHint:SetPoint("TOPLEFT", nativeAuraBox, "TOPLEFT", 240, -30)
nativeAuraHint:SetWidth(185); nativeAuraHint:SetJustifyH("LEFT")
nativeAuraHint:SetText("Hold Ctrl+Shift to move each visible area. Enable Movable Unit Frames above. Reset Frame Positions also resets these areas.")

-- Action Buttons
local resetPosBtn = CreateFrame("Button", "FCTweaksResetUFPosBtn", unitContainer, "UIPanelButtonTemplate")
Theme.Button(resetPosBtn)
resetPosBtn:SetPoint("TOPLEFT", nativeAuraBox, "BOTTOMLEFT", 0, -12)
resetPosBtn:SetWidth(218)
resetPosBtn:SetHeight(24)
resetPosBtn:SetText("Reset Frame Positions")
if resetPosBtn:GetFontString() then resetPosBtn:GetFontString():SetFontObject("GameFontNormalSmall") end
resetPosBtn:SetScript("OnClick", function()
    if FostercareTweaks_Config then
        FostercareTweaks_Config.unitframe_positions = nil
    end
    ReloadUI()
end)

local resetUFDefaultsBtn = CreateFrame("Button", "FCTweaksResetUFDefaultsBtn", unitContainer, "UIPanelButtonTemplate")
Theme.Button(resetUFDefaultsBtn)
resetUFDefaultsBtn:SetPoint("TOPRIGHT", nativeAuraBox, "BOTTOMRIGHT", 0, -12)
resetUFDefaultsBtn:SetWidth(218)
resetUFDefaultsBtn:SetHeight(24)
resetUFDefaultsBtn:SetText("Reset to Defaults")
if resetUFDefaultsBtn:GetFontString() then resetUFDefaultsBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local isUFUpdating = false
local function ApplyEnergySettings(self)
    if isUFUpdating then return end
    local control = self or this
    if control == energyWidthSlider then
        local value = math.floor(control:GetValue() + 0.5)
        FT.SetOverride("energytick_width", value)
        control.label:SetText("Tick Line Width: " .. value .. " px")
    else
        FT.SetOverride(control == energyContrastCB and "energytick_contrast" or "energytick_flash", control:GetChecked() and 1 or 0)
    end
    if FT.RefreshEnergyTick then FT.RefreshEnergyTick() end
end
energyContrastCB:SetScript("OnClick", ApplyEnergySettings)
energyFlashCB:SetScript("OnClick", ApplyEnergySettings)
energyWidthSlider:SetScript("OnValueChanged", ApplyEnergySettings)
local function ApplyMarkSettings(self)
    if isUFUpdating then return end
    local control = self or this
    if control == markSizeSlider then
        local value = math.floor(control:GetValue() + 0.5)
        FT.SetOverride("raidmark_size", value)
        control.label:SetText("Unit Frame Mark Size: " .. value .. " px")
    elseif control == plateMarkSizeSlider then
        local value = math.floor(control:GetValue() + 0.5)
        FT.SetOverride("nameplate_raidmark_size", value)
        control.label:SetText("Nameplate Mark Size: " .. value .. " px")
    elseif control == markOutsideCB then
        FT.SetOverride("raidmark_position", control:GetChecked() and "outside" or "portrait")
    elseif control == plateMarkAboveCB then
        FT.SetOverride("nameplate_raidmark_position", control:GetChecked() and "above" or "left")
    end
    if FT.RefreshRaidMarks then FT:RefreshRaidMarks() end
end
markSizeSlider:SetScript("OnValueChanged", ApplyMarkSettings)
plateMarkSizeSlider:SetScript("OnValueChanged", ApplyMarkSettings)
markOutsideCB:SetScript("OnClick", ApplyMarkSettings)
plateMarkAboveCB:SetScript("OnClick", ApplyMarkSettings)
local function ApplyArmorSettings(self)
    if isUFUpdating then return end
    local control = self or this
    if control == armorDebuffCB then
        local value = control:GetChecked() and 1 or 0
        FostercareTweaks_Config["Larger Armor Debuffs"], current_config["Larger Armor Debuffs"] = value, value
    elseif control == armorScaleSlider then
        local value = math.floor(control:GetValue() * 100 + 0.5) / 100
        FT.SetOverride("uf_armor_debuff_scale", value)
        control.label:SetText("Armor Debuff Size: " .. string.format("%.2f", value) .. "x")
    end
    FT.UnitFrames:ApplyConfiguration()
end
armorDebuffCB:SetScript("OnClick", ApplyArmorSettings)
armorScaleSlider:SetScript("OnValueChanged", ApplyArmorSettings)
local unitChecks = {
    { modernPlayerCB, "Modern Player Frame" },
    { modernTargetCB, "Modern Target Frame" },
    { modernToTCB, "Modern Target's Target" },
    { modernComboCB, "Modern Combo Points" },
    { modernPvPCB, "Show PvP Emblem" },
    { modernLevelCB, "Show Target Level" },
    { modernClassCB, "Show Target Class" },
    { modernNameCB, "Show Unit Name" },
    { moveUFCB, "Movable Unit Frames" },
    { classColorCB, "Unit Frame Class Colors" },
    { classPortraitCB, "Unit Frame Class Portraits" },
    { healthNumbersCB, "Real Health Numbers" },
    { energyTickCB, "Show Energy Ticks" },
    { enemyCastbarCB, "Enemy Castbars" },
    { uninterruptCB, "Uninterruptible Castbars" },
    { debuffTimerCB, "Debuff Timer" },
    { improvedStandardAurasCB, "Improved Standard Auras" },
    { showBuffsPlayerCB, "Show Player Buffs" },
    { showBuffsTargetCB, "Show Target Buffs" },
    { buffSpinCB, "Show Buff Cooldown Spiral" },
    { buffTextCB, "Show Buff Duration Text" },
    { showDebuffsPlayerCB, "Show Player Debuffs" },
    { showDebuffsTargetCB, "Show Target Debuffs" },
    { debuffSpinCB, "Show Debuff Cooldown Spiral" },
    { debuffTextCB, "Show Debuff Duration Text" },
    { colorDispelCB, "Color Debuffs by Dispel Type" },
    { onlyMyDebuffsCB, "Only Show My Debuffs on Target" },
}
local function OnUnitCheckboxClicked(self)
    if isUFUpdating then return end
    local control = self or this
    local key = control.setting
    local value = control:GetChecked() and 1 or 0
    FostercareTweaks_Config[key], current_config[key] = value, value
    local UF = FT.UnitFrames
    if UF then UF:ApplyConfiguration() end
    local classColor = FT.mods["Unit Frame Class Colors"]
    if key == "Unit Frame Class Colors" and classColor and classColor.apply then classColor:apply() end
end
for _, entry in ipairs(unitChecks) do
    entry[1].setting = entry[2]
    entry[1]:SetScript("OnClick", OnUnitCheckboxClicked)
end

buffSizeSlider:SetScript("OnValueChanged", function()
    if isUFUpdating then return end
    local val = math.floor(this:GetValue() + 0.5)
    if buffSizeSlider.label then buffSizeSlider.label:SetText("Buff Size" .. ": " .. val .. " px") end
    FT.SetOverride("uf_buff_size", val)

    local UF = FT.UnitFrames
    if UF and UF.Auras and UF.Auras.ApplyBuffSize then
        if UF.playerFrame and UF.playerFrame.auraContainer then
            UF.Auras:ApplyBuffSize(UF.playerFrame.auraContainer, val)
        end
        if UF.targetFrame and UF.targetFrame.auraContainer then
            UF.Auras:ApplyBuffSize(UF.targetFrame.auraContainer, val)
        end
        if UF.blizzPlayerAuras then
            UF.Auras:ApplyBuffSize(UF.blizzPlayerAuras, val)
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
    if debuffSizeSlider.label then debuffSizeSlider.label:SetText("Debuff Size" .. ": " .. val .. " px") end
    FT.SetOverride("uf_debuff_size", val)

    local UF = FT.UnitFrames
    if UF and UF.Auras and UF.Auras.ApplyDebuffSize then
        if UF.playerFrame and UF.playerFrame.auraContainer then
            UF.Auras:ApplyDebuffSize(UF.playerFrame.auraContainer, val)
        end
        if UF.targetFrame and UF.targetFrame.auraContainer then
            UF.Auras:ApplyDebuffSize(UF.targetFrame.auraContainer, val)
        end
        if UF.blizzPlayerAuras then
            UF.Auras:ApplyDebuffSize(UF.blizzPlayerAuras, val)
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
    if ufScaleSlider.label then ufScaleSlider.label:SetText("Modern Frame Scale" .. ": " .. string.format("%.2f", val) .. "x") end
    FT.SetOverride("uf_scale", val)
    local UF = FT.UnitFrames
    if UF and UF.ApplyScale then UF:ApplyScale(val) end
end)

local function ApplyUnitNumber(self)
    if isUFUpdating then return end
    local control = self or this
    local value = math.floor(control:GetValue() + 0.5)
    FT.SetOverride(control.setting, value)
    if control.label then control.label:SetText(control.caption .. ": " .. value .. " " .. control.suffix) end
    local UF = FT.UnitFrames
    if UF then
        if control.layout == "fonts" then UF:ApplyFonts() else UF:ApplyConfiguration() end
    end
end
local unitNumbers = {
    { ufPlayerWSlider, "uf_player_width", "Player Width", "px", "dimensions" },
    { ufPlayerHSlider, "uf_player_height", "Player Height", "px", "dimensions" },
    { ufTargetWSlider, "uf_target_width", "Target Width", "px", "dimensions" },
    { ufTargetHSlider, "uf_target_height", "Target Height", "px", "dimensions" },
    { ufToTWSlider, "uf_tot_width", "ToT Width", "px", "dimensions" },
    { ufToTHSlider, "uf_tot_height", "ToT Height", "px", "dimensions" },
    { ufPowerHSlider, "uf_power_height", "Power Bar Height", "px", "dimensions" },
    { ufFontNameSlider, "uf_font_name", "Name Font Size", "pt", "fonts" },
    { ufFontLevelSlider, "uf_font_level", "Level / Class Font Size", "pt", "fonts" },
    { ufFontHealthSlider, "uf_font_health", "Health Font Size", "pt", "fonts" },
    { ufFontPowerSlider, "uf_font_power", "Power Font Size", "pt", "fonts" },
}
for _, entry in ipairs(unitNumbers) do
    local control = entry[1]
    control.setting, control.caption, control.suffix, control.layout = entry[2], entry[3], entry[4], entry[5]
    control:SetScript("OnValueChanged", ApplyUnitNumber)
end

local healthFormats = {
    smart = fmtHpCurMaxBtn,
    current = fmtHpCurBtn,
    percent = fmtHpPctBtn,
    deficit = fmtHpDefBtn,
    none = fmtHpHideBtn,
}
local function UpdateUFHealthFormatButtons(fmt)
    if not healthFormats[fmt] then fmt = "smart" end
    for value, button in pairs(healthFormats) do
        if value == fmt then button:Disable() else button:Enable() end
        Theme.SelectButton(button, value == fmt)
    end
end

local function SetUFHealthFormat(fmt)
    FT.SetOverride("uf_health_format", fmt)
    UpdateUFHealthFormatButtons(fmt)
    local UF = FT.UnitFrames
    if UF and UF.ApplyConfiguration then UF:ApplyConfiguration() end
end

local powerFormats = {
    smart = fmtPwCurMaxBtn,
    current = fmtPwCurBtn,
    percent = fmtPwPctBtn,
    none = fmtPwHideBtn,
}
local function UpdateUFPowerFormatButtons(fmt)
    if not powerFormats[fmt] then fmt = "smart" end
    for value, button in pairs(powerFormats) do
        if value == fmt then button:Disable() else button:Enable() end
        Theme.SelectButton(button, value == fmt)
    end
end

local function SetUFPowerFormat(fmt)
    FT.SetOverride("uf_power_format", fmt)
    UpdateUFPowerFormatButtons(fmt)
    local UF = FT.UnitFrames
    if UF and UF.ApplyConfiguration then UF:ApplyConfiguration() end
end

fmtHpCurMaxBtn:SetScript("OnClick", function() SetUFHealthFormat("smart") end)
fmtHpCurBtn:SetScript("OnClick", function() SetUFHealthFormat("current") end)
fmtHpPctBtn:SetScript("OnClick", function() SetUFHealthFormat("percent") end)
fmtHpDefBtn:SetScript("OnClick", function() SetUFHealthFormat("deficit") end)
fmtHpHideBtn:SetScript("OnClick", function() SetUFHealthFormat("none") end)

fmtPwCurMaxBtn:SetScript("OnClick", function() SetUFPowerFormat("smart") end)
fmtPwCurBtn:SetScript("OnClick", function() SetUFPowerFormat("current") end)
fmtPwPctBtn:SetScript("OnClick", function() SetUFPowerFormat("percent") end)
fmtPwHideBtn:SetScript("OnClick", function() SetUFPowerFormat("none") end)

local unitDefaultOverrides = {
    uf_scale = 1, uf_buff_size = 20, uf_debuff_size = 20, uf_aura_size = 20,
    uf_player_width = 200, uf_player_height = 42, uf_target_width = 200, uf_target_height = 42,
    uf_tot_width = 120, uf_tot_height = 26, uf_power_height = 10,
    uf_font_name = 12, uf_font_level = 11, uf_font_health = 11, uf_font_power = 11,
    uf_health_format = "smart", uf_power_format = "smart", uf_armor_debuff_scale = 1.5,
    raidmark_size = 22, raidmark_position = "portrait",
    nameplate_raidmark_size = 20, nameplate_raidmark_position = "left",
    energytick_contrast = 1, energytick_flash = 1, energytick_width = 3,
}
local uncheckedDefaults = {
    ["Modern Player Frame"] = true, ["Modern Target Frame"] = true,
    ["Modern Target's Target"] = true, ["Show Target Class"] = true,
    ["Unit Frame Class Portraits"] = true, ["Only Show My Debuffs on Target"] = true,
}
resetUFDefaultsBtn:SetScript("OnClick", function()
    for _, entry in ipairs(unitChecks) do
        local key = entry[2]
        local value = uncheckedDefaults[key] and 0 or 1
        FostercareTweaks_Config[key], current_config[key] = value, value
    end
    FostercareTweaks_Config["Larger Armor Debuffs"] = 0
    for key, value in pairs(unitDefaultOverrides) do FT.SetOverride(key, value) end
    for _, control in ipairs(auraBorderChecks) do
        FostercareTweaks_Config[control.setting], current_config[control.setting] = control.defaultValue, control.defaultValue
    end
    for _, control in ipairs(nativeAuraChecks) do
        FostercareTweaks_Config[control.setting], current_config[control.setting] = 1, 1
    end
    local UF = FT.UnitFrames
    if UF then
        UF:ApplyScale(1)
        if UF.Auras then
            for _, key in ipairs({"playerFrame", "targetFrame", "blizzPlayerAuras", "blizzTargetAuras"}) do
                local frame = UF[key]
                local container = frame and (frame.auraContainer or frame)
                if container and container.buffButtons then
                    UF.Auras:ApplyBuffSize(container, 20)
                    UF.Auras:ApplyDebuffSize(container, 20)
                end
            end
        end
        UF:ApplyConfiguration()
        if UF.Auras then UF.Auras:RefreshBorders() end
    end
    if FT.RefreshRaidMarks then FT:RefreshRaidMarks() end
    if FT.ApplyStandardAuraSettings then FT.ApplyStandardAuraSettings() end
    if FT.RefreshEnergyTick then FT.RefreshEnergyTick() end
    unitPage:RefreshValues()
end)

function unitPage:RefreshValues()
    local UF = FT.UnitFrames
    if not UF then return end
    isUFUpdating = true

    modernPlayerCB:SetChecked(UF:IsModernPlayer() and true or nil)
    modernTargetCB:SetChecked(UF:IsModernTarget() and true or nil)
    modernToTCB:SetChecked(UF:IsModernToT() and true or nil)
    modernComboCB:SetChecked(UF:IsModernComboPoints() and true or nil)
    modernPvPCB:SetChecked(UF:IsShowPvP() and true or nil)
    modernLevelCB:SetChecked(UF:IsShowLevel() and true or nil)
    modernClassCB:SetChecked(UF:IsShowClass() and true or nil)
    modernNameCB:SetChecked(UF:IsShowName() and true or nil)
    improvedStandardAurasCB:SetChecked(UF:IsImprovedStandardAuras() and true or nil)

    local cfg = FostercareTweaks_Config or {}
    for _, cb in ipairs(nativeAuraChecks) do cb:SetChecked(cfg[cb.setting] ~= 0) end
    for _, cb in ipairs(auraBorderChecks) do
        local value = cfg[cb.setting]
        if value == nil then value = cb.defaultValue end
        cb:SetChecked(value == 1)
    end
    moveUFCB:SetChecked((cfg["Movable Unit Frames"] == nil or cfg["Movable Unit Frames"] == 1) and true or nil)
    classColorCB:SetChecked((cfg["Unit Frame Class Colors"] == nil or cfg["Unit Frame Class Colors"] == 1) and true or nil)
    classPortraitCB:SetChecked(cfg["Unit Frame Class Portraits"] == 1 and true or nil)
    healthNumbersCB:SetChecked((cfg["Real Health Numbers"] == nil or cfg["Real Health Numbers"] == 1) and true or nil)
    energyTickCB:SetChecked((cfg["Show Energy Ticks"] == nil or cfg["Show Energy Ticks"] == 1) and true or nil)
    energyContrastCB:SetChecked(FT.GetNumber("energytick_contrast", 1, 0, 1) ~= 0)
    energyFlashCB:SetChecked(FT.GetNumber("energytick_flash", 1, 0, 1) ~= 0)
    local tickWidth = FT.GetNumber("energytick_width", 3, 2, 6)
    energyWidthSlider:SetValue(tickWidth)
    energyWidthSlider.label:SetText("Tick Line Width: " .. tickWidth .. " px")
    enemyCastbarCB:SetChecked((cfg["Enemy Castbars"] == nil or cfg["Enemy Castbars"] == 1) and true or nil)
    uninterruptCB:SetChecked((cfg["Uninterruptible Castbars"] == nil or cfg["Uninterruptible Castbars"] == 1) and true or nil)
    debuffTimerCB:SetChecked((cfg["Debuff Timer"] == nil or cfg["Debuff Timer"] == 1) and true or nil)

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
    armorDebuffCB:SetChecked(cfg["Larger Armor Debuffs"] == 1)
    local armorScale = UF.Auras:GetArmorDebuffScale()
    armorScaleSlider:SetValue(armorScale)
    armorScaleSlider.label:SetText("Armor Debuff Size: " .. string.format("%.2f", armorScale) .. "x")
    local values = cfg.overwrites or {}
    local markSize = math.max(12, math.min(36, tonumber(values.raidmark_size) or 22))
    local plateSize = math.max(12, math.min(32, tonumber(values.nameplate_raidmark_size) or 20))
    markSizeSlider:SetValue(markSize); plateMarkSizeSlider:SetValue(plateSize)
    markSizeSlider.label:SetText("Unit Frame Mark Size: " .. markSize .. " px")
    plateMarkSizeSlider.label:SetText("Nameplate Mark Size: " .. plateSize .. " px")
    markOutsideCB:SetChecked(values.raidmark_position == "outside")
    plateMarkAboveCB:SetChecked(values.nameplate_raidmark_position == "above")

    local bsize = UF:GetBuffSize()
    buffSizeSlider:SetValue(bsize)
    if buffSizeSlider.label then
        buffSizeSlider.label:SetText("Buff Size" .. ": " .. bsize .. " px")
    end

    local dsize = UF:GetDebuffSize()
    debuffSizeSlider:SetValue(dsize)
    if debuffSizeSlider.label then
        debuffSizeSlider.label:SetText("Debuff Size" .. ": " .. dsize .. " px")
    end

    local s = UF:GetScale()
    ufScaleSlider:SetValue(s)
    if ufScaleSlider.label then
        ufScaleSlider.label:SetText("Modern Frame Scale" .. ": " .. string.format("%.2f", s) .. "x")
    end

    local pw = UF:GetPlayerWidth()
    ufPlayerWSlider:SetValue(pw)
    if ufPlayerWSlider.label then ufPlayerWSlider.label:SetText("Player Width: " .. pw .. " px") end

    local ph = UF:GetPlayerHeight()
    ufPlayerHSlider:SetValue(ph)
    if ufPlayerHSlider.label then ufPlayerHSlider.label:SetText("Player Height: " .. ph .. " px") end

    local tw = UF:GetTargetWidth()
    ufTargetWSlider:SetValue(tw)
    if ufTargetWSlider.label then ufTargetWSlider.label:SetText("Target Width: " .. tw .. " px") end

    local th = UF:GetTargetHeight()
    ufTargetHSlider:SetValue(th)
    if ufTargetHSlider.label then ufTargetHSlider.label:SetText("Target Height: " .. th .. " px") end

    local totw = UF:GetToTWidth()
    ufToTWSlider:SetValue(totw)
    if ufToTWSlider.label then ufToTWSlider.label:SetText("ToT Width: " .. totw .. " px") end

    local toth = UF:GetToTHeight()
    ufToTHSlider:SetValue(toth)
    if ufToTHSlider.label then ufToTHSlider.label:SetText("ToT Height: " .. toth .. " px") end

    local pwh = UF:GetPowerHeight()
    ufPowerHSlider:SetValue(pwh)
    if ufPowerHSlider.label then ufPowerHSlider.label:SetText("Power Bar Height: " .. pwh .. " px") end

    local fn = UF:GetFontNameSize()
    ufFontNameSlider:SetValue(fn)
    if ufFontNameSlider.label then ufFontNameSlider.label:SetText("Name Font Size: " .. fn .. " pt") end

    local fl = UF:GetFontLevelSize()
    ufFontLevelSlider:SetValue(fl)
    if ufFontLevelSlider.label then ufFontLevelSlider.label:SetText("Level / Class Font Size: " .. fl .. " pt") end

    local fh = UF:GetFontHealthSize()
    ufFontHealthSlider:SetValue(fh)
    if ufFontHealthSlider.label then ufFontHealthSlider.label:SetText("Health Font Size: " .. fh .. " pt") end

    local fp = UF:GetFontPowerSize()
    ufFontPowerSlider:SetValue(fp)
    if ufFontPowerSlider.label then ufFontPowerSlider.label:SetText("Power Font Size: " .. fp .. " pt") end

    UpdateUFHealthFormatButtons(UF:GetHealthFormat())
    UpdateUFPowerFormatButtons(UF:GetPowerFormat())

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
raidContainer:SetHeight(650)
raidPage:SetScrollChild(raidContainer)

-- Box 1: Raid & Group Frames
local rBox1 = CreateSectionBox(raidContainer, "Raid & Group Frames", 88)
rBox1:SetPoint("TOPLEFT", raidContainer, "TOPLEFT", 22, -10)
rBox1:SetPoint("TOPRIGHT", raidContainer, "TOPRIGHT", -22, -10)

local enableCB = CreateCheckButton("FCTweaksRaidPageEnableCB", "Enable Raid Frames", "Toggle display of unified party and raid frames.", rBox1, 16, -26)

local groupLabelsCB = CreateCheckButton("FCTweaksGroupLabelsCB", "Show Group Labels", "Show G1-G8 in raids and Party in groups. Hiding labels removes header space.", rBox1, 16, -54)

local fmtLabel = Theme.Font(rBox1, "OVERLAY", "GameFontNormalSmall")
fmtLabel:SetPoint("TOPLEFT", rBox1, "TOPLEFT", 200, -10)
fmtLabel:SetText("Health Display Format:")
Theme.Text(fmtLabel)

local fmtDeficitBtn = CreateFrame("Button", "FCTweaksFmtDeficitBtn", rBox1, "UIPanelButtonTemplate")
Theme.Button(fmtDeficitBtn)
fmtDeficitBtn:SetWidth(72)
fmtDeficitBtn:SetHeight(22)
fmtDeficitBtn:SetPoint("TOPLEFT", rBox1, "TOPLEFT", 200, -28)
fmtDeficitBtn:SetText("Deficit")
if fmtDeficitBtn:GetFontString() then fmtDeficitBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local fmtPercentBtn = CreateFrame("Button", "FCTweaksFmtPercentBtn", rBox1, "UIPanelButtonTemplate")
Theme.Button(fmtPercentBtn)
fmtPercentBtn:SetWidth(72)
fmtPercentBtn:SetHeight(22)
fmtPercentBtn:SetPoint("LEFT", fmtDeficitBtn, "RIGHT", 4, 0)
fmtPercentBtn:SetText("Percent")
if fmtPercentBtn:GetFontString() then fmtPercentBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local fmtCurrentBtn = CreateFrame("Button", "FCTweaksFmtCurrentBtn", rBox1, "UIPanelButtonTemplate")
Theme.Button(fmtCurrentBtn)
fmtCurrentBtn:SetWidth(72)
fmtCurrentBtn:SetHeight(22)
fmtCurrentBtn:SetPoint("LEFT", fmtPercentBtn, "RIGHT", 4, 0)
fmtCurrentBtn:SetText("Current")
if fmtCurrentBtn:GetFontString() then fmtCurrentBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

-- Box 2: Raid Indicators
local rBox2 = CreateSectionBox(raidContainer, "Raid Indicators", 80)
rBox2:SetPoint("TOPLEFT", rBox1, "BOTTOMLEFT", 0, -14)
rBox2:SetPoint("TOPRIGHT", rBox1, "BOTTOMRIGHT", 0, -14)

local aggroCB  = CreateCheckButton("FCTweaksRaidAggroCB",  "Show Aggro Indicator", "Display a red threat warning square on unit frames when threat is high.", rBox2, 16, -24)
local hotCB    = CreateCheckButton("FCTweaksRaidHoTCB",    "Show HoT Indicator",   "Display a HoT tracking square on the top-left of friendly frames (Renew, Rejuvenation, Regrowth, PW:S, BoP).", rBox2, 230, -24)
local debuffCB = CreateCheckButton("FCTweaksRaidDebuffCB", "Show Debuff Badges",   "Show debuffs inside member frames. Debuffs with a dispel type come first.", rBox2, 16, -48)

local raidBuffBox = CreateSectionBox(raidContainer, "Buffs and Debuffs Inside Frames", 208)
raidBuffBox:SetPoint("TOPLEFT", rBox2, "BOTTOMLEFT", 0, -14)
raidBuffBox:SetPoint("TOPRIGHT", rBox2, "BOTTOMRIGHT", 0, -14)
local raidBuffCB = CreateCheckButton("FCTweaksRaidBuffCB", "Show Raid Buffs", "Show buffs in the member frame. Healing buffs and your buffs come first.", raidBuffBox, 16, -24)
local raidAllBuffsCB = CreateCheckButton("FCTweaksRaidAllBuffsCB", "Show All Buffs", "Include all client buffs. Frame space still limits visible icons; +N shows overflow.", raidBuffBox, 230, -24)
local raidBuffHint = Theme.Font(raidBuffBox, "OVERLAY", "GameFontHighlightSmall")
raidBuffHint:SetPoint("TOPLEFT", raidBuffBox, "TOPLEFT", 24, -52)
raidBuffHint:SetText("Debuffs first; healing buffs next. Icons shrink to fit; +N means more.")
local raidBuffCountSlider = CreateSlider("FCTweaksRaidBuffCountSlider", "Buffs Per Player", 1, 8, 1, "", raidBuffBox, 16, -82, 196)
local raidBuffSizeSlider = CreateSlider("FCTweaksRaidBuffSizeSlider", "Raid Buff Size", 8, 18, 1, " px", raidBuffBox, 236, -82, 196)

local raidDebuffCountSlider = CreateSlider("FCTweaksRaidDebuffCountSlider", "Debuffs Per Player", 1, 8, 1, "", raidBuffBox, 16, -130, 196)
local raidDebuffSizeSlider = CreateSlider("FCTweaksRaidDebuffSizeSlider", "Raid Debuff Size", 8, 18, 1, " px", raidBuffBox, 236, -130, 196)
local raidAuraSpacingSlider = CreateSlider("FCTweaksRaidAuraSpacingSlider", "Space Between Icons", 0, 6, 1, " px", raidBuffBox, 16, -178, 416)

-- Box 3: Dimensions & Spacing
local rBox3 = CreateSectionBox(raidContainer, "Dimensions & Spacing", 166)
rBox3:SetPoint("TOPLEFT", raidBuffBox, "BOTTOMLEFT", 0, -14)
rBox3:SetPoint("TOPRIGHT", raidBuffBox, "BOTTOMRIGHT", 0, -14)

local widthSlider    = CreateSlider("FCTweaksRaidWidthSlider",    "Width",              40,  120, 1,    " px", rBox3, 16, -34,  196)
local heightSlider   = CreateSlider("FCTweaksRaidHeightSlider",   "Height",             20,  60,  1,    " px", rBox3, 236, -34, 196)
local spacingXSlider = CreateSlider("FCTweaksRaidSpacingXSlider", "Horizontal Spacing", 0,   20,  1,    " px", rBox3, 16, -82,  196)
local spacingYSlider = CreateSlider("FCTweaksRaidSpacingYSlider", "Vertical Spacing",   0,   20,  1,    " px", rBox3, 236, -82, 196)
local scaleSlider    = CreateSlider("FCTweaksRaidScaleSlider",    "Scale",              0.5, 2.0, 0.05, "x",   rBox3, 16, -130, 416)

-- Bottom Buttons
local resetBtn = CreateFrame("Button", "FCTweaksRaidPageResetBtn", raidContainer, "UIPanelButtonTemplate")
Theme.Button(resetBtn)
resetBtn:SetPoint("TOPLEFT", rBox3, "BOTTOMLEFT", 0, -12)
resetBtn:SetWidth(218)
resetBtn:SetHeight(24)
resetBtn:SetText("Reset to Defaults")
if resetBtn:GetFontString() then resetBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local testBtn = CreateFrame("Button", "FCTweaksRaidPageTestBtn", raidContainer, "UIPanelButtonTemplate")
Theme.Button(testBtn)
testBtn:SetPoint("TOPRIGHT", rBox3, "BOTTOMRIGHT", 0, -12)
testBtn:SetWidth(218)
testBtn:SetHeight(24)
testBtn:SetText("Toggle Test Grid (40)")
if testBtn:GetFontString() then testBtn:GetFontString():SetFontObject("GameFontNormalSmall") end

local isRaidUpdating = false
local function UpdateRaidBuffCountControl()
    -- Native 1.12 Slider widgets do not have Button:Enable/Disable methods.
    local allBuffs = raidAllBuffsCB:GetChecked()
    raidBuffCountSlider:EnableMouse(not allBuffs)
    raidBuffCountSlider:SetAlpha(allBuffs and 0.45 or 1)
end

local function ApplyRaidBuffSettings()
    if isRaidUpdating then return end
    local UF = FT.UnitFrames
    if not UF then return end
    local cfg = FostercareTweaks_Config
    cfg.overwrites = cfg.overwrites or {}
    cfg["Show Raid Buffs"] = raidBuffCB:GetChecked() and 1 or 0
    cfg["Show All Raid Buffs"] = raidAllBuffsCB:GetChecked() and 1 or 0
    UpdateRaidBuffCountControl()
    cfg.overwrites.raid_buff_count = math.floor(raidBuffCountSlider:GetValue() + 0.5)
    cfg.overwrites.raid_buff_size = math.floor(raidBuffSizeSlider:GetValue() + 0.5)
    cfg.overwrites.raid_debuff_count = math.floor(raidDebuffCountSlider:GetValue() + 0.5)
    cfg.overwrites.raid_debuff_size = math.floor(raidDebuffSizeSlider:GetValue() + 0.5)
    cfg.overwrites.raid_aura_spacing = math.floor(raidAuraSpacingSlider:GetValue() + 0.5)
    raidDebuffCountSlider.label:SetText("Debuffs Per Player: " .. cfg.overwrites.raid_debuff_count)
    raidDebuffSizeSlider.label:SetText("Raid Debuff Size: " .. cfg.overwrites.raid_debuff_size .. " px")
    raidAuraSpacingSlider.label:SetText("Space Between Icons: " .. cfg.overwrites.raid_aura_spacing .. " px")
    raidBuffCountSlider.label:SetText("Buffs Per Player: " .. (raidAllBuffsCB:GetChecked() and "All" or cfg.overwrites.raid_buff_count))
    raidBuffSizeSlider.label:SetText("Raid Buff Size: " .. cfg.overwrites.raid_buff_size .. " px")
    UF:UpdateAllRaidFrames()
end
raidBuffCB:SetScript("OnClick", ApplyRaidBuffSettings)
raidAllBuffsCB:SetScript("OnClick", ApplyRaidBuffSettings)
raidBuffCountSlider:SetScript("OnValueChanged", ApplyRaidBuffSettings)
raidBuffSizeSlider:SetScript("OnValueChanged", ApplyRaidBuffSettings)
raidDebuffCountSlider:SetScript("OnValueChanged", ApplyRaidBuffSettings)
raidDebuffSizeSlider:SetScript("OnValueChanged", ApplyRaidBuffSettings)
raidAuraSpacingSlider:SetScript("OnValueChanged", ApplyRaidBuffSettings)
groupLabelsCB:SetScript("OnClick", function()
    FostercareTweaks_Config["Show Group Labels"] = groupLabelsCB:GetChecked() and 1 or 0
    FT.UnitFrames:UpdateAllRaidFrames()
end)

local raidHealthFormats = {
    deficit = fmtDeficitBtn,
    percent = fmtPercentBtn,
    current = fmtCurrentBtn,
}
local function UpdateRaidHealthFormatButtons(fmt)
    if not raidHealthFormats[fmt] then fmt = "deficit" end
    for value, button in pairs(raidHealthFormats) do
        if value == fmt then button:Disable() else button:Enable() end
        Theme.SelectButton(button, value == fmt)
    end
end

local function SetRaidHealthFormat(fmt)
    FT.SetOverride("raid_health_format", fmt)
    UpdateRaidHealthFormatButtons(fmt)
    local UF = FT.UnitFrames
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

    FostercareTweaks_Config["Show Raid Aggro Indicator"] = aVal
    FostercareTweaks_Config["Show Raid HoT Indicator"] = hVal
    FostercareTweaks_Config["Show Raid Debuff Badges"] = dVal

    current_config["Show Raid Aggro Indicator"] = aVal
    current_config["Show Raid HoT Indicator"] = hVal
    current_config["Show Raid Debuff Badges"] = dVal

    local UF = FT.UnitFrames
    if UF and UF.UpdateAllRaidFrames then
        UF:UpdateAllRaidFrames()
    end
end

aggroCB:SetScript("OnClick", OnRaidIndicatorClicked)
hotCB:SetScript("OnClick", OnRaidIndicatorClicked)
debuffCB:SetScript("OnClick", OnRaidIndicatorClicked)

local function OnRaidSliderValueChanged()
    if isRaidUpdating then return end
    local UF = FT.UnitFrames
    if not UF or not UF.ApplyGroupDimensions then return end

    local w = math.floor(widthSlider:GetValue() + 0.5)
    local h = math.floor(heightSlider:GetValue() + 0.5)
    local s = math.floor(scaleSlider:GetValue() * 100 + 0.5) / 100
    local spX = math.floor(spacingXSlider:GetValue() + 0.5)
    local spY = math.floor(spacingYSlider:GetValue() + 0.5)

    if widthSlider.label then widthSlider.label:SetText("Width" .. ": " .. w .. " px") end
    if heightSlider.label then heightSlider.label:SetText("Height" .. ": " .. h .. " px") end
    if scaleSlider.label then scaleSlider.label:SetText("Scale" .. ": " .. string.format("%.2f", s) .. "x") end
    if spacingXSlider.label then spacingXSlider.label:SetText("Horizontal Spacing" .. ": " .. spX .. " px") end
    if spacingYSlider.label then spacingYSlider.label:SetText("Vertical Spacing" .. ": " .. spY .. " px") end

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
    local UF = FT.UnitFrames
    if not UF or not UF.ApplyGroupDimensions then return end
    local isChecked = this:GetChecked() and true or false
    UF:ApplyGroupDimensions(nil, nil, nil, nil, nil, isChecked)
end)

resetBtn:SetScript("OnClick", function()
    isRaidUpdating = true
    enableCB:SetChecked(true)
    groupLabelsCB:SetChecked(true)
    FostercareTweaks_Config["Show Group Labels"] = 1
    raidDebuffCountSlider:SetValue(3); raidDebuffSizeSlider:SetValue(11); raidAuraSpacingSlider:SetValue(2)
    FostercareTweaks_Config.overwrites.raid_debuff_count = 3
    FostercareTweaks_Config.overwrites.raid_debuff_size = 11
    FostercareTweaks_Config.overwrites.raid_aura_spacing = 2
    raidDebuffCountSlider.label:SetText("Debuffs Per Player: 3")
    raidDebuffSizeSlider.label:SetText("Raid Debuff Size: 11 px")
    raidAuraSpacingSlider.label:SetText("Space Between Icons: 2 px")
    raidBuffCB:SetChecked(true)
    raidAllBuffsCB:SetChecked(false)
    UpdateRaidBuffCountControl()
    FostercareTweaks_Config["Show All Raid Buffs"] = 0
    raidBuffCountSlider:SetValue(4)
    raidBuffSizeSlider:SetValue(10)
    FostercareTweaks_Config["Show Raid Buffs"] = 1
    FostercareTweaks_Config.overwrites.raid_buff_count = 4
    FostercareTweaks_Config.overwrites.raid_buff_size = 10
    raidBuffCountSlider.label:SetText("Buffs Per Player: 4")
    raidBuffSizeSlider.label:SetText("Raid Buff Size: 10 px")
    aggroCB:SetChecked(true)
    hotCB:SetChecked(true)
    debuffCB:SetChecked(true)
    widthSlider:SetValue(64)
    heightSlider:SetValue(34)
    scaleSlider:SetValue(1.0)
    spacingXSlider:SetValue(4)
    spacingYSlider:SetValue(3)
    isRaidUpdating = false

    if widthSlider.label then widthSlider.label:SetText("Width" .. ": 64 px") end
    if heightSlider.label then heightSlider.label:SetText("Height" .. ": 34 px") end
    if scaleSlider.label then scaleSlider.label:SetText("Scale" .. ": 1.00x") end
    if spacingXSlider.label then spacingXSlider.label:SetText("Horizontal Spacing" .. ": 4 px") end
    if spacingYSlider.label then spacingYSlider.label:SetText("Vertical Spacing" .. ": 3 px") end

    if not FostercareTweaks_Config then FostercareTweaks_Config = {} end
    FostercareTweaks_Config["Show Raid Aggro Indicator"] = 1
    FostercareTweaks_Config["Show Raid HoT Indicator"] = 1
    FostercareTweaks_Config["Show Raid Debuff Badges"] = 1
    current_config["Show Raid Aggro Indicator"] = 1
    current_config["Show Raid HoT Indicator"] = 1
    current_config["Show Raid Debuff Badges"] = 1

    SetRaidHealthFormat("deficit")

    local UF = FT.UnitFrames
    if UF and UF.ApplyGroupDimensions then
        UF:ApplyGroupDimensions(64, 34, 1.0, 4, 3, true)
    end
    if UF and UF.UpdateAllRaidFrames then
        UF:UpdateAllRaidFrames()
    end
end)

testBtn:SetScript("OnClick", function()
    local UF = FT.UnitFrames
    if UF and UF.ToggleRaidTest then
        UF:ToggleRaidTest()
    end
end)

function raidPage:RefreshValues()
    local UF = FT.UnitFrames
    if not UF or not UF.GetGroupDimensions then return end
    local dims = UF:GetGroupDimensions()

    isRaidUpdating = true
    enableCB:SetChecked(dims.enabled)
    groupLabelsCB:SetChecked(UF:IsShowGroupLabels())
    local dsize, dcount, gap = UF:GetRaidAuraLayout()
    raidDebuffCountSlider:SetValue(dcount); raidDebuffSizeSlider:SetValue(dsize); raidAuraSpacingSlider:SetValue(gap)
    raidDebuffCountSlider.label:SetText("Debuffs Per Player: " .. dcount)
    raidDebuffSizeSlider.label:SetText("Raid Debuff Size: " .. dsize .. " px")
    raidAuraSpacingSlider.label:SetText("Space Between Icons: " .. gap .. " px")
    local buffsEnabled, buffCount, buffSize, allBuffs = UF:GetRaidBuffSettings()
    raidBuffCB:SetChecked(buffsEnabled)
    raidAllBuffsCB:SetChecked(allBuffs)
    UpdateRaidBuffCountControl()
    raidBuffCountSlider:SetValue(buffCount)
    raidBuffSizeSlider:SetValue(buffSize)
    raidBuffCountSlider.label:SetText("Buffs Per Player: " .. (allBuffs and "All" or buffCount))
    raidBuffSizeSlider.label:SetText("Raid Buff Size: " .. buffSize .. " px")
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

    if widthSlider.label then widthSlider.label:SetText("Width" .. ": " .. dims.width .. " px") end
    if heightSlider.label then heightSlider.label:SetText("Height" .. ": " .. dims.height .. " px") end
    if scaleSlider.label then scaleSlider.label:SetText("Scale" .. ": " .. string.format("%.2f", dims.scale) .. "x") end
    if spacingXSlider.label then spacingXSlider.label:SetText("Horizontal Spacing" .. ": " .. dims.spacingX .. " px") end
    if spacingYSlider.label then spacingYSlider.label:SetText("Vertical Spacing" .. ": " .. dims.spacingY .. " px") end
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
    for title, module in pairs(FT.mods) do
        local category = module.category or "General"
        if category ~= "Unit Frames" then
            gui[category] = gui[category] or {}
            gui[category][title] = module
        end
    end

    local topspace = 10
    local required_height = topspace
    local entrysize = 22
    local previous = nil

    local sortCategories = function(a, b)
        if a == "General" then return true end
        if b == "General" then return false end
        if a == "Action Bar" then return true end
        if b == "Action Bar" then return false end
        if a == "Unit Frames" then return true end
        if b == "Unit Frames" then return false end
        if a == "Nameplates" then return true end
        if b == "Nameplates" then return false end
        if a == "World & MiniMap" then return true end
        if b == "World & MiniMap" then return false end
        if a == "Social & Chat" then return true end
        if b == "Social & Chat" then return false end
        if a == "Tooltip & Items" then return true end
        if b == "Tooltip & Items" then return false end
        return a < b
    end

    for category, entries in FT.spairs(gui, sortCategories) do
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

        local categoryFrame = settings.category[category]
        local collapse = function(parent, expand)
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
        settings.category[category].button:SetScript("OnClick", function() collapse(categoryFrame) end)

        settings.category[category].title = settings.category[category].title or CreateFrame("Button", nil, settings.container)
        settings.category[category].title:SetPoint("TOPLEFT", settings.category[category], "TOPLEFT", 22, entrysize - 4)
        settings.category[category].title:SetWidth(220)
        settings.category[category].title:SetHeight(entrysize)
        settings.category[category].title.parent = settings.category[category]
        settings.category[category].title:SetScript("OnClick", function() collapse(categoryFrame) end)

        Theme.Panel(settings.category[category])

        settings.category[category].text = settings.category[category].text or Theme.Font(settings.category[category].title, "OVERLAY", "GameFontHighlightSmall")
        settings.category[category].text:SetJustifyH("LEFT")
        settings.category[category].text:SetAllPoints()
        settings.category[category].text:SetText(category)
        Theme.Text(settings.category[category].text, "heading")

        for title, module in FT.spairs(entries) do
            local cleanTitle = string.gsub(title, "[^%w]", "")
            if not settings.entries[title] then
                settings.entries[title] = CreateFrame("CheckButton", "FCTweaksGUI_" .. cleanTitle, settings.category[category], "OptionsCheckButtonTemplate")
                settings.entries[title]:SetHeight(24)
                settings.entries[title]:SetWidth(24)
                Theme.CheckButton(settings.entries[title])
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
            Theme.Text(text)
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
    for title, mod in pairs(FT.mods) do
        if mod.category ~= "Unit Frames" then
            current_config[title] = mod.enabled and 1 or 0
        end
    end
    settings:load()
end

settings:SetScript("OnShow", function()
    current_config = {}
    if FostercareTweaks_Config and FT.mods then
        for title, mod in pairs(FT.mods) do
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
