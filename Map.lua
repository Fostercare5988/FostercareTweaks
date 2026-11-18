-- The minimap (size, square, a 24-hour clock, no clutter, each piece placed by
-- Ctrl+Shift drag) and the world map (window size, coordinates, group colours).
local _, FT = ...
if not FT.apply then return end
local db = TweaksDB

-- Minimap ---------------------------------------------------------------------

-- The clock. AutoLazy's tray leaves a frame of this name alone.
local clock = CreateFrame("Frame", "MinimapClock", Minimap)
clock:SetSize(50, 23)
clock:SetFrameLevel(64)
clock:SetPoint("BOTTOM", MinimapCluster, "BOTTOM", 8, 4)
clock:EnableMouse(true)
local clockText = clock:CreateFontString(nil, "OVERLAY", "GameFontNormal")
clockText:SetAllPoints(clock)
clock:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")
    GameTooltip:AddLine("Clock")
    GameTooltip:AddDoubleLine("Local time", date("%H:%M"), 1, 1, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine("Server time", string.format("%02d:%02d", GetGameTime()), 1, 1, 1, 1, 1, 1)
    GameTooltip:Show()
end)
clock:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- The text changes once a minute, so the clock wakes once a minute, just after it
-- turns, and not at all while it is off.
local ticking
local function Tick()
    if not db.minimapClock then ticking = nil; return end
    clockText:SetText(date("%H:%M"))
    C_Timer.After(61 - tonumber(date("%S")), Tick)
end
function FT.apply.minimapClock()
    clock:SetShown(db.minimapClock)
    if db.minimapClock and not ticking then ticking = true; Tick() end
end

-- The map is scaled, not sized: a resized minimap breaks the engine's own blips.
-- The clock and the icons on it keep their size. The map itself, not the larger
-- cluster around it, stays on screen (### frame:SetClampRectInsets).
local FIXED = { clock, MiniMapMailFrame, MiniMapBattlefieldFrame, MiniMapTrackingFrame }
local function Clamp()
    if not Minimap:GetLeft() then return end
    local e = Minimap:GetEffectiveScale() / MinimapCluster:GetEffectiveScale()
    MinimapCluster:SetClampRectInsets(Minimap:GetLeft() * e - MinimapCluster:GetLeft(),
        Minimap:GetRight() * e - MinimapCluster:GetRight(), Minimap:GetTop() * e - MinimapCluster:GetTop(),
        Minimap:GetBottom() * e - MinimapCluster:GetBottom())
end
function FT.apply.minimapScale()
    Minimap:SetScale(db.minimapScale)
    for _, frame in ipairs(FIXED) do frame:SetScale(1 / db.minimapScale) end
    Clamp()
end

local square = CreateFrame("Frame", nil, Minimap)
square:SetFrameStrata("BACKGROUND")
square:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -3, 3)
square:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 3, -3)
square:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 16 })
square:SetBackdropBorderColor(0.9, 0.8, 0.5, 1)
function FT.apply.minimapSquare()
    local on = db.minimapSquare
    Minimap:SetMaskTexture(on and "Interface\\Buttons\\WHITE8X8" or "Textures\\MinimapMask")
    MinimapBorder:SetTexture(not on and "Interface\\Minimap\\UI-Minimap-Border" or nil)
    Minimap:SetPoint("CENTER", MinimapCluster, "TOP", 9, on and -98 or -92) -- -92: Minimap.xml
    square:SetShown(on)
    Clamp()
end

