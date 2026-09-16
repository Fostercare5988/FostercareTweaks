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

    local defaultFallbackColor = { r = 0.5, g = 0.5, b = 0.5 }

    local function Normalize(class)
        if not class then return nil end
        if FostercareTweaks.NormalizeClass then
            return FostercareTweaks.NormalizeClass(class)
        end
        return string.upper(tostring(class))
    end

    local function ResolveClassFromGUID(guid)
        if not guid or type(guid) ~= "string" or string.sub(guid, 1, 2) ~= "0x" then return nil end
        if not UnitIsPlayer or not UnitClass then return nil end
        local ok1, isP = pcall(UnitIsPlayer, guid)
        if not ok1 or not isP then return nil end
        local ok2, c1, c2 = pcall(UnitClass, guid)
        if ok2 and (c1 or c2) then
            local raw = (type(c2) == "string" and c2 ~= "" and c2) or (type(c1) == "string" and c1 ~= "" and c1)
            if raw then
                return Normalize(raw)
            end
        end
        return nil
    end

    table.insert(libnameplate.OnShow, function(plate)
        if not plate then return end
        plate.fctLastName = nil
        plate.fctClass = nil
        plate.fctIsPlayer = nil
    end)

    table.insert(libnameplate.OnUpdate, function(plate)
        if not plate or not plate.healthbar then return end

        local plateName = plate.name and plate.name.GetText and plate.name:GetText()
        if not plateName or plateName == "" then return end

        -- Reset cached identity when the frame is reused by the engine for a different unit
        if plate.fctLastName ~= plateName then
            plate.fctLastName = plateName
            plate.fctClass = nil
            plate.fctIsPlayer = nil
        end

        local class = plate.fctClass
        local isPlayer = plate.fctIsPlayer

        -- Tier 0: Direct ClassicAPI nameplate unit token ("nameplate1", "nameplate2", etc.)
        local unitToken = plate.unit or (plate.GetUnit and plate:GetUnit())
        if not class and unitToken and UnitExists(unitToken) and UnitIsPlayer(unitToken) then
            local ok, c1, c2 = pcall(UnitClass, unitToken)
            local raw = ok and ((type(c2) == "string" and c2 ~= "" and c2) or (type(c1) == "string" and c1 ~= "" and c1))
            if raw then
                local norm = Normalize(raw)
                if norm then
                    class = norm
                    isPlayer = true
                    plate.fctClass = norm
                    plate.fctIsPlayer = true
                    if FostercareTweaks.AddUnitData then
                        FostercareTweaks.AddUnitData("players", plateName, norm, UnitLevel(unitToken))
                    end
                end
            end
        end

        -- Tier 1: Active target (100% authoritative live inspection)
        if not class and UnitExists("target") and UnitName("target") == plateName and UnitIsPlayer("target") then
            local ok, c1, c2 = pcall(UnitClass, "target")
            local raw = ok and ((type(c2) == "string" and c2 ~= "" and c2) or (type(c1) == "string" and c1 ~= "" and c1))
            if raw then
                local norm = Normalize(raw)
                if norm then
                    class = norm
                    isPlayer = true
                    plate.fctClass = norm
                    plate.fctIsPlayer = true
                    if FostercareTweaks.AddUnitData then
                        FostercareTweaks.AddUnitData("players", plateName, norm, UnitLevel("target"))
                    end
                end
            end
        end

        -- Tier 2: SuperWoW / NamPower GUID via plate:GetName(1)
        if not class and plate.GetName then
            local guid = plate:GetName(1)
            local guidClass = ResolveClassFromGUID(guid)
            if guidClass then
                class = guidClass
                isPlayer = true
                plate.fctClass = guidClass
                plate.fctIsPlayer = true
                if FostercareTweaks.AddUnitData then
                    FostercareTweaks.AddUnitData("players", plateName, guidClass)
                end
            end
        end

        -- Tier 3: AutoBG / BattlegroundTargets live roster lookup
        if not class and type(AutoBG_FindPlayerClass) == "function" then
            local bgClass = AutoBG_FindPlayerClass(plateName)
            if bgClass then
                local norm = Normalize(bgClass)
                if norm then
                    class = norm
                    isPlayer = true
                    plate.fctClass = norm
                    plate.fctIsPlayer = true
                    if FostercareTweaks.AddUnitData then
                        FostercareTweaks.AddUnitData("players", plateName, norm)
                    end
                end
            end
        end

        -- Tier 4: FostercareTweaks.GetUnitData / persistent cache
        if not class and FostercareTweaks.GetUnitData then
            local c, _, _, p = FostercareTweaks.GetUnitData(plateName)
            if c and p then
                local norm = Normalize(c)
                if norm then
                    class = norm
                    isPlayer = true
                    plate.fctClass = norm
                    plate.fctIsPlayer = true
                end
            end
        end

        -- Tier 5: Apply class color to health bar
        -- Continually checks GetStatusBarColor() to immediately override C++ engine hostile red resets
        if class and isPlayer then
            local color = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]) or defaultFallbackColor
            local curR, curG, curB = plate.healthbar:GetStatusBarColor()
            if not curR or math.abs(curR - color.r) > 0.01 or math.abs(curG - color.g) > 0.01 or math.abs(curB - color.b) > 0.01 then
                plate.healthbar:SetStatusBarColor(color.r, color.g, color.b, 1)
            end
        end
    end)
end
