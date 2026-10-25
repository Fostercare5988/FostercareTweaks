-- FostercareTweaks: Helpers.lua
-- Shared settings helpers, metadata and unit-frame health

local FT = FostercareTweaks
if not FT then return end

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

-- Chat modules leave combat-log windows alone. A window counts as combat
-- output when more than five of its message types are spell/combat types.
function FT.IsCombatChatFrame(frame)
    local combat = 0
    for _, msg in pairs(frame and frame.messageTypeList or {}) do
        if strfind(msg, "SPELL", 1) or strfind(msg, "COMBAT", 1) then
            combat = combat + 1
        end
    end
    return combat > 5
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

local function NormalizeClass(class)
    if type(class) ~= "string" or class == "" then return nil end
    return string.upper(class)
end
FT.NormalizeClass = NormalizeClass

-- A player's class token by name. ClassicAPI looks in the group, nearby
-- players, friends, everyone seen this session and, when the player turned it
-- on (AddOn Options > ClassicAPI), its saved player cache.
function FT.GetPlayerClass(name)
    if type(name) ~= "string" or name == "" then return end
    local _, class = C_PlayerCache.GetPlayerInfoByName(name)
    return NormalizeClass(class)
end

-- SuperWoW supplies real values through native UnitHealth/UnitHealthMax.
function FT.GetUnitHealthValues(unit)
    if not unit or not UnitExists(unit) then return 0, 0 end
    return UnitHealth(unit) or 0, UnitHealthMax(unit) or 0
end

-- One palette for all settings pages. These styles touch addon-owned UI
-- only; native font objects and gameplay frames keep their original colors.
-- VanillaForge dark plum and lavender settings theme (KNOWN_PATTERNS).
local Theme = {
    background = { 0.055, 0.045, 0.075 }, -- window
    panel = { 0.10, 0.075, 0.14 }, -- grouped settings, between window and buttons
    control = { 0.14, 0.10, 0.20 }, -- buttons and tracks
    selected = { 0.25, 0.18, 0.35 }, -- active choice (button hover tone)
    text = { 0.92, 0.90, 1 },
    heading = { 0.78, 0.65, 1 },
    muted = { 0.80, 0.76, 0.90 },
    hint = { 0.80, 0.76, 0.90 },
    border = { 0.55, 0.43, 0.72 }, -- panel border
    buttonBorder = { 0.42, 0.33, 0.54 },
    accent = { 0.78, 0.65, 1 },
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
    local color = selected and Theme.accent or Theme.buttonBorder
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
