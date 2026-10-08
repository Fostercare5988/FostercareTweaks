local FT, settings = FostercareTweaks, FostercareTweaksSettingsGUI
if not FT or not settings then return end
local Theme, CD = FT.SettingsTheme, FT.NameplateCooldowns
local page = CreateFrame("ScrollFrame", "FCTweaksNameplateSettingsPage", settings, "UIPanelScrollFrameTemplate")
page:SetPoint("TOPLEFT", settings, "TOPLEFT", 14, -64)
page:SetPoint("BOTTOMRIGHT", settings, "BOTTOMRIGHT", -34, 48)
page:Hide()
settings.nameplatePage = page
local content = CreateFrame("Frame", "FCTweaksNameplateSettingsContent", page)
content:SetWidth(492); content:SetHeight(770)
page:SetScrollChild(content)
Theme.Panel(content)
local controls, refreshing, startup = {}, nil, {}
page.controls = controls
local function Text(text, x, y, color, height)
    local label = Theme.Font(content, "OVERLAY", "GameFontNormalSmall", color)
    label:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
    label:SetWidth(448); label:SetHeight(height or 22); label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end
local function Check(name, title, x, y, callback)
    local button = CreateFrame("CheckButton", name, content, "OptionsCheckButtonTemplate")
    button:SetWidth(24); button:SetHeight(24)
    button:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
    Theme.CheckButton(button)
    local label = _G[name .. "Text"]
    label:SetText(title); label:SetFontObject("GameFontNormalSmall"); Theme.Text(label)
    button:SetScript("OnClick", function()
        if refreshing then return end
        callback(button:GetChecked() and true or false); page:RefreshValues()
    end)
    return button
end
local function RefreshPlates(key)
    if (not key or key == "nameplate_scale") and FT.RefreshNameplateScale then FT.RefreshNameplateScale() end
    if (not key or string.find(key, "nameplate_raidmark_", 1, true)) and FT.RefreshNameplateRaidMarks then
        FT.RefreshNameplateRaidMarks()
    end
    if (not key or string.find(key, "nameplate_cd_", 1, true)) and CD then CD:Refresh() end
end
local function Slider(name, key, title, minimum, maximum, step, fallback, x, y, width, suffix)
    local slider = CreateFrame("Slider", name, content, "OptionsSliderTemplate")
    slider:SetWidth(width); slider:SetHeight(16)
    slider:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
    slider:SetMinMaxValues(minimum, maximum); slider:SetValueStep(step); Theme.Slider(slider)
    local label = _G[name .. "Text"]
    Theme.Text(label)
    for _, part in ipairs({ "Low", "High" }) do Theme.Text(_G[name .. part], "muted") end
    _G[name .. "Low"]:SetText(minimum .. suffix); _G[name .. "High"]:SetText(maximum .. suffix)
    slider.label = label
    slider:SetScript("OnValueChanged", function()
        local value = math.floor(slider:GetValue() / step + 0.5) * step
        label:SetText(title .. ": " .. (step < 1 and string.format("%.2f", value) or tostring(value)) .. suffix)
        if not refreshing then FT.SetOverride(key, value); RefreshPlates(key) end
    end)
    controls[key] = slider
    slider.key, slider.fallback, slider.minimum, slider.maximum = key, fallback, minimum, maximum
    return slider
end

Text("Nameplates", 18, -14, "heading")
Text("Size and icon changes apply immediately. Enable changes below need Reload UI.", 18, -38, "hint", 34)
local ownerNote = Text("", 18, -78, "hint", 30)
local modules = { { "Nameplate Scale", "Adjust plate size" },
    { "Nameplate Class Colors", "Class colors" }, { "Nameplate Castbar", "Castbars" } }
for i, entry in ipairs(modules) do
    local title = entry[1]
    startup[title] = FT.IsEnabled(title)
    controls[title] = Check("FCTweaksPlateModule" .. i, entry[2], 16 + ((i - 1) % 2) * 235,
        -116 - math.floor((i - 1) / 2) * 28, function(value)
            FostercareTweaks_Config[title] = value and 1 or 0
        end)
