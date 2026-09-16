-- FostercareTweaks: mods/blue-shaman.lua
-- Changes shaman class color to blue

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Blue Shaman Class Colors"],
    description = T["Changes the class color code of shamans to blue, as known from TBC+."],
    expansions = { ["vanilla"] = true, ["tbc"] = nil },
    category = T["Social & Chat"],
    enabled = true,
})

module.enable = function(self)
    if not RAID_CLASS_COLORS then
        RAID_CLASS_COLORS = {
            ["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43, colorStr = "ffc79c6e" },
            ["MAGE"]    = { r = 0.41, g = 0.80, b = 0.94, colorStr = "ff69ccf0" },
            ["ROGUE"]   = { r = 1.00, g = 0.96, b = 0.41, colorStr = "fffff569" },
            ["DRUID"]   = { r = 1.00, g = 0.49, b = 0.04, colorStr = "ffff7d0a" },
            ["HUNTER"]  = { r = 0.67, g = 0.83, b = 0.45, colorStr = "ffabd473" },
            ["SHAMAN"]  = { r = 0.14, g = 0.35, b = 1.00, colorStr = "ff2459ff" },
            ["PRIEST"]  = { r = 1.00, g = 1.00, b = 1.00, colorStr = "ffffffff" },
            ["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79, colorStr = "ff9482c9" },
            ["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73, colorStr = "fff58cba" },
        }
    else
        if RAID_CLASS_COLORS["SHAMAN"] then
            RAID_CLASS_COLORS["SHAMAN"].r = 0.14
            RAID_CLASS_COLORS["SHAMAN"].g = 0.35
            RAID_CLASS_COLORS["SHAMAN"].b = 1.00
            RAID_CLASS_COLORS["SHAMAN"].colorStr = "ff2459ff"
        else
            RAID_CLASS_COLORS["SHAMAN"] = { r = 0.14, g = 0.35, b = 1.00, colorStr = "ff2459ff" }
        end
    end

    if not getmetatable(RAID_CLASS_COLORS) then
        local defaultClassColor = { r = 0.6, g = 0.6, b = 0.6, colorStr = "ff999999" }
        setmetatable(RAID_CLASS_COLORS, {
            __index = function(tab, key)
                return defaultClassColor
            end
        })
    end
end
