local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/equip-compare.lua
-- Shows currently equipped items on tooltips while the shift key is pressed.
-- ClassicAPI fires OnTooltipSetItem whenever a tooltip's item is set, so a new
-- item under the cursor reaches us without watching the tooltip.

local module = FT:register({
    title = "Equip Compare",
    always = true,
})

module.enable = function(self)
    ShoppingTooltip1:SetClampedToScreen(true)
    ShoppingTooltip2:SetClampedToScreen(true)

    local leftShiftDown = IsLeftShiftKeyDown() and true or false
    local rightShiftDown = IsRightShiftKeyDown() and true or false
    local isShiftDown = leftShiftDown or rightShiftDown
    -- Tooltips that compare, in the order a Shift press looks at them.
    local hooked = {}
    local pending, wantedLinks = false, {}

    local function GetTooltipLink(tooltip)
        local _, link = tooltip:GetItem()
        return link or tooltip.itemLink or tooltip.link or tooltip.compareLink
    end

    local function HideCompare()
        if ShoppingTooltip1:IsShown() then ShoppingTooltip1:Hide() end
        if ShoppingTooltip2:IsShown() then ShoppingTooltip2:Hide() end
        for _, tooltip in ipairs(hooked) do tooltip.lastComparedItem = nil end
    end

    local function ShowCompare(tooltip)
        if not tooltip:IsShown() or not (isShiftDown or IsShiftKeyDown()) then
            HideCompare()
            return
        end
        local link = GetTooltipLink(tooltip)
        if not link then
            HideCompare()
            return
        end
        tooltip.compareLink = link
        if ShoppingTooltip1:IsShown() and tooltip.lastComparedItem == link then return end
        HideCompare()
        -- ClassicAPI's bundled GameTooltip_ShowCompareItem fills and places both shopping tooltips.
        GameTooltip_ShowCompareItem(tooltip)
        tooltip.lastComparedItem = link
    end

    -- Next frame: each tooltip still showing the item it asked about compares it.
    local function FlushCompare()
        pending = false
        for _, tooltip in ipairs(hooked) do
            local expected = wantedLinks[tooltip]
            if expected then
                wantedLinks[tooltip] = nil
                if tooltip:IsShown() and GetTooltipLink(tooltip) == expected then ShowCompare(tooltip) end
            end
        end
    end

    local function QueueCompare(tooltip)
        if not (isShiftDown or IsShiftKeyDown()) then wantedLinks[tooltip] = nil; HideCompare(); return end
        wantedLinks[tooltip] = GetTooltipLink(tooltip)
        if not wantedLinks[tooltip] or pending then return end
        pending = true
        -- OnTooltipSetItem fires inside the native build. Rebuilding comparison
        -- tooltips there can reenter DLL hooks. Coalesce until the next frame.
        C_Timer.After(0, FlushCompare)
    end

    local function Forget(tooltip)
        wantedLinks[tooltip] = nil
        tooltip.compareLink = nil
        tooltip.lastComparedItem = nil
        HideCompare()
    end

    local function HookTooltip(tooltip)
        if not tooltip then return end
        if not tooltip.shoppingTooltips then tooltip.shoppingTooltips = { ShoppingTooltip1, ShoppingTooltip2 } end
        hooked[#hooked + 1] = tooltip
        FT.HookScript(tooltip, "OnTooltipSetItem", QueueCompare)
        FT.HookScript(tooltip, "OnShow", QueueCompare)
        FT.HookScript(tooltip, "OnHide", Forget)
        FT.HookScript(tooltip, "OnTooltipCleared", Forget)
    end

    HookTooltip(GameTooltip)
    HookTooltip(ItemRefTooltip)
    -- AtlasLoot's item tooltips, when it is loaded (an optional dependency).
    FT.HookAddonOrVariable("AtlasLoot", function()
        HookTooltip(AtlasLootTooltip)
        HookTooltip(AtlasLootTooltip2)
    end)

    local modFrame = CreateFrame("Frame", "FCTweaksEquipCompareModFrame", UIParent)
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
        if shiftActive == isShiftDown then return end
        isShiftDown = shiftActive
        if not isShiftDown then
            HideCompare()
            return
        end
        -- The hovered item wins over an open item link the cursor is not on.
        if GameTooltip:IsShown() and not (ItemRefTooltip:IsShown() and MouseIsOver(ItemRefTooltip)) then
            ShowCompare(GameTooltip)
            return
        end
        for i = 2, #hooked do
            if hooked[i]:IsShown() then ShowCompare(hooked[i]); return end
        end
    end)
end
