-- FostercareTweaks: mods/sell-junk.lua
-- Adds a "Sell Junk" button to merchant windows that automatically sells grey items

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Sell Junk"],
    description = T["Adds a “Sell Junk” button to every merchant window, that sells all grey items."],
    expansions = { ["vanilla"] = true, ["tbc"] = true },
    category = T["Tooltip & Items"],
    enabled = true,
})

module.enable = function(self)
    local autovendor = CreateFrame("Frame", nil, UIParent)

    local function UpdateButton()
        local button = autovendor.button
        if not button then return end
        if MerchantFrame:IsShown() and MerchantFrame.selectedTab == 1 then
            button:Show()
            if C_MerchantFrame.GetNumJunkItems() > 0 then
                button:Enable()
                button:GetNormalTexture():SetDesaturated(false)
            else
                button:Disable()
                button:GetNormalTexture():SetDesaturated(true)
            end
        else
            button:Hide()
        end
    end

    autovendor:RegisterEvent("MERCHANT_SHOW")
    autovendor:RegisterEvent("MERCHANT_CLOSED")
    autovendor:RegisterEvent("MERCHANT_UPDATE")
    autovendor:RegisterEvent("BAG_UPDATE")
    autovendor:SetScript("OnEvent", function()
        UpdateButton()
        if MerchantRepairText then MerchantRepairText:SetText("") end
        if MerchantRepairItemButton and MerchantRepairItemButton:IsShown() then
            autovendor.button:ClearAllPoints()
            autovendor.button:SetPoint("RIGHT", MerchantRepairItemButton, "LEFT", -4, 0)
        elseif MerchantBuyBackItemItemButton then
            autovendor.button:ClearAllPoints()
            autovendor.button:SetPoint("RIGHT", MerchantBuyBackItemItemButton, "LEFT", -14, 0)
        end
    end)

    autovendor.button = CreateFrame("Button", "FCTweaksSellJunkButton", MerchantFrame)
    autovendor.button:SetWidth(36)
    autovendor.button:SetHeight(36)
    autovendor.button:SetNormalTexture("Interface\\Icons\\Spell_Shadow_SacrificialShield")
    autovendor.button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(T["Sell Grey Items"])
        GameTooltip:Show()
    end)
    autovendor.button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    autovendor.button:SetScript("OnClick", function()
        if not MerchantFrame:IsShown() or MerchantFrame.selectedTab ~= 1 then return end
        -- The engine owns the item-GUID queue and cancels on merchant changes.
        -- Submission has no success return; do not claim unconfirmed earnings.
        C_MerchantFrame.SellAllJunkItems()
        UpdateButton()
    end)

    FostercareTweaks.hooksecurefunc("MerchantFrame_Update", UpdateButton)
    UpdateButton()
end
