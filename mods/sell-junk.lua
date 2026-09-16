-- FostercareTweaks: mods/sell-junk.lua
-- Adds a "Sell Junk" button to merchant windows that automatically sells grey items

local T = FostercareTweaks.T
local GetItemIDFromLink = FostercareTweaks.GetItemIDFromLink

local module = FostercareTweaks:register({
    title = T["Sell Junk"],
    description = T["Adds a “Sell Junk” button to every merchant window, that sells all grey items."],
    expansions = { ["vanilla"] = true, ["tbc"] = true },
    category = T["Tooltip & Items"],
    enabled = true,
})

local processed = {}

local function CreateGoldString(money)
    if type(money) ~= "number" then return "-" end

    local gold = floor(money / 100 / 100)
    local silver = floor((money / 100) % 100)
    local copper = floor(money % 100)

    local str = ""
    if gold > 0 then str = str .. "|cffffffff" .. gold .. "|cffffd700g" end
    if silver > 0 or gold > 0 then str = str .. "|cffffffff " .. silver .. "|cffc7c7cfs" end
    str = str .. "|cffffffff " .. copper .. "|cffeda55fc"

    return str
end

local function GetItemSellPrice(itemID)
    if not itemID then return 0 end
    if C_Item and C_Item.GetItemSellPriceByID then
        local ok, price = pcall(C_Item.GetItemSellPriceByID, itemID)
        if ok and type(price) == "number" and price > 0 then
            return price
        end
    end
    local db = FostercareTweaks.SellValueDB or (ShaguTweaks and ShaguTweaks.SellValueDB)
    if db and db[itemID] then
        return db[itemID]
    end
    return 0
end

local function IsJunkItem(bag, slot)
    local link = GetContainerItemLink(bag, slot)
    if not link then return false end
    local itemID = GetItemIDFromLink(link)
    if not itemID then return false end

    local quality
    if C_Item and C_Item.GetItemQualityByID then
        local ok, q = pcall(C_Item.GetItemQualityByID, itemID)
        if ok and type(q) == "number" then quality = q end
    end
    if not quality then
        local _, _, itemQuality = GetItemInfo(itemID)
        quality = itemQuality
    end

    if quality == 0 then
        local price = GetItemSellPrice(itemID)
        return (price and price > 0), price, itemID
    end
    return false
end

local function HasGreyItems()
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            if IsJunkItem(bag, slot) then return true end
        end
    end
    return false
end

local wipe = table.wipe or wipe

local function GetNextGreyItem()
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local key = bag * 100 + slot
            if not processed[key] then
                local isJunk, price, itemID = IsJunkItem(bag, slot)
                if isJunk then
                    processed[key] = true
                    return bag, slot, price, itemID
                end
            end
        end
    end
    return nil, nil, nil, nil
end

module.enable = function(self)
    local autovendor = CreateFrame("Frame", nil, UIParent)
    autovendor:Hide()

    autovendor:SetScript("OnShow", function()
        if wipe then wipe(processed) end
        this.price = 0
        this.count = 0
    end)

    autovendor:SetScript("OnHide", function()
        if this.count and this.count > 0 then
            local moneyStr = (GetCoinTextureString and GetCoinTextureString(this.price)) or CreateGoldString(this.price)
            DEFAULT_CHAT_FRAME:AddMessage(T["Your vendor trash has been sold and you earned"] .. " " .. moneyStr)
        end
    end)

    autovendor:SetScript("OnUpdate", function()
        if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + 0.1 end

        local bag, slot, price, itemID = GetNextGreyItem()
        if not bag or not slot then
            this:Hide()
            return
        end

        local _, icount = GetContainerItemInfo(bag, slot)
        icount = (icount and icount > 0) and icount or 1
        if this.price and price then
            this.price = this.price + (price * icount)
            this.count = this.count + 1
        end

        if not this.merchant then return end

        ClearCursor()
        UseContainerItem(bag, slot)
    end)

    autovendor:RegisterEvent("MERCHANT_SHOW")
    autovendor:RegisterEvent("MERCHANT_CLOSED")
    autovendor:RegisterEvent("MERCHANT_UPDATE")
    autovendor:SetScript("OnEvent", function()
        if autovendor.button and autovendor.button.Update then
            autovendor.button:Update()
        end

        local ev = event or _G.event
        if ev == "MERCHANT_CLOSED" then
            autovendor.merchant = nil
            autovendor:Hide()
        elseif ev == "MERCHANT_SHOW" then
            autovendor.merchant = true
            if autovendor.button then autovendor.button:Show() end
        end

        if MerchantRepairText then
            MerchantRepairText:SetText("")
        end

        if autovendor.button then
            if MerchantRepairItemButton and MerchantRepairItemButton:IsShown() then
                autovendor.button:ClearAllPoints()
                autovendor.button:SetPoint("RIGHT", MerchantRepairItemButton, "LEFT", -4, 0)
            elseif MerchantBuyBackItemItemButton then
                autovendor.button:ClearAllPoints()
                autovendor.button:SetPoint("RIGHT", MerchantBuyBackItemItemButton, "LEFT", -14, 0)
            end
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
        autovendor:Show()
    end)

    autovendor.button.Update = function()
        if not autovendor:IsVisible() then
            if HasGreyItems() then
                autovendor.button:Enable()
                autovendor.button:GetNormalTexture():SetDesaturated(false)
            else
                autovendor.button:Disable()
                autovendor.button:GetNormalTexture():SetDesaturated(true)
            end
        else
            autovendor.button:Disable()
            autovendor.button:GetNormalTexture():SetDesaturated(true)
        end
    end

    FostercareTweaks.hooksecurefunc("MerchantFrame_Update", function()
        if MerchantFrame.selectedTab == 1 then
            autovendor.button:Show()
        else
            autovendor.button:Hide()
        end
    end)
    if MerchantFrame.selectedTab == 1 then
        autovendor.button:Show()
    else
        autovendor.button:Hide()
    end
end
