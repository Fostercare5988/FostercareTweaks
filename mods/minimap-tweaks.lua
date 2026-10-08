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
    clock:SetPoint("BOTTOM", MinimapCluster, "BOTTOM", 8, 18)
    clock:SetWidth(50)
    clock:SetHeight(23)
    clock:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    clock:SetBackdropBorderColor(0.9, 0.8, 0.5, 1)
    clock:SetBackdropColor(0.4, 0.4, 0.4, 1)
    clock:EnableMouse(true)

    clock.text = clock:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    clock.text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    clock.text:SetAllPoints(clock)
    clock.text:SetFontObject(GameFontWhite)

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
