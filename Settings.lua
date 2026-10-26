local FT = FostercareTweaks
if not FT then return end
local _, ns = ...
local UI = ns.UI

-- ForgeUI settings window (VanillaForge templates/ForgeUI): columns at 28 and
-- 264, five tabs. Every change saves at once; a feature that can only start
-- or stop with a fresh UI shows the Reload UI button instead.
local LEFT, RIGHT, SIDE, INDENT = 28, 264, 208, 44
local panel = UI.Window("FostercareTweaksSettingsGUI", "FostercareTweaks", 500, 480,
    GetAddOnMetadata("FostercareTweaks", "Version"))

local syncs = {}
local reloadNeeded = false
local function Refresh()
    for _, sync in ipairs(syncs) do sync() end
end
local function Config() return FostercareTweaks_Config end
local function UF() return FT.UnitFrames end
local function ApplyUnitFrames() if UF() then UF():ApplyConfiguration() end end
local function RefreshRaid() if UF() then UF():UpdateAllRaidFrames() end end
local function NeedReload() reloadNeeded = true end
local function Always() return true end
local function Pixels(value) return value .. " px" end
local function Times(value) return string.format("%.2fx", value) end

-- Dims a slider block the way UI.Sync dims a switch.
local function Dim(slider, on)
    local alpha = on and 1 or 0.4
    slider:EnableMouse(on and true or false); slider:SetAlpha(alpha)
    slider.label:SetAlpha(alpha); slider.valueText:SetAlpha(alpha)
end

-- A switch for one module's own saved key. after(value) applies the change
-- live; without it the change waits for a reload. needs() dims the switch.
local function Feature(page, title, text, tip, x, y, after, needs, default)
    local widget = UI.Switch("FTOpt_" .. string.gsub(title, "[^%w]", ""), page, text, tip, x, y, function(value)
        Config()[title] = value and 1 or 0
        if after then after(value) else NeedReload() end
        Refresh()
    end, x == LEFT and 190 or 172)
    table.insert(syncs, function()
        UI.Sync(widget, FT.IsEnabled(title, default), (needs or Always)())
    end)
    return widget
end

-- A switch for one value in the overrides table (1 on, 0 off).
local function Option(page, key, default, text, tip, x, y, after, needs)
    local widget = UI.Switch("FTOpt_" .. key, page, text, tip, x, y, function(value)
        FT.SetOverride(key, value and 1 or 0); after(); Refresh()
    end, x == LEFT and 190 or 172)
    table.insert(syncs, function()
        UI.Sync(widget, FT.GetNumber(key, default, 0, 1) ~= 0, (needs or Always)())
    end)
end

local function Slider(page, key, default, minimum, maximum, step, text, x, y, after, needs, format)
    local slider = UI.Slider("FTOpt_" .. key, page, text, x, y, SIDE, minimum, maximum, step, function(value)
        FT.SetOverride(key, value); after(value)
    end, format or Pixels)
    table.insert(syncs, function()
        UI.SetSlider(slider, FT.GetNumber(key, default, minimum, maximum))
        Dim(slider, (needs or Always)())
    end)
    return slider
end

local function Hint(page, text, x, y, width)
    local label = UI.Label(page, text, x, y, "GameFontDisableSmall")
    label:SetWidth(width or SIDE)
    return label
end

local function FooterButton(page, name, text, x, width, onClick, tip)
    local button = UI.Button(name, page, text, 0, 0, width, onClick)
    button:ClearAllPoints(); button:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", x, 18)
    if tip then UI.Tooltip(button, tip) end
    return button
end

local tab = 1
local TABS = { "general", "unit", "auras", "raid", "bars" }
local pages, ShowTab = UI.Tabs(panel, "FTOpt", {
    { label = "General", height = 520 },
    { label = "Unit Frames", height = 452 },
    { label = "Auras", height = 400 },
    { label = "Raid", height = 590 },
    { label = "Action Bars", height = 574 },
}, function(index) tab = index; Refresh() end)
panel:SetScript("OnShow", function() ShowTab(tab) end)

-- One Reload UI button, shown on every page while a change waits for it.
for index, page in ipairs(pages) do
    local reload = FooterButton(page, "FTOptReload" .. index, "Reload UI", RIGHT + 36, 172, function() ReloadUI() end,
        "Some changes start or stop only with a fresh interface.")
    reload:Hide()
    table.insert(syncs, function() if reloadNeeded then reload:Show() else reload:Hide() end end)
