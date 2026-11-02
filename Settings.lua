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
local MOVE_HINT = "Hold Ctrl+Shift to move frames, aura areas, the raid frames and minimap pieces. Action bars: Move bars."

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
-- The Action Bars page sets its own height as bar settings open and close.
local TAB_LIST = {
    { label = "General", height = 590 },
    { label = "Unit Frames", height = 440 },
    { label = "Auras", height = 470 },
    { label = "Raid", height = 590 },
    { label = "Action Bars", height = 620 },
}
local pages, ShowTab = UI.Tabs(panel, "FTOpt", TAB_LIST, function(index) tab = index; Refresh() end)
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
Feature(general, "Auto Dismount", "Dismount to attack, fly, talk",
    "Dismount or leave your form when you attack, take a flight, talk to an NPC or use an item.", LEFT, -118)
Feature(general, "Auto Stance", "Switch stance for spells",
    "A warrior or druid spell that needs another stance or form switches to the first one you can use.", LEFT, -144)
Feature(general, "Hide Stealth / Stance Bar", "Hide the stance bar", "Hide the stealth, stance and form buttons.",
    LEFT, -170, function(value) FT.mods["Hide Stealth / Stance Bar"]:apply(value) end)
UI.Heading(general, "Minimap", LEFT, -210)
Feature(general, "MiniMap Clock", "Clock", "A 24-hour clock under the minimap.", LEFT, -230)
Feature(general, "MiniMap Square", "Square minimap", "A square minimap instead of a round one.", LEFT, -256)
Feature(general, "MiniMap Tweaks", "Tidy buttons, wheel zoom", "Hide extra minimap buttons and zoom with the mouse wheel.", LEFT, -282)
Slider(general, "minimap_scale", 1, 0.7, 1.6, 0.05, "Minimap size", LEFT, -312,
    function(value) FT.ApplyMinimapScale(value) end, nil, Times)
Hint(general, "Always on: sell prices, Shift to compare, quality borders, the Sell Junk button, copyable web links, "
    .. "and coordinates and class colors on the world map.", LEFT, -366)
UI.Heading(general, "Chat", RIGHT, -98)
Feature(general, "Chat Tweaks", "Wheel scroll, sticky channels",
    "Scroll with the mouse wheel, keep the last channel, repeat messages with the arrow keys.", RIGHT, -118)
Feature(general, "Chat History", "Keep chat history", "Restore chat windows after a reload or login.", RIGHT, -144)
Feature(general, "Chat Timestamps", "Timestamps", "The time before each chat message. The combat log has none.", RIGHT, -170)
Feature(general, "Chat Class Colors", "Class colors for names",
    "Player names in their class color. To remember players between sessions, turn on the player cache in AddOn Options > ClassicAPI.", RIGHT, -196)
Feature(general, "Blue Shaman Class Colors", "Blue shamans", "Shamans in blue instead of pink.", RIGHT, -222)
UI.Heading(general, "World map", RIGHT, -262)
Slider(general, "worldmap_scale", 1, 0.6, 2, 0.05, "Map window size, Ctrl+wheel", RIGHT, -282,
    function() FT.ApplyWorldMapScale() end, nil, Times)
UI.Heading(general, "Moving", RIGHT, -342)
Hint(general, MOVE_HINT, RIGHT, -362)
UI.Heading(general, "Layouts by zone", LEFT, -428)
Feature(general, "Zone Layouts", "Own layout per zone",
    "The world, battlegrounds, and dungeons and raids each keep their own frame positions, raid frames, aura sizes, "
    .. "raid marks, minimap size and action bars. The layout changes after the loading screen.",
    LEFT, -448, function(value) if value then FT.SwitchLayout(FT.ZoneLayout()) end end)
local layoutNow = Hint(general, "", LEFT, -474, 444)
local copyLayout = UI.Button("FTOpt_CopyLayout", general, "Use this layout everywhere", RIGHT + 36, -446, 172, function()
    FT.CopyLayoutToAll(); Refresh()
end)
UI.Tooltip(copyLayout, "The other two layouts become copies of this one.")
table.insert(syncs, function()
    local on = FT.IsEnabled("Zone Layouts")
    layoutNow:SetText(on and ("Now: " .. FT.LAYOUT_NAMES[Config().profile or FT.ZoneLayout()] .. ".")
        or "One layout everywhere.")
    UI.SetEnabled(copyLayout, on)
end)
Hint(general, "For spells, dismounting, leaving forms and standing up are ClassicAPI settings: AddOn Options > ClassicAPI.",
    LEFT, -502, 444)

