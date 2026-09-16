-- FostercareTweaks: mods/hide-errors.lua
-- Hides and ignores Lua errors produced by broken addons

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Hide Errors"],
    description = T["Hides and ignores all Lua errors produced by broken addons."],
    expansions = { ["vanilla"] = true, ["tbc"] = true },
    category = T["General"],
    enabled = nil,
})

module.enable = function(self)
    local noop = function() end
    seterrorhandler(noop)
end
