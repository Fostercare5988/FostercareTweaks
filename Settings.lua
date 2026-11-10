local FT = FostercareTweaks
if not FT then return end
local _, ns = ...
local UI = ns.UI

-- ForgeUI settings (VanillaForge templates/ForgeUI): six pages, shown in the
-- /ft window in two columns, or one at a time in AddOn Options in one column.
-- Every change saves at once; a feature that can only start or stop with a
-- fresh UI shows the Reload UI button instead.
--
-- What goes where: General (gameplay, minimap, chat, map), Frames (the player
-- and target frames, cast bars, marks), Auras (every buff and debuff list, one
-- heading per place on screen), Watched (the auras picked by name), Raid (the
-- party and raid frames), Bars (action bars).
local LEFT, RIGHT, SIDE, INDENT = 28, 264, 208, 16
local panel = UI.Window("FostercareTweaksSettingsGUI", "FostercareTweaks", 500, 480,
    GetAddOnMetadata("FostercareTweaks", "Version"))

local TABS = { "general", "unit", "auras", "watched", "raid", "bars" }
local TAB_LIST = {
    { label = "General", height = 590 },
    { label = "Frames", height = 440 },
    { label = "Auras", height = 620 },
    { label = "Watched", height = 300 },
    { label = "Raid", height = 480 },
    { label = "Bars", height = 620 },
}
local pages, ShowTab
local tab = 1
local book                              -- the pages in AddOn Options (ForgeLayout.lua)

-- Pages are built as sections of one or two columns (ForgeLayout.lua): side
-- by side in the window, one column in AddOn Options.
local L, R = UI.L, UI.R
local layout = UI.NewLayout()
local function Section(page, full) layout:Section(page, full) end
local function Add(page, column, item) return layout:Add(page, column, item) end

local syncs = {}
local reloadNeeded = false
local function Refresh()
    for _, sync in ipairs(syncs) do sync() end
    book:Place(tab)
end
local function Config() return FostercareTweaks_Config end
local function UF() return FT.UnitFrames end
local function ApplyUnitFrames() UF():ApplyConfiguration() end
local function RefreshRaid() UF():UpdateAllRaidFrames() end
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

-- Items --------------------------------------------------------------------------
local function Heading(page, column, text) layout:Heading(page, column, text) end
local function SwitchItem(page, column, widget, options) layout:Switch(page, column, widget, options) end
local function ButtonItem(page, column, button, options) layout:Button(page, column, button, options) end
local function SliderItem(page, column, slider, options) layout:Slider(page, column, slider, options) end
local MoveSlider = UI.MoveSlider

-- A switch for one module's own saved key; its default is the module's
-- (FT:register). after(value) applies the change live; without it the change
-- waits for a reload. needs() dims the switch.
local function Feature(page, title, text, tip, column, options, after, needs)
    local widget = UI.Switch("FTOpt_" .. string.gsub(title, "[^%w]", ""), page, text, tip, 0, 0, function(value)
        Config()[title] = value and 1 or 0
        if after then after(value) else NeedReload() end
        Refresh()
    end, column == L and 190 or 172)
    table.insert(syncs, function()
        UI.Sync(widget, FT.IsEnabled(title), (needs or Always)())
    end)
    SwitchItem(page, column, widget, options)
    return widget
end

-- after() for a module that starts and stops by itself (module:apply(on)).
local function Live(title)
    return function(value) FT.mods[title]:apply(value) end
end

-- A switch for one number in the overrides table (1 on, 0 off; FT.NUMBERS).
local function Option(page, key, text, tip, column, options, after, needs)
    local widget = UI.Switch("FTOpt_" .. key, page, text, tip, 0, 0, function(value)
        FT.SetOverride(key, value and 1 or 0); after(); Refresh()
    end, column == L and 190 or 172)
    table.insert(syncs, function()
        UI.Sync(widget, FT.GetNumber(key) ~= 0, (needs or Always)())
    end)
    SwitchItem(page, column, widget, options)
end

-- A slider for one number in the overrides table; its default and range are
-- the setting's own (FT.NUMBERS).
local function Slider(page, key, step, text, column, options, after, needs, format)
    local number = FT.NUMBERS[key]
    local slider = UI.Slider("FTOpt_" .. key, page, text, 0, 0, SIDE, number[2], number[3], step, function(value)
        FT.SetOverride(key, value); after(value)
    end, format or Pixels)
    table.insert(syncs, function()
        UI.SetSlider(slider, FT.GetNumber(key))
        Dim(slider, (needs or Always)())
    end)
    SliderItem(page, column, slider, options)
    return slider
