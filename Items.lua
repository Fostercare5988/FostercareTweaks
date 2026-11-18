-- Items: sell prices on tooltips, Shift to compare with what you wear, quality
-- borders on the character and inspect slots, and a Sell Junk button at merchants.
local _, FT = ...
if not FT.apply then return end -- no ClassicAPI: Core.lua said so

-- Sell prices -----------------------------------------------------------------

-- OnTooltipSetItem fires for every item a tooltip shows (### OnTooltipSet*
-- scripts); its arg1 is the item's GUID where there is one (bags, bank, worn,
-- trade), and that gives the stack (### C_Item.GetStackCount). At a merchant the
-- game prices your own items itself.
local function Price()
    this.ftPrice = nil
    if arg1 and MerchantFrame:IsShown() then return end
    local _, _, id = this:GetItem()
    local price = id and C_Item.GetItemSellPriceByID(id)
    if not price or price <= 0 then return end
    this.ftPrice = price
    SetTooltipMoney(this, price * (arg1 and math.max(C_Item.GetStackCount(arg1), 1) or 1))
end

-- Loot, rolls, mail, quests, the trade partner and auctions have no GUID: the
-- count comes with the call that showed them, third of what each one returns
-- (FrameXML LootFrame, MailFrame, QuestFrame, QuestLogFrame, TradeFrame).
local COUNTS = {
    SetLootItem = GetLootSlotInfo, SetLootRollItem = GetLootRollItemInfo, SetInboxItem = GetInboxItem,
    SetQuestItem = GetQuestItemInfo, SetTradeTargetItem = GetTradeTargetItemInfo,
    SetAuctionItem = GetAuctionItemInfo, SetAuctionSellItem = GetAuctionSellItemInfo,
    SetQuestLogItem = function(kind, i)
        if kind == "choice" then return GetQuestLogChoiceInfo(i) end
        return GetQuestLogRewardInfo(i)
    end,
}
for method, info in pairs(COUNTS) do
    hooksecurefunc(GameTooltip, method, function(tip, a, b)
        local count = tip.ftPrice and select(3, info(a, b))
        if count and count > 1 then MoneyFrame_Update(tip:GetName() .. "MoneyFrame", tip.ftPrice * count) end
    end)
end

-- Compare ---------------------------------------------------------------------

-- With Shift down, the item a tooltip shows is compared with what you wear,
-- one frame later: comparing inside OnTooltipSetItem can crash the client
-- (### OnTooltipSet* scripts, the caveat).
local tips = { GameTooltip, ItemRefTooltip, AtlasLootTooltip, AtlasLootTooltip2 } -- AtlasLoot loads first
local wanted, queued

local function HideCompare() ShoppingTooltip1:Hide(); ShoppingTooltip2:Hide() end

local function Compare()
    local tip = wanted
    queued, wanted = nil, nil
    if tip and tip:IsShown() and FT.Shift() and tip:GetItem() then GameTooltip_ShowCompareItem(tip) end
end

local function Want(tip)
    HideCompare()
    wanted = FT.Shift() and tip or nil
    if wanted and not queued then
        queued = true
        C_Timer.After(0, Compare)
    end
end

local function Forget() if wanted == this then wanted = nil end; HideCompare() end

for i, tip in ipairs(tips) do
    if i <= 2 then tip:HookScript("OnTooltipSetItem", Price) end -- AtlasLoot's show no price
    tip:HookScript("OnTooltipSetItem", function() Want(this) end)
    tip:HookScript("OnHide", Forget)
end
ShoppingTooltip1:SetClampedToScreen(true)
ShoppingTooltip2:SetClampedToScreen(true)

-- Shift pressed over an item: the hovered tooltip wins over an open item link.
local shiftWas = false
FT.OnModifiers(function(shift)
    if shift == shiftWas then return end
    shiftWas = shift
    if not shift then wanted = nil; HideCompare(); return end
    if GameTooltip:IsShown() and not (ItemRefTooltip:IsShown() and MouseIsOver(ItemRefTooltip)) then
        return Want(GameTooltip)
    end
    for i = 2, #tips do
        if tips[i]:IsShown() then return Want(tips[i]) end
    end
end)

-- Quality borders -------------------------------------------------------------

-- Character and inspect slots. Bags and bank have none here: Bagnon draws
-- its own, in the windows it puts in place of the game's.
local EDGE = { edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 16 }

-- A border in the item's quality colour, grey for an empty slot. Written only
-- when the quality changes.
local function Border(button, quality)
    local border = button.ftBorder
    if not border then
        border = CreateFrame("Frame", nil, button)
        border:SetPoint("TOPLEFT", button, "TOPLEFT", -3, 3)
        border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 3, -3)
        border:SetBackdrop(EDGE)
        button.ftBorder = border
    end
    if not quality or quality < 0 then quality = false end -- the client's -1: not known
    if border.quality == quality then return end
    border.quality = quality
    local r, g, b = 0.5, 0.5, 0.46
    if quality then r, g, b = GetItemQualityColor(quality) end
    border:SetBackdropBorderColor(r, g, b, 1)
end

-- Character slots (`this`; FrameXML PaperDollFrame.lua). The game redraws them at
-- every change of your gear, also while the window is closed (each poison charge
-- used is one), so a border is drawn only while they show, the rest when they open.
local stale = {}
local function Worn(button) Border(button, GetInventoryItemQuality("player", button:GetID())) end
hooksecurefunc("PaperDollItemSlotButton_Update", function(cooldownOnly)
    if cooldownOnly then return end
    if PaperDollFrame:IsVisible() then Worn(this) else stale[this] = true end
end)
PaperDollFrame:HookScript("OnShow", function()
    for button in pairs(stale) do Worn(button) end
    table.wipe(stale)
end)

-- Inspect: the inspected member, who need not be the target (InspectFrame.unit,
-- Blizzard_InspectUI). Its items may arrive after the frame opens.
local inspected, arrived = {}, CreateFrame("Frame")
local function InspectBorder(button)
    inspected[button] = true
    local link = GetInventoryItemLink(InspectFrame.unit, button:GetID())
    local id = link and tonumber(string.match(link, "item:(%d+)"))
    Border(button, id and C_Item.GetItemQualityByID(id))
end
arrived:SetScript("OnEvent", function() for button in pairs(inspected) do InspectBorder(button) end end)
FT.WhenLoaded("Blizzard_InspectUI", function()
    hooksecurefunc("InspectPaperDollItemSlotButton_Update", InspectBorder)
    InspectFrame:HookScript("OnShow", function() arrived:RegisterEvent("GET_ITEM_INFO_RECEIVED") end)
    InspectFrame:HookScript("OnHide", function() arrived:UnregisterEvent("GET_ITEM_INFO_RECEIVED") end)
end)

-- Sell Junk -------------------------------------------------------------------

-- Shown on the merchant's own tab while you carry grey items. The client sells
-- them one at a time and stops when the merchant closes
-- (### C_MerchantFrame.SellAllJunkItems()).
local junk = CreateFrame("Button", nil, MerchantFrame)
junk:SetSize(36, 36)
junk:SetNormalTexture("Interface\\Icons\\Spell_Shadow_SacrificialShield")
junk:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
junk:Hide()
junk:SetScript("OnClick", function() C_MerchantFrame.SellAllJunkItems() end)
junk:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText("Sell " .. C_MerchantFrame.GetNumJunkItems() .. " grey items")
end)
junk:SetScript("OnLeave", function() GameTooltip:Hide() end)

local anchor
local function UpdateJunk()
    if MerchantFrame.selectedTab ~= 1 or C_MerchantFrame.GetNumJunkItems() == 0 then return junk:Hide() end
    local at = MerchantRepairItemButton:IsShown() and MerchantRepairItemButton or MerchantBuyBackItemItemButton
    if at ~= anchor then
        anchor = at
        junk:ClearAllPoints()
        junk:SetPoint("RIGHT", at, "LEFT", at == MerchantRepairItemButton and -4 or -14, 0)
    end
    junk:Show()
end
hooksecurefunc("MerchantFrame_Update", UpdateJunk)
junk:SetScript("OnEvent", UpdateJunk) -- a sale changes the bags
MerchantFrame:HookScript("OnShow", function() junk:RegisterEvent("BAG_UPDATE_DELAYED") end)
MerchantFrame:HookScript("OnHide", function() junk:UnregisterEvent("BAG_UPDATE_DELAYED") end)
