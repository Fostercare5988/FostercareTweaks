local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/blue-shaman.lua
-- Changes shaman class color to blue

local module = FT:register({
    title = "Blue Shaman Class Colors",
    enabled = true,
})

-- Native class colors are guaranteed. Mutate only Shaman so table identity
-- and other classes' custom colors/methods stay intact. Names already drawn
-- keep their color until they are drawn again.
local color = RAID_CLASS_COLORS.SHAMAN
local stock = { color.r, color.g, color.b, color.colorStr }
module.apply = function(self, on)
    if on then color.r, color.g, color.b, color.colorStr = 0.14, 0.35, 1, "ff2459ff"
    else color.r, color.g, color.b, color.colorStr = stock[1], stock[2], stock[3], stock[4] end
end

module.enable = function() module:apply(true) end
