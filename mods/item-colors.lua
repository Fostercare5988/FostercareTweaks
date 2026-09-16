-- FostercareTweaks: mods/item-colors.lua
-- Show item rarity as border color on bags, bank, character and inspect frames

local T = FostercareTweaks.T
local AddBorder = FostercareTweaks.AddBorder
local HookAddonOrVariable = FostercareTweaks.HookAddonOrVariable

local module = FostercareTweaks:register({
    title = T["Item Rarity Borders"],
    description = T["Show item rarity as the border color on bags, bank, character and inspect frames."],
    expansions = { ["vanilla"] = true, ["tbc"] = true },
    category = T["Tooltip & Items"],
    enabled = true,
})

local defcolor = {}

local paperdoll_slots = {
    [0] = "AmmoSlot", "HeadSlot",
    "NeckSlot", "ShoulderSlot",
    "ShirtSlot", "ChestSlot",
    "WaistSlot", "LegsSlot",
    "FeetSlot", "WristSlot",
    "HandsSlot", "Finger0Slot",
    "Finger1Slot", "Trinket0Slot",
    "Trinket1Slot", "BackSlot",
    "MainHandSlot", "SecondaryHandSlot",
    "RangedSlot", "TabardSlot",
}

local inspect_slots = {
    "HeadSlot", "NeckSlot",
    "ShoulderSlot", "ShirtSlot",
    "ChestSlot", "WaistSlot",
    "LegsSlot", "FeetSlot",
    "WristSlot", "HandsSlot",
    "Finger0Slot", "Finger1Slot",
    "Trinket0Slot", "Trinket1Slot",
    "BackSlot", "MainHandSlot",
    "SecondaryHandSlot", "RangedSlot",
    "TabardSlot"
}