end

-- General ---------------------------------------------------------------------
local general = pages[1]
UI.Heading(general, "Gameplay", LEFT, -98)
Feature(general, "Auto Dismount", "Dismount for everything else",
    "Dismount or leave your form when you attack, take a flight, talk to an NPC or use an item. Spells do this in ClassicAPI.",
    LEFT, -118)
Feature(general, "Auto Stance", "Switch stance for spells",
    "A warrior or druid spell that needs another stance or form switches to the first one you can use.", LEFT, -144)
Feature(general, "Hide Stealth / Stance Bar", "Hide the stance bar", "Hide the stealth, stance and form buttons.",
    LEFT, -170, function(value) FT.mods["Hide Stealth / Stance Bar"]:apply(value) end)
UI.Heading(general, "Items", LEFT, -210)
Feature(general, "Vendor Values", "Sell prices on tooltips", "Show what a merchant pays for an item.", LEFT, -230)
Feature(general, "Equip Compare", "Compare with Shift", "Hold Shift over an item to see what you wear in its slot.", LEFT, -256)
Feature(general, "Item Rarity Borders", "Quality borders", "Color item borders by quality in bags, bank, character and inspect.", LEFT, -282)
Feature(general, "Sell Junk", "Sell Junk button", "A merchant button that sells every grey item.", LEFT, -308)
UI.Heading(general, "Minimap", LEFT, -348)
Feature(general, "MiniMap Clock", "Clock", "A 24-hour clock under the minimap.", LEFT, -368)
Feature(general, "MiniMap Square", "Square minimap", "A square minimap instead of a round one.", LEFT, -394)
Feature(general, "MiniMap Tweaks", "Tidy buttons, wheel zoom", "Hide extra minimap buttons and zoom with the mouse wheel.", LEFT, -420)
UI.Heading(general, "Chat", RIGHT, -98)
Feature(general, "Chat Tweaks", "Wheel scroll, sticky channels",
    "Scroll with the mouse wheel, keep the last channel, repeat messages with the arrow keys.", RIGHT, -118)
Feature(general, "Chat Hyperlinks", "Copyable links", "Click web links to copy them; quest and item links open.", RIGHT, -144)
Feature(general, "Chat History", "Keep chat history", "Restore chat windows after a reload or login.", RIGHT, -170)
Feature(general, "Chat Timestamps", "Timestamps", "The time before each chat message. The combat log has none.", RIGHT, -196)
Feature(general, "Chat Class Colors", "Class colors for names",
    "Player names in their class color. To remember players between sessions, turn on the player cache in AddOn Options > ClassicAPI.", RIGHT, -222)
Feature(general, "Blue Shaman Class Colors", "Blue shamans", "Shamans in blue instead of pink.", RIGHT, -248)
UI.Heading(general, "World map", RIGHT, -288)
Feature(general, "WorldMap Window", "Map in a window", "A movable map window. Ctrl + mouse wheel resizes it.", RIGHT, -308)
Feature(general, "WorldMap Coordinates", "Coordinates", "Your and the cursor's coordinates under the map.", RIGHT, -334)
Feature(general, "WorldMap Class Colors", "Class colors", "Group members in class colors on the world and battleground map.", RIGHT, -360)
Hint(general, "For spells, dismounting, leaving forms and standing up are ClassicAPI settings: AddOn Options > ClassicAPI.",
    LEFT, -456, 444)

-- Unit Frames -------------------------------------------------------------------
local unit = pages[2]
local function Marks() if FT.RefreshRaidMarks then FT:RefreshRaidMarks() end end
local function Ticks() if FT.RefreshEnergyTick then FT.RefreshEnergyTick() end end
local function On(title, default) return function() return FT.IsEnabled(title, default) end end
UI.Heading(unit, "Player and target", LEFT, -98)
Feature(unit, "Unit Frame Class Colors", "Class colors behind names", "Players' names on a bar in their class color.",
    LEFT, -118, function() FT.mods["Unit Frame Class Colors"]:apply() end)
Feature(unit, "Real Health Numbers", "Health numbers", "Exact health and mana numbers on the player, target and pet frames.", LEFT, -144)
UI.Heading(unit, "Target castbar", LEFT, -184)
Feature(unit, "Enemy Castbars", "Castbar under the target", "Your target's casts under the target frame; grey when you cannot interrupt them.",
    LEFT, -204, function() FT.mods["Enemy Castbars"]:apply() end)
