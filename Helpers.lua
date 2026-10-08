-- FostercareTweaks: Helpers.lua
-- Shared timers, frame traversal, metadata and nameplate ownership

local FT = FostercareTweaks
if not FT then return end

-- Traverse frame returns without constructing a temporary region array.
local function RegionWalk(idx, callback, arg1, arg2, arg3, r, ...)
    if not r then return end
    callback(r, idx, arg1, arg2, arg3)
    return RegionWalk(idx + 1, callback, arg1, arg2, arg3, ...)
end

FT.ForEachRegion = function(frame, callback, arg1, arg2, arg3)
    if frame and frame.GetRegions and callback then
        RegionWalk(1, callback, arg1, arg2, arg3, frame:GetRegions())
    end
end

-- Required ClassicAPI posthooks preserve native return values and ownership.
FT.hooksecurefunc = hooksecurefunc

-- ClassicAPI HookScript invokes the previous script without positional args.
-- Preserve modern owners too: forward the original call to them, and normalize
-- only our posthook. Native FrameXML still receives its original globals.
FT.HookScript = function(frame, script, func)
    if not frame or not func then return end
    local previous = frame:GetScript(script)
    frame:SetScript(script, function(...)
        if previous then previous(...) end
        if script == "OnEvent" then
            return func(frame, FT.EventArgs(...))
        elseif select(1, ...) == frame then
            return func(...)
        end
        return func(frame, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    end)
end

-- ClassicAPI may dispatch positional arguments or native globals. Decode once
-- at the event boundary; module logic always receives (frame, event, payload).
function FT.EventArgs(first, second, ...)
    if type(first) == "table" then return second, ... end
    if type(first) == "string" then return first, second, ... end
    return event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
end

function FT.SetEventHandler(frame, handler)
    frame:SetScript("OnEvent", function(...)
        return handler(frame, FT.EventArgs(...))
    end)
end

function FT.IsEnabled(key, default)
    local value = FostercareTweaks_Config[key]
    if value == nil then
        local module = FT.mods[key]
        if module then return module.enabled == true end
        return default == true
    end
    return value == 1
end

function FT.GetOverride(key, default)
    local value = FostercareTweaks_Config.overwrites[key]
    if value == nil then value = FT.overwrites and FT.overwrites[key] end
    if value == nil then return default end
    return value
end

function FT.ClampNumber(input, default, minimum, maximum)
    local value = tonumber(input)
    if not value or value ~= value or value == math.huge or value == -math.huge then value = default end
    return math.max(minimum, math.min(maximum, value))
end

function FT.GetNumber(key, default, minimum, maximum)
    return FT.ClampNumber(FT.GetOverride(key), default, minimum, maximum)
end

function FT.SetOverride(key, value)
    FostercareTweaks_Config.overwrites[key] = value
    FT.overwrites = FT.overwrites or {}
    FT.overwrites[key] = value
end

-- One load watcher serves optional integrations, including late globals.
local waiting, loadWatcher = {}, CreateFrame("Frame")
FT.SetEventHandler(loadWatcher, function()
    for i = #waiting, 1, -1 do
        local request = waiting[i]
        if IsAddOnLoaded(request.name) or _G[request.name] then
            table.remove(waiting, i)
            local ok, err = pcall(request.callback)
            if not ok and DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("FostercareTweaks: " .. request.name .. ": " .. tostring(err), 1, 0.3, 0.3)
            end
        end
    end
    if #waiting == 0 then loadWatcher:UnregisterAllEvents() end
end)

function FT.HookAddonOrVariable(addon, callback)
    if IsAddOnLoaded(addon) or _G[addon] then return callback() end
    waiting[#waiting + 1] = { name = addon, callback = callback }
    loadWatcher:RegisterEvent("ADDON_LOADED")
    loadWatcher:RegisterEvent("PLAYER_LOGIN")
    loadWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
end

-- Math & Color Utilities
FT.rgbhex = function(r, g, b, a)
    local _r, _g, _b, _a
    if type(r) == "table" then
        if r.r then
            _r, _g, _b, _a = r.r, r.g, r.b, (r.a or 1)
        elseif #r >= 3 then
            _r, _g, _b, _a = r[1], r[2], r[3], (r[4] or 1)
        end
    elseif tonumber(r) then
        _r, _g, _b, _a = r, g, b, (a or 1)
    end

    if _r and _g and _b and _a then
        _r = _r > 1 and 1 or _r < 0 and 0 or _r
        _g = _g > 1 and 1 or _g < 0 and 0 or _g
        _b = _b > 1 and 1 or _b < 0 and 0 or _b
        _a = _a > 1 and 1 or _a < 0 and 0 or _a
        return string.format("|c%02x%02x%02x%02x", _a * 255, _r * 255, _g * 255, _b * 255)
    end
    return ""
end

FT.round = function(input, places)
    places = places or 0
    if type(input) == "number" then
        local pow = 10 ^ places
        return floor(input * pow + 0.5) / pow
    end
end

FT.Abbreviate = function(number, eachk)
    if type(number) ~= "number" then return number or "" end
    local sign = number < 0 and -1 or 1
    local num = math.abs(number)

    if num >= 1000000 then
        return FT.round(num / 1000000 * sign, 2) .. "m"
    elseif not eachk and num >= 10000 then
        return FT.round(num / 1000 * sign, 2) .. "k"
    elseif eachk and num >= 1000 then
        return FT.round(num / 1000 * sign, 2) .. "k"
    end
    return number
end

FT.TimeConvert = function(remaining)
    local color = "|cffffffff"
    if remaining < 5 then
        color = "|cffff5555"
    elseif remaining < 10 then
        color = "|cffffff55"
    end

    if remaining < 60 then
        return color .. ceil(remaining)
    elseif remaining < 3600 then
        return color .. ceil(remaining / 60) .. "m"
    elseif remaining < 86400 then
        return color .. ceil(remaining / 3600) .. "h"
    else
        return color .. ceil(remaining / 86400) .. "d"
    end
end

local borderDef = {
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 16,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

FT.AddBorder = function(frame, inset, color)
    if not frame then return end
    if frame.FostercareTweaks_border then return frame.FostercareTweaks_border end

    local top, right, bottom, left
    if type(inset) == "table" then
        top, right, bottom, left = unpack(inset)
        left, bottom = -left, -bottom
    end

    local b = CreateFrame("Frame", nil, frame)
    b:SetPoint("TOPLEFT", frame, "TOPLEFT", (left or -inset), (top or inset))
    b:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", (right or inset), (bottom or -inset))
    b:SetBackdrop(borderDef)

    if color then
        b:SetBackdropBorderColor(color.r, color.g, color.b, color.a or 1)
    end

    frame.FostercareTweaks_border = b
    frame.ShaguTweaks_border = b
    return b
end

-- Each iterator owns its keys, including nested/early-ended iteration.
FT.spairs = function(t, sortFunc)
    local keys = {}
    for key in pairs(t) do table.insert(keys, key) end
    table.sort(keys, sortFunc)
    local index = 0
    return function()
        index = index + 1
        local key = keys[index]
        if key ~= nil then return key, t[key] end
    end
end

-- Item Identification & Counting
FT.GetItemIDFromLink = function(itemLink)
    if type(itemLink) ~= "string" then return end
    return tonumber(string.match(itemLink, "item:(%d+)"))
end

-- Compile native printf-style messages once, escaping literal pattern syntax.
-- Argument positions (%2$s) are kept; no localized combat-text heuristics.
local formatPatterns = {}
local function EscapePattern(text)
    return string.gsub(text, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end
local function CompileFormat(template)
    local parts, positions, cursor, count = {"^"}, {}, 1, 0
    while cursor <= #template do
        local first, last, position, kind = string.find(template, "%%(%d*)%$?([sd%%])", cursor)
        if not first then parts[#parts + 1] = EscapePattern(string.sub(template, cursor)); break end
        parts[#parts + 1] = EscapePattern(string.sub(template, cursor, first - 1))
        if kind == "%" then parts[#parts + 1] = "%%"
        else
            count = count + 1
            positions[tonumber(position) or count] = count
            parts[#parts + 1] = kind == "d" and "([+-]?%d+)" or "(.-)"
        end
        cursor = last + 1
    end
    parts[#parts + 1] = "$"
    return { pattern = table.concat(parts), positions = positions }
end
local function Capture(index, ...)
    if index then
        local value = select(index, ...)
        return value
    end
end
function FT.cmatch(message, template)
    if type(message) ~= "string" or type(template) ~= "string" then return end
    local compiled = formatPatterns[template]
    if not compiled then compiled = CompileFormat(template); formatPatterns[template] = compiled end
    local a, b, c, d, e = string.match(message, compiled.pattern)
    local order = compiled.positions
    return Capture(order[1], a, b, c, d, e), Capture(order[2], a, b, c, d, e),
        Capture(order[3], a, b, c, d, e), Capture(order[4], a, b, c, d, e), Capture(order[5], a, b, c, d, e)
end

-- Player metadata is indexed on roster events. Live unit/GUID data wins over
-- saved names, and pooled tokens are validated before use.
local unitMobs, rosterUnits = {}, {}
local classMisses, missCount, classSource = {}, 0, nil
local function ClearClassMisses()
    table.wipe(classMisses)
    missCount = 0
end
local function NormalizeClass(class)
    if type(class) ~= "string" or class == "" then return nil end
    return string.upper(class)
end
FT.NormalizeClass = NormalizeClass

local function AddUnitData(database, name, class, level, elite)
    if type(name) ~= "string" or name == "" or name == UNKNOWN then return end
    local records = database == "players" and FostercareTweaks_Cache.players or unitMobs
    local record = records[name]
    if type(record) ~= "table" then record = {}; records[name] = record end
    if class then record.class = NormalizeClass(class) end
    if type(level) == "number" and level > 0 then record.level = level end
    if elite then record.elite = elite end
end
FT.AddUnitData = AddUnitData

local function ReadUnit(unit, expectedName)
    if not UnitExists(unit) then return end
    local name = UnitName(unit)
    if expectedName and name ~= expectedName then return end
    local _, class = UnitClass(unit)
    local level = UnitLevel(unit)
    local player = UnitIsPlayer(unit)
    local elite = not player and UnitClassification(unit) or nil
    AddUnitData(player and "players" or "mobs", name, class, level, elite)
    return NormalizeClass(class), level, elite, player
end

function FT.GetUnitData(name)
    if type(name) ~= "string" or name == "" then return end
    if string.match(name, "^0x%x+$") then return ReadUnit(name) end
    if UnitName("target") == name then
        local class, level, elite, player = ReadUnit("target", name)
        if class then return class, level, elite, player end
    end
    if UnitName("mouseover") == name then
        local class, level, elite, player = ReadUnit("mouseover", name)
        if class then return class, level, elite, player end
    end
    if rosterUnits[name] then
        local class, level, elite, player = ReadUnit(rosterUnits[name], name)
        if class then return class, level, elite, player end
    end
    local record = FostercareTweaks_Cache.players[name]
    if type(record) == "table" and record.class then
        return NormalizeClass(record.class), record.level, record.elite, true
    end
    record = unitMobs[name]
    if record then return record.class, record.level, record.elite, false end
    -- AutoBG's public helper scans the scoreboard and roster. Use our event
    -- indexes first, and ask it only once per unknown name per source update.
    if type(AutoBG_FindPlayerClass) == "function" then
        if classSource ~= AutoBG_FindPlayerClass then
            classSource = AutoBG_FindPlayerClass
            ClearClassMisses()
        end
        if not classMisses[name] then
            local class = NormalizeClass(AutoBG_FindPlayerClass(name))
            if class then AddUnitData("players", name, class); return class, nil, nil, true end
            if missCount >= 256 then ClearClassMisses() end
            classMisses[name], missCount = true, missCount + 1
        end
    end
end

local function ScanRoster()
    table.wipe(rosterUnits)
    local function AddRosterUnit(unit, expectedName)
        ReadUnit(unit, expectedName)
        local name = expectedName or UnitName(unit)
        if name and name ~= UNKNOWN then rosterUnits[name] = unit end
    end
    AddRosterUnit("player")
    local raidCount = GetNumRaidMembers()
    if raidCount > 0 then
        for i = 1, raidCount do
            local name, _, _, level, localized, token = GetRaidRosterInfo(i)
            AddUnitData("players", name, token or localized, level)
            AddRosterUnit("raid" .. i, name)
        end
    else
        for i = 1, GetNumPartyMembers() do AddRosterUnit("party" .. i) end
    end
end
local function ScanFriends()
    for i = 1, GetNumFriends() do
        local name, level, class = GetFriendInfo(i)
        AddUnitData("players", name, class, level)
    end
end
local function ScanGuild()
    for i = 1, GetNumGuildMembers() do
        local name, _, _, level, class = GetGuildRosterInfo(i)
        AddUnitData("players", name, class, level)
    end
end
local function ScanWho()
    for i = 1, GetNumWhoResults() do
        local name, _, level, _, class = GetWhoInfo(i)
        AddUnitData("players", name, class, level)
    end
end
local function ScanBattlefield()
    for i = 1, GetNumBattlefieldScores() do
        local name, _, _, _, _, _, _, _, localized, token = GetBattlefieldScore(i)
        local class = NormalizeClass(token or localized)
        if name and class and RAID_CLASS_COLORS[class] then
            AddUnitData("players", name, class)
            AddUnitData("players", string.match(name, "^[^-]+"), class)
        end
    end
end
local unitScanFrame = CreateFrame("Frame", "FCTweaksUnitScan", UIParent)
for _, ev in ipairs({"PLAYER_ENTERING_WORLD", "FRIENDLIST_UPDATE", "GUILD_ROSTER_UPDATE",
    "RAID_ROSTER_UPDATE", "PARTY_MEMBERS_CHANGED", "PLAYER_TARGET_CHANGED",
    "WHO_LIST_UPDATE", "UPDATE_MOUSEOVER_UNIT", "UPDATE_BATTLEFIELD_SCORE"}) do
    unitScanFrame:RegisterEvent(ev)
end
FT.SetEventHandler(unitScanFrame, function(_, ev)
    if ev == "PLAYER_ENTERING_WORLD" or ev == "RAID_ROSTER_UPDATE" or ev == "PARTY_MEMBERS_CHANGED" then
        ClearClassMisses()
        ScanRoster()
    elseif ev == "FRIENDLIST_UPDATE" then ScanFriends()
    elseif ev == "GUILD_ROSTER_UPDATE" then ScanGuild()
    elseif ev == "WHO_LIST_UPDATE" then ScanWho()
    elseif ev == "UPDATE_BATTLEFIELD_SCORE" then ClearClassMisses(); ScanBattlefield()
    elseif ev == "PLAYER_TARGET_CHANGED" then ReadUnit("target")
    elseif ev == "UPDATE_MOUSEOVER_UNIT" then ReadUnit("mouseover") end
end)

-- Nameplate lifecycle and verified GUID bindings.
local NAMEPLATE_OBJECTORDER = { "border", "glow", "name", "level", "levelicon", "raidicon", "dragon" }

local function IsNamePlate(frame)
    if not frame or frame:GetObjectType() ~= "Button" then return false end
    local regions = frame:GetRegions()
    if not regions or not regions.GetObjectType or not regions.GetTexture then return false end
    if regions:GetObjectType() ~= "Texture" then return false end
    return regions:GetTexture() == "Interface\\Tooltips\\Nameplate-Border"
end

local libnameplate = CreateFrame("Frame", "FCTweaksLibNameplate", UIParent)
libnameplate.OnInit = {}
libnameplate.OnShow = {}
libnameplate.OnUpdate = {}
local plateRegistry = {}

local function InitPlate(plate, unit)
    if not plate or plateRegistry[plate] then
        if plate and unit then plate.fctUnitGUID = UnitGUID(unit) end
        return
    end
    if not IsNamePlate(plate) then return end

    if unit then plate.fctUnitGUID = UnitGUID(unit) end
    plate.healthbar = plate:GetChildren()
    FT.ForEachRegion(plate, function(region, regIdx)
        local key = NAMEPLATE_OBJECTORDER[regIdx]
        if key then
            plate[key] = region
        end
    end)

    for _, func in ipairs(libnameplate.OnInit) do
        func(plate)
    end

    FT.HookScript(plate, "OnUpdate", function(self)
        for _, callback in ipairs(libnameplate.OnUpdate) do callback(self) end
    end)
    FT.HookScript(plate, "OnShow", function(self)
        for _, callback in ipairs(libnameplate.OnShow) do callback(self) end
    end)

    plateRegistry[plate] = plate
end

-- Validate pooled-frame ownership before consuming any unit data.
FT.GetNameplateUnit = function(plate)
    local guid = plate.fctUnitGUID
    if guid and C_NamePlate.GetNamePlateForUnit(guid) == plate then
        return guid
    end
    plate.fctUnitGUID = nil
end

libnameplate:RegisterEvent("NAME_PLATE_CREATED")
libnameplate:RegisterEvent("NAME_PLATE_UNIT_ADDED")
libnameplate:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
libnameplate:RegisterEvent("PLAYER_ENTERING_WORLD")

FT.SetEventHandler(libnameplate, function(_, ev, a1)
    if ev == "NAME_PLATE_CREATED" and a1 then
        InitPlate(a1)
    elseif ev == "NAME_PLATE_UNIT_ADDED" and a1 then
        local unit = a1
        local plate = C_NamePlate.GetNamePlateForUnit(unit)
        if plate then
            InitPlate(plate, unit)
        end
    elseif ev == "NAME_PLATE_UNIT_REMOVED" and a1 then
        local unit = a1
        local plate = C_NamePlate.GetNamePlateForUnit(unit)
        if plate and plate.fctUnitGUID == UnitGUID(unit) then
            plate.fctUnitGUID = nil
        end
    elseif ev == "PLAYER_ENTERING_WORLD" then
        for _, guid in ipairs(C_NamePlate.GetNamePlateGUIDs()) do
            InitPlate(C_NamePlate.GetNamePlateForGUID(guid), guid)
        end
    end
end)

FT.libnameplate = libnameplate

-- SuperWoW supplies real values through native UnitHealth/UnitHealthMax.
function FT.GetUnitHealthValues(unit)
    if not unit or not UnitExists(unit) then return 0, 0 end
    return UnitHealth(unit) or 0, UnitHealthMax(unit) or 0
end

-- One palette for all settings pages. These styles touch addon-owned UI
-- only; native font objects and gameplay frames keep their original colors.
local Theme = {
    background = { 19 / 255, 25 / 255, 32 / 255 }, -- #131920: window
    panel = { 36 / 255, 46 / 255, 58 / 255 }, -- #242E3A: grouped settings
    control = { 53 / 255, 69 / 255, 86 / 255 }, -- #354556: buttons and tracks
    selected = { 18 / 255, 61 / 255, 75 / 255 }, -- #123D4B: active choice
    text = { 241 / 255, 245 / 255, 249 / 255 }, -- #F1F5F9
    heading = { 1, 1, 1 },
    muted = { 193 / 255, 203 / 255, 214 / 255 }, -- #C1CBD6
    hint = { 193 / 255, 203 / 255, 214 / 255 },
    border = { 139 / 255, 156 / 255, 176 / 255 }, -- #8B9CB0
    accent = { 100 / 255, 216 / 255, 230 / 255 }, -- #64D8E6
}
FT.SettingsTheme = Theme
local settingsBackdrop = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
}
function Theme.Text(font, role)
    if not font then return end
    local color = Theme[role or "text"]
    font:SetTextColor(color[1], color[2], color[3])
end
function Theme.Font(parent, layer, font, role)
    local text = parent:CreateFontString(nil, layer, font)
    Theme.Text(text, role)
    return text
end
function Theme.Panel(frame, surface)
    frame:SetBackdrop(settingsBackdrop)
    local bg, border = Theme[surface or "panel"], Theme.border
    frame:SetBackdropColor(bg[1], bg[2], bg[3], 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], 1)
end
function Theme.SelectButton(button, selected)
    local color = selected and Theme.accent or Theme.border
    local bg = selected and Theme.selected or Theme.control
    button:SetBackdropColor(bg[1], bg[2], bg[3], 1)
    button:SetBackdropBorderColor(color[1], color[2], color[3], 1)
    Theme.Text(button:GetFontString(), selected and "heading" or "text")
    -- A visible underline identifies selection without relying on its color.
    if selected and not button.fctSelectionMark then
        local mark = button:CreateTexture(nil, "OVERLAY")
        mark:SetTexture("Interface\\Buttons\\WHITE8X8")
        mark:SetVertexColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
        mark:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 4, 3)
        mark:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 3)
        mark:SetHeight(2)
        button.fctSelectionMark = mark
    end
    if button.fctSelectionMark then
        if selected then button.fctSelectionMark:Show() else button.fctSelectionMark:Hide() end
    end
end
function Theme.Button(button)
    Theme.Panel(button, "control")
    -- Keep the native button's text, state transitions and hit rectangle.
    button:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
    button:GetNormalTexture():SetVertexColor(Theme.text[1], Theme.text[2], Theme.text[3], 0.08)
    button:SetPushedTexture("Interface\\Buttons\\WHITE8X8")
    button:GetPushedTexture():SetVertexColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.18)
    button:SetDisabledTexture("Interface\\Buttons\\WHITE8X8")
    button:GetDisabledTexture():SetVertexColor(Theme.border[1], Theme.border[2], Theme.border[3], 0.04)
    button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
    button:GetHighlightTexture():SetVertexColor(Theme.text[1], Theme.text[2], Theme.text[3], 0.14)
    Theme.SelectButton(button, false)
end
function Theme.CheckButton(button)
    Theme.Button(button)
    -- Keep native checked/disabled state and its checkmark shape.
    button:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    button:GetCheckedTexture():SetVertexColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
end
function Theme.Slider(slider)
    local bg, border = Theme.control, Theme.border
    slider:SetBackdropColor(bg[1], bg[2], bg[3], 1)
    slider:SetBackdropBorderColor(border[1], border[2], border[3], 1)
    -- OptionsSliderTemplate names this native thumb; do not replace its input
    -- owner, value, range or 32-pixel artwork with a later-client widget API.
    local name = slider:GetName()
    local thumb = name and _G[name .. "Thumb"]
    if thumb then thumb:SetVertexColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1) end
end
