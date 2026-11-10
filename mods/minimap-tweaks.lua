local FT = FostercareTweaks
if not FT then return end

do
-- Minimap size: the map is scaled (a resized frame breaks the engine's own blip,
-- arrow and tooltip geometry). The clock and the icons below keep their own size,
-- and AutoLazy's tray sizes the buttons it docks. The map, the zone name, the
-- clock and each icon are placed on their own, against the screen: resizing or
-- moving one never moves another.
local module = FT:register({
    title = "MiniMap Size",
    always = true,
})

-- A minimap piece (zone name, clock, icon) where the player left it, against
-- the screen, moved with Ctrl+Shift.
function FT.PlaceIcon(frame, key, label)
    FT.RestoreFramePosition(frame, key)
    FT.RegisterFrameMover(frame, key, label)
end

-- The map, not the larger cluster frame behind it, is what must stay on screen.
-- The cluster has a gap above and beside the map that would otherwise stop the map
-- short of the screen edge. Each inset is the map's edge minus the cluster's edge,
-- in the cluster's units (ClassicAPI frame:SetClampRectInsets).
function FT.ClampMinimapToMap()
    if not Minimap:GetLeft() or not MinimapCluster:GetLeft() then return end
    local e = Minimap:GetEffectiveScale() / MinimapCluster:GetEffectiveScale()
    MinimapCluster:SetClampRectInsets(
        Minimap:GetLeft() * e - MinimapCluster:GetLeft(),
        Minimap:GetRight() * e - MinimapCluster:GetRight(),
        Minimap:GetTop() * e - MinimapCluster:GetTop(),
        Minimap:GetBottom() * e - MinimapCluster:GetBottom())
end

-- These children of the map keep their own size when the map is scaled.
local FIXED_SIZE = { "FCTweaksMinimapClock", "MiniMapMailFrame", "MiniMapBattlefieldFrame", "MiniMapTrackingFrame" }

function FT.ApplyMinimapScale(scale)
    Minimap:SetScale(scale)
    for _, name in ipairs(FIXED_SIZE) do
        local frame = _G[name]
        if frame then frame:SetScale(1 / scale) end
    end
    FT.ClampMinimapToMap()
end

module.enable = function(self)
    FT.ApplyMinimapScale(FT.GetNumber("minimap_scale"))
    -- Ctrl+Shift moves the map with its zone name; the handle covers the map itself.
    MinimapCluster.fctPositionPoint = "TOPRIGHT"
    FT.RestoreFramePosition(MinimapCluster, "minimap")
    FT.RegisterFrameMover(MinimapCluster, "minimap", "Minimap")
    MinimapCluster.fctMover:ClearAllPoints()
    MinimapCluster.fctMover:SetAllPoints(Minimap)
    -- Once the map's own layout is final (the square map re-anchors it).
    C_Timer.After(0, FT.ClampMinimapToMap)
end
end

do
-- Adds a 24h clock to the MiniMap

local module = FT:register({
    title = "MiniMap Clock",
    enabled = true,
})

local clock, ticking

-- Refresh only when the displayed minute changes.
local function UpdateClock()
    local currentTime = date("%H:%M")
    if clock.lastTime ~= currentTime then
        clock.text:SetText(currentTime)
        clock.lastTime = currentTime
    end
end

-- One timer chain while the clock shows; it ends at the first tick after a hide.
local function Tick()
    if not clock:IsShown() then ticking = nil; return end
    UpdateClock()
    C_Timer.After(61 - tonumber(date("%S")), Tick)
end

