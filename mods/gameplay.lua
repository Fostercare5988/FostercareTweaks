local FT = FostercareTweaks
if not FT then return end

do
-- Reversible Blizzard stance bar suppression for stealth, stances and forms.

local module = FT:register({
    title = "Hide Stealth / Stance Bar",
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
    enabled = true,
})

local stancedance
module.apply = function(self, on)
    local _, playerClass = UnitClass("player")
    if playerClass ~= "WARRIOR" and playerClass ~= "DRUID" then return end
    if not stancedance then
        if not on then return end
        stancedance = CreateFrame("Frame", "FCTweaksStancedance")
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
    if on then stancedance:RegisterEvent("UI_ERROR_MESSAGE") else stancedance:UnregisterEvent("UI_ERROR_MESSAGE") end
end

module.enable = function() module:apply(true) end
end
