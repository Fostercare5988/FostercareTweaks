local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/custom.lua
-- This module can be used to add your own custom code.

-- Remove the following line to activate the module:
if true then return end


local module = FT:register({
    title = "Custom Settings",
    description = "Custom code: Have a look at mods/custom.lua",
    category = nil,
    enabled = nil,
})

module.enable = function(self)
    -- Put custom user code here
end
