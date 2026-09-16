-- FostercareTweaks: mods/castbar-uninterruptible.lua
-- Configuration toggle for uninterruptible castbar styling (Rule AP-10, Rule C3 compliant)

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Uninterruptible Castbars"],
    description = T["Changes castbar color to silver for spells that cannot be interrupted (target and nameplates)."],
    category = T["Unit Frames"],
    enabled = true,
})