end
local reload = CreateFrame("Button", "FCTweaksNameplatesReload", content, "UIPanelButtonTemplate")
reload:SetWidth(110); reload:SetHeight(24); reload:SetPoint("TOPLEFT", content, "TOPLEFT", 254, -146)
reload:SetText("Reload UI"); Theme.Button(reload)
reload:SetScript("OnClick", function() ReloadUI() end)
controls.reload = reload
Slider("FCTweaksPlateScaleSlider", "nameplate_scale", "Plate size", 0.5, 2, 0.05, 1, 22, -210, 442, "x")
Text("Raid target marks", 18, -256, "heading")
Slider("FCTweaksPlateMarkSizeSlider", "nameplate_raidmark_size", "Mark size", 12, 32, 1, 20, 22, -300, 210, " px")
controls.markAbove = Check("FCTweaksPlateMarkAboveCB", "Above the name", 250, -285, function(value)
    FT.SetOverride("nameplate_raidmark_position", value and "above" or "left"); RefreshPlates("nameplate_raidmark_position")
end)
Text("Marks otherwise sit beside the health bar. Enable Clear Raid Target Marks in Unit Frames.", 18, -338, "hint", 34)
Text("Enemy cooldowns", 18, -390, "heading")
controls.cooldowns = Check("FCTweaksPlateCooldowns", "Show estimated enemy cooldowns", 16, -418, function(value)
    FostercareTweaks_Config["Enemy Nameplate Cooldowns"] = value and 1 or 0
    CD:ApplyConfiguration()
end)
Text("Observed enemy players only. ~ means estimated: talents, resets and server rules can change timers. Item cooldowns and unobserved abilities are not revealed.", 18, -452, "hint", 48)
Slider("FCTweaksPlateCDSizeSlider", "nameplate_cd_size", "Icon size", 14, 40, 1, 22, 22, -548, 210, " px")
Slider("FCTweaksPlateCDCountSlider", "nameplate_cd_count", "Maximum icons", 1, 8, 1, 5, 264, -548, 200, "")
Slider("FCTweaksPlateCDMinimumSlider", "nameplate_cd_minimum", "Minimum base cooldown", 5, 120, 1, 5, 22, -610, 210, " s")
Slider("FCTweaksPlateCDOffsetSlider", "nameplate_cd_offset", "Extra space above name", 0, 60, 1, 8, 264, -610, 200, " px")
local reset = CreateFrame("Button", "FCTweaksNameplatesReset", content, "UIPanelButtonTemplate")
reset:SetWidth(160); reset:SetHeight(24); reset:SetPoint("TOPLEFT", content, "TOPLEFT", 18, -690)
reset:SetText("Reset size and icons"); Theme.Button(reset)
reset:SetScript("OnClick", function()
    for _, control in pairs(controls) do
        if control.key then FT.SetOverride(control.key, control.fallback) end
    end
    FT.SetOverride("nameplate_raidmark_position", "left")
    RefreshPlates(); page:RefreshValues()
end)
controls.reset = reset
Text("Enable choices and other frame settings are kept. Cooldowns require NamPower 4.6.2+.", 18, -726, "hint", 34)

function page:RefreshValues()
    refreshing = true
    local changed = false
    for _, entry in ipairs(modules) do
        local title = entry[1]
        local enabled = FT.IsEnabled(title)
        controls[title]:SetChecked(enabled)
        if enabled ~= startup[title] then changed = true end
    end
    for _, control in pairs(controls) do
        if control.key then control:SetValue(FT.GetNumber(control.key, control.fallback, control.minimum, control.maximum)) end
    end
    controls.markAbove:SetChecked(FT.GetOverride("nameplate_raidmark_position") == "above")
    controls.cooldowns:SetChecked(FT.IsEnabled("Enemy Nameplate Cooldowns", true))
    if ShaguPlates then ownerNote:SetText("ShaguPlates owns your nameplates. These changes stay inactive while it is loaded.")
    elseif not CD:IsAvailable() then ownerNote:SetText("Enemy cooldowns need NamPower 4.6.2+. Other nameplate features remain available.")
    elseif changed then ownerNote:SetText("Enable choices saved. Click Reload UI to apply them.")
    else ownerNote:SetText("Spell timers use your client's spell data. Latest observed abilities appear first.") end
    if changed then reload:Enable() else reload:Disable() end
    refreshing = nil
end