end

local function Hint(page, column, text, options) return layout:Hint(page, column, text, options) end

-- Footer buttons: along the window's bottom, under the page in AddOn Options.
local function FooterButton(page, name, text, x, width, onClick, tip)
    local button = UI.Button(name, page, text, 0, 0, width, onClick)
    if tip then UI.Tooltip(button, tip) end
    return layout:Footer(page, button, x)
end

pages, ShowTab = UI.Tabs(panel, "FTOpt", TAB_LIST, function(index) tab = index; Refresh() end)
-- A page back from AddOn Options is hidden even when its tab is the active one.
panel:SetScript("OnShow", function() ShowTab(tab); pages[tab]:Show() end)

-- General ---------------------------------------------------------------------
local general = pages[1]
Heading(general, L, "Gameplay")
Feature(general, "Auto Stance", "Switch stance for spells",
    "A warrior or druid spell that needs another stance or form switches to the first one you can use.", L, nil,
    Live("Auto Stance"))
Feature(general, "Hide Stealth / Stance Bar", "Hide the stance bar", "Hide the stealth, stance and form buttons.",
    L, nil, Live("Hide Stealth / Stance Bar"))
Heading(general, L, "Minimap")
Feature(general, "MiniMap Clock", "Clock", "A 24-hour clock under the minimap.", L, nil, Live("MiniMap Clock"))
Feature(general, "MiniMap Square", "Square minimap", "A square minimap instead of a round one.", L)
Feature(general, "MiniMap Tweaks", "Tidy buttons, wheel zoom", "Hide extra minimap buttons and zoom with the mouse wheel.", L)
Slider(general, "minimap_scale", 0.05, "Minimap size", L, { before = 4 },
    function(value) FT.ApplyMinimapScale(value) end, nil, Times)
Hint(general, L, "Always on: sell prices, Shift to compare, quality borders, the Sell Junk button, copyable web links, "
    .. "and coordinates and class colors on the world map.")
Heading(general, R, "Chat")
Feature(general, "Chat Tweaks", "Wheel scroll, arrow keys",
    "Scroll with the mouse wheel (Shift: to the top or bottom) and repeat messages with the arrow keys.", R)
Feature(general, "Chat History", "Keep chat history", "Restore chat windows after a reload or login.", R)
Feature(general, "Chat Timestamps", "Timestamps", "The time before each new chat message. The combat log has none.",
    R, nil, Live("Chat Timestamps"))
Feature(general, "Chat Class Colors", "Class colors for names",
    "Player names in their class color, in new messages. To remember players between sessions, turn on the player cache in AddOn Options > ClassicAPI.",
    R, nil, Live("Chat Class Colors"))
Feature(general, "Blue Shaman Class Colors", "Blue shamans",
    "Shamans in blue instead of pink. Names already on screen change when they are drawn again.",
    R, nil, Live("Blue Shaman Class Colors"))
Heading(general, R, "World map")
Slider(general, "worldmap_scale", 0.05, "Map window size, Ctrl+wheel", R, nil,
    function() FT.ApplyWorldMapScale() end, nil, Times)
Heading(general, R, "Moving")
Hint(general, R, MOVE_HINT)

-- Frames ------------------------------------------------------------------------
local unit = pages[2]
local function Marks() FT:RefreshRaidMarks() end
local function Ticks() if FT.RefreshEnergyTick then FT.RefreshEnergyTick() end end
local function On(title) return function() return FT.IsEnabled(title) end end
Heading(unit, L, "Player and target")
Feature(unit, "Unit Frame Class Colors", "Class colors behind names", "Players' names on a bar in their class color.",
    L, nil, function() FT.mods["Unit Frame Class Colors"]:apply() end)
Heading(unit, L, "Cast bars")
Feature(unit, "Enemy Castbars", "Castbar under the target", "Your target's casts under the target frame; grey when you cannot interrupt them.",
    L, nil, function() FT.mods["Enemy Castbars"]:apply() end)
Feature(unit, "Borderless Castbars", "No castbar borders", "Remove the border art from your cast bar and the target's. Takes effect after a reload.", L)
Heading(unit, L, "Raid marks")
local outside = UI.Switch("FTOpt_raidmark_position", unit, "Beside the portrait",
    "The target's mark beside its frame instead of on the portrait.", 0, 0, function(value)
        FT.SetOverride("raidmark_position", value and "outside" or "portrait"); Marks(); Refresh()
    end, 190)