module.enable = function(self)
    local defaultBorderColor = { r = 0.5, g = 0.5, b = 0.46 }

    do -- paperdoll
        local refresh_paperdoll = function()
            if not CharacterFrame or not CharacterFrame:IsShown() then return end
            for i, slot in pairs(paperdoll_slots) do
                local button = _G["Character" .. slot]
                if button then
                    local border = button.FCTweaks_border or button.ShaguTweaks_border
                    if not border then
                        border = AddBorder(button, 3, { r = 0.5, g = 0.5, b = 0.5 })
                        button.FCTweaks_border = border
                        button.ShaguTweaks_border = border
                    end

                    if not defcolor["paperdoll"] then
                        local r, g, b = border:GetBackdropBorderColor()
                        defcolor["paperdoll"] = { r or 0.5, g or 0.5, b or 0.5 }
                    end

                    local quality = GetInventoryItemQuality("player", i)
                    if quality then
                        local r, g, b = GetItemQualityColor(quality)
                        border:SetBackdropBorderColor(r, g, b, 1)
                    else
                        border:SetBackdropBorderColor(defcolor["paperdoll"][1], defcolor["paperdoll"][2], defcolor["paperdoll"][3], 1)
                    end
                end
            end
        end

        local paperdoll = CreateFrame("Frame", nil, CharacterFrame)
        paperdoll:RegisterEvent("UNIT_INVENTORY_CHANGED")
        paperdoll:SetScript("OnEvent", refresh_paperdoll)
        paperdoll:SetScript("OnShow", refresh_paperdoll)
    end

    do -- inspect
        local refresh_inspect = function()
            if not InspectFrame or not InspectFrame:IsShown() then return end
            for i, v in pairs(inspect_slots) do
                local button = _G["Inspect" .. v]
                if button then
                    local link = GetInventoryItemLink("target", i)
                    local border = button.FCTweaks_border or button.ShaguTweaks_border

                    if not border then
                        border = AddBorder(button, 3, { r = 0.5, g = 0.5, b = 0.5 })
                        button.FCTweaks_border = border
                        button.ShaguTweaks_border = border
                    end

                    if not defcolor["inspect"] then
                        local r, g, b = border:GetBackdropBorderColor()
                        defcolor["inspect"] = { r or 0.5, g or 0.5, b or 0.5 }
                    end

                    border:SetBackdropBorderColor(defcolor["inspect"][1], defcolor["inspect"][2], defcolor["inspect"][3], 1)
                    if link then
                        local _, _, istring = string.find(link, "|H(.+)|h")
                        local _, _, quality = GetItemInfo(istring)
                        if quality then
                            local r, g, b = GetItemQualityColor(quality)
                            border:SetBackdropBorderColor(r, g, b, 1)
                        end
                    end
                end
            end
        end

        if HookAddonOrVariable then
            HookAddonOrVariable("Blizzard_InspectUI", function()
                FostercareTweaks.hooksecurefunc("InspectPaperDollItemSlotButton_Update", function()
                    refresh_inspect()
                end)
            end)
        end
    end

    do -- bags
        for i = 0, 3 do
            local bagSlot = _G["CharacterBag" .. i .. "Slot"]
            if bagSlot then
                local b = AddBorder(bagSlot, 3, defaultBorderColor)
                bagSlot.FCTweaks_border = b
                bagSlot.ShaguTweaks_border = b
            end
        end

        for i = 1, 12 do
            for k = 1, MAX_CONTAINER_ITEMS do
                local itemBtn = _G["ContainerFrame" .. i .. "Item" .. k]
                if itemBtn then
                    local b = AddBorder(itemBtn, 3, defaultBorderColor)
                    itemBtn.FCTweaks_border = b
                    itemBtn.ShaguTweaks_border = b
                end
            end
        end

        local refresh_bags = function()
            for i = 1, 12 do
                local frame = _G["ContainerFrame" .. i]
                if frame and frame:IsShown() then
                    local name = frame:GetName()
                    local id = frame:GetID()
                    for k = 1, MAX_CONTAINER_ITEMS do
                        local button = _G[name .. "Item" .. k]
                        if button and button.FCTweaks_border then
                            if not defcolor["bag"] then
                                local r, g, b = button.FCTweaks_border:GetBackdropBorderColor()
                                defcolor["bag"] = { r or 0.5, g or 0.5, b or 0.5 }
                            end

                            button.FCTweaks_border:SetBackdropBorderColor(defcolor["bag"][1], defcolor["bag"][2], defcolor["bag"][3], 1)

                            local link = GetContainerItemLink(id, button:GetID())
                            if button:IsShown() and link then
                                local _, _, istring = string.find(link, "|H(.+)|h")
                                local _, _, quality = GetItemInfo(istring)
                                if quality then
                                    local r, g, b = GetItemQualityColor(quality)
                                    button.FCTweaks_border:SetBackdropBorderColor(r, g, b, 1)
                                end
                            end
                        end
                    end
                end
            end
        end

        local bags = CreateFrame("Frame", nil, ContainerFrame1)
        bags:RegisterEvent("BAG_UPDATE")
        bags:SetScript("OnEvent", refresh_bags)

        FostercareTweaks.hooksecurefunc("ContainerFrame_OnShow", refresh_bags)
        FostercareTweaks.hooksecurefunc("ContainerFrame_OnHide", refresh_bags)
    end

    do -- bank
        for i = 1, 28 do
            local bankItem = _G["BankFrameItem" .. i]
            if bankItem then
                local b = AddBorder(bankItem, 3, defaultBorderColor)
                bankItem.FCTweaks_border = b
                bankItem.ShaguTweaks_border = b
            end
        end

        local refresh_bank = function()
            for i = 1, 28 do
                local button = _G["BankFrameItem" .. i]
                if button and button.FCTweaks_border then
                    local link = GetContainerItemLink(-1, i)
                    if not defcolor["bank"] then
                        defcolor["bank"] = { button.FCTweaks_border:GetBackdropBorderColor() }
                    end

                    button.FCTweaks_border:SetBackdropBorderColor(defcolor["bank"][1], defcolor["bank"][2], defcolor["bank"][3], 1)

                    if link then
                        local _, _, istring = string.find(link, "|H(.+)|h")
                        local _, _, q = GetItemInfo(istring)
                        if q and q > 1 then
                            local r, g, b = GetItemQualityColor(q)
                            button.FCTweaks_border:SetBackdropBorderColor(r, g, b, 1)
                        end
                    end
                end
            end
        end

        local bank = CreateFrame("Frame", nil, BankFrame)
        bank:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
        bank:SetScript("OnEvent", refresh_bank)
        bank:SetScript("OnShow", refresh_bank)
    end

    do -- weapon buff
        if TempEnchant1 then
            local b1 = AddBorder(TempEnchant1, 3, { 0.2, 0.2, 0.2 })
            TempEnchant1.FCTweaks_border = b1
            TempEnchant1.ShaguTweaks_border = b1
        end
        if TempEnchant2 then
            local b2 = AddBorder(TempEnchant2, 3, { 0.2, 0.2, 0.2 })
            TempEnchant2.FCTweaks_border = b2
            TempEnchant2.ShaguTweaks_border = b2
        end

        FostercareTweaks.hooksecurefunc("BuffFrame_Enchant_OnUpdate", function(elapsed)
            local mh, _, _, oh = GetWeaponEnchantInfo()
            if not mh and not oh then
                if TempEnchant1 then TempEnchant1.lastQuality = nil end
                if TempEnchant2 then TempEnchant2.lastQuality = nil end
                return
            end

            if TempEnchant1 and TempEnchant1.FCTweaks_border then
                local q = GetInventoryItemQuality("player", TempEnchant1:GetID()) or 1
                if TempEnchant1.lastQuality ~= q then
                    TempEnchant1.lastQuality = q
                    local r, g, b = GetItemQualityColor(q)
                    TempEnchant1.FCTweaks_border:SetBackdropBorderColor(r, g, b, 1)
                end
                if TempEnchant1Border and TempEnchant1Border:GetAlpha() ~= 0 then
                    TempEnchant1Border:SetAlpha(0)
                end
            end

            if TempEnchant2 and TempEnchant2.FCTweaks_border then
                local q = GetInventoryItemQuality("player", TempEnchant2:GetID()) or 1
                if TempEnchant2.lastQuality ~= q then
                    TempEnchant2.lastQuality = q
                    local r, g, b = GetItemQualityColor(q)
                    TempEnchant2.FCTweaks_border:SetBackdropBorderColor(r, g, b, 1)
                end
                if TempEnchant2Border and TempEnchant2Border:GetAlpha() ~= 0 then
                    TempEnchant2Border:SetAlpha(0)
                end
            end
        end)
    end
end
