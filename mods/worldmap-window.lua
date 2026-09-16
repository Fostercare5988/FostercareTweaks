-- FostercareTweaks: mods/worldmap-window.lua
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
                WorldMapFrame:SetScale(0.85)
            end)

            HookScript(WorldMapFrame, "OnMouseWheel", function()
                local delta = _G.arg1 or 0
                if IsShiftKeyDown() then
                    WorldMapFrame:SetAlpha(WorldMapFrame:GetAlpha() + delta / 10)
                elseif IsControlKeyDown() then
                    WorldMapFrame:SetScale(WorldMapFrame:GetScale() + delta / 10)
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
