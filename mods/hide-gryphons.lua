-- FostercareTweaks: mods/hide-gryphons.lua
local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Hide Gryphons"],
    description = T["Hides the gryphons left and right of the action bar."],
    category = T["Action Bar"],
    enabled = nil,
})

module.enable = function(self)
    if MainMenuBarLeftEndCap then MainMenuBarLeftEndCap:Hide() end
    if MainMenuBarRightEndCap then MainMenuBarRightEndCap:Hide() end
end
