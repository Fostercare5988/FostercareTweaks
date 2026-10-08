local FT = FostercareTweaks
if not FT then return end

-- Related modules; settings remain independent.

do
-- Turns world map into a movable, scalable window

local HookScript = FT.HookScript

local module = FT:register({
    title = "WorldMap Window",
    description = "Turns the world map into a movable window. The map can be scaled with <Ctrl> + Mousewheel.",
    category = "World & MiniMap",
    enabled = true,
})

module.enable = function(self)
    table.insert(UISpecialFrames, "WorldMapFrame")

    function _G.ToggleWorldMap()
        if WorldMapFrame:IsShown() then
            WorldMapFrame:Hide()
        else
            WorldMapFrame:Show()
        end
    end

    local delay = CreateFrame("Frame")
    delay:RegisterEvent("PLAYER_ENTERING_WORLD")
    FT.SetEventHandler(delay, function(self)
        if Cartographer or METAMAP_TITLE then return end

        UIPanelWindows["WorldMapFrame"] = { area = "center" }

        if not self.hooked then
            self.hooked = true

            HookScript(WorldMapFrame, "OnShow", function(frame)
                frame:EnableKeyboard(false)
                frame:EnableMouseWheel(true)
            end)

            HookScript(WorldMapFrame, "OnMouseWheel", function(_, delta)
                delta = delta or 0
                if IsShiftKeyDown() then
                    WorldMapFrame:SetAlpha(math.max(0.2, math.min(1, WorldMapFrame:GetAlpha() + delta / 10)))
                elseif IsControlKeyDown() then
                    WorldMapFrame:SetScale(math.max(0.3, math.min(1.5, WorldMapFrame:GetScale() + delta / 10)))
                end
            end)

            HookScript(WorldMapFrame, "OnMouseDown", function()
                WorldMapFrame:StartMoving()
            end)

            HookScript(WorldMapFrame, "OnMouseUp", function()
                WorldMapFrame:StopMovingOrSizing()
            end)
        end

        WorldMapFrame:SetMovable(true)
        WorldMapFrame:EnableMouse(true)
        WorldMapFrame:SetScale(0.85)
        WorldMapFrame:ClearAllPoints()
        WorldMapFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
        WorldMapFrame:SetWidth(WorldMapButton:GetWidth() + 15)
        WorldMapFrame:SetHeight(WorldMapButton:GetHeight() + 55)

        if BlackoutWorld then
            BlackoutWorld:Hide()
        end
    end)
end
end

do
-- Adds player and cursor coordinates to the World Map (Rule AP-10, Rule C3, Rule C12 compliant)


local module = FT:register({
    title = "WorldMap Coordinates",
    description = "Adds coordinates to the bottom of the World Map.",
    category = "World & MiniMap",
    enabled = true,
})

