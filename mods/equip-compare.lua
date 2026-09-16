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
    local sides = { "Left", "Right" }

    local function AddHeader(tooltip)
        local name = tooltip:GetName()
        for i = tooltip:NumLines(), 1, -1 do
            for _, side in pairs(sides) do
                local current = _G[name .. "Text" .. side .. i]
                local below = _G[name .. "Text" .. side .. (i + 1)]

                if current and current:IsShown() then
                    local text = current:GetText()
                    local r, g, b = current:GetTextColor()

                    if text and text ~= "" then
                        if tooltip:NumLines() < i + 1 then
                            tooltip:AddLine(text, r, g, b, true)
                        else
                            below:SetText(text)
                            below:SetTextColor(r, g, b)
                            below:Show()
                            current:Hide()
                        end
                    end
                end
            end
        end

        local headerLine = _G[name .. "TextLeft1"]
        if headerLine then
            headerLine:SetTextColor(0.5, 0.5, 0.5, 1)
            headerLine:SetText(CURRENTLY_EQUIPPED or "Currently Equipped")
            headerLine:Show()
        end

        tooltip:Show()
    end

    local EQUIPLOC_TO_SLOTS = {
        ["INVTYPE_HEAD"] = { "HeadSlot" },
        ["INVTYPE_NECK"] = { "NeckSlot" },
        ["INVTYPE_SHOULDER"] = { "ShoulderSlot" },
        ["INVTYPE_BODY"] = { "ShirtSlot" },
        ["INVTYPE_CHEST"] = { "ChestSlot" },
        ["INVTYPE_ROBE"] = { "ChestSlot" },
        ["INVTYPE_WAIST"] = { "WaistSlot" },
        ["INVTYPE_LEGS"] = { "LegsSlot" },
        ["INVTYPE_FEET"] = { "FeetSlot" },
        ["INVTYPE_WRIST"] = { "WristSlot" },
        ["INVTYPE_HAND"] = { "HandsSlot" },
        ["INVTYPE_FINGER"] = { "Finger0Slot", "Finger1Slot" },
        ["INVTYPE_TRINKET"] = { "Trinket0Slot", "Trinket1Slot" },
        ["INVTYPE_CLOAK"] = { "BackSlot" },
        ["INVTYPE_WEAPON"] = { "MainHandSlot", "SecondaryHandSlot" },
        ["INVTYPE_2HWEAPON"] = { "MainHandSlot" },
        ["INVTYPE_WEAPONMAINHAND"] = { "MainHandSlot" },
        ["INVTYPE_WEAPONOFFHAND"] = { "SecondaryHandSlot" },
        ["INVTYPE_SHIELD"] = { "SecondaryHandSlot" },
        ["INVTYPE_HOLDABLE"] = { "SecondaryHandSlot" },
        ["INVTYPE_RANGED"] = { "RangedSlot" },
        ["INVTYPE_RANGEDRIGHT"] = { "RangedSlot" },
        ["INVTYPE_THROWN"] = { "RangedSlot" },
        ["INVTYPE_WAND"] = { "RangedSlot" },
        ["INVTYPE_GUN"] = { "RangedSlot" },
        ["INVTYPE_CROSSBOW"] = { "RangedSlot" },
        ["INVTYPE_PROJECTILE"] = { "AmmoSlot" },
        ["INVTYPE_TABARD"] = { "TabardSlot" },
        ["INVTYPE_RELIC"] = { "RangedSlot" },
    }

    if ShoppingTooltip1 then ShoppingTooltip1:SetClampedToScreen(true) end
    if ShoppingTooltip2 then ShoppingTooltip2:SetClampedToScreen(true) end

    local function HideCompare()
        if ShoppingTooltip1 and ShoppingTooltip1:IsShown() then ShoppingTooltip1:Hide() end
        if ShoppingTooltip2 and ShoppingTooltip2:IsShown() then ShoppingTooltip2:Hide() end
        if GameTooltip then GameTooltip.lastComparedItem = nil end
        if ItemRefTooltip then ItemRefTooltip.lastComparedItem = nil end
        if AtlasLootTooltip then AtlasLootTooltip.lastComparedItem = nil end
        if AtlasLootTooltip2 then AtlasLootTooltip2.lastComparedItem = nil end
    end

    local function GetTooltipItemEquipLoc(tooltip)
        if not tooltip then return nil, nil end
        local name, link
        if tooltip.GetItem then
            name, link = tooltip:GetItem()
        end
        link = link or tooltip.itemLink
        if not link and tooltip.GetName then
            local title = _G[tooltip:GetName() .. "TextLeft1"]
            name = name or (title and title:GetText())
        end

        local equipLoc
        if link and C_Item and C_Item.GetItemInventoryType then
            local ok, loc = pcall(C_Item.GetItemInventoryType, link)
            if ok and loc and loc ~= "" then equipLoc = loc end
        end
        if not equipLoc and (link or name) then
            local _, _, _, _, _, _, _, _, itemEquip = GetItemInfo(link or name)
            if itemEquip and itemEquip ~= "" then equipLoc = itemEquip end
        end
        return equipLoc, (name or link)
    end

    local function ShowCompare(tooltip)
        if not tooltip or not tooltip:IsShown() or not IsShiftKeyDown() then
            HideCompare()
            return
        end

        local equipLoc, itemName = GetTooltipItemEquipLoc(tooltip)
        if not equipLoc or not itemName then
            HideCompare()
            return
        end

        if tooltip.lastComparedItem == itemName then
            return
        end

        local slotNames = EQUIPLOC_TO_SLOTS[equipLoc]
        if not slotNames then
            HideCompare()
            return
        end

        local slotID = GetInventorySlotInfo(slotNames[1])
        if not slotID then
            HideCompare()
            return
        end

        local x = GetCursorPosition() / UIParent:GetEffectiveScale()
        local anchor = x < (GetScreenWidth() / 2) and "TOPLEFT" or "TOPRIGHT"
        local relative = x < (GetScreenWidth() / 2) and "TOPRIGHT" or "TOPLEFT"

        local pos, parent = tooltip:GetPoint()
        if parent and parent == UIParent and pos == "TOPRIGHT" then
            anchor = "TOPRIGHT"
            relative = "TOPLEFT"
        end

        local hasFirst = false
        if ShoppingTooltip1 then
            ShoppingTooltip1:SetOwner(tooltip, "ANCHOR_NONE")
            ShoppingTooltip1:ClearAllPoints()
            ShoppingTooltip1:SetPoint(anchor, tooltip, relative, 0, 0)
            local hasItem = ShoppingTooltip1:SetInventoryItem("player", slotID)
            if hasItem and ShoppingTooltip1:NumLines() > 0 then
                ShoppingTooltip1:Show()
                AddHeader(ShoppingTooltip1)
                hasFirst = true
            else
                ShoppingTooltip1:Hide()
            end
        end

        if slotNames[2] and ShoppingTooltip2 then
            local slotID_other = GetInventorySlotInfo(slotNames[2])
            ShoppingTooltip2:SetOwner(tooltip, "ANCHOR_NONE")
            ShoppingTooltip2:ClearAllPoints()
            if hasFirst and ShoppingTooltip1 and ShoppingTooltip1:IsShown() then
                ShoppingTooltip2:SetPoint(anchor, ShoppingTooltip1, relative, 0, 0)
            else
                ShoppingTooltip2:SetPoint(anchor, tooltip, relative, 0, 0)
            end
            local hasOther = ShoppingTooltip2:SetInventoryItem("player", slotID_other)
            if hasOther and ShoppingTooltip2:NumLines() > 0 then
                ShoppingTooltip2:Show()
                AddHeader(ShoppingTooltip2)
            else
                ShoppingTooltip2:Hide()
            end
        elseif ShoppingTooltip2 then
            ShoppingTooltip2:Hide()
        end

        tooltip.lastComparedItem = itemName
    end

    local function CheckActiveTooltips()
        if not IsShiftKeyDown() then
            HideCompare()
            return
        end

        if GameTooltip and GameTooltip:IsShown() then
            ShowCompare(GameTooltip)
        elseif ItemRefTooltip and ItemRefTooltip:IsShown() and MouseIsOver(ItemRefTooltip) then
            ShowCompare(ItemRefTooltip)
        elseif AtlasLootTooltip and AtlasLootTooltip:IsShown() then
            ShowCompare(AtlasLootTooltip)
        elseif AtlasLootTooltip2 and AtlasLootTooltip2:IsShown() then
            ShowCompare(AtlasLootTooltip2)
        else
            HideCompare()
        end
    end

    local modFrame = CreateFrame("Frame", "FCTweaksEquipCompareModFrame", UIParent)
    modFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
    modFrame:SetScript("OnEvent", function()
        local key = arg1
        if not key or string.find(key, "SHIFT") then
            if IsShiftKeyDown() then
                CheckActiveTooltips()
            else
                HideCompare()
            end
        end
    end)

    local function HookTooltip(tt)
        if not tt then return end
        if FostercareTweaks.HookScript then
            FostercareTweaks.HookScript(tt, "OnShow", function()
                if IsShiftKeyDown() then
                    ShowCompare(tt)
                end
            end)
            FostercareTweaks.HookScript(tt, "OnHide", function()
                tt.lastComparedItem = nil
                HideCompare()
            end)
        end
    end

    HookTooltip(GameTooltip)
    HookTooltip(ItemRefTooltip)

    if FostercareTweaks.HookAddonOrVariable then
        FostercareTweaks.HookAddonOrVariable("AtlasLoot", function()
            HookTooltip(AtlasLootTooltip)
            HookTooltip(AtlasLootTooltip2)
        end)
    end
end
