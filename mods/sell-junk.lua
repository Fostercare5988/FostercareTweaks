local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/sell-junk.lua
-- Adds a "Sell Junk" button to merchant windows that automatically sells grey items


local module = FT:register({
    title = "Sell Junk",
    description = "Adds a “Sell Junk” button to every merchant window, that sells all grey items.",
    category = "Tooltip & Items",
    enabled = true,
})

module.enable = function(self)
    local autovendor = CreateFrame("Frame", nil, UIParent)
    local lastAnchor, lastOffset

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
            return
        end
        local anchor, offset
        if MerchantRepairItemButton and MerchantRepairItemButton:IsShown() then
            anchor, offset = MerchantRepairItemButton, -4
        elseif MerchantBuyBackItemItemButton then
            anchor, offset = MerchantBuyBackItemItemButton, -14
        end
        if anchor and (lastAnchor ~= anchor or lastOffset ~= offset) then
            lastAnchor, lastOffset = anchor, offset
            button:ClearAllPoints()
            button:SetPoint("RIGHT", anchor, "LEFT", offset, 0)
        end
    end

    for _, ev in ipairs({"MERCHANT_SHOW", "MERCHANT_CLOSED", "MERCHANT_UPDATE", "BAG_UPDATE_DELAYED"}) do
        autovendor:RegisterEvent(ev)
    end
    FT.SetEventHandler(autovendor, UpdateButton)

    autovendor.button = CreateFrame("Button", "FCTweaksSellJunkButton", MerchantFrame)
    autovendor.button:SetWidth(36)
    autovendor.button:SetHeight(36)
    autovendor.button:SetNormalTexture("Interface\\Icons\\Spell_Shadow_SacrificialShield")
    autovendor.button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Sell Grey Items")
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

    FT.hooksecurefunc("MerchantFrame_Update", UpdateButton)
    UpdateButton()
end
