local FT = FostercareTweaks
if not FT then return end

-- Ctrl+Shift moves your own cast bar, which the action bars can cover.
-- The game's cast bar keeps doing the casting; only its position is saved.
local module = FT:register({
    title = "Movable Cast Bar", category = "Unit Frames", always = true,
    description = "Hold Ctrl+Shift to move your own cast bar.",
})

local KEY = "player_castbar"
local saved

local function Place() if saved then FT.RestoreFramePosition(CastingBarFrame, KEY) end end

module.enable = function()
    saved = FT.RestoreFramePosition(CastingBarFrame, KEY)
    -- The game re-anchors the bar whenever it lays out the screen.
    FT.hooksecurefunc("UIParent_ManageFramePositions", Place)
    -- Shown while Ctrl+Shift is held so it can be grabbed; then the game's own rule.
    CastingBarFrame.fctRestoreShown = function(bar)
        if not (bar.casting or bar.channeling or bar.fadeOut) then bar:Hide() end
    end
    FT.RegisterFrameMover(CastingBarFrame, KEY, "Cast Bar", nil, function() saved = true end)
end
