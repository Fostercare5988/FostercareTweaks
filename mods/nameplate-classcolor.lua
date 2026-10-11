local FT = FostercareTweaks
if not FT then return end
local module = FT:register({ title = "Nameplate Class Colors", category = "Nameplates",
    enabled = true, description = "Changes player nameplate health bars to their class color." })
local initialized, active

local function Reset(plate)
    plate.fctClassUnit, plate.fctCachedClass, plate.fctNextClassQuery = nil, nil, nil
    plate.fctReactionColor = nil
end

module.enable = function()
    active = FT.IsEnabled(module.title) and FT.OwnsNameplates()
    if not initialized then
        initialized = true
        table.insert(FT.libnameplate.OnShow, function(plate)
            if plate.fctClassUnit ~= plate.fctUnitGUID then Reset(plate) end
        end)
        table.insert(FT.libnameplate.OnAdded, Reset)
        table.insert(FT.libnameplate.OnRemoved, Reset)
        table.insert(FT.libnameplate.OnUpdate, function(plate, unit, now)
            if not active or not plate.healthbar then return end
            if unit ~= plate.fctClassUnit or not plate.fctNextClassQuery or now >= plate.fctNextClassQuery then
                local class
                if unit and UnitIsPlayer(unit) then local localized; localized, class = UnitClass(unit) end
                plate.fctClassUnit, plate.fctCachedClass = unit, class
                -- A class cannot change for a GUID. Retry unresolved identities
                -- slowly; avoid recurring class/name/level queries once known.
                plate.fctNextClassQuery = class and math.huge or now + 0.5
            end
            local class = plate.fctCachedClass
            local color = class and RAID_CLASS_COLORS[class]
            if not unit or not color then return end
            if plate.fctObservedGUID ~= unit or plate.fctObservedClass ~= class then
                FT.AddUnitData("players", UnitName(unit), class, UnitLevel(unit))
                plate.fctObservedGUID, plate.fctObservedClass = unit, class
            end
            local r, g, b = plate.healthbar:GetStatusBarColor()
            if math.abs(r - color.r) > 0.01 or math.abs(g - color.g) > 0.01 or math.abs(b - color.b) > 0.01 then
                local reaction = plate.fctReactionColor or {}
                reaction[1], reaction[2], reaction[3] = r, g, b
                plate.fctReactionColor = reaction
                plate.healthbar:SetStatusBarColor(color.r, color.g, color.b, 1)
            end
        end)
    end
    if not active then
        for plate in pairs(FT.libnameplate.plates) do
            if plate.fctReactionColor then plate.healthbar:SetStatusBarColor(unpack(plate.fctReactionColor)) end
            Reset(plate)
        end
    end
end
