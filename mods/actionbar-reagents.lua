if not FostercareTweaks then return end

-- Available casts from exact action/macro spell identity and client DBC data.
local T = FostercareTweaks.T
local module = FostercareTweaks:register({
    title = T["Reagent Counter"],
    description = T["Shows available casts for spells that consume reagents."],
    category = T["Action Bar"],
    enabled = false,
})

local ACTION_BARS = {
    "Action", "BonusAction", "MultiBarBottomLeft",
    "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight"
}

module.enable = function(self)
    local spells, counts = {}, {}
    local pending, fullScan = false, false

    local function ScanSlot(slot)
        local actionType, id = GetActionInfo(slot)
        local spellID
        if actionType == "spell" then
            spellID = id
        elseif actionType == "macro" and id then
            local _, _, macroSpellID = GetMacroSpell(id)
            spellID = macroSpellID
        end
        -- An empty reagent list is authoritative. A shared icon never supplies
        -- a reagent for a different spell, item or equipment set.
        local reagents = spellID and C_Spell.GetSpellReagents(spellID)
        spells[slot] = reagents and reagents[1] and spellID or nil
    end

    local function UpdateButtonReagent(button)
        button = button or this
        if not button then return end
        local slot = ActionButton_GetPagedID(button)
        local spellID = slot and spells[slot]
        if not spellID then return end
        local count = counts[spellID]
        if count == nil then
            count = C_Spell.GetSpellCastCount(spellID)
            counts[spellID] = count
        end
        local text = _G[button:GetName() .. "Count"]
        if text then
            text:SetText(count > 999 and "*" or tostring(count))
            text:Show()
        end
    end

    local function Refresh()
        pending = false
        if fullScan then
            fullScan = false
            for slot = 1, 120 do ScanSlot(slot) end
        end
        table.wipe(counts)
        for _, prefix in ipairs(ACTION_BARS) do
            for i = 1, NUM_ACTIONBAR_BUTTONS do
                local button = _G[prefix .. "Button" .. i]
                if button then
                    -- Native code restores item stack counts/clears old labels;
                    -- the posthook decorates only slots with verified reagents.
                    -- 1.12 FrameXML reads global this even with a button argument.
                    local previousThis = this
                    this = button
                    ActionButton_UpdateCount(button)
                    this = previousThis
                end
            end
        end
    end

    hooksecurefunc("ActionButton_UpdateCount", UpdateButtonReagent)
    local controller = CreateFrame("Frame", "FCTweaksReagentCount", UIParent)
    for _, ev in ipairs({"PLAYER_ENTERING_WORLD", "ACTIONBAR_SLOT_CHANGED",
        "ACTIONBAR_PAGE_CHANGED", "UPDATE_BONUS_ACTIONBAR", "BAG_UPDATE",
        "SPELLS_CHANGED", "UPDATE_MACROS", "MODIFIER_STATE_CHANGED", "PLAYER_TARGET_CHANGED"}) do
        controller:RegisterEvent(ev)
    end
    controller:SetScript("OnEvent", function(frame, ev, slot)
        ev, slot = ev or event, slot or arg1
        if ev == "ACTIONBAR_SLOT_CHANGED" and type(slot) == "number" and slot > 0 then
            ScanSlot(slot)
        elseif ev ~= "BAG_UPDATE" then
            fullScan = true
        end
        if not pending then
            pending = true
            C_Timer.After(0.01, Refresh)
        end
    end)
    fullScan = true
    Refresh()
end