-- Unit Frames -------------------------------------------------------------------
local unit = pages[2]
local function Marks() FT:RefreshRaidMarks() end
local function Ticks() if FT.RefreshEnergyTick then FT.RefreshEnergyTick() end end
local function On(title, default) return function() return FT.IsEnabled(title, default) end end
UI.Heading(unit, "Player and target", LEFT, -98)
Feature(unit, "Unit Frame Class Colors", "Class colors behind names", "Players' names on a bar in their class color.",
    LEFT, -118, function() FT.mods["Unit Frame Class Colors"]:apply() end)
UI.Heading(unit, "Target castbar", LEFT, -158)
Feature(unit, "Enemy Castbars", "Castbar under the target", "Your target's casts under the target frame; grey when you cannot interrupt them.",
    LEFT, -178, function() FT.mods["Enemy Castbars"]:apply() end)
UI.Heading(unit, "Raid marks", LEFT, -218)
local outside = UI.Switch("FTOpt_raidmark_position", unit, "Beside the portrait",
    "The target's mark beside its frame instead of on the portrait.", LEFT, -238, function(value)
        FT.SetOverride("raidmark_position", value and "outside" or "portrait"); Marks(); Refresh()
    end, 190)
table.insert(syncs, function() UI.Sync(outside, FT.GetOverride("raidmark_position") == "outside") end)
Slider(unit, "raidmark_size", 22, 12, 36, 1, "Mark size", LEFT, -268, Marks)
Hint(unit, "On the target and raid frames. Solo, the raid mark keys set marks only you see.", LEFT, -320)
Hint(unit, MOVE_HINT, LEFT, -360, 444)
UI.Heading(unit, "Energy ticks", RIGHT, -98)
Feature(unit, "Show Energy Ticks", "Energy and mana ticks",
    "Estimated energy ticks and the five-second mana rule on your power bar.", RIGHT, -118, ApplyUnitFrames)
local ticks = On("Show Energy Ticks", true)
Option(unit, "energytick_contrast", 1, "Bright line", "A white center and glow on the tick line.", RIGHT, -144, Ticks, ticks)
Option(unit, "energytick_flash", 1, "Flash on tick", "The bar's edge lights up at each tick.", RIGHT, -170, Ticks, ticks)
Slider(unit, "energytick_width", 3, 2, 6, 1, "Line width", RIGHT, -200, Ticks, ticks)
UI.Heading(unit, "Castbars", RIGHT, -244)
Feature(unit, "Borderless Castbars", "No castbar borders", "Remove the border art from your cast bar and the target's. Takes effect after a reload.", RIGHT, -264)
FooterButton(unit, "FTOpt_ResetPositions", "Reset all positions", LEFT, 172, function()
    Config().unitframe_positions = nil; NeedReload(); Refresh()
end, "Put every moved frame, aura area, the raid frames and the minimap pieces back in place. Takes effect after a reload.")

-- Auras -------------------------------------------------------------------------
local auras = pages[3]
local function StandardAuras()
    if FT.ApplyStandardAuraSettings then FT.ApplyStandardAuraSettings() end
    if UF() and UF().Auras then UF().Auras:RefreshBorders() end
end
UI.Heading(auras, "Player and target", LEFT, -98)
Feature(auras, "Show Player Buffs", "Player buffs", "Under the player frame, with sweeps and countdowns.", LEFT, -118, ApplyUnitFrames)
Feature(auras, "Show Player Debuffs", "Player debuffs", "Under the player frame; dispel colors on the border.", LEFT, -144, ApplyUnitFrames)
Feature(auras, "Show Target Buffs", "Target buffs", "Under the target frame.", LEFT, -170, ApplyUnitFrames)
Feature(auras, "Show Target Debuffs", "Target debuffs", "Under the target frame.", LEFT, -196, ApplyUnitFrames)
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

-- Watched auras: type a name, pick where it shows; one row per aura.
local WA = FT.WatchedAuras
UI.Heading(auras, "Watched auras", LEFT, -352)
Hint(auras, "Each its own icon with the time left, while the aura is up. Hold Ctrl+Shift to move them.", LEFT, -372, 444)
local watchName = CreateFrame("EditBox", "FTOpt_WatchName", auras)
watchName:SetWidth(180); watchName:SetHeight(22)
watchName:SetPoint("TOPLEFT", auras, "TOPLEFT", LEFT, -398)
watchName:SetAutoFocus(false)
watchName:SetFontObject(GameFontHighlightSmall)
watchName:SetTextInsets(10, 10, 0, 0)
UI.Rounded(watchName, "BACKGROUND", 11, UI.control)
UI.Tooltip(watchName, "A spell's name, or its ID.")
local function AddWatch(unit)
    WA.Add(watchName:GetText(), unit)
    watchName:SetText(""); watchName:ClearFocus(); Refresh()