-- The calendar button, the top border, the toggle and the zoom buttons go; the
-- mouse wheel zooms.
local CLUTTER = { GameTimeFrame, MinimapBorderTop, MinimapToggleButton, MinimapZoomIn, MinimapZoomOut }
GameTimeFrame:HookScript("OnShow", function() if db.minimapTidy then this:Hide() end end)
Minimap:SetScript("OnMouseWheel", function()
    if arg1 > 0 then Minimap_ZoomIn() else Minimap_ZoomOut() end
end)
function FT.apply.minimapTidy()
    for _, piece in ipairs(CLUTTER) do piece:SetShown(not db.minimapTidy) end
    Minimap:EnableMouseWheel(db.minimapTidy)
    if not db.pieces.zone then -- the zone name where the top border was; -3, 83: Minimap.xml
        MinimapZoneTextButton:ClearAllPoints()
        MinimapZoneTextButton:SetPoint("CENTER", MinimapCluster, "CENTER", db.minimapTidy and 7 or -3,
            db.minimapTidy and 85 or 83)
    end
end

FT.apply.minimapScale()
FT.apply.minimapSquare()
FT.apply.minimapTidy()
FT.apply.minimapClock()

-- Ctrl+Shift moves the map and each piece on its own. The mail, battleground and
-- tracking icons show while the keys are held; then the game's rule decides.
MinimapCluster:SetClampedToScreen(true)
FT.Movable(MinimapCluster, "minimap", "Minimap"):SetAllPoints(Minimap) -- the handle on the map itself
FT.Movable(MinimapZoneTextButton, "zone", "Zone")
FT.Movable(clock, "clock", "Clock", function(frame) frame:SetShown(db.minimapClock) end)
FT.Movable(MiniMapMailFrame, "mail", "Mail", function(frame) frame:SetShown(HasNewMail()) end)
FT.Movable(MiniMapBattlefieldFrame, "battlefield", "BG", function() BattlefieldFrame_UpdateStatus() end)
FT.Movable(MiniMapTrackingFrame, "tracking", "Track", function(frame) frame:SetShown(GetTrackingTexture()) end)

-- World map -------------------------------------------------------------------

-- The client's windowed map (FrameXML WorldMapFrame.lua: WorldMapFrame_Minimize)
-- at the page's size; Ctrl+wheel on it changes the size. The full-screen map is
-- never scaled. A new size keeps the window's centre where it is.
FT.MAP_MIN, FT.MAP_MAX = 0.6, 2
function FT.apply.mapScale()
    local scale = WORLDMAP_WINDOWED == 1 and db.mapScale or 1
    local old = WorldMapFrame:GetScale()
    if old == scale then return end
    local x, y = WorldMapFrame:GetCenter()
    WorldMapFrame:SetScale(scale)
    if x and WORLDMAP_WINDOWED == 1 then
        WorldMapFrame:ClearAllPoints()
        WorldMapFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x * old / scale, y * old / scale)
    end
end
hooksecurefunc("WorldMapFrame_Minimize", FT.apply.mapScale)
hooksecurefunc("WorldMapFrame_Maximize", FT.apply.mapScale)
WorldMapFrame:EnableMouseWheel(true)
WorldMapFrame:HookScript("OnMouseWheel", function()
    if WORLDMAP_WINDOWED ~= 1 or not IsControlKeyDown() then return end
    db.mapScale = math.max(FT.MAP_MIN, math.min(FT.MAP_MAX, math.floor((db.mapScale + arg1 * 0.05) * 20 + 0.5) / 20))
    FT.apply.mapScale()
    if FT.mapSetting then FT.mapSetting:NotifyUpdate() end
end)
FT.apply.mapScale()

-- Your and the cursor's coordinates, in tenths of a percent of the shown map;
-- the text is written only when it changes.
local function Label(point, x, title)
    local label = WorldMapButton:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    label:SetPoint(point, WorldMapButton, point, x, -21)
    label.title = "|cffffcc00" .. title .. ": |r"
    return label
end
local cursorLabel, playerLabel = Label("BOTTOMLEFT", 3, "Cursor"), Label("BOTTOMRIGHT", -3, "Player")
local function Coordinates(label, x, y)
    if x == 0 and y == 0 then x = nil end -- not on the shown map
    if x then x, y = math.floor(x * 1000 + 0.5) / 10, math.floor(y * 1000 + 0.5) / 10 else y = nil end
    if label.set and label.x == x and label.y == y then return end
    label.set, label.x, label.y = true, x, y
    label:SetText(x and string.format("%s%.1f / %.1f", label.title, x, y) or label.title .. "N/A")
