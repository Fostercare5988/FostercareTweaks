local FT, settings = FostercareTweaks, FostercareTweaksSettingsGUI
if not FT or not settings then return end
local Theme, Widgets = FT.SettingsTheme, FT.SettingsWidgets
local CreateCheckButton, CreateSlider, CreateSectionBox = Widgets.Check, Widgets.Slider, Widgets.Section
local max_width = 540

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

local markBox = CreateSectionBox(unitContainer, "Raid Target Marks", 180)
markBox:SetPoint("TOPLEFT", formatBox, "BOTTOMLEFT", 0, -14)
markBox:SetPoint("TOPRIGHT", formatBox, "BOTTOMRIGHT", 0, -14)
local markEnabledCB = CreateCheckButton("FCTweaksMarkEnabledCB", "Adjust unit-frame raid marks", "Larger marks on unit frames. Changing support requires Reload UI. Nameplate marks have separate controls.", markBox, 16, -24)
local markSizeSlider = CreateSlider("FCTweaksMarkSizeSlider", "Unit Frame Mark Size", 12, 36, 1, " px", markBox, 16, -72, 416)
local markOutsideCB = CreateCheckButton("FCTweaksMarkOutsideCB", "Marks Beside Portraits", "Place unit frame marks outside the portrait. Raid marks keep a reserved column inside member frames.", markBox, 16, -104)
local markHint = Theme.Font(markBox, "OVERLAY", "GameFontHighlightSmall")
markHint:SetPoint("TOPLEFT", markBox, "TOPLEFT", 24, -140)
markHint:SetWidth(400); markHint:SetJustifyH("LEFT")
markHint:SetText("Size and placement apply live. Enable changes need Reload UI below. Nameplate marks have separate controls on the Nameplates page.")

local sharedBox = CreateSectionBox(unitContainer, "Standard-frame appearance", 150)
sharedBox:SetPoint("TOPLEFT", markBox, "BOTTOMLEFT", 0, -14)
sharedBox:SetPoint("TOPRIGHT", markBox, "BOTTOMRIGHT", 0, -14)
local moveUFCB = CreateCheckButton("FCTweaksMoveUFCB", "Movable Unit Frames", "Hold Ctrl+Shift to move frames and separate buff/debuff areas.", sharedBox, 16, -24)
local classColorCB = CreateCheckButton("FCTweaksClassColorCB", "Unit Frame Class Colors", "Class colors on standard player and target name backgrounds.", sharedBox, 16, -48)
local classPortraitCB = CreateCheckButton("FCTweaksClassPortCB", "Unit Frame Class Portraits", "Class portraits on standard Blizzard frames.", sharedBox, 16, -72)
local healthNumbersCB = CreateCheckButton("FCTweaksHealthNumCB", "Real Health Numbers", "Real health values on standard unit frames.", sharedBox, 230, -24)
local energyTickCB = CreateCheckButton("FCTweaksEnergyTickCB", "Show Energy Ticks", "Estimated two-second energy ticks; mana spending shows the five-second rule. Spell gains are excluded when NamPower v4.6.2+ is available.", sharedBox, 230, -48)
local enemyCastbarCB = CreateCheckButton("FCTweaksEnemyCastCB", "Target-frame castbar", "Show casts beneath your selected target frame. Nameplate castbars are controlled separately on the Nameplates page.", sharedBox, 230, -72)
local uninterruptCB = CreateCheckButton("FCTweaksUninterruptCB", "Grey bars for uninterruptible casts", "Applies to both target-frame and nameplate castbars.", sharedBox, 16, -96)
local debuffTimerCB = CreateCheckButton("FCTweaksDebuffTimerCB", "Timers on original target debuffs", "Used only when Enhanced standard-frame auras is off. Changing this option requires Reload UI.", sharedBox, 230, -96)
local improvedStandardAurasCB = CreateCheckButton("FCTweaksImpStdAurasCB", "Enhanced standard-frame auras", "Show enhanced auras on standard frames. Hold Ctrl+Shift to move each aura area.", sharedBox, 16, -120)
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
local borderBox = CreateSectionBox(unitContainer, "Aura borders (unit, raid and Blizzard icons)", 96)
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
    settings:RequireReload()
end)

local resetUFDefaultsBtn = CreateFrame("Button", "FCTweaksResetUFDefaultsBtn", unitContainer, "UIPanelButtonTemplate")
Theme.Button(resetUFDefaultsBtn)
resetUFDefaultsBtn:SetPoint("TOPRIGHT", nativeAuraBox, "BOTTOMRIGHT", 0, -12)
resetUFDefaultsBtn:SetWidth(218)
resetUFDefaultsBtn:SetHeight(24)
resetUFDefaultsBtn:SetText("Reset all unit settings")
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
    elseif control == markOutsideCB then
        FT.SetOverride("raidmark_position", control:GetChecked() and "outside" or "portrait")
    end
    if FT.RefreshRaidMarks then FT:RefreshRaidMarks() end
