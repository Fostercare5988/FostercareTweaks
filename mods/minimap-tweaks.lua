local FT = FostercareTweaks
if not FT then return end

-- Related modules; settings remain independent.

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

    -- Ctrl+Shift moves it, like the unit frames.
    FT.RestoreFramePosition(clock, "minimap_clock")
    FT.RegisterFrameMover(clock, "minimap_clock", "Clock")

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
            FT.RestoreFramePosition(frame, entry[2])
            FT.RegisterFrameMover(frame, entry[2], entry[3])
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
