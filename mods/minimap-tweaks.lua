-- FostercareTweaks: mods/minimap-tweaks.lua
-- Hides unnecessary minimap buttons and allows mouse wheel zooming

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["MiniMap Tweaks"],
    description = T["Hides unnecessary mini map buttons and allows to zoom using the mouse wheel."],
    expansions = { ["vanilla"] = true, ["tbc"] = true },
    category = T["World & MiniMap"],
    enabled = true,
})

module.enable = function(self)
    if GameTimeFrame then
        GameTimeFrame:Hide()
        GameTimeFrame:SetScript("OnShow", function() this:Hide() end)
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