module.enable = function(self)
    local mapAreaIDs = C_Map.GetMapAreaIDs()
    local mapIDsByName = {}
    for _, mapID in pairs(mapAreaIDs) do
        local name = C_Map.GetAreaInfo(mapID)
        if name then mapIDsByName[name] = mapID end
    end
    for _, map in ipairs(C_Map.GetMapChildrenInfo(C_Map.GetFallbackWorldMapID())) do
        mapIDsByName[map.name] = map.mapID
    end

    local function GetPlayerPosition()
        local mapName = GetMapInfo()
        local mapID = mapName and mapAreaIDs[mapName]
        if not mapID then
            -- Continents have no area ID; some city texture folders differ
            -- from their DBC names. Resolve the displayed selection by name.
            local continent = GetCurrentMapContinent()
            if continent > 0 then
                local zone = GetCurrentMapZone()
                local name
                if zone > 0 then
                    name = select(zone, GetMapZones(continent))
                else
                    name = select(continent, GetMapContinents())
                end
                mapID = name and mapIDsByName[name]
            end
        end
        if not mapID then return end
        local position = C_Map.GetPlayerMapPosition(mapID, "player")
        if position then return position.x, position.y end
    end

    local delay = CreateFrame("Frame")
    delay:RegisterEvent("PLAYER_ENTERING_WORLD")
    FT.SetEventHandler(delay, function(self)
        if Cartographer or METAMAP_TITLE then return end

        if not WorldMapButton.coords then
            local coords = CreateFrame("Frame", "FCTweaksWorldMapCursorCoords", WorldMapButton)
            coords.text = coords:CreateFontString(nil, "OVERLAY")
            coords.text:SetPoint("BOTTOMLEFT", WorldMapButton, "BOTTOMLEFT", 3, -21)
            coords.text:SetFontObject(GameFontWhite)
            coords.text:SetTextColor(1, 1, 1)
            coords.text:SetJustifyH("RIGHT")

            if Gatherer_WorldMapDisplay then
                coords.text:SetPoint("LEFT", Gatherer_WorldMapDisplay, "RIGHT", 3, -21)
            end

            local player = CreateFrame("Frame", "FCTweaksWorldMapPlayerCoords", WorldMapButton)
            player.text = player:CreateFontString(nil, "OVERLAY")
            player.text:SetPoint("BOTTOMRIGHT", WorldMapButton, "BOTTOMRIGHT", -3, -21)
            player.text:SetFontObject(GameFontWhite)
            player.text:SetTextColor(1, 1, 1)
            player.text:SetJustifyH("RIGHT")

            WorldMapButton.coords = coords
            WorldMapButton.player = player

            local elapsed = 0
            coords:SetScript("OnUpdate", function()
                -- Immediate short-circuit: do zero work when WorldMap is not visible
                if not WorldMapButton:IsVisible() then return end

                elapsed = elapsed + (arg1 or 0)
                if elapsed < 0.1 then return end
                elapsed = 0

                local width  = WorldMapButton:GetWidth()
                local height = WorldMapButton:GetHeight()
                local mx, my = WorldMapButton:GetCenter()
                local scale  = WorldMapButton:GetEffectiveScale()
                local x, y   = GetCursorPosition()

                if mx and my and scale and scale > 0 and width > 0 and height > 0 then
                    mx = (((x / scale) - (mx - width / 2)) / width) * 100
                    my = (((my + height / 2) - (y / scale)) / height) * 100
                end

                -- Coordinate diff caching to eliminate font string layout and formatting churn
                local px, py = GetPlayerPosition()
                if px and py then
                    local rx = math.floor(px * 1000 + 0.5) / 10
                    local ry = math.floor(py * 1000 + 0.5) / 10
                    if rx ~= player.lastX or ry ~= player.lastY then
                        player.text:SetText(string.format("|cffffcc00%s: |r%.1f / %.1f", "Player", rx, ry))
                        player.lastX = rx
                        player.lastY = ry
                    end
                elseif player.lastX ~= -1 then
                    player.text:SetText(string.format("|cffffcc00%s: |r%s", "Player", "N/A"))
                    player.lastX = -1
                    player.lastY = -1
                end

                if mx and my and MouseIsOver(WorldMapButton) then
                    local rx = math.floor(mx * 10 + 0.5) / 10
                    local ry = math.floor(my * 10 + 0.5) / 10
                    if rx ~= coords.lastX or ry ~= coords.lastY then
                        coords.text:SetText(string.format("|cffffcc00%s: |r%.1f / %.1f", "Cursor", rx, ry))
                        coords.lastX = rx
                        coords.lastY = ry
                    end
                elseif coords.lastX ~= -1 then
                    coords.text:SetText(string.format("|cffffcc00%s: |r%s", "Cursor", "N/A"))
                    coords.lastX = -1
                    coords.lastY = -1
                end
            end)
        end
    end)
end
end

do
-- Show class colored circles on world and battlefield map (Rule AP-10, Rule C3 compliant)


do
local module = FT:register({
    title = "WorldMap Class Colors",
    description = "Show class colored circles and tooltips on world and battlefield map.",
    category = "World & MiniMap",
    enabled = true,
})

local myPartyNames = {}

local function GetUnitClassToken(unit, name)
    if unit and UnitExists(unit) then
        local _, class = UnitClass(unit)
        local token = FT.NormalizeClass(class)
        if token and RAID_CLASS_COLORS[token] then return token end
    end
    local raidIndex = unit and tonumber(string.match(unit, "^raid(%d+)$"))
    if raidIndex then
        local _, _, _, _, localized, token = GetRaidRosterInfo(raidIndex)
        token = FT.NormalizeClass(token or localized)
        if token and RAID_CLASS_COLORS[token] then return token end
    end
    name = name or (unit and UnitName(unit))
    local token = FT.GetUnitData(name)
    if token and RAID_CLASS_COLORS[token] then return token end
end

