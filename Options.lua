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
settings:SetClampedToScreen(true)
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

-- General changes are staged; gameplay pages apply live.
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
settings.okay:SetText("Apply")
settings.okay:SetScript("OnClick", function()
    local reload = false

    if FT.mods then
        for title, mod in pairs(FT.mods) do
            if current_config[title] ~= nil and current_config[title] ~= FostercareTweaks_Config[title] then
                FostercareTweaks_Config[title] = current_config[title]
                if mod.apply then
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

    current_config = {}

    if reload then settings:RequireReload() end
    for title, mod in pairs(FT.mods) do
        if mod.category ~= "Unit Frames" then
            current_config[title] = FostercareTweaks_Config[title]
        end
    end
    settings:load()
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

-- A reload is never a side effect of Apply or resetting a page.
settings.reload = CreateFrame("Button", "FCTweaksReloadUI", settings, "GameMenuButtonTemplate")
settings.reload:SetWidth(104); settings.reload:SetHeight(24); settings.reload:SetText("Reload UI")
Theme.Button(settings.reload); settings.reload:Hide()
settings.reload:SetScript("OnClick", function() ReloadUI() end)
function settings:RequireReload()
    self.reloadRequired = true
    self.reload:Show()
end

-- Navigation Tabs & Subsystem Pages
settings.tabs = {}

local function EnsureWindowHeight()
    -- UIParent already reports UI-coordinate bounds. Every page scrolls;
    -- leave room for the window's controls on shorter/scaled viewports.
    local frameHeight = math.min(600, math.max(240, UIParent:GetHeight() - 40))
    if settings:GetHeight() ~= frameHeight then settings:SetHeight(frameHeight) end
end
settings:RegisterEvent("UI_SCALE_CHANGED")
FT.SetEventHandler(settings, EnsureWindowHeight)

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
            if page.sectionHeader then
                if id == tabId then page.sectionHeader:Show() else page.sectionHeader:Hide() end
            end
        end
    end
    local general = tabId == 1
    settings.reload:ClearAllPoints()
    settings.reload:SetPoint("BOTTOMLEFT", settings, "BOTTOMLEFT", general and 120 or 16, 16)
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
    tab:SetWidth(96)
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

-- Categories have fixed headings on every visit. No page has collapse arrows.
settings.load = function(self)
    EnsureWindowHeight()
    self.entries = self.entries or {}
    if not self.generalBuilt then
        local gui = {}
        for _, title in ipairs(FT.moduleOrder) do
            local module = FT.mods[title]
            if module.category ~= "Unit Frames" then
                gui[module.category] = gui[module.category] or {}
                table.insert(gui[module.category], module)
            end
        end
        local hint = Theme.Font(self.container, "OVERLAY", "GameFontNormalSmall", "hint")
        hint:SetPoint("TOPLEFT", self.container, "TOPLEFT", 22, -10)
        hint:SetWidth(448); hint:SetHeight(34); hint:SetJustifyH("LEFT")
        hint:SetText("Apply saves General changes. Other pages save each change immediately. Reload UI appears when needed.")
        local height = 56
        self.category = {}
        local order = { General=1, ["Action Bar"]=2, ["World & MiniMap"]=3,
            ["Social & Chat"]=4, ["Tooltip & Items"]=5 }
        for category, modules in FT.spairs(gui, function(a, b)
            local left, right = order[a] or 6, order[b] or 6
            if left ~= right then return left < right end
            return a < b
        end) do
            table.sort(modules, function(a,b) return a.title < b.title end)
            local box = FT.SettingsWidgets.Section(self.container, category, 32 + #modules * 28)
            box:SetPoint("TOPLEFT", self.container, "TOPLEFT", 22, -height)
            box:SetPoint("TOPRIGHT", self.container, "TOPRIGHT", -22, -height)
            self.category[category] = box
            for index, module in ipairs(modules) do
                local title = module.title
                local name = "FCTweaksGUI_" .. string.gsub(title, "[^%w]", "")
                local button = FT.SettingsWidgets.Check(name, title, module.description, box, 16, -24 - (index-1)*28)
                button.title = title
                button:SetScript("OnClick", function() current_config[title] = button:GetChecked() and 1 or 0 end)
                self.entries[title] = button
            end
            height = height + box:GetHeight() + 14
        end
        self.container:SetHeight(height + 12)
        self.generalBuilt = true
    end
    for title, button in pairs(self.entries) do button:SetChecked(current_config[title] == 1) end
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
            if mod.category ~= "Unit Frames" then current_config[title] = FostercareTweaks_Config[title] end
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