end
markSizeSlider:SetScript("OnValueChanged", ApplyMarkSettings)
markOutsideCB:SetScript("OnClick", ApplyMarkSettings)
local function ApplyArmorSettings(self)
    if isUFUpdating then return end
    local control = self or this
    if control == armorDebuffCB then
        local value = control:GetChecked() and 1 or 0
        FostercareTweaks_Config["Larger Armor Debuffs"] = value
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
    { markEnabledCB, "Clear Raid Target Marks" },
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
    FostercareTweaks_Config[key] = value
    local UF = FT.UnitFrames
    local reloadOnly = key == "Clear Raid Target Marks" or key == "Unit Frame Class Portraits"
        or key == "Real Health Numbers" or key == "Debuff Timer"
    if reloadOnly then settings:RequireReload()
    elseif key == "Unit Frame Class Colors" then FT.mods[key]:apply()
    elseif key == "Enemy Castbars" then FT.mods[key]:apply()
    elseif key == "Uninterruptible Castbars" then
        if FT.RefreshTargetCastbar then FT.RefreshTargetCastbar() end
    elseif UF then UF:ApplyConfiguration() end
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
        FostercareTweaks_Config[key] = value
    end
    FostercareTweaks_Config["Larger Armor Debuffs"] = 0
    for key, value in pairs(unitDefaultOverrides) do FT.SetOverride(key, value) end
    for _, control in ipairs(auraBorderChecks) do
        FostercareTweaks_Config[control.setting] = control.defaultValue
    end
    for _, control in ipairs(nativeAuraChecks) do
        FostercareTweaks_Config[control.setting] = 1
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
    settings:RequireReload()
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
    markEnabledCB:SetChecked(FT.IsEnabled("Clear Raid Target Marks", true))
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
    markSizeSlider:SetValue(markSize)
    markSizeSlider.label:SetText("Unit Frame Mark Size: " .. markSize .. " px")
    markOutsideCB:SetChecked(values.raidmark_position == "outside")

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


local modernBox = CreateSectionBox(unitContainer, "Modern-frame appearance", 224)
local combatBox = CreateSectionBox(unitContainer, "Castbars", 104)
local toolsBox = CreateSectionBox(unitContainer, "Position and defaults", 66)
local function Place(control, parent, x, y)
    control:SetParent(parent); control:ClearAllPoints(); control:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
end
ufBox.title:SetText("Choose your frame style")
ufBox:SetHeight(150)
Place(moveUFCB, ufBox, 16, -104)
Place(styleHint, ufBox, 230, -28); styleHint:SetWidth(194); styleHint:SetHeight(68); styleHint:SetJustifyH("LEFT")
styleHint:SetText("Unchecked uses Blizzard frames. Hold Ctrl+Shift to move frames when movement is enabled.")
Place(modernComboCB, modernBox, 16, -24)
Place(modernPvPCB, modernBox, 16, -52)
Place(modernLevelCB, modernBox, 16, -80)
Place(modernClassCB, modernBox, 16, -108)
Place(modernNameCB, modernBox, 16, -136)
Place(ufScaleSlider, modernBox, 16, -186)
Place(classColorCB, sharedBox, 16, -24)
Place(classPortraitCB, sharedBox, 16, -52)
Place(healthNumbersCB, sharedBox, 16, -80)
Place(improvedStandardAurasCB, sharedBox, 16, -108)
Place(debuffTimerCB, sharedBox, 16, -136); sharedBox:SetHeight(170)
Place(enemyCastbarCB, combatBox, 16, -24)
Place(uninterruptCB, combatBox, 16, -52)
local castHint = Theme.Font(combatBox, "OVERLAY", "GameFontNormalSmall", "hint")
castHint:SetPoint("TOPLEFT", combatBox, "TOPLEFT", 24, -80)
castHint:SetWidth(402); castHint:SetHeight(22); castHint:SetJustifyH("LEFT")
castHint:SetText("Nameplate castbars have their own switch on the Nameplates page.")
energyBox:SetHeight(200)
Place(energyTickCB, energyBox, 16, -24)
Place(energyContrastCB, energyBox, 16, -52)
Place(energyFlashCB, energyBox, 16, -80)
Place(energyWidthSlider, energyBox, 16, -132)
Place(energyHint, energyBox, 16, -163); energyHint:SetWidth(402); energyHint:SetHeight(30)
buffBox:SetHeight(192)
Place(buffSpinCB, buffBox, 16, -80); Place(buffTextCB, buffBox, 16, -108)
Place(buffSizeSlider, buffBox, 16, -158)
debuffBox:SetHeight(324)
Place(debuffSpinCB, debuffBox, 16, -108); Place(debuffTextCB, debuffBox, 16, -136)
Place(onlyMyDebuffsCB, debuffBox, 16, -164); Place(armorDebuffCB, debuffBox, 16, -192)
Place(debuffSizeSlider, debuffBox, 16, -244); Place(armorScaleSlider, debuffBox, 16, -292)
armorScaleSlider:SetWidth(416)
Place(resetPosBtn, toolsBox, 16, -28); resetPosBtn:SetWidth(196)
Place(resetUFDefaultsBtn, toolsBox, 230, -28); resetUFDefaultsBtn:SetWidth(196)
Widgets.Sections(unitPage, unitContainer, {
    {title="Frame style", boxes={ufBox, toolsBox}, hint="Start here. Choose Blizzard or modern frames separately for player, target and target of target."},
    {title="Standard frames", boxes={sharedBox}, hint="These enhancements apply to Blizzard frames. Changes needing a restart of the UI show a Reload UI button."},
    {title="Modern layout", boxes={modernBox, dimBox, fontBox, formatBox}, hint="Size, text and decorations for the modern frames selected under Frame style. Blizzard frames keep their original layout."},
    {title="Unit auras", boxes={buffBox, debuffBox}, hint="Buffs and debuffs attached to player/target frames. Blizzard frames need Enhanced standard-frame auras for these controls."},
    {title="Combat details", boxes={combatBox, energyBox, markBox}, hint="Target-frame casts, energy/mana timing and unit-frame raid marks. Nameplate details remain on the Nameplates page."},
    {title="Blizzard auras", boxes={nativeAuraBox, borderBox}, hint="Top-right buffs, debuffs and weapon enchants. Border settings also apply to unit/raid aura icons; visibility stays independent."},
}, "Choose a section. Live changes apply immediately; Reload UI is always an explicit action.")
