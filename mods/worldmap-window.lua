if not FostercareTweaks then return end

-- Related modules; settings remain independent.

do
-- Turns world map into a movable, scalable window

local T = FostercareTweaks.T
local HookScript = FostercareTweaks.HookScript

local module = FostercareTweaks:register({
    title = T["WorldMap Window"],
    description = T["Turns the world map into a movable window. The map can be scaled with <Ctrl> + Mousewheel."],
    expansions = { ["vanilla"] = true, ["tbc"] = true },
    category = T["World & MiniMap"],
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
    delay:SetScript("OnEvent", function()
        if Cartographer or METAMAP_TITLE then return end

        UIPanelWindows["WorldMapFrame"] = { area = "center" }

        if not this.hooked then
            this.hooked = true

            HookScript(WorldMapFrame, "OnShow", function()
                this:EnableKeyboard(false)
                this:EnableMouseWheel(true)
            end)

            HookScript(WorldMapFrame, "OnMouseWheel", function()
                local delta = _G.arg1 or 0
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

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["WorldMap Coordinates"],
    description = T["Adds coordinates to the bottom of the World Map."],
    expansions = { ["vanilla"] = true, ["tbc"] = true },
    category = T["World & MiniMap"],
    enabled = true,
})

local GetPlayerPosition = (C_Map and C_Map.GetPlayerMapPosition) or GetPlayerMapPosition

module.enable = function(self)
    local delay = CreateFrame("Frame")
    delay:RegisterEvent("PLAYER_ENTERING_WORLD")
    delay:SetScript("OnEvent", function(arg1_param)
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
                local px, py = GetPlayerPosition("player")
                if px and py and px > 0 and py > 0 then
                    local rx = math.floor(px * 1000 + 0.5) / 10
                    local ry = math.floor(py * 1000 + 0.5) / 10
                    if rx ~= player.lastX or ry ~= player.lastY then
                        player.text:SetText(string.format("|cffffcc00%s: |r%.1f / %.1f", T["Player"], rx, ry))
                        player.lastX = rx
                        player.lastY = ry
                    end
                elseif player.lastX ~= -1 then
                    player.text:SetText(string.format("|cffffcc00%s: |r%s", T["Player"], T["N/A"]))
                    player.lastX = -1
                    player.lastY = -1
                end

                if mx and my and MouseIsOver(WorldMapButton) then
                    local rx = math.floor(mx * 10 + 0.5) / 10
                    local ry = math.floor(my * 10 + 0.5) / 10
                    if rx ~= coords.lastX or ry ~= coords.lastY then
                        coords.text:SetText(string.format("|cffffcc00%s: |r%.1f / %.1f", T["Cursor"], rx, ry))
                        coords.lastX = rx
                        coords.lastY = ry
                    end
                elseif coords.lastX ~= -1 then
                    coords.text:SetText(string.format("|cffffcc00%s: |r%s", T["Cursor"], T["N/A"]))
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

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["WorldMap Class Colors"],
    description = T["Show class colored circles on world and battlefield map."],
    expansions = { ["vanilla"] = true, ["tbc"] = true },
    category = T["World & MiniMap"],
    enabled = true,
})

local function SetAllPointsOffset(frame, parent, offset)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", offset, -offset)
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -offset, offset)
end

-- Preallocate button name-to-unit mappings at load time to avoid runtime table churn
local worldmapButtons = {}
local battlefieldButtons = {}

for i = 1, 4 do
    worldmapButtons[string.format("WorldMapParty%d", i)] = string.format("party%d", i)
    battlefieldButtons[string.format("BattlefieldMinimapParty%d", i)] = string.format("party%d", i)
end
for i = 1, 40 do
    worldmapButtons[string.format("WorldMapRaid%d", i)] = string.format("raid%d", i)
    battlefieldButtons[string.format("BattlefieldMinimapRaid%d", i)] = string.format("raid%d", i)
end

local myPartyNames = {}

local function UpdateMapButtons(buttons)
    for name, unitstr in pairs(buttons) do
        local frame = _G[name]
        if frame and UnitExists(unitstr) then
            local icon = _G[name .. "Icon"]
            if icon then icon:SetTexture(nil) end

            if not frame.texture then
                frame.texture = frame:CreateTexture(nil, "OVERLAY")
                SetAllPointsOffset(frame.texture, frame, 12)
            end

            local uname = UnitName(unitstr)
            local ingroup = uname and myPartyNames[uname]

            if ingroup and frame.texture.ingroup ~= "PARTY" then
                frame.texture:SetTexture("Interface\\AddOns\\FostercareTweaks\\img\\circleparty")
                frame.texture.ingroup = "PARTY"
            elseif not ingroup and frame.texture.ingroup ~= "RAID" then
                frame.texture:SetTexture("Interface\\AddOns\\FostercareTweaks\\img\\circleraid")
                frame.texture.ingroup = "RAID"
            end

            local _, class = UnitClass(unitstr)
            if class and frame.texture.class ~= class then
                local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
                if color then
                    frame.texture:SetVertexColor(color.r, color.g, color.b)
                else
                    frame.texture:SetVertexColor(0.5, 1, 0.5)
                end
                frame.texture.class = class
            end
        end
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
        UpdateMapButtons(worldmapButtons)
    end
    if showBattlefield then
        UpdateMapButtons(battlefieldButtons)
    end
end

module.enable = function(self)
    C_Timer.NewTicker(0.2, UpdateWorldMapColors)
end
end
