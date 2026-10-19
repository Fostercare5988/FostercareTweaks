local FT, settings = FostercareTweaks, FostercareTweaksSettingsGUI
if not FT or not settings then return end
local Theme, Widgets = FT.SettingsTheme, FT.SettingsWidgets
local CreateCheckButton, CreateSlider, CreateSectionBox = Widgets.Check, Widgets.Slider, Widgets.Section
local max_width = 540

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

local enableCB = CreateCheckButton("FCTweaksRaidPageEnableCB", "Use FostercareTweaks party and raid frames", "Replace party frames and pause the built-in compact group grid. Turning this off returns control to the game's frame settings.", rBox1, 16, -26)

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
local debuffCB = CreateCheckButton("FCTweaksRaidDebuffCB", "Show debuff icons",   "Show debuffs inside member frames. Debuffs with a dispel type come first.", rBox2, 16, -48)

local raidBuffBox = CreateSectionBox(raidContainer, "Buffs and Debuffs Inside Frames", 208)
raidBuffBox:SetPoint("TOPLEFT", rBox2, "BOTTOMLEFT", 0, -14)
raidBuffBox:SetPoint("TOPRIGHT", rBox2, "BOTTOMRIGHT", 0, -14)
local raidBuffCB = CreateCheckButton("FCTweaksRaidBuffCB", "Show Raid Buffs", "Show buffs in the member frame. Healing buffs and your buffs come first.", raidBuffBox, 16, -24)
local raidAllBuffsCB = CreateCheckButton("FCTweaksRaidAllBuffsCB", "Consider every buff", "Include all client buffs. Frame space still limits visible icons; +N shows overflow.", raidBuffBox, 230, -24)
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
resetBtn:SetText("Reset all raid settings")
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

local function OnRaidBuffSwitch(control)
    if isRaidUpdating then return end
    control = control or this
    FostercareTweaks_Config[control.setting] = control:GetChecked() and 1 or 0
    UpdateRaidBuffCountControl()
    -- The model supplies the default count before the slider has saved one.
    local _, buffCount, _, allBuffs = FT.UnitFrames:GetRaidBuffSettings()
    raidBuffCountSlider.label:SetText("Buffs Per Player: " .. (allBuffs and "All" or buffCount))
    FT.UnitFrames:UpdateAllRaidFrames()
end
raidBuffCB.setting, raidAllBuffsCB.setting = "Show Raid Buffs", "Show All Raid Buffs"
raidBuffCB:SetScript("OnClick", OnRaidBuffSwitch)
raidAllBuffsCB:SetScript("OnClick", OnRaidBuffSwitch)
local function OnRaidAuraSize(control)
    if isRaidUpdating then return end
    control = control or this
    local value = math.floor(control:GetValue() + 0.5)
    FT.SetOverride(control.setting, value)
    control.label:SetText(control.baseLabel .. ": " .. value .. control.unitSuffix)
    FT.UnitFrames:UpdateAllRaidFrames()
end
for _, entry in ipairs({
    {raidBuffCountSlider, "raid_buff_count"}, {raidBuffSizeSlider, "raid_buff_size"},
    {raidDebuffCountSlider, "raid_debuff_count"}, {raidDebuffSizeSlider, "raid_debuff_size"},
    {raidAuraSpacingSlider, "raid_aura_spacing"},
}) do
    entry[1].setting = entry[2]
    entry[1]:SetScript("OnValueChanged", OnRaidAuraSize)
end
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

local function OnRaidIndicatorClicked(control)
    if isRaidUpdating then return end
    control = control or this
    FostercareTweaks_Config[control.setting] = control:GetChecked() and 1 or 0
    FT.UnitFrames:UpdateAllRaidFrames()
end
for _, entry in ipairs({{aggroCB, "Show Raid Aggro Indicator"},
    {hotCB, "Show Raid HoT Indicator"}, {debuffCB, "Show Raid Debuff Badges"}}) do
    entry[1].setting = entry[2]
    entry[1]:SetScript("OnClick", OnRaidIndicatorClicked)
end

local function OnRaidSliderValueChanged(control)
    if isRaidUpdating then return end
    control = control or this
    local UF = FT.UnitFrames
    local value = control:GetValue()
    if control == scaleSlider then value = math.floor(value * 100 + 0.5) / 100
    else value = math.floor(value + 0.5) end
    control.label:SetText(control.baseLabel .. ": " ..
        (control == scaleSlider and string.format("%.2f", value) or value) .. control.unitSuffix)
    -- Unchanged dimensions come from the current model, never stale UI controls.
    if control == widthSlider then UF:ApplyGroupDimensions(value)
    elseif control == heightSlider then UF:ApplyGroupDimensions(nil, value)
    elseif control == scaleSlider then UF:ApplyGroupDimensions(nil, nil, value)
    elseif control == spacingXSlider then UF:ApplyGroupDimensions(nil, nil, nil, value)
    else UF:ApplyGroupDimensions(nil, nil, nil, nil, value) end
end
for _, slider in ipairs({widthSlider, heightSlider, scaleSlider, spacingXSlider, spacingYSlider}) do
    slider:SetScript("OnValueChanged", OnRaidSliderValueChanged)
end

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

    FT.SetOverride("raid_health_format", "deficit")
    UpdateRaidHealthFormatButtons("deficit")

    local UF = FT.UnitFrames
    if UF and UF.ApplyGroupDimensions then
        UF:ApplyGroupDimensions(64, 34, 1.0, 4, 3, true)
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


local toolsBox = CreateSectionBox(raidContainer, "Preview and defaults", 68)
local function Place(control, parent, x, y)
    control:SetParent(parent); control:ClearAllPoints(); control:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
end
rBox1:SetHeight(144)
Place(fmtLabel, rBox1, 16, -84)
Place(fmtDeficitBtn, rBox1, 16, -106)
Place(fmtPercentBtn, rBox1, 94, -106)
Place(fmtCurrentBtn, rBox1, 172, -106)
rBox2:SetHeight(116)
Place(hotCB, rBox2, 16, -52)
Place(debuffCB, rBox2, 16, -80)
Place(testBtn, toolsBox, 16, -28); testBtn:SetWidth(196)
Place(resetBtn, toolsBox, 230, -28); resetBtn:SetWidth(196)
Widgets.Sections(raidPage, raidContainer, {
    {title="Layout", boxes={rBox1, rBox3, toolsBox}, hint="One frame grid serves parties and raids. Set member size, spacing and health text; use the test grid to check the result."},
    {title="Indicators", boxes={rBox2}, hint="Corner warnings and healing indicators. Debuff icons share the internal aura strip configured under Auras."},
    {title="Auras", boxes={raidBuffBox}, hint="Buffs and debuffs share the space inside each member frame. Debuffs take priority; +N counts eligible effects that did not fit."},
}, "Choose Layout, Indicators or Auras. Changes apply immediately and your frame position is kept.")
