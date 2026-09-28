-- FostercareTweaks: mods/nameplate-classcolor.lua
-- Changes the nameplate health bar color to class color

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Nameplate Class Colors"],
    description = T["Changes the nameplate health bar color to the class color."],
    expansions = { ["vanilla"] = true, ["tbc"] = true },
    category = T["Nameplates"],
    enabled = true,
})

module.enable = function(self)
    if ShaguPlates then return end

    local libnameplate = FostercareTweaks.libnameplate or (ShaguTweaks and ShaguTweaks.libnameplate)
    if not libnameplate then return end

    table.insert(libnameplate.OnUpdate, function(plate)
        if not plate or not plate.healthbar then return end
        local unit = FostercareTweaks.GetNameplateUnit(plate)
        if not unit or not UnitIsPlayer(unit) then return end
        local _, class = UnitClass(unit)
        local color = class and RAID_CLASS_COLORS[class]
        if not color then return end

        if plate.fctObservedGUID ~= unit or plate.fctObservedClass ~= class then
            FostercareTweaks.AddUnitData("players", UnitName(unit), class, UnitLevel(unit))
            plate.fctObservedGUID, plate.fctObservedClass = unit, class
        end

        -- The engine can restore its reaction color during a native redraw.
        local r, g, b = plate.healthbar:GetStatusBarColor()
        if not r or math.abs(r - color.r) > 0.01 or math.abs(g - color.g) > 0.01 or math.abs(b - color.b) > 0.01 then
            plate.healthbar:SetStatusBarColor(color.r, color.g, color.b, 1)
        end
    end)
end
