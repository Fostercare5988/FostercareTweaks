-- FostercareTweaks: mods/actionbar-reagents.lua
local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Reagent Counter"],
    description = T["Shows a reagent counter on action buttons."],
    category = T["Action Bar"],
    enabled = nil,
})

-- Class-specific texture fallbacks for macros and edge cases where tooltip doesn't expose reagent
local CLASS_REAGENT_FALLBACKS = {
    ["ROGUE"] = {
        ["ability_vanish"] = 5140, -- Flash Powder
        ["spell_shadow_mindsteal"] = 5530, -- Blinding Powder
    },
    ["PRIEST"] = {
        ["spell_holy_prayeroffortitude"] = 17028, -- Candle of Devotion
        ["spell_holy_prayerofshadowprotection"] = 17029, -- Sacred Candle
        ["spell_holy_prayerofspirit"] = 17029, -- Sacred Candle
        ["spell_nature_sentinal"] = 17056, -- Light Feather
    },
    ["MAGE"] = {
        ["spell_arcane_teleport"] = 17031, -- Rune of Teleportation
        ["spell_arcane_portal"] = 17032, -- Rune of Portals
        ["spell_holy_magicalsentry"] = 17020, -- Arcane Powder
        ["spell_nature_slowfall"] = 17056, -- Light Feather
    },
    ["DRUID"] = {
        ["spell_nature_giftofthewild"] = 17026, -- Wild Thornroot
        ["spell_nature_reincarnation"] = 17034, -- Ironwood Seed (Rebirth)
    },
    ["SHAMAN"] = {
        ["spell_nature_reincarnation"] = 17030, -- Ankh
        ["spell_nature_waterwalking"] = 17058, -- Fish Oil
        ["spell_nature_tranquility"] = 17057, -- Shiny Fish Scales
    },
    ["PALADIN"] = {
        ["greaterblessing"] = 21177, -- Symbol of Kings
        ["spell_nature_timestop"] = 17033, -- Symbol of Divinity
    },
    ["WARLOCK"] = {
        ["spell_shadow_scourgebuild"] = 6265, -- Soul Shard (Shadowburn)
        ["spell_shadow_summoninfernal"] = 5565, -- Infernal Stone
        ["spell_shadow_demonicfortitude"] = 16583, -- Demonic Figurine
        ["spell_shadow_soulgem"] = 6265, -- Soul Shard (Create Soulstone)
        ["spell_shadow_twilight"] = 6265, -- Soul Shard (Ritual of Summoning)
        ["spell_shadow_enslavedemon"] = 6265, -- Soul Shard (Enslave Demon)
        ["spell_shadow_summonsuccubus"] = 6265, -- Soul Shard (Summon Succubus)
        ["spell_shadow_summonvoidwalker"] = 6265, -- Soul Shard (Summon Voidwalker)
        ["spell_shadow_summonfelhunter"] = 6265, -- Soul Shard (Summon Felhunter)
        ["spell_fire_fireball02"] = 6265, -- Soul Shard (Soul Fire)
        ["inv_stone_04"] = 6265, -- Soul Shard (Create Healthstone)
        ["inv_ammo_fireprototype"] = 6265, -- Soul Shard (Create Firestone)
        ["inv_misc_gem_sapphire_01"] = 6265, -- Soul Shard (Create Spellstone)
    },
}

local ACTION_BARS = {
    "Action", "BonusAction", "MultiBarBottomLeft",
    "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight"
}

local function GetReagentForSpell(spellID)
    if not spellID then return nil end
    local query = (C_Spell and C_Spell.GetSpellReagents) or GetSpellReagents
    if query then
        local ok, reagents = pcall(query, spellID)
        if ok and reagents then
            if type(reagents) == "table" then
                local first = reagents[1]
                if type(first) == "table" then
                    return first.itemID or first.id or first[1]
                elseif type(first) == "number" then
                    return first
                end
            elseif type(reagents) == "number" then
                return reagents
            end
        end
    end
    return nil
end

