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
-- Automatically dismounts or cancels shapeshift on spell casting attempts


local module = FT:register({
    title = "Auto Dismount",
    description = "Dismounts or leaves a form after an action reports a mount/form restriction.",
    category = "General",
    enabled = true,
})

local errors = {
    SPELL_FAILED_NOT_MOUNTED, ERR_ATTACK_MOUNTED, ERR_TAXIPLAYERALREADYMOUNTED,
    SPELL_FAILED_NOT_SHAPESHIFT, SPELL_FAILED_NO_ITEMS_WHILE_SHAPESHIFTED, SPELL_NOT_SHAPESHIFTED,
    SPELL_NOT_SHAPESHIFTED_NOSPACE, ERR_CANT_INTERACT_SHAPESHIFTED, ERR_NOT_WHILE_SHAPESHIFTED,
    ERR_NO_ITEMS_WHILE_SHAPESHIFTED, ERR_TAXIPLAYERSHAPESHIFTED, ERR_MOUNT_SHAPESHIFTED
}

local errorMap = {}
for _, err in pairs(errors) do
    if err then errorMap[err] = true end
end

module.enable = function(self)
    local dismount = CreateFrame("Frame")
    FT.dismount = dismount
    dismount:RegisterEvent("UI_ERROR_MESSAGE")
    FT.SetEventHandler(dismount, function(_, ev, msg)
        if msg == SPELL_FAILED_NOT_STANDING then
            SitOrStand()
            return
        end

        if errorMap[msg] then
            -- The required runtime cancels the actual mount/form by identity.
            -- Do not guess or cancel another aura based on a shared texture.
            Dismount()
            CancelShapeshiftForm()
        end
    end)
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

do
-- Hides and ignores Lua errors produced by broken addons


local module = FT:register({
    title = "Hide Errors",
    description = "Hides and ignores all Lua errors produced by broken addons.",
    category = "General",
    enabled = nil,
})

module.enable = function(self)
    local noop = function() end
    seterrorhandler(noop)
end
end
