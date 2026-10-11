local FT = FostercareTweaks
if not FT then return end
local Theme = FT.SettingsTheme

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

FT.SettingsWidgets = { Check = CreateCheckButton, Slider = CreateSlider, Section = CreateSectionBox }
local Widgets = FT.SettingsWidgets

-- A fixed selector row keeps a long settings page focused on one task.
-- Build once at source load; switching sections only lays out existing boxes.
function Widgets.Sections(page, content, sections, hint)
    page.sections, page.sectionButtons = sections, {}
    local rows = math.ceil(#sections / 3)
    page:ClearAllPoints()
    page:SetPoint("TOPLEFT", FostercareTweaksSettingsGUI, "TOPLEFT", 14, -118 - rows * 28)
    page:SetPoint("BOTTOMRIGHT", FostercareTweaksSettingsGUI, "BOTTOMRIGHT", -34, 48)
    -- Keep navigation outside the scrolling/clipped content area.
    local header = CreateFrame("Frame", nil, FostercareTweaksSettingsGUI)
    page.sectionHeader = header
    header:Hide()
    header:SetPoint("TOPLEFT", FostercareTweaksSettingsGUI, "TOPLEFT", 14, -64)
    header:SetWidth(492); header:SetHeight(46 + rows * 28)
    local caption = Theme.Font(header, "OVERLAY", "GameFontNormalSmall", "hint")
    caption:SetPoint("TOPLEFT", header, "TOPLEFT", 22, -4)
    caption:SetWidth(448); caption:SetHeight(30); caption:SetJustifyH("LEFT"); caption:SetText(hint)
    local description = Theme.Font(content, "OVERLAY", "GameFontNormalSmall", "hint")
    description:SetPoint("TOPLEFT", content, "TOPLEFT", 22, -8)
    description:SetWidth(448); description:SetHeight(40); description:SetJustifyH("LEFT")
    function page:SelectSection(id)
        local selected = sections[id] and id or 1
        self.currentSection = selected
        local height, previous = 56, nil
        for index, section in ipairs(sections) do
            local button = self.sectionButtons[index]
            if selected == index then button:Disable() else button:Enable() end
            Theme.SelectButton(button, selected == index)
            for _, box in ipairs(section.boxes) do
                if selected == index then
                    box:ClearAllPoints()
                    if previous then
                        box:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -14)
                        box:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -14)
                    else
                        box:SetPoint("TOPLEFT", content, "TOPLEFT", 22, -height)
                        box:SetPoint("TOPRIGHT", content, "TOPRIGHT", -22, -height)
                    end
                    box:Show(); previous = box; height = height + box:GetHeight() + 14
                else box:Hide() end
            end
        end
        description:SetText(sections[selected].hint)
        content:SetHeight(height + 14)
        page:SetVerticalScroll(0)
        if page.UpdateScrollChildRect then page:UpdateScrollChildRect() end
    end
    for index, section in ipairs(sections) do
        local button = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
        button:SetWidth(146); button:SetHeight(24)
        button:SetPoint("TOPLEFT", header, "TOPLEFT", 22 + ((index - 1) % 3) * 151,
            -38 - math.floor((index - 1) / 3) * 28)
        button:SetText(section.title); Theme.Button(button)
        if button:GetFontString() then button:GetFontString():SetFontObject("GameFontNormalSmall") end
        button:SetScript("OnClick", function() page:SelectSection(index) end)
        page.sectionButtons[index] = button
    end
    page:SelectSection(1)
end