end
watchName:SetScript("OnEscapePressed", function() watchName:ClearFocus() end)
watchName:SetScript("OnEnterPressed", function() AddWatch("player") end)
UI.Button("FTOpt_WatchBuff", auras, "Add your buff", LEFT + 190, -398, 120, function() AddWatch("player") end)
UI.Button("FTOpt_WatchDebuff", auras, "Add target debuff", LEFT + 316, -398, 128, function() AddWatch("target") end)
local watchRows = {}
local function WatchRow(i)
    if watchRows[i] then return watchRows[i] end
    local row = UI.Row("FTOpt_WatchRow" .. i, auras, LEFT, -430 - (i - 1) * 28, 444)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row, "LEFT", 8, 0)
    UI.Color(row.name, "text")
    row.kind = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.kind:SetPoint("LEFT", row, "LEFT", 150, 0)
    UI.Color(row.kind, "hint")
    row.mine = UI.Switch("FTOpt_WatchMine" .. i, row, "Only mine", "Only the debuff you cast; off shows anyone's.",
        250, -3, function(value) WA.SetMine(i, value) end, 90)
    row.remove = UI.Button("FTOpt_WatchRemove" .. i, row, "Remove", 370, -2, 70, function()
        WA.Remove(i); Refresh()
    end, { ghost = true })
    watchRows[i] = row
    return row
end
table.insert(syncs, function()
    local list = WA.List()
    for i, entry in ipairs(list) do
        local row = WatchRow(i)
        row.name:SetText(entry.name)
        row.kind:SetText(entry.unit == "player" and "Your buff" or "Target debuff")
        if entry.unit == "target" then row.mine:Show(); UI.Sync(row.mine, entry.mine) else row.mine:Hide() end
        row:Show()
    end
    for i = #list + 1, #watchRows do watchRows[i]:Hide() end
    TAB_LIST[3].height = 470 + #list * 28
    if tab == 3 then panel:SetHeight(TAB_LIST[3].height) end
end)

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
-- One row per bar: its own Show switch and size, and "More" for the rest of its
-- settings under the row. Changing a bar turns custom layouts on; they keep
-- every bar where it stands.
local bars = pages[5]
local AB = FT.ActionBars
UI.Heading(bars, "Look", LEFT, -98)
Feature(bars, "Hide Gryphons", "Hide gryphons", "Remove the gryphons at both ends of the bar.", LEFT, -118)
Feature(bars, "Floating Actionbar", "No bar background", "Remove the bar's background art.", LEFT, -144)
Feature(bars, "Reduced Actionbar Size", "Short main bar", "A shorter main bar without the bag and game menu buttons.", LEFT, -170)
Feature(bars, "Center Vertical Actionbar", "Center the right bars", "Center the right-side bars vertically.", RIGHT, -118)
Feature(bars, "Reagent Counter", "Reagent counts", "How many casts your reagents allow, on the button.", RIGHT, -144)
UI.Heading(bars, "Bars", LEFT, -210)
local layouts = UI.Switch("FTOpt_Layouts", bars, "Custom layouts", "Off puts every bar back in the game's layout.",
    LEFT, -230, function(value) AB:SetEnabled(value); Refresh() end)
local move = UI.Button("FTOpt_MoveBars", bars, "Move bars", RIGHT + 36, -228, 172, function()
    AB:SetEditing(not AB.editing); Refresh()
end)
UI.Tooltip(move, "Show a handle on each bar to drag it. Click again, or close this window, to lock them. Not in combat.")
table.insert(syncs, function()
    UI.Sync(layouts, AB.enabled)
    UI.SetEnabled(move, AB.enabled)
    UI.Select(move, AB.editing)
end)

local ROW_TOP, ROW_STEP, DETAILS = -266, 28, 100
local NAMES = { main = "Main", bottomleft = "Bottom left", bottomright = "Bottom right", right = "Right", left = "Left" }
local NOTES = {
    main = "The main bar and the stealth or stance bar share this layout. It is always shown.",
    extra = "Shows action page 2 (slots 13 to 24). Bind keys in Key Bindings.",
}
local CUSTOM = "Drop spells or items on its buttons; Shift-right-click clears one. Bind keys in Key Bindings."
local open                                  -- the bar whose settings are open
local function Percent(v) return math.floor(v * 100 + 0.5) .. "%" end
local function BarValue(id, key, fallback)
    local value = AB:GetSettings(id)[key]
    if value == nil then return fallback end
    return value
end
local function NativeShown(definition)
    local bar, frame = AB.bars[definition.id], _G[definition.prefix]
    return (bar and bar.nativeVisible) or (frame and frame:IsShown()) or false
end
local function SetBar(id, key, value)
    if not AB.enabled then AB:SetEnabled(true) end
    if AB.enabled then AB:SetValue(id, key, value) end
