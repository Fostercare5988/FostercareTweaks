-- Dedicated layout controls; edits apply immediately, without replacing actions.
local FT = FostercareTweaks
local settings = FostercareTweaksSettingsGUI
if not FT or not FT.ActionBars or not settings then return end
local AB = FT.ActionBars
local Theme = FT.SettingsTheme
local page = CreateFrame("ScrollFrame", "FCTweaksActionSettingsPage", settings, "UIPanelScrollFrameTemplate")
page:SetPoint("TOPLEFT", settings, "TOPLEFT", 14, -64)
page:SetPoint("BOTTOMRIGHT", settings, "BOTTOMRIGHT", -34, 48)
page:Hide()
settings.actionPage = page
local content = CreateFrame("Frame", "FCTweaksActionSettingsContent", page)
content:SetWidth(492)
page:SetScrollChild(content)
Theme.Panel(content)
local selected = AB.definitions[1]
local refreshing
local controls = {}
page.controls = controls

local function Text(text, x, y, width)
    local label = Theme.Font(content, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
    label:SetWidth(width or 444)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end
local title = Text("Action Bars", 18, -14)
Theme.Text(title, "heading")
Text("Keep your current appearance. Enable custom layouts to move or reshape bars.", 18, -40)

local function Check(name, text, x, y, callback)
    local button = CreateFrame("CheckButton", "FCTweaksBars" .. name, content, "OptionsCheckButtonTemplate")
    button:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
    button:SetWidth(24)
    button:SetHeight(24)
    Theme.CheckButton(button)
    local label = _G[button:GetName() .. "Text"]
    label:SetText(text)
    Theme.Text(label)
    button:SetScript("OnClick", function()
        if refreshing then return end
        callback(button:GetChecked() and true or false)
        page:RefreshValues()
    end)
    return button
end
controls.enabled = Check("Enabled", "Enable custom layouts", 16, -70, function(value) AB:SetEnabled(value) end)
controls.editing = Check("Editing", "Unlock bar handles", 250, -70, function(value) AB:SetEditing(value) end)
local help = Text("Drag the lavender handles, then lock them to use the buttons. Edits save per character.", 18, -103)
Theme.Text(help, "hint")

local selectors = {}
for index, definition in ipairs(AB.definitions) do
    local choice = definition
    local button = CreateFrame("Button", "FCTweaksBarsSelect" .. definition.id, content, "UIPanelButtonTemplate")
    button:SetWidth(144)
    button:SetHeight(24)
    button:SetPoint("TOPLEFT", content, "TOPLEFT", 18 + ((index - 1) % 3) * 150, -140 - math.floor((index - 1) / 3) * 28)
    button:SetText(definition.title)
    Theme.Button(button)
    button:SetScript("OnClick", function() selected = choice; page:RefreshValues() end)
    selectors[definition.id] = button
end
controls.selectors = selectors
local detailsY = -152 - math.ceil(#AB.definitions / 3) * 28
content:SetHeight(-detailsY + 350)
local heading = Text("", 18, detailsY)
Theme.Text(heading, "heading")
controls.visible = Check("Visible", "Show this bar", 16, detailsY - 24, function(value) AB:SetValue(selected.id, "visible", value) end)
controls.empty = Check("Empty", "Show empty buttons", 250, detailsY - 24, function(value) AB:SetValue(selected.id, "showEmpty", value) end)
controls.up = Check("Up", "Bottom to top", 16, detailsY - 56, function(value) AB:SetValue(selected.id, "growUp", value) end)

local function Slider(key, title, minimum, maximum, step, x, y, width, format)
    local slider = CreateFrame("Slider", "FCTweaksBars" .. key, content, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
    slider:SetWidth(width)
    slider:SetHeight(16)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
    Theme.Slider(slider)
    _G[slider:GetName() .. "Low"]:SetText(tostring(minimum))
    Theme.Text(_G[slider:GetName() .. "Low"], "muted")
    _G[slider:GetName() .. "High"]:SetText(tostring(maximum))
    Theme.Text(_G[slider:GetName() .. "High"], "muted")
    local label = _G[slider:GetName() .. "Text"]
    Theme.Text(label)
    slider:SetScript("OnValueChanged", function()
        local value = math.floor(slider:GetValue() / step + 0.5) * step
        label:SetText(title .. ": " .. format(value))
        if not refreshing then AB:SetValue(selected.id, key, value); page:RefreshValues() end
    end)
    return slider
end
controls.columns = Slider("columns", "Buttons per row", 1, 12, 1, 22, detailsY - 104, 210, function(v) return tostring(v) end)
controls.scale = Slider("scale", "Size", 0.5, 2, 0.05, 264, detailsY - 104, 200, function(v) return math.floor(v * 100 + 0.5) .. "%" end)
controls.spacing = Slider("spacing", "Spacing", 0, 20, 1, 22, detailsY - 166, 442, function(v) return tostring(v) .. " px" end)
local summary = Text("", 18, detailsY - 200)
local note = Text("", 18, detailsY - 226)
note:SetHeight(46)
local reset = CreateFrame("Button", "FCTweaksBarsReset", content, "UIPanelButtonTemplate")
Theme.Button(reset)
reset:SetPoint("TOPLEFT", content, "TOPLEFT", 18, detailsY - 286)
reset:SetWidth(160)
reset:SetHeight(24)
reset:SetText("Reset this bar's layout")
reset:SetScript("OnClick", function() AB:ResetBar(selected.id); page:RefreshValues() end)
controls.reset = reset
Text("Actions and key bindings are kept. Extra rows can be bound in the game's Key Bindings window.", 18, detailsY - 322)

function page:RefreshValues()
    refreshing = true
    local config = AB:GetSettings(selected.id)
    local bar = AB.bars[selected.id]
    local nativeFrame = selected.id == "main" and MainMenuBar or _G[selected.prefix]
    local visible = selected.id == "main" or config.visible == true
        or (config.visible == nil and ((bar and bar.nativeVisible) or (nativeFrame and nativeFrame:IsShown())))
    controls.enabled:SetChecked(AB.enabled)
    controls.editing:SetChecked(AB.editing)
    if AB.enabled then controls.editing:Enable() else controls.editing:Disable() end
    for id, button in pairs(selectors) do
        if id == selected.id then button:Disable() else button:Enable() end
        Theme.SelectButton(button, id == selected.id)
    end
    heading:SetText(selected.title)
    controls.visible:SetChecked(visible)
    if selected.id == "main" then controls.visible:Disable() else controls.visible:Enable() end
    controls.empty:SetChecked(config.showEmpty == true or (config.showEmpty == nil and (selected.id == "extra" or selected.custom)))
    controls.up:SetChecked(config.growUp == true)
    local columns = math.floor(FT.ClampNumber(config.columns, selected.columns, 1, 12))
    controls.columns:SetValue(columns)
    controls.scale:SetValue(FT.ClampNumber(config.scale, 1, 0.5, 2))
    controls.spacing:SetValue(FT.ClampNumber(config.spacing, 6, 0, 20))
    summary:SetText("12 buttons in " .. math.ceil(12 / columns) .. " row(s). Changes apply immediately.")
    if selected.custom then
        note:SetText("Drop a spell or item onto an empty button. Drag within Extra Rows 2–7; Shift-right-click clears. Keep macros on native bars.")
    elseif selected.id == "extra" then
        note:SetText("Extra Row uses action page 2 (slots 13–24). Selecting page 2 on the main bar shows the same actions. Reserved stance pages are kept.")
    elseif selected.id == "main" then
        note:SetText("Main and stealth buttons share this layout. Native paging, stealth transitions and existing key bindings are kept.")
    else note:SetText("This bar keeps its original action slots, tooltips, drag behavior and key bindings.") end
    refreshing = nil
end

-- Closing the menu also closes the input-blocking edit handles.
FT.HookScript(settings, "OnHide", function() AB:SetEditing(false) end)
local watcher = CreateFrame("Frame", nil, page)
watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
FT.SetEventHandler(watcher, function() if page:IsVisible() then page:RefreshValues() end end)
