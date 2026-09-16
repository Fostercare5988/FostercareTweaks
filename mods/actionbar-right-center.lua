-- FostercareTweaks: mods/actionbar-right-center.lua
local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Center Vertical Actionbar"],
    description = T["Center the vertical actionbar on the right side."],
    category = T["Action Bar"],
    enabled = nil,
})

module.enable = function(self)
    if MultiBarRight then
        MultiBarRight:ClearAllPoints()
        MultiBarRight:SetPoint("RIGHT", UIParent, "RIGHT", 0, -16)
    end
end