UI.Heading(unit, "Raid marks", LEFT, -244)
Feature(unit, "Clear Raid Target Marks", "Bigger marks on frames", "Larger raid marks on the target and raid frames.", LEFT, -264)
local marks = On("Clear Raid Target Marks", true)
local outside = UI.Switch("FTOpt_raidmark_position", unit, "Beside the portrait", "The target's mark outside its portrait.",
    INDENT, -290, function(value)
        FT.SetOverride("raidmark_position", value and "outside" or "portrait"); Marks(); Refresh()
    end, 172)
table.insert(syncs, function() UI.Sync(outside, FT.GetOverride("raidmark_position") == "outside", marks()) end)
Slider(unit, "raidmark_size", 22, 12, 36, 1, "Mark size", LEFT, -320, Marks, marks)
Hint(unit, "Hold Ctrl+Shift to move frames, aura areas, the raid frames and action bars.", LEFT, -372, 444)
UI.Heading(unit, "Energy ticks", RIGHT, -98)
Feature(unit, "Show Energy Ticks", "Energy and mana ticks",
    "Estimated energy ticks and the five-second mana rule on your power bar.", RIGHT, -118, ApplyUnitFrames)
local ticks = On("Show Energy Ticks", true)
Option(unit, "energytick_contrast", 1, "Bright line", "A white center and glow on the tick line.", RIGHT, -144, Ticks, ticks)
Option(unit, "energytick_flash", 1, "Flash on tick", "The bar's edge lights up at each tick.", RIGHT, -170, Ticks, ticks)
Slider(unit, "energytick_width", 3, 2, 6, 1, "Line width", RIGHT, -200, Ticks, ticks)
FooterButton(unit, "FTOpt_ResetPositions", "Reset positions", LEFT, 172, function()
    Config().unitframe_positions = nil; NeedReload(); Refresh()
end, "Put every moved frame and aura area back in its place. Takes effect after a reload.")

-- Auras -------------------------------------------------------------------------
local auras = pages[3]
local function StandardAuras()
    if FT.ApplyStandardAuraSettings then FT.ApplyStandardAuraSettings() end
    if UF() and UF().Auras then UF().Auras:RefreshBorders() end
end
UI.Heading(auras, "Player and target", LEFT, -98)
Feature(auras, "Show Player Buffs", "Player buffs", "Under the player frame, with sweeps and countdowns.", LEFT, -118, ApplyUnitFrames)
Feature(auras, "Show Player Debuffs", "Player debuffs", "Under the player frame; dispel colors on the border.", LEFT, -144, ApplyUnitFrames)
Feature(auras, "Show Target Buffs", "Target buffs", nil, LEFT, -170, ApplyUnitFrames)
Feature(auras, "Show Target Debuffs", "Target debuffs", nil, LEFT, -196, ApplyUnitFrames)
local function AuraSize(kind)
    return function(value)
        local apply = UF().Auras["Apply" .. kind .. "Size"]
        for _, container in ipairs({ UF().blizzPlayerAuras, UF().blizzTargetAuras }) do
            if container then apply(UF().Auras, container, value) end
        end
        ApplyUnitFrames()
    end
end
UI.Heading(auras, "Size", LEFT, -236)
Slider(auras, "uf_buff_size", 20, 14, 32, 1, "Buffs", LEFT, -256, AuraSize("Buff"))
Slider(auras, "uf_debuff_size", 20, 14, 32, 1, "Debuffs", LEFT, -298, AuraSize("Debuff"))
UI.Heading(auras, "Top right of the screen", RIGHT, -98)
Feature(auras, "Show Standard Buffs", "Buffs", "Blizzard's buff icons. Hold Ctrl+Shift to move them.", RIGHT, -118, StandardAuras, nil, true)
Feature(auras, "Show Standard Debuffs", "Debuffs", "Blizzard's debuff icons.", RIGHT, -144, StandardAuras, nil, true)
Feature(auras, "Show Weapon Enchants", "Weapon enchants", "Poisons, oils and other weapon enchants, in their own movable area.",
    RIGHT, -170, StandardAuras, nil, true)