end

-- Group members as dots in their class colours, on the world map and the
-- battleground map. The map moves its group buttons and gives them other units
-- every frame (FrameXML WorldMapFrame.lua, "Position groupmates"), so the dots
-- are coloured on a timer while a map shows.
local DOT = "Interface\\AddOns\\Tweaks\\img\\circle"
local maps, mine = {}, {}
local function GroupButtons(prefix)
    local list = {}
    for i = 1, 4 do list[i] = _G[prefix .. "Party" .. i] end
    for i = 1, 40 do list[4 + i] = _G[prefix .. "Raid" .. i] end
    maps[#maps + 1] = list
end

local function Dot(button, unit)
    if not button:IsShown() then return end
    unit = button.unit or unit
    local name = button.name or (unit and UnitName(unit))
    if not name then return end
    local dot = button.ftDot
    if not dot then
        dot = button:CreateTexture(nil, "OVERLAY")
        dot:SetPoint("CENTER", button)
        dot:SetSize(button:GetWidth() / 2, button:GetHeight() / 2)
        button.ftDot, dot.class = dot, false
        button.ftIcon = _G[button:GetName() .. "Icon"]
    end
    if button.ftIcon and button.ftIcon:GetTexture() then button.ftIcon:SetTexture(nil) end
    local kind = mine[name] and "party" or "raid"
    if dot.group ~= kind then dot.group = kind; dot:SetTexture(DOT .. kind) end
    local class
    if unit then _, class = UnitClass(unit) end
    if not class then _, class = C_PlayerCache.GetPlayerInfoByName(name) end
    if dot.class == class then return end -- written only when it changes
    dot.class = class
    local color = class and RAID_CLASS_COLORS[class]
    if color then dot:SetVertexColor(color.r, color.g, color.b) else dot:SetVertexColor(0.5, 1, 0.5) end
end

local PARTY = { "party1", "party2", "party3", "party4" }
local ticks, ticker = 0
local function Tick()
    if WorldMapFrame:IsShown() then
        Coordinates(playerLabel, GetPlayerMapPosition("player"))
        if MouseIsOver(WorldMapButton) then
            local scale, cx, cy = WorldMapButton:GetEffectiveScale(), GetCursorPosition()
            Coordinates(cursorLabel, (cx / scale - WorldMapButton:GetLeft()) / WorldMapButton:GetWidth(),
                (WorldMapButton:GetTop() - cy / scale) / WorldMapButton:GetHeight())
        else
            Coordinates(cursorLabel)
        end
    end
    ticks = ticks + 1
    if ticks % 2 == 1 then return end -- the dots five times a second
    table.wipe(mine)
    mine[UnitName("player")] = true
    for i = 1, 4 do
        local name = UnitName(PARTY[i])
        if name then mine[name] = true end
    end
    for _, list in ipairs(maps) do
        for i = 1, #list do Dot(list[i], PARTY[i]) end
    end
end

-- One timer while a map shows; none while both are closed.
local function Watch()
    local open = WorldMapFrame:IsShown() or (BattlefieldMinimap and BattlefieldMinimap:IsShown())
    if open and not ticker then ticker = C_Timer.NewTicker(0.1, Tick); Tick()
    elseif not open and ticker then ticker:Cancel(); ticker = nil end
end
GroupButtons("WorldMap")
WorldMapFrame:HookScript("OnShow", Watch)
WorldMapFrame:HookScript("OnHide", Watch)
FT.WhenLoaded("Blizzard_BattlefieldMinimap", function()
    GroupButtons("BattlefieldMinimap")
    BattlefieldMinimap:HookScript("OnShow", Watch)
    BattlefieldMinimap:HookScript("OnHide", Watch)
end)