table.insert(syncs, function() UI.Sync(outside, FT.GetOverride("raidmark_position") == "outside") end)
SwitchItem(unit, L, outside)
Slider(unit, "raidmark_size", 1, "Mark size", L, { before = 4 }, Marks)
Hint(unit, L, "On the target and raid frames. Solo, the raid mark keys set marks only you see.")
Heading(unit, R, "Energy ticks")
Feature(unit, "Show Energy Ticks", "Energy and mana ticks",
    "Estimated energy ticks and the five-second mana rule on your power bar.", R, nil, ApplyUnitFrames)
local ticks = On("Show Energy Ticks")
Option(unit, "energytick_contrast", "Bright line", "A white center and glow on the tick line.", R, nil, Ticks, ticks)
Option(unit, "energytick_flash", "Flash on tick", "The bar's edge lights up at each tick.", R, nil, Ticks, ticks)
Slider(unit, "energytick_width", 1, "Line width", R, { before = 4 }, Ticks, ticks)
Hint(unit, R, "Buffs and debuffs under these frames: the Auras page.", { before = 14 })
Section(unit, true)
Hint(unit, L, MOVE_HINT, { before = 14 })
FooterButton(unit, "FTOpt_ResetPositions", "Reset all positions", LEFT, 172, function()
    Config().unitframe_positions = nil; NeedReload(); Refresh()
end, "Put every moved frame, aura area, the raid frames and the minimap pieces back in place. Takes effect after a reload.")

-- Auras -------------------------------------------------------------------------
-- Every list of buffs and debuffs, one heading per place on screen.
local auras = pages[3]
local function Raid() return UF():GetGroupDimensions().enabled end
local function StandardAuras()
    FT.ApplyStandardAuraSettings()
    UF().Auras:RefreshBorders()
end
local function AuraSize(kind)
    return function(value)
        local apply = UF().Auras["Apply" .. kind .. "Size"]
        for _, container in ipairs({ UF().blizzPlayerAuras, UF().blizzTargetAuras }) do
            if container then apply(UF().Auras, container, value) end
        end
        ApplyUnitFrames()
    end
end
Heading(auras, L, "Under the player frame")
Feature(auras, "Show Player Buffs", "Buffs", "Your buffs under the player frame, with sweeps and countdowns.", L, nil, ApplyUnitFrames)
Feature(auras, "Show Player Debuffs", "Debuffs", "Your debuffs under the player frame; dispel colors on the border.", L, nil, ApplyUnitFrames)
Heading(auras, L, "Under the target frame")
Feature(auras, "Show Target Buffs", "Buffs", "Your target's buffs under the target frame.", L, nil, ApplyUnitFrames)
Feature(auras, "Show Target Debuffs", "Debuffs", "Your target's debuffs under the target frame.", L, nil, ApplyUnitFrames)
Heading(auras, L, "Icon size under the frames")
Slider(auras, "uf_buff_size", 1, "Buffs", L, nil, AuraSize("Buff"))
Slider(auras, "uf_debuff_size", 1, "Debuffs", L, nil, AuraSize("Debuff"))
Heading(auras, R, "Top right of the screen")
Feature(auras, "Show Standard Buffs", "Buffs", "The game's own buff icons. Hold Ctrl+Shift to move them.", R, nil, StandardAuras)
Feature(auras, "Show Standard Debuffs", "Debuffs", "The game's own debuff icons.", R, nil, StandardAuras)
Feature(auras, "Show Weapon Enchants", "Weapon enchants", "Poisons, oils and other weapon enchants, in their own movable area.",
    R, nil, StandardAuras)
Heading(auras, R, "Borders, everywhere")
Feature(auras, "Show Buff Borders", "Buff borders", "A dark border around buffs in every list.", R, nil, StandardAuras)
Feature(auras, "Show Debuff Borders", "Debuff borders", "A dispel-colored border around debuffs in every list.", R, nil, StandardAuras)
Feature(auras, "Show Weapon Enchant Borders", "Enchant borders", "The weapon's quality color around its enchant.",
    R, nil, StandardAuras)
Hint(auras, R, "One aura with its own icon and timer: the Watched page.", { before = 14 })

