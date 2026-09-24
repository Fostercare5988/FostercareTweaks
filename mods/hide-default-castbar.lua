-- Suppress only Blizzard's player cast bar; its event lifecycle stays intact.
local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Hide Default Cast Bar"],
    description = T["Hide Blizzard's player cast bar without affecting custom cast bars."],
    category = T["General"],
    enabled = false,
})

local suppressed = false
local hooked = false

module.apply = function(self, enabled)
    suppressed = enabled and true or false
    if not CastingBarFrame then return end

    if suppressed and not hooked then
        -- Blizzard's cast handlers use IsShown() and OnUpdate to finish casts.
        -- Keeping the frame shown and its events registered preserves that state.
        FostercareTweaks.HookScript(CastingBarFrame, "OnEvent", function()
            if suppressed then CastingBarFrame:SetAlpha(0) end
        end)
        hooked = true
    end

    CastingBarFrame:SetAlpha(suppressed and 0 or 1)
end

module.enable = function(self)
    self:apply(true)
end