module.enable = function(self)
    local reagent_slots = {}
    local reagent_counts = {}
    local _, playerClass = UnitClass("player")
    local classFallbacks = playerClass and CLASS_REAGENT_FALLBACKS[playerClass]

    local function ScanSlot(slot)
        if not HasAction(slot) then
            reagent_slots[slot] = nil
            return
        end

        local foundReagent = nil

        -- 1. Structured action & spell metadata (ClassicAPI C_Spell.GetSpellReagents)
        if GetActionInfo then
            local actionType, actionID = GetActionInfo(slot)
            if actionType == "spell" and actionID then
                foundReagent = GetReagentForSpell(actionID)
            end
        end

        -- 2. Fallback to texture inspection (works for macros and client fallbacks)
        if not foundReagent and classFallbacks then
            local texture = GetActionTexture(slot)
            if texture then
                local ltex = string.lower(texture)
                for pattern, item in pairs(classFallbacks) do
                    if string.find(ltex, pattern) then
                        foundReagent = item
                        break
                    end
                end
            end
        end

        if foundReagent then
            reagent_slots[slot] = foundReagent
            if reagent_counts[foundReagent] == nil then
                reagent_counts[foundReagent] = FostercareTweaks.GetItemCount(foundReagent)
            end
        else
            reagent_slots[slot] = nil
        end
    end

    local function UpdateButtonReagent(btn)
        local button = btn or this
        if not button or not button.GetName then return end
        local slot = ActionButton_GetPagedID(button)
        if not slot then return end

        local reagent = reagent_slots[slot]
        if reagent then
            local count = reagent_counts[reagent]
            if count == nil then
                count = FostercareTweaks.GetItemCount(reagent)
                reagent_counts[reagent] = count
            end
            local text = _G[button:GetName() .. "Count"]
            if text then
                if count > 999 then
                    text:SetText("*")
                else
                    text:SetText(tostring(count))
                end
                text:Show()
            end
        end
    end

    local function RefreshButtonTexts()
        -- Recalculate counts for all reagents currently tracked
        for item in pairs(reagent_counts) do
            reagent_counts[item] = FostercareTweaks.GetItemCount(item)
        end

        for _, prefix in ipairs(ACTION_BARS) do
            for i = 1, NUM_ACTIONBAR_BUTTONS do
                local button = _G[prefix .. "Button" .. i]
                if button then
                    local slot = ActionButton_GetPagedID(button)
                    local text = _G[button:GetName() .. "Count"]
                    if slot and text then
                        local reagent = reagent_slots[slot]
                        if reagent then
                            local count = reagent_counts[reagent] or 0
                            if count > 999 then
                                text:SetText("*")
                            else
                                text:SetText(tostring(count))
                            end
                            text:Show()
                        elseif not IsConsumableAction(slot) then
                            text:SetText("")
                        end
                    end
                end
            end
        end
    end

    local function FullScanAndUpdate()
        for slot = 1, 120 do
            ScanSlot(slot)
        end
        RefreshButtonTexts()
    end

    -- Hook Blizzard's ActionButton_UpdateCount so whenever Blizzard updates
    -- an action button (and wipes non-consumable text), our reagent count
    -- is immediately restored with zero flicker or loss!
    FostercareTweaks.hooksecurefunc("ActionButton_UpdateCount", UpdateButtonReagent)

    local reagentcounter = CreateFrame("Frame", "FCTweaksReagentCount", UIParent)
    reagentcounter:RegisterEvent("PLAYER_ENTERING_WORLD")
    reagentcounter:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    reagentcounter:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    reagentcounter:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    reagentcounter:RegisterEvent("BAG_UPDATE")
    reagentcounter:RegisterEvent("SPELLS_CHANGED")

    reagentcounter:SetScript("OnEvent", function(arg1_param, arg2_param, arg3_param)
        local ev = (type(arg1_param) == "table" and (arg2_param or event)) or (type(arg1_param) == "string" and arg1_param) or arg2_param or event
        local a1 = (type(arg1_param) == "table" and (arg3_param or _G.arg1)) or arg2_param or _G.arg1
        if ev == "BAG_UPDATE" then
            this.pendingRefresh = true
        elseif ev == "ACTIONBAR_SLOT_CHANGED" and a1 then
            ScanSlot(a1)
            this.pendingRefresh = true
        else
            this.pendingFullScan = true
        end
        this:Show()
    end)

    reagentcounter:SetScript("OnUpdate", function()
        this:Hide()
        if this.pendingFullScan then
            this.pendingFullScan = nil
            this.pendingRefresh = nil
            FullScanAndUpdate()
        elseif this.pendingRefresh then
            this.pendingRefresh = nil
            RefreshButtonTexts()
        end
    end)

    -- Hide by default so OnUpdate does not fire continuously
    reagentcounter:Hide()

    -- Immediate full scan on enable
    FullScanAndUpdate()
end