Section(auras)
Heading(auras, L, "On raid members: buffs")
local raidBuffs = On("Show Raid Buffs")
Feature(auras, "Show Raid Buffs", "Buff icons", "Buffs inside each member; heals and your own first.", L, nil, RefreshRaid, Raid)
Feature(auras, "Show All Raid Buffs", "Every buff", "Show all buffs that fit; +N counts the rest.", L, { indent = INDENT }, RefreshRaid,
    function() return Raid() and raidBuffs() end)
Slider(auras, "raid_buff_count", 1, "Buffs per member", L, { before = 8 }, RefreshRaid,
    function() return Raid() and raidBuffs() and not FT.IsEnabled("Show All Raid Buffs") end, tostring)
Slider(auras, "raid_buff_size", 1, "Buff size", L, nil, RefreshRaid, Raid)
Heading(auras, R, "On raid members: debuffs")
Feature(auras, "Show Raid Debuff Badges", "Debuff icons", "Debuffs inside each member; dispellable ones first.", R, nil, RefreshRaid, Raid)
Slider(auras, "raid_debuff_count", 1, "Debuffs per member", R, { before = 8 }, RefreshRaid, Raid, tostring)
Slider(auras, "raid_debuff_size", 1, "Debuff size", R, nil, RefreshRaid, Raid)
Slider(auras, "raid_aura_spacing", 1, "Gap between icons", R, nil, RefreshRaid, Raid)
local function TestGrid(page, name)
    local button = FooterButton(page, name, "Test grid", LEFT, 120, function()
        UF():ToggleRaidTest(); Refresh()
    end, "Show 40 sample members to check size and position. Hold Ctrl+Shift to move them.")
    table.insert(syncs, function() UI.Select(button, UF():IsRaidTest()) end)
end
TestGrid(auras, "FTOpt_RaidTestAuras")

-- Watched -----------------------------------------------------------------------
-- Type a name and add it; the list is a grid of chips, and the
-- chosen one's card says where it shows.
local WA = FT.WatchedAuras
local CHIP_W, CHIP_H = 218, 24
local selected
local watch = pages[4]
Section(watch, true)
Heading(watch, L, "Watched auras")
Hint(watch, L, "A buff on you or a debuff on your target, picked by name: it gets its own icon with the time left, "
    .. "and leaves the lists on the Auras page. Click one to choose where it shows.")
local watchName = CreateFrame("EditBox", "FTOpt_WatchName", watch)
watchName:SetHeight(22)
watchName:SetAutoFocus(false)
watchName:SetFontObject(GameFontHighlightSmall)
watchName:SetTextInsets(10, 10, 0, 0)
UI.Rounded(watchName, "BACKGROUND", 11, UI.control)
UI.Tooltip(watchName, "A spell's name, or its ID.")
local function AddWatch(unit)
    local before = #WA.List()
    WA.Add(watchName:GetText(), unit)
    if #WA.List() > before then selected = #WA.List() end     -- open the new one's card
    watchName:SetText(""); watchName:ClearFocus(); Refresh()
end
watchName:SetScript("OnEscapePressed", function() watchName:ClearFocus() end)
watchName:SetScript("OnEnterPressed", function() AddWatch("player") end)
local addBuff = UI.Button("FTOpt_WatchBuff", watch, "Add your buff", 0, 0, 120, function() AddWatch("player") end)
local addDebuff = UI.Button("FTOpt_WatchDebuff", watch, "Add target debuff", 0, 0, 128, function() AddWatch("target") end)
-- One line in the window; narrower, the buttons share a line under the name.
Add(watch, L, { before = 8, place = function(x, y, width)
    local wide = width >= 440
    watchName:ClearAllPoints(); watchName:SetPoint("TOPLEFT", watch, "TOPLEFT", x, y)
    watchName:SetWidth(wide and 180 or width)
    local half = math.floor((width - 6) / 2)
    local line = wide and y or y - 28
    addBuff:ClearAllPoints(); addBuff:SetPoint("TOPLEFT", watch, "TOPLEFT", wide and x + 190 or x, line)
    addBuff:SetWidth(wide and 120 or half)
    addDebuff:ClearAllPoints(); addDebuff:SetPoint("TOPLEFT", watch, "TOPLEFT", wide and x + 316 or x + half + 6, line)
    addDebuff:SetWidth(wide and 128 or width - half - 6)
    return wide and 32 or 60
end })