UI.Heading(auras, "Borders", RIGHT, -210)
Feature(auras, "Show Buff Borders", "Buff borders", "A dark border around buffs everywhere.", RIGHT, -230, StandardAuras, nil, false)
Feature(auras, "Show Debuff Borders", "Debuff borders", "A dispel-colored border around debuffs everywhere.", RIGHT, -256, StandardAuras, nil, false)
Feature(auras, "Show Weapon Enchant Borders", "Enchant borders", "The weapon's quality color around its enchant.",
    RIGHT, -282, StandardAuras, nil, true)

-- Raid --------------------------------------------------------------------------
local raid = pages[4]
local function Raid() return UF() and UF():GetGroupDimensions().enabled end
local function Dimension(index)
    return function(value)
        local args = {}
        args[index] = value
        UF():ApplyGroupDimensions(args[1], args[2], args[3], args[4], args[5])
    end
end
local function GroupSlider(key, index, minimum, maximum, step, text, y, format)
    local slider = UI.Slider("FTOpt_raid_" .. key, raid, text, RIGHT, y, SIDE, minimum, maximum, step, Dimension(index), format or Pixels)
    table.insert(syncs, function()
        UI.SetSlider(slider, UF():GetGroupDimensions()[key]); Dim(slider, Raid())
    end)
end
UI.Heading(raid, "Party and raid frames", LEFT, -98)
local useRaid = UI.Switch("FTOpt_RaidFrames", raid, "Use these frames", "Replace the party frames and the game's raid frames.",
    LEFT, -118, function(value) UF():ApplyGroupDimensions(nil, nil, nil, nil, nil, value); Refresh() end)
table.insert(syncs, function() UI.Sync(useRaid, Raid()) end)
Feature(raid, "Show Group Labels", "Group labels", "G1 to G8 above the groups.", INDENT, -144, RefreshRaid, Raid, true)
UI.Heading(raid, "Health text", LEFT, -184)
local FORMATS = { "deficit", "percent", "current" }
local formatButtons, SelectFormat, formatTrack = UI.Segmented("FTOpt_RaidHealth", raid, { "Missing", "Percent", "Current" },
    LEFT, -204, SIDE, function(index)
        FT.SetOverride("raid_health_format", FORMATS[index]); RefreshRaid(); Refresh()
    end, { height = 24 })
table.insert(syncs, function()
    local chosen = 1
    for i, value in ipairs(FORMATS) do if value == UF():GetRaidHealthFormat() then chosen = i end end
    SelectFormat(chosen)
    formatTrack:SetAlpha(Raid() and 1 or 0.4)
    for _, button in ipairs(formatButtons) do if Raid() then button:Enable() else button:Disable() end end
end)
UI.Heading(raid, "Indicators", LEFT, -246)
Feature(raid, "Show Raid Aggro Indicator", "Aggro corner", "A red corner on the member your enemy target is attacking.",
    LEFT, -266, RefreshRaid, Raid)
Feature(raid, "Show Raid HoT Indicator", "Heal-over-time corner", "Renew, Rejuvenation, Regrowth, shields and Blessing of Protection.",
    LEFT, -292, RefreshRaid, Raid)
Feature(raid, "Show Raid Debuff Badges", "Debuff icons", "Debuffs inside each member; dispellable ones first.", LEFT, -318, RefreshRaid, Raid)
UI.Heading(raid, "Buffs", LEFT, -358)
local raidBuffs = On("Show Raid Buffs", true)
Feature(raid, "Show Raid Buffs", "Buff icons", "Buffs inside each member; heals and your own first.", LEFT, -378, RefreshRaid, Raid, true)
Feature(raid, "Show All Raid Buffs", "Every buff", "Show all buffs that fit; +N counts the rest.", INDENT, -404, RefreshRaid,
    function() return Raid() and raidBuffs() end)
Slider(raid, "raid_buff_count", 4, 1, 8, 1, "Buffs per member", LEFT, -440, RefreshRaid,
    function() return Raid() and raidBuffs() and not FT.IsEnabled("Show All Raid Buffs") end, tostring)
