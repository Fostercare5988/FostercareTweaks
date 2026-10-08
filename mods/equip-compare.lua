local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/equip-compare.lua
-- Shows currently equipped items on tooltips while the shift key is pressed


local module = FT:register({
    title = "Equip Compare",
    description = "Shows currently equipped items on tooltips while the shift key is pressed.",
    category = "Tooltip & Items",
    enabled = true,
})

module.enable = function(self)
    if ShoppingTooltip1 then ShoppingTooltip1:SetClampedToScreen(true) end
    if ShoppingTooltip2 then ShoppingTooltip2:SetClampedToScreen(true) end

    if ItemRefTooltip and not ItemRefTooltip.shoppingTooltips then
        ItemRefTooltip.shoppingTooltips = { ShoppingTooltip1, ShoppingTooltip2 }
    end

    local leftShiftDown = IsLeftShiftKeyDown() and true or false
    local rightShiftDown = IsRightShiftKeyDown() and true or false
    local isShiftDown = leftShiftDown or rightShiftDown
    local lastProcessedLink = nil
    local hoverTicker
    local scheduled, wantedLinks = {}, {}

    local function GetTooltipLink(tooltip)
        local link
        if tooltip.GetItem then
            local name
            name, link = tooltip:GetItem()
        end
        return link or tooltip.itemLink or tooltip.link or tooltip.compareLink
    end

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

        local link = GetTooltipLink(tooltip)
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
            local slots = ShoppingTooltip1:SetHyperlinkCompareItem(link, 1, nil, tooltip)
            if slots and slots > 0 then
                ShoppingTooltip1:SetOwner(tooltip, "ANCHOR_NONE")
                ShoppingTooltip1:ClearAllPoints()
                ShoppingTooltip1:SetPoint("TOPLEFT", tooltip, "TOPRIGHT", 10, -10)
                ShoppingTooltip1:Show()
                if slots > 1 and ShoppingTooltip2 and ShoppingTooltip2:SetHyperlinkCompareItem(link, 2, nil, tooltip) > 0 then
                    ShoppingTooltip2:SetOwner(ShoppingTooltip1, "ANCHOR_NONE")
                    ShoppingTooltip2:ClearAllPoints()
                    ShoppingTooltip2:SetPoint("TOPLEFT", ShoppingTooltip1, "TOPRIGHT", 10, 0)
                    ShoppingTooltip2:Show()
                end
            end
        end

        tooltip.lastComparedItem = link
    end

    local function QueueCompare(tooltip)
        if not IsShiftActive() then wantedLinks[tooltip] = nil; HideCompare(); return end
        wantedLinks[tooltip] = GetTooltipLink(tooltip)
        if not wantedLinks[tooltip] or scheduled[tooltip] then return end
        scheduled[tooltip] = true
        -- OnTooltipSetItem fires inside the native build. Rebuilding comparison
        -- tooltips there can reenter DLL hooks. Coalesce until the next frame.
        C_Timer.After(0, function()
            scheduled[tooltip] = nil
            local expected = wantedLinks[tooltip]
            wantedLinks[tooltip] = nil
            if expected and tooltip:IsShown() and GetTooltipLink(tooltip) == expected then ShowCompare(tooltip) end
        end)
    end

    local function HookTooltip(tt)
        if not tt then return end

        FT.HookScript(tt, "OnTooltipSetItem", QueueCompare)
        FT.HookScript(tt, "OnShow", QueueCompare)

        FT.HookScript(tt, "OnHide", function(self)
            wantedLinks[self] = nil
            self.compareLink = nil
            self.lastComparedItem = nil
            if self == GameTooltip then
                lastProcessedLink = nil
            end
            HideCompare()
        end)

        FT.HookScript(tt, "OnTooltipCleared", function(self)
            wantedLinks[self] = nil
            self.compareLink = nil
            self.lastComparedItem = nil
            HideCompare()
        end)
    end

    HookTooltip(GameTooltip)
    HookTooltip(ItemRefTooltip)

    FT.HookAddonOrVariable("AtlasLoot", function()
            if AtlasLootTooltip and not AtlasLootTooltip.shoppingTooltips then
                AtlasLootTooltip.shoppingTooltips = { ShoppingTooltip1, ShoppingTooltip2 }
            end
            if AtlasLootTooltip2 and not AtlasLootTooltip2.shoppingTooltips then
                AtlasLootTooltip2.shoppingTooltips = { ShoppingTooltip1, ShoppingTooltip2 }
            end
            HookTooltip(AtlasLootTooltip)
            HookTooltip(AtlasLootTooltip2)
    end)

    local modFrame = CreateFrame("Frame", "FCTweaksEquipCompareModFrame", UIParent)

    local function UpdateHover()
        if not GameTooltip or not GameTooltip:IsShown() then
            lastProcessedLink = nil
            return
        end

        local link = GetTooltipLink(GameTooltip)
        if not link then
            return
        end

        if link ~= lastProcessedLink then
            lastProcessedLink = link
            ShowCompare(GameTooltip)
        end
    end

    local function SetHoverActive(active)
        if active and not hoverTicker then
            -- Tooltip events defer normal changes to the next frame; bounded
            -- reconciliation also supports optional addons that set link fields.
            hoverTicker = C_Timer.NewTicker(0.1, UpdateHover)
        elseif not active and hoverTicker then
            hoverTicker:Cancel()
            hoverTicker = nil
        end
    end

    modFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
    FT.SetEventHandler(modFrame, function(_, ev, key, state)
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
                    local link = GetTooltipLink(GameTooltip)
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
                SetHoverActive(true)
            else
                SetHoverActive(false)
                lastProcessedLink = nil
                HideCompare()
            end
        end
    end)
    if isShiftDown then UpdateHover(); SetHoverActive(true) end
end
