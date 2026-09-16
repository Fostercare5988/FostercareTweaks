-- FostercareTweaks: mods/minimap-square.lua
-- Draw the mini map in a squared shape instead of a round one

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["MiniMap Square"],
    description = T["Draw the mini map in a squared shape instead of a round one."],
    expansions = { ["vanilla"] = true, ["tbc"] = true },
    category = T["World & MiniMap"],
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