local function CreateClock()
    clock = CreateFrame("Frame", "FCTweaksMinimapClock", Minimap)
    clock:SetFrameLevel(64)
    clock:SetPoint("BOTTOM", MinimapCluster, "BOTTOM", 8, 4)  -- under the map border, not over the map
    clock:SetWidth(50)
    clock:SetHeight(23)
    clock:EnableMouse(true)
    clock:SetScale(1 / Minimap:GetScale())

    -- Plain text in the zone text's font and gold: no border, no background.
    clock.text = clock:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local font, size, flags = MinimapZoneText:GetFont()
    clock.text:SetFont(font, size, flags)
    clock.text:SetAllPoints(clock)

    -- Ctrl+Shift moves it; placed once the map's own layout is final.
    C_Timer.After(0, function() FT.PlaceIcon(clock, "minimap_clock_s", "Clock") end)

    clock:SetScript("OnEnter", function()
        local h, m = GetGameTime()
        local servertime = string.format("%.2d:%.2d", h or 0, m or 0)
        local localtime = date("%H:%M")

        GameTooltip:ClearLines()
        GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine("Clock")
        GameTooltip:AddDoubleLine("Local time", localtime, 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine("Server time", servertime, 1, 1, 1, 1, 1, 1)
        GameTooltip:Show()
    end)

    clock:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

module.apply = function(self, on)
    if not clock then
        if not on then return end
        CreateClock()
    end
    if on then
        clock:Show()
        UpdateClock()
        if not ticking then ticking = true; Tick() end
    else
        clock:Hide()
    end
end

module.enable = function() module:apply(true) end
end

do
-- Draw the mini map in a squared shape instead of a round one

local module = FT:register({
    title = "MiniMap Square",
})

module.enable = function(self)
    MinimapBorder:SetTexture(nil)
    Minimap:SetPoint("CENTER", MinimapCluster, "TOP", 9, -98)
    Minimap:SetMaskTexture("Interface\\Buttons\\WHITE8X8")

    Minimap.border = CreateFrame("Frame", nil, Minimap)
    Minimap.border:SetFrameStrata("BACKGROUND")
    Minimap.border:SetFrameLevel(1)
    Minimap.border:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -3, 3)
    Minimap.border:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 3, -3)
    Minimap.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    Minimap.border:SetBackdropBorderColor(0.9, 0.8, 0.5, 1)
    Minimap.border:SetBackdropColor(0.4, 0.4, 0.4, 1)
end
end

do
-- Hides unnecessary minimap buttons and allows mouse wheel zooming

local module = FT:register({
    title = "MiniMap Tweaks",
    enabled = true,
})

module.enable = function(self)
    GameTimeFrame:Hide()
    FT.HookScript(GameTimeFrame, "OnShow", function() GameTimeFrame:Hide() end)
    MinimapBorderTop:Hide()
    MinimapToggleButton:Hide()
    MinimapZoneTextButton:SetPoint("CENTER", 7, 85)
    -- The zone name moves with Ctrl+Shift like the icons.
    C_Timer.After(0, function() FT.PlaceIcon(MinimapZoneTextButton, "minimap_zone_s", "Zone") end)

    -- Ctrl+Shift moves the mail, battleground and tracking (herbs, ...) icons. The
    -- game hides them until needed; the mover shows each one while it is held and
    -- then asks the game's own rule again.
    local movable = {
        { "MiniMapMailFrame", "minimap_mail_s", "Mail", function(f) if HasNewMail() then f:Show() else f:Hide() end end },
        { "MiniMapBattlefieldFrame", "minimap_bg_s", "BG", function() BattlefieldFrame_UpdateStatus() end },
        { "MiniMapTrackingFrame", "minimap_tracking_s", "Track", function(f) if GetTrackingTexture() then f:Show() else f:Hide() end end },
    }
    for _, entry in ipairs(movable) do
        local frame = _G[entry[1]]
        frame.fctRestoreShown = entry[4]
        C_Timer.After(0, function() FT.PlaceIcon(frame, entry[2], entry[3]) end)
    end

    MinimapZoomIn:Hide()
    MinimapZoomOut:Hide()

    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function()
        local delta = _G.arg1 or 0
        if delta > 0 then
            Minimap_ZoomIn()
        else
            Minimap_ZoomOut()
        end
    end)
end
end
