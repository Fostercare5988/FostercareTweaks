-- FostercareTweaks: mods/minimap-clock.lua
-- Adds a 24h clock to the MiniMap (Rule AP-10, Rule C3 compliant)

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["MiniMap Clock"],
    description = T["Adds a small 24h clock to the mini map."],
    expansions = { ["vanilla"] = true, ["tbc"] = nil },
    category = T["World & MiniMap"],
    enabled = true,
})

local function StartClockTicker(interval, callback)
    if C_Timer and C_Timer.NewTicker then
        return C_Timer.NewTicker(interval, callback)
    end

    local timerFrame = CreateFrame("Frame")
    local elapsedTotal = 0
    timerFrame:SetScript("OnUpdate", function()
        local elapsed = arg1 or 0
        elapsedTotal = elapsedTotal + elapsed
        if elapsedTotal >= interval then
            elapsedTotal = 0
            callback()
        end
    end)
    return timerFrame
end

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

    clock.text = clock:CreateFontString(nil, "LOW", "GameFontNormal")
    clock.text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    clock.text:SetAllPoints(clock)
    clock.text:SetFontObject(GameFontWhite)

    -- Hardware timer with minute diff caching (zero 144 FPS OnUpdate churn)
    local function UpdateClock()
        local currentTime = date("%H:%M")
        if clock.lastTime ~= currentTime then
            clock.text:SetText(currentTime)
            clock.lastTime = currentTime
        end
    end

    UpdateClock()
    StartClockTicker(1.0, UpdateClock)

    clock:SetScript("OnEnter", function()
        local h, m = GetGameTime()
        local servertime = string.format("%.2d:%.2d", h or 0, m or 0)
        local localtime = date("%H:%M")

        GameTooltip:ClearLines()
        GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine(T["Clock"])
        GameTooltip:AddDoubleLine(T["Localtime"], localtime, 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine(T["Servertime"], servertime, 1, 1, 1, 1, 1, 1)
        GameTooltip:Show()
    end)

    clock:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    clock:Show()
end
