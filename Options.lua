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

settings.scrollframe = CreateFrame("ScrollFrame", "FostercareTweaksGUIScrollframe", settings, "UIPanelScrollFrameTemplate")
settings.scrollframe:SetWidth(max_width - 50)
settings.scrollframe:SetPoint("CENTER", settings, "CENTER", -12, 15)
settings.scrollframe:Hide()

settings.container = CreateFrame("Frame", "FostercareTweaksGUIContainer", settings)

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
    for k, v in pairs(current_config) do
        if current_config[k] ~= FostercareTweaks_Config[k] then
            reload = true
        end
        FostercareTweaks_Config[k] = v
    end

    if reload then
        ReloadUI()
    end
    settings:Hide()
end)

settings.defaults = CreateFrame("Button", "FostercareTweaksDefaults", settings, "GameMenuButtonTemplate")
settings.defaults:SetWidth(96)
settings.defaults:SetHeight(24)
settings.defaults:SetPoint("BOTTOMLEFT", settings, "BOTTOMLEFT", 16, 16)
settings.defaults:SetText(DEFAULTS)
settings.defaults:SetScript("OnClick", function()
    settings:defaults()
end)

settings.load = function(self)
    max_height = math.min(UIParent:GetHeight() / UIParent:GetScale() * 0.75, 700)
    settings:SetHeight(max_height)
    settings.scrollframe:SetHeight(max_height - 84)
    settings.container:SetHeight(max_height - 30)

    settings.entries = settings.entries or {}

    local gui = {}
    for title, module in pairs(FostercareTweaks.mods) do
        local category = module.category or T["General"]
        gui[category] = gui[category] or {}
        gui[category][title] = module
    end

    local topspace = 10
    local required_height = topspace
    local entrysize = 22
    local previous = nil

    local sortCategories = function(a, b)
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
        if a == T["General"] then return false end
        if b == T["General"] then return true end
        return a < b
    end

    for category, entries in FostercareTweaks.spairs(gui, sortCategories) do
        local entry, spacing = 1, 22
        local height = 0

        settings.category = settings.category or {}
        settings.category[category] = settings.category[category] or CreateFrame("Frame", nil, settings.container)

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

        collapse(settings.category[category], true)
        height = height + spacing
        settings.category[category]:SetHeight(height)
        required_height = required_height + height + spacing
    end

    settings.container:SetHeight(required_height)

    if required_height < max_height then
        settings:SetHeight(required_height + 60)
        settings.container:SetParent(settings)
        settings.container:ClearAllPoints()
        settings.container:SetPoint("CENTER", settings, "CENTER", 0, 20)
        settings.container:SetWidth(max_width - 20)
        settings.scrollframe:Hide()
    else
        settings.container:SetParent(settings.scrollframe)
        settings.container:SetHeight(settings.scrollframe:GetHeight())
        settings.container:SetWidth(settings.scrollframe:GetWidth() + 20)
        settings.scrollframe:SetScrollChild(settings.container)
        settings.scrollframe:Show()
    end
end

settings.defaults = function()
    for title, mod in pairs(FostercareTweaks.mods) do
        current_config[title] = mod.enabled and 1 or 0
    end
    settings:load()
end

settings:SetScript("OnShow", function()
    for k, v in pairs(FostercareTweaks_Config) do
        current_config[k] = v
    end
    settings:load()
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