local chips = {}
local function Chip(i)
    if chips[i] then return chips[i] end
    local chip = UI.Button("FTOpt_WatchChip" .. i, watch, "", 0, 0, CHIP_W, function()
        selected = selected ~= i and i or nil; Refresh()
    end, { ghost = true, height = CHIP_H })
    chip.icon = chip:CreateTexture(nil, "ARTWORK")
    chip.icon:SetWidth(18); chip.icon:SetHeight(18)
    chip.icon:SetPoint("LEFT", chip, "LEFT", 4, 0)
    chip.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local label = chip:GetFontString()
    label:ClearAllPoints()
    label:SetPoint("LEFT", chip, "LEFT", 28, 0); label:SetPoint("RIGHT", chip, "RIGHT", -52, 0)
    label:SetJustifyH("LEFT")
    chip.kind = chip:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    chip.kind:SetPoint("RIGHT", chip, "RIGHT", -10, 0)
    UI.Color(chip.kind, "hint")
    chips[i] = chip
    return chip
end
-- Two chips a row in the window, one in AddOn Options.
Add(watch, L, { place = function(x, y, width)
    local count = #WA.List()
    local columns = width >= 440 and 2 or 1
    local chipWidth = columns == 2 and CHIP_W or width
    for i = 1, count do
        local chip = chips[i]
        chip:SetWidth(chipWidth)
        chip:ClearAllPoints()
        chip:SetPoint("TOPLEFT", watch, "TOPLEFT", x + ((i - 1) % columns) * (width - chipWidth),
            y - math.floor((i - 1) / columns) * (CHIP_H + 4))
    end
    return math.ceil(count / columns) * (CHIP_H + 4)
end })

-- The chosen aura's card: where it shows, Only mine, Remove.
local card = UI.Row("FTOpt_WatchCard", watch, 0, 0, 444)
card.title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
card.title:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -9)
UI.Color(card.title, "heading")
local function Where(name, text, tip, place)
    return UI.Switch("FTOpt_Watch" .. name, card, text, tip, 0, 0, function(value)
        WA.SetShown(selected, place, value); Refresh()
    end, 100)
end
card.icon = Where("Icon", "Own icon", "Its own icon with the time left. Hold Ctrl+Shift to move it.", "icon")
card.top = Where("Top", "Top right", "Also in Blizzard's buffs at the top right of the screen.", "topRight")
card.row = Where("Row", "Player row", "Also in the row under the player or target frame.", "inRow")
card.cool = Where("Cooldown", "Cooldown", "When it ends, the icon stays greyed with its spell's cooldown until it is ready.", "cooldown")
card.mine = UI.Switch("FTOpt_WatchMine", card, "Only mine", "Only the debuff you cast; off shows anyone's.",
    0, 0, function(value) WA.SetMine(selected, value); Refresh() end, 100)
card.remove = UI.Button("FTOpt_WatchRemove", card, "Remove", 0, 0, 78, function()
    WA.Remove(selected); selected = nil; Refresh()
end, { ghost = true })
-- Its switches three to a line in the window, two in AddOn Options; Remove at
-- the end of the last line, or on its own.
Add(watch, L, { place = function(x, y, width)
    if not card:IsShown() then return 0 end
    card:ClearAllPoints(); card:SetPoint("TOPLEFT", watch, "TOPLEFT", x, y - 4)
    card:SetWidth(width)
    local perLine, n = width >= 440 and 3 or 2, 0
    for _, switch in ipairs({ card.icon, card.top, card.row, card.cool, card.mine }) do
        if switch:IsShown() then
            switch:ClearAllPoints()
            switch:SetPoint("TOPLEFT", card, "TOPLEFT", 10 + (n % perLine) * 140, -34 - math.floor(n / perLine) * 28)
            n = n + 1
        end
    end
    local lines = math.ceil(n / perLine)
    if n % perLine == 0 then lines = lines + 1 end
    card.remove:ClearAllPoints()
    card.remove:SetPoint("TOPLEFT", card, "TOPLEFT", width - 88, -32 - (lines - 1) * 28)
    card:SetHeight(36 + lines * 28)
    return 40 + lines * 28
end })

