local FT = FostercareTweaks
if not FT then return end

-- Related modules; settings remain independent.


do
-- Suppress only Blizzard's player cast bar; its event lifecycle stays intact.

local module = FT:register({
    title = "Hide Default Cast Bar",
    description = "Hide Blizzard's player cast bar without affecting custom cast bars.",
    category = "General",
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
        FT.HookScript(CastingBarFrame, "OnEvent", function()
            if suppressed then CastingBarFrame:SetAlpha(0) end
        end)
        hooked = true
    end

    CastingBarFrame:SetAlpha(suppressed and 0 or 1)
end

module.enable = function(self)
    self:apply(true)
end
end

do
-- Reversible Blizzard stance bar suppression for stealth, stances and forms.

local module = FT:register({
    title = "Hide Stealth / Stance Bar",
    description = "Hide Blizzard's stealth, stance and shapeshift bar.",
    category = "General",
    enabled = false,
})

local suppressed = false
local hooked = false

local function SuppressBar()
    if suppressed and ShapeshiftBarFrame then ShapeshiftBarFrame:Hide() end
end

module.apply = function(self, enabled)
    suppressed = enabled and true or false
    if suppressed and not hooked then
        hooksecurefunc("ShapeshiftBar_Update", SuppressBar)
        hooksecurefunc("UIParent_ManageFramePositions", SuppressBar)
        hooked = true
    end

    if suppressed then
        SuppressBar()
    elseif ShapeshiftBar_Update then
        -- Let FrameXML determine visibility and button state from current forms.
        ShapeshiftBar_Update()
    end
end

module.enable = function(self)
    self:apply(true)
end
end

do
-- Automatically switches to the required warrior or druid stance on spell cast


local module = FT:register({
    title = "Auto Stance",
    description = "Automatically switch to the required warrior or druid stance on spell cast.",
    category = "General",
    enabled = true,
})

module.enable = function(self)
    local _, playerClass = UnitClass("player")
    if playerClass ~= "WARRIOR" and playerClass ~= "DRUID" then return end

    local stancedance = CreateFrame("Frame", "FCTweaksStancedance")
    stancedance:RegisterEvent("UI_ERROR_MESSAGE")
    FT.SetEventHandler(stancedance, function(_, ev, msg)
        -- No structured required-form accessor is exposed by this runtime.
        -- Match the exact native error template, never unrelated message text.
        local stances = FT.cmatch(msg, SPELL_FAILED_ONLY_SHAPESHIFT)
        if not stances then return end
        for stance in string.gmatch(stances, "([^,]+)") do
            local name = string.match(stance, "^%s*(.-)%s*$")
            local usable = C_Spell.IsSpellUsable(name)
            if usable then CastSpellByName(name); return end
        end
    end)
end
end
