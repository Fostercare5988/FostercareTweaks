-- Tweaks: tooltips, merchant, chat, minimap, world map and Auto Stance.
-- Doc headings are ClassicAPI's docs/API.md; "FrameXML" is the client's own code.
if not CLASSIC_API_VERSION then error("Tweaks needs ClassicAPI.", 0) end

local _, FT = ...
TweaksDB = TweaksDB or {} -- restored first: LoadSavedVariablesFirst
local db = TweaksDB

-- The page's switches and sliders. Filled in here, since the features start
-- before the Settings window registers the page.
FT.DEFAULTS = { arrowKeys = true, history = true, timestamps = true, classColors = true,
    blueShaman = true, minimapSquare = true, minimapClock = true, minimapTidy = true,
    autoStance = true, minimapScale = 1.6, mapScale = 1.65 }
for key, value in pairs(FT.DEFAULTS) do if db[key] == nil then db[key] = value end end
db.pieces = db.pieces or {} -- minimap pieces the game would put back: key = { x, y }

-- What a page row runs when its value changes: FT.apply[key]().
FT.apply = {}

-- Ctrl+Shift ------------------------------------------------------------------

-- Every MODIFIER_STATE_CHANGED goes to these, with whether Shift and Ctrl are down.
-- The left and right reads: the merged IsShiftKeyDown lags this event
-- (CLASSICAPI_MASTER_REFERENCE, "Modifier event state ordering").
local listeners = {}
function FT.OnModifiers(fn) listeners[#listeners + 1] = fn end
function FT.Shift() return (IsLeftShiftKeyDown() or IsRightShiftKeyDown()) and true or false end
local modifiers = CreateFrame("Frame")
modifiers:RegisterEvent("MODIFIER_STATE_CHANGED")
modifiers:SetScript("OnEvent", function()
    local shift = FT.Shift()
    local ctrl = (IsLeftControlKeyDown() or IsRightControlKeyDown()) and true or false
    for i = 1, #listeners do listeners[i](shift, ctrl) end
end)

-- Ctrl+Shift shows a handle on each frame that can be moved; dragging it moves
-- the frame. They are minimap pieces the game anchors again by itself, so their
-- places are saved here, centred against the screen, and not by the client
-- (### frame:SetDontSavePosition).
local handles, held = {}, false
local function Stop(handle)
    if not handle.moving then return end
    handle.moving = nil
    handle.frame:StopMovingOrSizing()
    local x, y = handle.frame:GetCenter()
    db.pieces[handle.key] = { x, y }
end

-- `rule(frame)` is the game's rule for when a piece shows, asked again after.
function FT.Movable(frame, key, label, rule)
    frame:SetMovable(true)
    frame:SetDontSavePosition(true)
    local at = db.pieces[key]
    if at then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", at[1], at[2])
    end
    local handle = CreateFrame("Frame", nil, frame)
    handle:SetAllPoints(frame)
    handle:SetFrameStrata("DIALOG")
    handle:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    handle:SetBackdropColor(0.2, 0.6, 1, 0.45)
    handle:EnableMouse(true)
    handle:Hide()
    local text = handle:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER", handle)
    text:SetText(label)
    handle.frame, handle.key, handle.rule = frame, key, rule
    handle:SetScript("OnMouseDown", function() this.moving = true; this.frame:StartMoving() end)
    handle:SetScript("OnMouseUp", function() Stop(this) end)
    handles[#handles + 1] = handle
    return handle
end

FT.OnModifiers(function(shift, ctrl)
    local on = shift and ctrl
    if on == held then return end
    held = on
    for _, handle in ipairs(handles) do
        local frame = handle.frame
        if on then
            frame:Show()
            handle:Show()
        else
            Stop(handle) -- let go of the keys while dragging
            handle:Hide()
            if handle.rule then handle.rule(frame) end
        end
    end
end)

-- `fn` runs once the client's load-on-demand addon `name` is loaded.
local waiting, loader = {}, CreateFrame("Frame")
loader:SetScript("OnEvent", function()
    local fn = waiting[arg1]
    if fn then waiting[arg1] = nil; fn() end
    if not next(waiting) then this:UnregisterEvent("ADDON_LOADED") end
end)
function FT.WhenLoaded(name, fn)
    if C_AddOns.IsAddOnLoaded(name) then return fn() end
    waiting[name] = fn
    loader:RegisterEvent("ADDON_LOADED")
end