Slider(raid, "raid_debuff_count", 3, 1, 8, 1, "Debuffs per member", LEFT, -482, RefreshRaid, Raid, tostring)
UI.Heading(raid, "Size", RIGHT, -98)
GroupSlider("width", 1, 40, 120, 1, "Width", -118)
GroupSlider("height", 2, 20, 60, 1, "Height", -160)
GroupSlider("scale", 3, 0.5, 2, 0.05, "Scale", -202, Times)
GroupSlider("spacingX", 4, 0, 20, 1, "Gap between groups", -244)
GroupSlider("spacingY", 5, 0, 20, 1, "Gap between members", -286)
UI.Heading(raid, "Icons", RIGHT, -330)
Slider(raid, "raid_buff_size", 10, 8, 18, 1, "Buff size", RIGHT, -350, RefreshRaid, Raid)
Slider(raid, "raid_debuff_size", 11, 8, 18, 1, "Debuff size", RIGHT, -392, RefreshRaid, Raid)
Slider(raid, "raid_aura_spacing", 2, 0, 6, 1, "Gap between icons", RIGHT, -434, RefreshRaid, Raid)
local preview = FooterButton(raid, "FTOpt_RaidTest", "Test grid", LEFT, 172, function()
    UF():ToggleRaidTest(); Refresh()
end, "Show 40 sample members to check size and position. Hold Ctrl+Shift to move them.")
table.insert(syncs, function() UI.Select(preview, UF():IsRaidTest()) end)
local RAID_DEFAULTS = { raid_health_format = "deficit", raid_buff_count = 4, raid_buff_size = 10,
    raid_debuff_count = 3, raid_debuff_size = 11, raid_aura_spacing = 2 }
FooterButton(raid, "FTOpt_RaidReset", "Reset raid settings", LEFT + 180, 140, function()
    for key, value in pairs(RAID_DEFAULTS) do FT.SetOverride(key, value) end
    for _, title in ipairs({ "Show Group Labels", "Show Raid Aggro Indicator", "Show Raid HoT Indicator",
        "Show Raid Debuff Badges", "Show Raid Buffs" }) do Config()[title] = 1 end
    Config()["Show All Raid Buffs"] = 0
    UF():ApplyGroupDimensions(64, 34, 1, 4, 3, true)
    RefreshRaid(); Refresh()
end, "Defaults for everything on this page. The frames stay where you put them.")

-- Action Bars -------------------------------------------------------------------
local bars = pages[5]
local AB = FT.ActionBars
local selected = AB.definitions[1]
local function Layouts() return AB.enabled end
UI.Heading(bars, "Look", LEFT, -98)
Feature(bars, "Hide Gryphons", "Hide gryphons", "Remove the gryphons at both ends of the bar.", LEFT, -118)
Feature(bars, "Floating Actionbar", "No bar background", "Remove the bar's background art.", LEFT, -144)
Feature(bars, "Reduced Actionbar Size", "Short main bar", "A shorter main bar without the bag and game menu buttons.", LEFT, -170)
Feature(bars, "Center Vertical Actionbar", "Center the right bars", "Center the right-side bars vertically.", LEFT, -196)
Feature(bars, "Reagent Counter", "Reagent counts", "How many casts your reagents allow, on the button.", LEFT, -222)
UI.Heading(bars, "Layouts", LEFT, -288)
local layouts = UI.Switch("FTOpt_Layouts", bars, "Custom layouts", "Move and reshape bars. Off keeps the game's layout.",
    LEFT, -308, function(value) AB:SetEnabled(value); Refresh() end)
local move = UI.Button("FTOpt_MoveBars", bars, "Move bars", LEFT, -340, 172, function()
    AB:SetEditing(not AB.editing); Refresh()
end)
UI.Tooltip(move, "Show a handle on each bar to drag it. Click again, or close this window, to lock them.")
Hint(bars, "Not in combat. Actions and key bindings stay on their buttons.", LEFT, -372)
table.insert(syncs, function()
    UI.Sync(layouts, AB.enabled)
    UI.SetEnabled(move, AB.enabled)
    UI.Select(move, AB.editing)
end)

-- The bar picker: two columns of pills, the chosen bar filled.
UI.Heading(bars, "Bar", RIGHT, -98)
local SHORT = { main = "Main", bottomleft = "Bottom left", bottomright = "Bottom right", right = "Right", left = "Left" }
local NOTES = {
    main = "The main bar and the stealth or stance bar share this layout.",
    extra = "Extra row 1 shows action page 2 (slots 13 to 24).",
}
local pickers = {}
for index, definition in ipairs(AB.definitions) do
    local choice = definition
    local label = SHORT[definition.id] or ("Extra " .. definition.extraIndex)
    local button = UI.Button("FTOpt_Bar" .. definition.id, bars, label, RIGHT + ((index - 1) % 2) * 106,
        -118 - math.floor((index - 1) / 2) * 26, 102, function() selected = choice; Refresh() end)
    UI.Tooltip(button, NOTES[definition.id] or (definition.custom
        and "Drop spells or items on its buttons; Shift-right-click clears one. Bind keys in Key Bindings."
        or "Keeps its own actions and key bindings."))
    pickers[definition.id] = button
