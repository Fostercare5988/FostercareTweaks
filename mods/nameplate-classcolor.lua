local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/nameplate-classcolor.lua
-- Changes the nameplate health bar color to class color


local module = FT:register({
    title = "Nameplate Class Colors",
    description = "Changes the nameplate health bar color to the class color.",
    category = "Nameplates",
    enabled = true,
})

module.enable = function(self)
    if ShaguPlates then return end

    local libnameplate = FT.libnameplate

    table.insert(libnameplate.OnShow, function(plate)
        plate.fctClassUnit, plate.fctNextClassQuery = nil, nil
    end)

    table.insert(libnameplate.OnUpdate, function(plate)
        if not plate or not plate.healthbar then return end
        local unit = FT.GetNameplateUnit(plate)
        local now = GetTime()
        if unit ~= plate.fctClassUnit or not plate.fctNextClassQuery or now >= plate.fctNextClassQuery then
            local class
            if unit and UnitIsPlayer(unit) then
                local localized
                localized, class = UnitClass(unit)
            end
            plate.fctClassUnit, plate.fctCachedClass, plate.fctNextClassQuery = unit, class, now + 0.25
        end
        if not unit then return end
        local class = plate.fctCachedClass
        local color = class and RAID_CLASS_COLORS[class]
        if not color then return end

        if plate.fctObservedGUID ~= unit or plate.fctObservedClass ~= class then
            FT.AddUnitData("players", UnitName(unit), class, UnitLevel(unit))
            plate.fctObservedGUID, plate.fctObservedClass = unit, class
        end

        -- The engine can restore its reaction color during a native redraw.
        local r, g, b = plate.healthbar:GetStatusBarColor()
        if not r or math.abs(r - color.r) > 0.01 or math.abs(g - color.g) > 0.01 or math.abs(b - color.b) > 0.01 then
            plate.healthbar:SetStatusBarColor(color.r, color.g, color.b, 1)
        end
    end)
end
