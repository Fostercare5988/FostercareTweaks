local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/blue-shaman.lua
-- Changes shaman class color to blue


local module = FT:register({
    title = "Blue Shaman Class Colors",
    description = "Changes the class color code of shamans to blue, as known from TBC+.",
    category = "Social & Chat",
    enabled = true,
})

module.enable = function()
    -- Native class colors are guaranteed. Mutate only Shaman so table identity
    -- and other classes' custom colors/methods stay intact.
    local color = RAID_CLASS_COLORS.SHAMAN
    color.r, color.g, color.b, color.colorStr = 0.14, 0.35, 1, "ff2459ff"
end