end
local rows = {}
for index, definition in ipairs(AB.definitions) do
    local def = definition
    local row = UI.Row("FTOpt_BarRow_" .. def.id, bars, LEFT, ROW_TOP - (index - 1) * ROW_STEP, 444)
    row.definition = def
    row.show = UI.Switch("FTOpt_BarShow_" .. def.id, row, NAMES[def.id] or ("Extra " .. def.extraIndex),
        NOTES[def.id] or (def.custom and CUSTOM or "Keeps its own actions and key bindings."), 6, -3,
        function(value) SetBar(def.id, "visible", value); Refresh() end, 150)
    row.size = UI.Slider("FTOpt_BarSize_" .. def.id, row, "", 190, 0, 140, 0.5, 2, 0.05,
        function(value) SetBar(def.id, "scale", value) end, Percent)
    row.size:ClearAllPoints(); row.size:SetPoint("LEFT", row, "LEFT", 190, 0)
    row.size.valueText:ClearAllPoints(); row.size.valueText:SetPoint("LEFT", row.size, "LEFT", 148, 0)
    row.size.valueText:SetJustifyH("LEFT")
    UI.Tooltip(row.size, "Size")
    row.more = UI.Button("FTOpt_BarMore_" .. def.id, row, "More", 384, -2, 56, function()
        if open == def.id then open = nil else open = def.id end
        Refresh()
    end, { ghost = true })
    rows[index] = row
end

-- The open bar's other settings, drawn under its row.
local details = CreateFrame("Frame", "FTOpt_BarDetails", bars)
details:SetWidth(444); details:SetHeight(DETAILS - 8)
local function Detail(key) return function(value) SetBar(open, key, value); Refresh() end end
local columns = UI.Slider("FTOpt_Bar_columns", details, "Buttons per row", 16, -4, 192, 1, 12, 1, Detail("columns"), tostring)
local spacing = UI.Slider("FTOpt_Bar_spacing", details, "Spacing", 16, -46, 192, 0, 20, 1, Detail("spacing"), Pixels)
local empty = UI.Switch("FTOpt_Bar_showEmpty", details, "Show empty buttons", nil, 236, -4, Detail("showEmpty"), 172)
local growUp = UI.Switch("FTOpt_Bar_growUp", details, "Fill bottom to top", nil, 236, -30, Detail("growUp"), 172)
local resetBar = UI.Button("FTOpt_BarReset", details, "Reset this bar", 236, -60, 172, function()
    AB:ResetBar(open); Refresh()
end)
UI.Tooltip(resetBar, "Its place, size and shape go back to the default. Its actions stay.")

table.insert(syncs, function()
    local y = ROW_TOP
    for _, row in ipairs(rows) do
        local def = row.definition
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", bars, "TOPLEFT", LEFT, y)
        local main = def.id == "main"
        UI.Sync(row.show, main or BarValue(def.id, "visible", NativeShown(def)), not main)
        UI.SetSlider(row.size, FT.ClampNumber(BarValue(def.id, "scale"), 1, 0.5, 2))
        UI.Select(row.more, open == def.id)
        y = y - ROW_STEP
        if open == def.id then
            details:ClearAllPoints(); details:SetPoint("TOPLEFT", bars, "TOPLEFT", LEFT, y)
            UI.SetSlider(columns, FT.ClampNumber(BarValue(def.id, "columns"), def.columns, 1, 12))
            UI.SetSlider(spacing, FT.ClampNumber(BarValue(def.id, "spacing"), 6, 0, 20))
            UI.Sync(empty, BarValue(def.id, "showEmpty", def.extraIndex ~= nil))
            UI.Sync(growUp, BarValue(def.id, "growUp", false))
            y = y - DETAILS
        end
    end
    if open then details:Show() else details:Hide() end
    TAB_LIST[5].height = 46 - y
    if tab == 5 then panel:SetHeight(TAB_LIST[5].height) end
end)

-- Handles block the buttons under them; lock them with the window and in combat.
FT.HookScript(panel, "OnHide", function() AB:SetEditing(false) end)
panel:RegisterEvent("PLAYER_REGEN_DISABLED")
FT.SetEventHandler(panel, function() if panel:IsShown() then Refresh() end end)

-- Opening ------------------------------------------------------------------------
-- A layout change elsewhere shows in the open window.
function FT.RefreshSettings() if panel:IsShown() then Refresh() end end

-- FT.OpenSettings() toggles the window; a page name opens that page.
function FT.OpenSettings(name)
    for index, key in ipairs(TABS) do if key == name then tab = index end end
    if name or not panel:IsShown() then
        panel:Show(); ShowTab(tab)
    else
        panel:Hide()
    end
end

-- Game Menu > AddOn Options > FostercareTweaks (ClassicAPI).
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