local function UpdateButton(frame, defaultUnit)
    if not frame then return end
    if not frame:IsShown() then
        if frame.texture then frame.texture:Hide() end
        return
    end

    local unit = frame.unit or defaultUnit
    local name = frame.name or (unit and UnitExists(unit) and UnitName(unit))
    if not unit and not name then
        if frame.texture then frame.texture:Hide() end
        return
    end

    local icon = _G[frame:GetName() .. "Icon"]
    if icon then icon:SetTexture(nil) end

    if not frame.texture then
        frame.texture = frame:CreateTexture(nil, "OVERLAY")
        -- Keep the native hover area, with a smaller dot centered inside it.
        frame.texture:SetPoint("CENTER", frame, "CENTER", 0, 0)
        frame.texture:SetWidth(frame:GetWidth() / 2)
        frame.texture:SetHeight(frame:GetHeight() / 2)
    end
    frame.texture:Show()

    local ingroup = name and myPartyNames[name]
    if ingroup and frame.texture.ingroup ~= "PARTY" then
        frame.texture:SetTexture("Interface\\AddOns\\FostercareTweaks\\img\\circleparty")
        frame.texture.ingroup = "PARTY"
    elseif not ingroup and frame.texture.ingroup ~= "RAID" then
        frame.texture:SetTexture("Interface\\AddOns\\FostercareTweaks\\img\\circleraid")
        frame.texture.ingroup = "RAID"
    end

    local class = GetUnitClassToken(unit, name)
    if class then
        local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then
            frame.texture:SetVertexColor(color.r, color.g, color.b)
        else
            frame.texture:SetVertexColor(0.5, 1, 0.5)
        end
    else
        frame.texture:SetVertexColor(0.5, 1, 0.5)
    end
end

local function UpdateGroupButtons(prefix)
    local maxParty = MAX_PARTY_MEMBERS or 4
    for i = 1, maxParty do
        local btn = _G[prefix .. "Party" .. i]
        if btn then UpdateButton(btn, "party" .. i) end
    end
    local maxRaid = MAX_RAID_MEMBERS or 40
    for i = 1, maxRaid do
        local btn = _G[prefix .. "Raid" .. i]
        if btn then UpdateButton(btn, nil) end
    end
end

local function UpdateWorldMapColors()
    local showWorld = WorldMapFrame and WorldMapFrame:IsShown()
    local showBattlefield = BattlefieldMinimap and BattlefieldMinimap:IsShown()

    -- Skip roster/style work while both maps are closed.
    if not showWorld and not showBattlefield then
        return
    end

    -- Pre-calculate party roster names once per tick for O(1) membership lookups
    table.wipe(myPartyNames)

    for i = 1, 4 do
        local pname = UnitName("party" .. i)
        if pname then myPartyNames[pname] = true end
    end
    local playerName = UnitName("player")
    if playerName then myPartyNames[playerName] = true end

    if showWorld then
        UpdateGroupButtons("WorldMap")
    end
    if showBattlefield then
        UpdateGroupButtons("BattlefieldMinimap")
    end
end

local hooksInstalled = false
local function EnsureTooltipHooks()
    if hooksInstalled then return end
    hooksInstalled = true

    if WorldMapUnit_OnEnter then
        FT.hooksecurefunc("WorldMapUnit_OnEnter", function()
            if not WorldMapTooltip or not WorldMapTooltip:IsShown() then return end
            local lines = {}
            if WorldMapPlayer and WorldMapPlayer:IsVisible() and MouseIsOver(WorldMapPlayer) then
                local pName = UnitName("player")
                local pClass = GetUnitClassToken("player", pName)
                local color = pClass and RAID_CLASS_COLORS and RAID_CLASS_COLORS[pClass]
                local hex = color and FT.rgbhex and FT.rgbhex(color)
                table.insert(lines, (hex or "") .. pName .. (hex and "|r" or ""))
            end
            local maxParty = MAX_PARTY_MEMBERS or 4
            for i = 1, maxParty do
                local btn = _G["WorldMapParty" .. i]
                if btn and btn:IsVisible() and MouseIsOver(btn) then
                    local u = btn.unit or ("party" .. i)
                    local uName = UnitName(u)
                    if uName then
                        local uClass = GetUnitClassToken(u, uName)
                        local color = uClass and RAID_CLASS_COLORS and RAID_CLASS_COLORS[uClass]
                        local hex = color and FT.rgbhex and FT.rgbhex(color)
                        table.insert(lines, (hex or "") .. uName .. (hex and "|r" or ""))
                    end
                end
            end
            local maxRaid = MAX_RAID_MEMBERS or 40
            for i = 1, maxRaid do
                local btn = _G["WorldMapRaid" .. i]
                if btn and btn:IsVisible() and MouseIsOver(btn) then
                    local u = btn.unit
                    local uName = btn.name or (u and UnitName(u))
                    if uName then
                        local uClass = GetUnitClassToken(u, uName)
                        local color = uClass and RAID_CLASS_COLORS and RAID_CLASS_COLORS[uClass]
                        local hex = color and FT.rgbhex and FT.rgbhex(color)
                        table.insert(lines, (hex or "") .. uName .. (hex and "|r" or ""))
                    end
                end
            end
            if #lines > 0 then
                WorldMapTooltip:SetText(table.concat(lines, "\n"))
                WorldMapTooltip:Show()
            end
        end)
    end
end

module.enable = function(self)
    EnsureTooltipHooks()
    C_Timer.NewTicker(0.2, UpdateWorldMapColors)
end
end
end
