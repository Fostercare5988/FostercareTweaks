local FT = FostercareTweaks
if not FT then return end

-- How many casts the reagents you carry allow, on each action button whose
-- spell uses reagents. ClassicAPI answers per slot: C_ActionBar.GetSpell (the
-- spell of a spell slot, or the spell a macro's button shows), IsConsumableSpell
-- (it uses reagents) and C_Spell.GetSpellCastCount (the count).
local module = FT:register({
    title = "Reagent Counter",
    enabled = false,
})

local ACTION_BARS = {
    "Action", "BonusAction", "MultiBarBottomLeft",
    "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight"
}

local buttons, controller
local active, pending, all = false, false, false

-- Runs after the game's ActionButton_UpdateCount, which redraws a button
-- when its slot or page changes; an item slot keeps the game's count.
local function UpdateButtonReagent(button)
    if not active then return end
    button = button or this
    local slot = button and ActionButton_GetPagedID(button)
    if not slot then return end
    local spellID = not IsItemAction(slot) and C_ActionBar.GetSpell(slot) or 0
    button.fctReagentSpell = spellID
    if spellID == 0 or not IsConsumableSpell(spellID) then return end
    local text = button.fctCountText
    if text == nil then text = _G[button:GetName() .. "Count"] or false; button.fctCountText = text end
    if text then
        local count = C_Spell.GetSpellCastCount(spellID)
        text:SetText(count > 999 and "*" or tostring(count))
        text:Show()
    end
end

-- Every button, or (macrosOnly) the macro buttons whose spell changed.
local function UpdateButtons(list, macrosOnly)
    for _, button in ipairs(list) do
        local slot = ActionButton_GetPagedID(button)
        if not macrosOnly or (GetActionInfo(slot) == "macro"
            and C_ActionBar.GetSpell(slot) ~= button.fctReagentSpell) then
            -- FrameXML reads the global this.
            local previousThis = this
            this = button
            ActionButton_UpdateCount(button)
            this = previousThis
        end
    end
end

local function Refresh()
    pending = false
    local macrosOnly = not all
    all = false
    UpdateButtons(buttons, macrosOnly)
    local extra = FT.ActionBars and FT.ActionBars:GetExtraButtons()
    if extra then UpdateButtons(extra, macrosOnly) end
end

-- Bags change the counts and an edit can change a macro; modifiers and
-- targets change only which spell a macro shows.
local EVENTS = { "BAG_UPDATE_DELAYED", "UPDATE_MACROS", "MODIFIER_STATE_CHANGED", "PLAYER_TARGET_CHANGED" }

-- Off leaves the game's own counts: its hook stands aside and the buttons redraw.
module.apply = function(self, on)
    if not buttons then
        if not on then return end
        buttons = {}
        for _, prefix in ipairs(ACTION_BARS) do
            for i = 1, NUM_ACTIONBAR_BUTTONS do
                local button = _G[prefix .. "Button" .. i]
                if button then buttons[#buttons + 1] = button end
            end
        end
        hooksecurefunc("ActionButton_UpdateCount", UpdateButtonReagent)
        controller = CreateFrame("Frame", "FCTweaksReagentCount", UIParent)
        FT.SetEventHandler(controller, function(_, ev)
            if ev ~= "MODIFIER_STATE_CHANGED" and ev ~= "PLAYER_TARGET_CHANGED" then all = true end
            if not pending then
                pending = true
                C_Timer.After(0.01, Refresh)
            end
        end)
    end
    active = on and true or false
    for _, ev in ipairs(EVENTS) do
        if active then controller:RegisterEvent(ev) else controller:UnregisterEvent(ev) end
    end
    all = true
    Refresh()
end

module.enable = function() module:apply(true) end
