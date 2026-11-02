local FT = FostercareTweaks
if not FT then return end

-- Ctrl+Shift moves your own cast bar, which the action bars can cover.
-- The game's cast bar keeps doing the casting; only its position is saved.
local module = FT:register({
    title = "Movable Cast Bar", always = true,
})

local KEY = "player_castbar"
local saved

local function Place() if saved then FT.RestoreFramePosition(CastingBarFrame, KEY) end end

module.enable = function()
    saved = FT.RestoreFramePosition(CastingBarFrame, KEY)
    -- The game re-anchors the bar whenever it lays out the screen.
    hooksecurefunc("UIParent_ManageFramePositions", Place)
    -- Shown while Ctrl+Shift is held so it can be grabbed; then the game's own rule.
    CastingBarFrame.fctRestoreShown = function(bar)
        if not (bar.casting or bar.channeling or bar.fadeOut) then bar:Hide() end
    end
    FT.RegisterFrameMover(CastingBarFrame, KEY, "Cast Bar", nil, function() saved = true end,
        function(restored) saved = restored; if not saved then UIParent_ManageFramePositions() end end)
end

-- Takes effect after a reload (the settings switch asks for one). The target
-- bar reads the same setting in mods/target-castbar.lua.
local borderless = FT:register({
    title = "Borderless Castbars",
})
borderless.enable = function()
    CastingBarBorder:SetTexture(nil)
    CastingBarFlash:SetTexture(nil)
end