table.insert(syncs, function()
    local list = WA.List()
    if selected and not list[selected] then selected = nil end
    for i, entry in ipairs(list) do
        local chip = Chip(i)
        chip:SetText(entry.name)
        local _, _, spellIcon = GetSpellInfo(entry.spellId or entry.name)
        chip.icon:SetTexture(entry.icon or spellIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
        chip.kind:SetText(entry.unit == "player" and "buff" or "debuff")
        UI.Select(chip, i == selected)
        chip:Show()
    end
    for i = #list + 1, #chips do chips[i]:Hide() end
    local entry = list[selected]
    if entry then
        card.title:SetText(entry.name .. (entry.unit == "player" and "  -  your buff" or "  -  target debuff"))
        UI.Sync(card.icon, not entry.noIcon)
        if entry.unit == "player" then
            card.top:Show(); UI.Sync(card.top, entry.topRight)
            card.cool:Show(); UI.Sync(card.cool, not entry.noCooldown)
        else
            card.top:Hide(); card.cool:Hide()
        end
        card.row.label:SetText(entry.unit == "player" and "Player row" or "Target row")
        UI.Sync(card.row, entry.inRow)
        if entry.unit == "target" then card.mine:Show(); UI.Sync(card.mine, entry.mine) else card.mine:Hide() end
        card:Show()
    else
        card:Hide()
    end
end)

-- Raid --------------------------------------------------------------------------
-- The frames themselves; the icons on their members are on the Auras page.
local raid = pages[5]
local function Dimension(index)
    return function(value)
        local args = {}
        args[index] = value
        UF():ApplyGroupDimensions(args[1], args[2], args[3], args[4], args[5])
    end
end
local function GroupSlider(key, index, minimum, maximum, step, text, format)
    local slider = UI.Slider("FTOpt_raid_" .. key, raid, text, 0, 0, SIDE, minimum, maximum, step, Dimension(index), format or Pixels)
    table.insert(syncs, function()
        UI.SetSlider(slider, UF():GetGroupDimensions()[key]); Dim(slider, Raid())
    end)
    SliderItem(raid, R, slider)
end
Heading(raid, L, "Party and raid frames")
local useRaid = UI.Switch("FTOpt_RaidFrames", raid, "Use these frames", "Replace the party frames and the game's raid frames.",
    0, 0, function(value) UF():ApplyGroupDimensions(nil, nil, nil, nil, nil, value); Refresh() end)
table.insert(syncs, function() UI.Sync(useRaid, Raid()) end)
SwitchItem(raid, L, useRaid)
Feature(raid, "Show Group Labels", "Group labels", "G1 to G8 above the groups.", L, { indent = INDENT }, RefreshRaid, Raid)
Heading(raid, L, "Health text")
local FORMATS = { "deficit", "percent", "current" }
local formatButtons, SelectFormat, formatTrack = UI.Segmented("FTOpt_RaidHealth", raid, { "Missing", "Percent", "Current" },
    0, 0, SIDE, function(index)
        FT.SetOverride("raid_health_format", FORMATS[index]); RefreshRaid(); Refresh()
    end, { height = 24 })
Add(raid, L, { height = 28, regions = { { formatTrack, "TOPLEFT", "TOPLEFT", 0, 0 } } })
table.insert(syncs, function()
    local chosen = 1
    for i, value in ipairs(FORMATS) do if value == UF():GetRaidHealthFormat() then chosen = i end end
    SelectFormat(chosen)
    formatTrack:SetAlpha(Raid() and 1 or 0.4)
    for _, button in ipairs(formatButtons) do if Raid() then button:Enable() else button:Disable() end end
end)
Heading(raid, L, "Corner marks")
Feature(raid, "Show Raid Aggro Indicator", "Aggro corner", "A red corner on the member your enemy target is attacking.",
    L, nil, RefreshRaid, Raid)
Feature(raid, "Show Raid HoT Indicator", "Heal-over-time corner", "Renew, Rejuvenation, Regrowth, shields and Blessing of Protection.",
    L, nil, RefreshRaid, Raid)
Hint(raid, L, "Buff and debuff icons on members: the Auras page.", { before = 14 })
Heading(raid, R, "Size")
GroupSlider("width", 1, 40, 120, 1, "Width")
GroupSlider("height", 2, 20, 60, 1, "Height")
GroupSlider("scale", 3, 0.5, 2, 0.05, "Scale", Times)
GroupSlider("spacingX", 4, 0, 20, 1, "Gap between groups")
GroupSlider("spacingY", 5, 0, 20, 1, "Gap between members")
TestGrid(raid, "FTOpt_RaidTest")
-- Clearing a saved value brings its default back (FT.NUMBERS, FT:register, raid.lua).
FooterButton(raid, "FTOpt_RaidReset", "Reset raid settings", LEFT + 128, 140, function()
    for _, key in ipairs({ "raid_health_format", "raid_buff_count", "raid_buff_size", "raid_debuff_count",
        "raid_debuff_size", "raid_aura_spacing" }) do FT.SetOverride(key, nil) end
    for _, title in ipairs({ "Show Group Labels", "Show Raid Aggro Indicator", "Show Raid HoT Indicator",
        "Show Raid Debuff Badges", "Show Raid Buffs", "Show All Raid Buffs" }) do
        Config()[title] = FT.mods[title].enabled and 1 or 0
    end
    Config().groupframe_dimensions = nil
    UF():ApplyGroupDimensions(nil, nil, nil, nil, nil, true)
    RefreshRaid(); Refresh()
end, "Defaults for the raid frames and the icons on their members. The frames stay where you put them.")

-- Action Bars -------------------------------------------------------------------
-- One row per bar: its own Show switch and size, and "More" for the rest of its
-- settings under the row. Changing a bar turns custom layouts on; they keep
-- every bar where it stands.
local bars = pages[6]
local AB = FT.ActionBars
Heading(bars, L, "Look")
Feature(bars, "Hide Gryphons", "Hide gryphons", "Remove the gryphons at both ends of the bar.", L, nil,
    Live("Hide Gryphons"))
Feature(bars, "Floating Actionbar", "No bar background", "Remove the bar's background art.", L)
Feature(bars, "Reduced Actionbar Size", "Short main bar", "A shorter main bar without the bag and game menu buttons.", L)
Feature(bars, "Reagent Counter", "Reagent counts", "How many casts your reagents allow, on the button.", R, { before = 20 },
    Live("Reagent Counter"))
Section(bars)
Heading(bars, L, "Bars")
local layouts = UI.Switch("FTOpt_Layouts", bars, "Custom layouts", "Off puts every bar back in the game's layout.",
    0, 0, function(value) AB:SetEnabled(value); Refresh() end)
SwitchItem(bars, L, layouts)
local move = UI.Button("FTOpt_MoveBars", bars, "Move bars", 0, 0, 172, function()
    AB:SetEditing(not AB.editing); Refresh()
end)
UI.Tooltip(move, "Show a handle on each bar to drag it. Click again, or close this window, to lock them. Not in combat.")
ButtonItem(bars, R, move, { before = { 32, 4 }, indent = 36 })
table.insert(syncs, function()
    UI.Sync(layouts, AB.enabled)
    UI.SetEnabled(move, AB.enabled)
    UI.Select(move, AB.editing)
end)

local ROW_STEP = 28
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
    local row = UI.Row("FTOpt_BarRow_" .. def.id, bars, 0, 0, 444)
    row.definition = def
    row.show = UI.Switch("FTOpt_BarShow_" .. def.id, row, NAMES[def.id] or ("Extra " .. def.extraIndex),
        NOTES[def.id] or (def.custom and CUSTOM or "Keeps its own actions and key bindings."), 6, -3,
        function(value) SetBar(def.id, "visible", value); Refresh() end, 100)
    row.size = UI.Slider("FTOpt_BarSize_" .. def.id, row, "", 0, 0, 140, 0.5, 2, 0.05,
        function(value) SetBar(def.id, "scale", value) end, Percent)
    row.size.valueText:SetJustifyH("LEFT")
    UI.Tooltip(row.size, "Size")
    row.more = UI.Button("FTOpt_BarMore_" .. def.id, row, "More", 0, 0, 56, function()
        if open == def.id then open = nil else open = def.id end
        Refresh()
    end, { ghost = true })
    rows[index] = row
end

-- The open bar's other settings, drawn under its row.
local details = CreateFrame("Frame", "FTOpt_BarDetails", bars)
local function Detail(key) return function(value) SetBar(open, key, value); Refresh() end end
local columns = UI.Slider("FTOpt_Bar_columns", details, "Buttons per row", 0, 0, 192, 1, 12, 1, Detail("columns"), tostring)
local spacing = UI.Slider("FTOpt_Bar_spacing", details, "Spacing", 0, 0, 192, 0, 20, 1, Detail("spacing"), Pixels)
local empty = UI.Switch("FTOpt_Bar_showEmpty", details, "Show empty buttons", nil, 0, 0, Detail("showEmpty"), 172)
local growUp = UI.Switch("FTOpt_Bar_growUp", details, "Fill bottom to top", nil, 0, 0, Detail("growUp"), 172)
local resetBar = UI.Button("FTOpt_BarReset", details, "Reset this bar", 0, 0, 172, function()
    AB:ResetBar(open); Refresh()
end)
UI.Tooltip(resetBar, "Its place, size and shape go back to the default. Its actions stay.")
-- Sliders left and the rest right in the window; one under the other narrower.
local function PlaceDetails(width)
    local wide = width >= 440
    local sliderWidth = wide and 192 or width - 32
    MoveSlider(columns, details, 16, -4, sliderWidth)
    MoveSlider(spacing, details, 16, -46, sliderWidth)
    local x, y = wide and 236 or 16, wide and -4 or -88
    empty:ClearAllPoints(); empty:SetPoint("TOPLEFT", details, "TOPLEFT", x, y - 2)
    growUp:ClearAllPoints(); growUp:SetPoint("TOPLEFT", details, "TOPLEFT", x, y - 28)
    resetBar:ClearAllPoints(); resetBar:SetPoint("TOPLEFT", details, "TOPLEFT", x, y - 56)
    local height = wide and 92 or 174
    details:SetHeight(height)
    return height + 8
end
Section(bars, true)
Add(bars, L, { before = 8, place = function(x, y, width)
    local top = y
    local sliderX = width >= 440 and 190 or 124
    local sliderWidth = width - sliderX - 112
    for _, row in ipairs(rows) do
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", bars, "TOPLEFT", x, y)
        row:SetWidth(width)
        row.size:ClearAllPoints(); row.size:SetPoint("LEFT", row, "LEFT", sliderX, 0)
        row.size:SetWidth(sliderWidth)
        row.size.valueText:ClearAllPoints(); row.size.valueText:SetPoint("LEFT", row.size, "LEFT", sliderWidth + 8, 0)
        row.more:ClearAllPoints(); row.more:SetPoint("TOPLEFT", row, "TOPLEFT", width - 60, -2)
        y = y - ROW_STEP
        if open == row.definition.id then
            details:ClearAllPoints(); details:SetPoint("TOPLEFT", bars, "TOPLEFT", x, y)
            details:SetWidth(width)
            y = y - PlaceDetails(width)
        end
    end
    return top - y
end })

table.insert(syncs, function()
    for _, row in ipairs(rows) do
        local def = row.definition
        local main = def.id == "main"
        UI.Sync(row.show, main or BarValue(def.id, "visible", NativeShown(def)), not main)
        UI.SetSlider(row.size, FT.ClampNumber(BarValue(def.id, "scale"), 1, 0.5, 2))
        UI.Select(row.more, open == def.id)
        if open == def.id then
            UI.SetSlider(columns, FT.ClampNumber(BarValue(def.id, "columns"), def.columns, 1, 12))
            UI.SetSlider(spacing, FT.ClampNumber(BarValue(def.id, "spacing"), 6, 0, 20))
            UI.Sync(empty, BarValue(def.id, "showEmpty", def.extraIndex ~= nil))
            UI.Sync(growUp, BarValue(def.id, "growUp", false))
        end
    end
    if open then details:Show() else details:Hide() end
end)

-- One Reload UI button on every page while a change waits for it; last in line.
for index, page in ipairs(pages) do
    local reload = FooterButton(page, "FTOptReload" .. index, "Reload UI", RIGHT + 36, 172, function() ReloadUI() end,
        "Some changes start or stop only with a fresh interface.")
    reload:Hide()
    table.insert(syncs, function() if reloadNeeded then reload:Show() else reload:Hide() end end)
end

-- Handles block the buttons under them; lock them with the window and in combat.
FT.HookScript(panel, "OnHide", function() AB:SetEditing(false) end)
panel:RegisterEvent("PLAYER_REGEN_DISABLED")

-- Game Menu > AddOn Options > FostercareTweaks (ClassicAPI): the same six pages,
-- one category each, in one column (ForgeLayout.lua).
book = UI.Book({
    name = "FostercareTweaks", text = "Open a page under FostercareTweaks, or type /ft for the settings window.",
    open = function() FT.OpenSettings("general") end,
    panel = panel, pages = pages, tabs = TAB_LIST, layout = layout, refresh = Refresh,
    select = function(index) tab = index end,
    hide = function() AB:SetEditing(false) end,
})
FT.SetEventHandler(panel, function() if book:Shown() then Refresh() end end)

-- Opening ------------------------------------------------------------------------
-- FT.OpenSettings() toggles the window; a page name opens that page.
function FT.OpenSettings(name)
    for index, key in ipairs(TABS) do if key == name then tab = index end end
    if name or not panel:IsShown() then
        if InterfaceOptionsFrame:IsShown() then InterfaceOptionsFrame:Hide() end
        panel:Show(); ShowTab(tab)
    else
        panel:Hide()
    end
end
