-- FostercareTweaks: mods/worldmap-coordinates.lua
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
