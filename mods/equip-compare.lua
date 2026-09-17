-- FostercareTweaks: mods/equip-compare.lua
-- Shows currently equipped items on tooltips while the shift key is pressed

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Equip Compare"],
    description = T["Shows currently equipped items on tooltips while the shift key is pressed."],
    expansions = { ["vanilla"] = true, ["tbc"] = nil },
    category = T["Tooltip & Items"],
    enabled = true,
})

module.enable = function(self)
    if ShoppingTooltip1 then ShoppingTooltip1:SetClampedToScreen(true) end
    if ShoppingTooltip2 then ShoppingTooltip2:SetClampedToScreen(true) end

    if ItemRefTooltip and not ItemRefTooltip.shoppingTooltips then
        ItemRefTooltip.shoppingTooltips = { ShoppingTooltip1, ShoppingTooltip2 }
    end

    local leftShiftDown = false
    local rightShiftDown = false
    local isShiftDown = false
    local lastProcessedLink = nil

    local function IsShiftActive()
        if isShiftDown then return true end
        if IsShiftKeyDown and IsShiftKeyDown() then return true end
        return false
    end

    local function HideCompare()
        if ShoppingTooltip1 and ShoppingTooltip1:IsShown() then
            ShoppingTooltip1:Hide()
        end
        if ShoppingTooltip2 and ShoppingTooltip2:IsShown() then
            ShoppingTooltip2:Hide()
        end
        if GameTooltip then
            GameTooltip.lastComparedItem = nil
        end
        if ItemRefTooltip then
            ItemRefTooltip.lastComparedItem = nil
        end
        if AtlasLootTooltip then
            AtlasLootTooltip.lastComparedItem = nil
        end
        if AtlasLootTooltip2 then
            AtlasLootTooltip2.lastComparedItem = nil
        end
    end

    local function ShowCompare(tooltip)
        if not tooltip or not tooltip:IsShown() or not IsShiftActive() then
            HideCompare()
            return
        end

        local name, link = tooltip.GetItem and tooltip:GetItem()
        link = link or tooltip.itemLink or tooltip.link or tooltip.compareLink
        if not link then
            HideCompare()
            return
        end
        tooltip.compareLink = link

        if ShoppingTooltip1 and ShoppingTooltip1:IsShown() and tooltip.lastComparedItem == link then
            return
        end

        HideCompare()
        if GameTooltip_ShowCompareItem then
            GameTooltip_ShowCompareItem(tooltip)
        elseif ShoppingTooltip1 and ShoppingTooltip1.SetHyperlinkCompareItem then
            if ShoppingTooltip1:SetHyperlinkCompareItem(link, 1, nil, tooltip) then
                ShoppingTooltip1:SetOwner(tooltip, "ANCHOR_NONE")
                ShoppingTooltip1:ClearAllPoints()
                ShoppingTooltip1:SetPoint("TOPLEFT", tooltip, "TOPRIGHT", 10, -10)
                ShoppingTooltip1:Show()
                if ShoppingTooltip2 and ShoppingTooltip2:SetHyperlinkCompareItem(link, 2, nil, tooltip) then
                    ShoppingTooltip2:SetOwner(ShoppingTooltip1, "ANCHOR_NONE")
                    ShoppingTooltip2:ClearAllPoints()
                    ShoppingTooltip2:SetPoint("TOPLEFT", ShoppingTooltip1, "TOPRIGHT", 10, 0)
                    ShoppingTooltip2:Show()
                end
            end
        end

        tooltip.lastComparedItem = link
    end

    local function HookScriptSafe(frame, script, handler)
        if not frame or not handler then return end
        if frame.HookScript then
            frame:HookScript(script, handler)
        elseif FostercareTweaks.HookScript then
            FostercareTweaks.HookScript(frame, script, handler)
        else
            local prev = frame.GetScript and frame:GetScript(script)
            frame:SetScript(script, function(a1, a2, a3, a4, a5)
                if prev then prev(a1, a2, a3, a4, a5) end
                handler(a1, a2, a3, a4, a5)
            end)
        end
    end

    local function HookTooltip(tt)
        if not tt then return end

        HookScriptSafe(tt, "OnTooltipSetItem", function(self)
            self = self or this or tt
            if IsShiftActive() then
                ShowCompare(self)
            else
                HideCompare()
            end
        end)

        HookScriptSafe(tt, "OnShow", function(self)
            self = self or this or tt
            if IsShiftActive() then
                ShowCompare(self)
            end
        end)

        HookScriptSafe(tt, "OnHide", function(self)
            self = self or this or tt
            self.compareLink = nil
            self.lastComparedItem = nil
            if self == GameTooltip then
                lastProcessedLink = nil
            end
            HideCompare()
        end)

        HookScriptSafe(tt, "OnTooltipCleared", function(self)
            self = self or this or tt
            self.compareLink = nil
            self.lastComparedItem = nil
            HideCompare()
        end)
    end

    HookTooltip(GameTooltip)
    HookTooltip(ItemRefTooltip)

    if FostercareTweaks.HookAddonOrVariable then
        FostercareTweaks.HookAddonOrVariable("AtlasLoot", function()
            if AtlasLootTooltip and not AtlasLootTooltip.shoppingTooltips then
                AtlasLootTooltip.shoppingTooltips = { ShoppingTooltip1, ShoppingTooltip2 }
            end
            if AtlasLootTooltip2 and not AtlasLootTooltip2.shoppingTooltips then
                AtlasLootTooltip2.shoppingTooltips = { ShoppingTooltip1, ShoppingTooltip2 }
            end
            HookTooltip(AtlasLootTooltip)
            HookTooltip(AtlasLootTooltip2)
        end)
    end

    local modFrame = CreateFrame("Frame", "FCTweaksEquipCompareModFrame", UIParent)

    local function OnUpdateHover()
        if not isShiftDown then
            modFrame:SetScript("OnUpdate", nil)
            lastProcessedLink = nil
            return
        end

        if not GameTooltip or not GameTooltip:IsShown() then
            lastProcessedLink = nil
            return
        end

        local name, link = GameTooltip.GetItem and GameTooltip:GetItem()
        link = link or GameTooltip.itemLink or GameTooltip.link or GameTooltip.compareLink
        if not link then
            return
        end

        if link ~= lastProcessedLink then
            lastProcessedLink = link
            ShowCompare(GameTooltip)
        end
    end

    modFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
    modFrame:SetScript("OnEvent", function()
        local key = arg1
        local state = arg2
        if key == "LSHIFT" then
            leftShiftDown = (state == 1)
        elseif key == "RSHIFT" then
            rightShiftDown = (state == 1)
        elseif key and string.find(key, "SHIFT") then
            leftShiftDown = (state == 1)
        else
            return
        end

        local shiftActive = leftShiftDown or rightShiftDown
        if shiftActive ~= isShiftDown then
            isShiftDown = shiftActive
            if isShiftDown then
                if GameTooltip and GameTooltip:IsShown() and (not ItemRefTooltip or not ItemRefTooltip:IsShown() or not MouseIsOver(ItemRefTooltip)) then
                    local name, link = GameTooltip.GetItem and GameTooltip:GetItem()
                    link = link or GameTooltip.itemLink or GameTooltip.link or GameTooltip.compareLink
                    if link then
                        lastProcessedLink = link
                    end
                    ShowCompare(GameTooltip)
                elseif ItemRefTooltip and ItemRefTooltip:IsShown() then
                    ShowCompare(ItemRefTooltip)
                elseif AtlasLootTooltip and AtlasLootTooltip:IsShown() then
                    ShowCompare(AtlasLootTooltip)
                elseif AtlasLootTooltip2 and AtlasLootTooltip2:IsShown() then
                    ShowCompare(AtlasLootTooltip2)
                end
                modFrame:SetScript("OnUpdate", OnUpdateHover)
            else
                modFrame:SetScript("OnUpdate", nil)
                lastProcessedLink = nil
                HideCompare()
            end
        end
    end)
end