end
local function BarValue(key, fallback)
    local value = AB:GetSettings(selected.id)[key]
    if value == nil then return fallback end
    return value
end
local function BarSwitch(key, text, y, fallback)
    local widget = UI.Switch("FTOpt_Bar_" .. key, bars, text, nil, RIGHT, y, function(value)
        AB:SetValue(selected.id, key, value); Refresh()
    end, 172)
    table.insert(syncs, function()
        UI.Sync(widget, BarValue(key, fallback()), Layouts() and not (key == "visible" and selected.id == "main"))
    end)
end
local function BarSlider(key, text, minimum, maximum, step, y, fallback, format)
    local slider = UI.Slider("FTOpt_Bar_" .. key, bars, text, RIGHT, y, SIDE, minimum, maximum, step, function(value)
        AB:SetValue(selected.id, key, value)
    end, format)
    table.insert(syncs, function()
        UI.SetSlider(slider, FT.ClampNumber(BarValue(key), fallback(), minimum, maximum)); Dim(slider, Layouts())
    end)
end
BarSwitch("visible", "Show this bar", -284, function()
    local bar, frame = AB.bars[selected.id], selected.id == "main" and MainMenuBar or _G[selected.prefix]
    return selected.id == "main" or (bar and bar.nativeVisible) or (frame and frame:IsShown()) or false
end)
BarSwitch("showEmpty", "Show empty buttons", -310, function() return selected.id == "extra" or selected.custom or false end)
BarSwitch("growUp", "Fill bottom to top", -336, function() return false end)
BarSlider("columns", "Buttons per row", 1, 12, 1, -370, function() return selected.columns end, tostring)
BarSlider("scale", "Size", 0.5, 2, 0.05, -412, function() return 1 end, function(v) return math.floor(v * 100 + 0.5) .. "%" end)
BarSlider("spacing", "Spacing", 0, 20, 1, -454, function() return 6 end, Pixels)
local resetBar = UI.Button("FTOpt_BarReset", bars, "Reset this bar", RIGHT, -496, 172, function()
    AB:ResetBar(selected.id); Refresh()
end)
UI.Tooltip(resetBar, "Its place and shape go back to the default. Its actions stay.")
table.insert(syncs, function()
    for id, button in pairs(pickers) do UI.Select(button, id == selected.id) end
    UI.SetEnabled(resetBar, Layouts())
end)

-- Handles block the buttons under them; lock them with the window and in combat.
FT.HookScript(panel, "OnHide", function() AB:SetEditing(false) end)
panel:RegisterEvent("PLAYER_REGEN_DISABLED")
FT.SetEventHandler(panel, function() if panel:IsShown() then Refresh() end end)

-- Opening ------------------------------------------------------------------------
-- FT.OpenSettings() toggles the window; a page name opens that page.
function FT.OpenSettings(name)
    for index, key in ipairs(TABS) do if key == name then tab = index end end
    if name or not panel:IsShown() then
        panel:Show(); ShowTab(tab)
    else
        panel:Hide()
    end
end

-- Game Menu > AddOn Options > FostercareTweaks (ClassicAPI 1.17.2+).
local entry = CreateFrame("Frame", "FostercareTweaksOptionsEntry")
entry.name = "FostercareTweaks"
local entryTitle = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
entryTitle:SetPoint("TOPLEFT", entry, "TOPLEFT", 16, -16)
entryTitle:SetText("FostercareTweaks")
local entryText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
entryText:SetPoint("TOPLEFT", entryTitle, "BOTTOMLEFT", 0, -8)
entryText:SetText("Settings open in their own window. Type /ft to open them at any time.")
local open = UI.Button("FostercareTweaksOptionsOpen", entry, "Open settings", 16, -70, 172, function()
    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then InterfaceOptionsFrame:Hide() end
    if GameMenuFrame and GameMenuFrame:IsShown() then HideUIPanel(GameMenuFrame) end
    FT.OpenSettings("general")
end)
UI.Select(open, true)
InterfaceOptions_AddCategory(entry)
