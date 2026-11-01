local FT = FostercareTweaks
if not FT then return end

-- Related modules; settings remain independent.

do
-- Minimap size: the whole cluster (map, zone text, clock, buttons) scales.
local module = FT:register({
    title = "MiniMap Size",
    description = "Scale the mini map and the buttons around it.",
    category = "World & MiniMap", always = true,
})

-- Put a minimap icon where the player left it. Positions are kept relative to the
-- map, so the icon follows the map when it is moved or resized. A position saved
-- against the screen by an earlier version (oldKey) is converted once.
function FT.PlaceOnMinimap(frame, key, oldKey, label)
    local saved = FostercareTweaks_Config.unitframe_positions
    if oldKey and saved and saved[oldKey] and not saved[key] then
        FT.RestoreFramePosition(frame, oldKey)
        FT.SaveFramePosition(frame, key, Minimap)
        if saved[key] then saved[oldKey] = nil end
    end
    FT.RestoreFramePosition(frame, key, Minimap)
    FT.RegisterFrameMover(frame, key, label, Minimap)
end

-- keep: the player changed the size now, so a moved map keeps its top-right
-- corner on screen (its saved offset is in the cluster's own units).
function FT.ApplyMinimapScale(scale, keep)
    if math.abs(MinimapCluster:GetScale() - scale) < 0.001 then return end
    local saved = FostercareTweaks_Config.unitframe_positions
    local right, top
    if keep and saved and saved.minimap and MinimapCluster:GetRight() then
        local eff = MinimapCluster:GetEffectiveScale()
        right, top = MinimapCluster:GetRight() * eff, MinimapCluster:GetTop() * eff
    end
    MinimapCluster:SetScale(scale)
    if right then
        local eff = MinimapCluster:GetEffectiveScale()
        local ratio = UIParent:GetEffectiveScale() / eff
        saved.minimap = { point = "TOPRIGHT", relPoint = "TOPRIGHT",
            x = right / eff - UIParent:GetRight() * ratio, y = top / eff - UIParent:GetTop() * ratio }
        FT.RestoreFramePosition(MinimapCluster, "minimap")
    end
end

-- The map frame itself grows (140 px at 1): a larger frame is a larger window on
-- the map, not a magnified picture. UNVERIFIED: test in game how much more of the
-- world it shows at each zoom.
function FT.ApplyMinimapView(factor)
    local size = 140 * factor
    if math.abs(Minimap:GetWidth() - size) < 0.5 then return end
    Minimap:SetWidth(size); Minimap:SetHeight(size)
    Minimap:SetZoom(Minimap:GetZoom())
end

module.enable = function(self)
    FT.ApplyMinimapScale(FT.GetNumber("minimap_scale", 1, 0.7, 1.6))
    FT.ApplyMinimapView(FT.GetNumber("minimap_view", 1, 1, 2))
    -- Ctrl+Shift moves the whole minimap area; it keeps its top-right corner.
    MinimapCluster.fctPositionPoint = "TOPRIGHT"
    FT.RestoreFramePosition(MinimapCluster, "minimap")
    FT.RegisterFrameMover(MinimapCluster, "minimap", "Minimap")
end
end

do
-- Adds a 24h clock to the MiniMap (Rule AP-10, Rule C3 compliant)


local module = FT:register({
    title = "MiniMap Clock",
    description = "Adds a small 24h clock to the mini map.",
    category = "World & MiniMap",
    enabled = true,
})

module.enable = function(self)
    local clock = CreateFrame("Frame", "FCTweaksMinimapClock", Minimap)
    _G.MinimapClock = clock
    clock:SetFrameLevel(64)
    clock:SetPoint("BOTTOM", MinimapCluster, "BOTTOM", 8, 4)  -- under the map border, not over the map
    clock:SetWidth(50)
    clock:SetHeight(23)
    clock:EnableMouse(true)

    -- Plain text in the zone text's font and gold: no border, no background.
    clock.text = clock:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local font, size, flags = MinimapZoneText:GetFont()
    clock.text:SetFont(font, size, flags)
    clock.text:SetAllPoints(clock)

    -- Ctrl+Shift moves it; placed once the map's own layout is final.
    C_Timer.After(0, function() FT.PlaceOnMinimap(clock, "minimap_clock_r", "minimap_clock", "Clock") end)

    -- Refresh only when the displayed minute changes.
    local function UpdateClock()
        local currentTime = date("%H:%M")
        if clock.lastTime ~= currentTime then
            clock.text:SetText(currentTime)
            clock.lastTime = currentTime
        end
    end

    UpdateClock()
    C_Timer.NewTicker(1.0, UpdateClock)

    clock:SetScript("OnEnter", function()
        local h, m = GetGameTime()
        local servertime = string.format("%.2d:%.2d", h or 0, m or 0)
        local localtime = date("%H:%M")

        GameTooltip:ClearLines()
        GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine("Clock")
        GameTooltip:AddDoubleLine("Localtime", localtime, 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine("Servertime", servertime, 1, 1, 1, 1, 1, 1)
        GameTooltip:Show()
    end)

    clock:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    clock:Show()
end
end

do
-- Draw the mini map in a squared shape instead of a round one


local module = FT:register({
    title = "MiniMap Square",
    description = "Draw the mini map in a squared shape instead of a round one.",
    category = "World & MiniMap",
    enabled = nil,
})

module.enable = function(self)
    if MinimapBorder then
        MinimapBorder:SetTexture(nil)
    end
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
    description = "Hides unnecessary mini map buttons and allows to zoom using the mouse wheel.",
    category = "World & MiniMap",
    enabled = true,
})

module.enable = function(self)
    if GameTimeFrame then
        GameTimeFrame:Hide()
        FT.HookScript(GameTimeFrame, "OnShow", function() GameTimeFrame:Hide() end)
    end

    if MinimapBorderTop then MinimapBorderTop:Hide() end
    if MinimapToggleButton then MinimapToggleButton:Hide() end
    if MinimapZoneTextButton then MinimapZoneTextButton:SetPoint("CENTER", 7, 85) end

    -- Ctrl+Shift moves the mail, battleground and tracking (herbs, ...) icons. The
    -- game hides them until needed; the mover shows each one while it is held and
    -- then asks the game's own rule again.
    local movable = {
        { "MiniMapMailFrame", "minimap_mail", "Mail", function(f) if HasNewMail() then f:Show() else f:Hide() end end },
        { "MiniMapBattlefieldFrame", "minimap_bg", "BG", function() BattlefieldFrame_UpdateStatus() end },
        { "MiniMapTrackingFrame", "minimap_tracking", "Track", function(f) if GetTrackingTexture() then f:Show() else f:Hide() end end },
    }
    for _, entry in ipairs(movable) do
        local frame = _G[entry[1]]
        if frame then
            frame.fctRestoreShown = entry[4]
            C_Timer.After(0, function() FT.PlaceOnMinimap(frame, entry[2] .. "_r", entry[2], entry[3]) end)
        end
    end

    if MinimapZoomIn then MinimapZoomIn:Hide() end
    if MinimapZoomOut then MinimapZoomOut:Hide() end

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
