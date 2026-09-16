-- FostercareTweaks: mods/vendor-values.lua
-- Shows vendor sell values on item tooltips using ClassicAPI C_Item

local T = FostercareTweaks.T
local GetItemLinkByName = FostercareTweaks.GetItemLinkByName
local GetItemIDFromLink = FostercareTweaks.GetItemIDFromLink

local module = FostercareTweaks:register({
  title = T["Vendor Values"],
  description = T["Shows the vendor sell values on all item tooltips."],
  expansions = { ["vanilla"] = true, ["tbc"] = true },
  category = T["Tooltip & Items"],
  enabled = true,
})

local priceCache = {}

local function GetSellPrice(idOrLink)
  if not idOrLink then return 0 end
  local id = tonumber(idOrLink) or (type(idOrLink) == "string" and GetItemIDFromLink(idOrLink))
  if id and priceCache[id] then
    return priceCache[id]
  end

  local price = 0
  if id and C_Item and C_Item.GetItemSellPriceByID then
    local ok, p = pcall(C_Item.GetItemSellPriceByID, id)
    if ok and type(p) == "number" and p > 0 then
      price = p
    end
  end

  if price <= 0 and C_Item and C_Item.GetItemSellPrice then
    local ok, p = pcall(C_Item.GetItemSellPrice, idOrLink)
    if ok and type(p) == "number" and p > 0 then
      price = p
    end
  end

  if id and price > 0 then
    priceCache[id] = price
  end

  return price
end

-- Backwards-compatible lookup table for other modules referencing SellValueDB[id]
local SellValueDB = setmetatable({}, {
  __index = function(tab, id)
    local p = GetSellPrice(id)
    return (p > 0) and p or nil
  end
})

FostercareTweaks.SellValueDB = SellValueDB
if ShaguTweaks then
  ShaguTweaks.SellValueDB = SellValueDB
end

local function AddVendorPrices(frame, idOrLink, count)
  local price = GetSellPrice(idOrLink)
  if price and price > 0 then
    SetTooltipMoney(frame, price * count)
    frame:Show()
  end
end

module.enable = function(self)
  local tooltip = CreateFrame("Frame", nil, GameTooltip)

  tooltip:SetScript("OnHide", function()
    GameTooltip.itemLink = nil
    GameTooltip.itemCount = nil
    GameTooltip.ignoreMerchant = nil
  end)

  tooltip:SetScript("OnShow", function()
    if not GameTooltip.itemLink and GameTooltip.GetItem then
      local _, link = GameTooltip:GetItem()
      if link then GameTooltip.itemLink = link end
    end

    if GameTooltip.itemLink and (GameTooltip.ignoreMerchant or not (MerchantFrame and MerchantFrame:IsShown())) then
      local itemID = GetItemIDFromLink(GameTooltip.itemLink)
      local count = tonumber(GameTooltip.itemCount) or 1
      AddVendorPrices(GameTooltip, itemID or GameTooltip.itemLink, math.max(count, 1))
    end
  end)

  local HookSetItemRef = SetItemRef
  SetItemRef = function(link, text, button)
    local itemID = (link and GetItemIDFromLink(link)) or GetItemIDFromLink(GameTooltip.itemLink)
    HookSetItemRef(link, text, button)
    if not IsAltKeyDown() and not IsShiftKeyDown() and not IsControlKeyDown() and (itemID or link) then
      AddVendorPrices(ItemRefTooltip, itemID or link, 1)
    end
  end

  local HookSetBagItem = GameTooltip.SetBagItem
  function GameTooltip.SetBagItem(self, container, slot)
    GameTooltip.itemLink = GetContainerItemLink(container, slot)
    _, GameTooltip.itemCount = GetContainerItemInfo(container, slot)
    GameTooltip.ignoreMerchant = false
    return HookSetBagItem(self, container, slot)
  end

  local HookSetQuestLogItem = GameTooltip.SetQuestLogItem
  function GameTooltip.SetQuestLogItem(self, itemType, index)
    GameTooltip.itemLink = GetQuestLogItemLink(itemType, index)
    if not GameTooltip.itemLink then return end
    GameTooltip.ignoreMerchant = true
    return HookSetQuestLogItem(self, itemType, index)
  end

  local HookSetQuestItem = GameTooltip.SetQuestItem
  function GameTooltip.SetQuestItem(self, itemType, index)
    GameTooltip.itemLink = GetQuestItemLink(itemType, index)
    GameTooltip.ignoreMerchant = true
    return HookSetQuestItem(self, itemType, index)
  end

  local HookSetLootItem = GameTooltip.SetLootItem
  function GameTooltip.SetLootItem(self, slot)
    GameTooltip.itemLink = GetLootSlotLink(slot)
    GameTooltip.ignoreMerchant = true
    HookSetLootItem(self, slot)
  end

  local HookSetInboxItem = GameTooltip.SetInboxItem
  function GameTooltip.SetInboxItem(self, mailID, attachmentIndex)
    local itemName = GetInboxItem(mailID)
    local link = (GetInboxItemLink and GetInboxItemLink(mailID, attachmentIndex or 1))
    if not link and GetItemLinkByName and itemName then
      link = GetItemLinkByName(itemName)
    end
    GameTooltip.itemLink = link
    GameTooltip.ignoreMerchant = true
    return HookSetInboxItem(self, mailID, attachmentIndex)
  end

  local HookSetInventoryItem = GameTooltip.SetInventoryItem
  function GameTooltip.SetInventoryItem(self, unit, slot)
    GameTooltip.itemLink = GetInventoryItemLink(unit, slot)
    GameTooltip.ignoreMerchant = true
    return HookSetInventoryItem(self, unit, slot)
  end

  local HookSetLootRollItem = GameTooltip.SetLootRollItem
  function GameTooltip.SetLootRollItem(self, id)
    GameTooltip.itemLink = GetLootRollItemLink(id)
    GameTooltip.ignoreMerchant = true
    return HookSetLootRollItem(self, id)
  end

  local HookSetMerchantItem = GameTooltip.SetMerchantItem
  function GameTooltip.SetMerchantItem(self, merchantIndex)
    GameTooltip.itemLink = GetMerchantItemLink(merchantIndex)
    GameTooltip.ignoreMerchant = false
    return HookSetMerchantItem(self, merchantIndex)
  end

  local HookSetCraftItem = GameTooltip.SetCraftItem
  function GameTooltip.SetCraftItem(self, skill, slot)
    GameTooltip.itemLink = GetCraftReagentItemLink(skill, slot)
    GameTooltip.ignoreMerchant = true
    return HookSetCraftItem(self, skill, slot)
  end

  local HookSetCraftSpell = GameTooltip.SetCraftSpell
  function GameTooltip.SetCraftSpell(self, slot)
    GameTooltip.itemLink = GetCraftItemLink(slot)
    GameTooltip.ignoreMerchant = true
    return HookSetCraftSpell(self, slot)
  end

  local HookSetTradeSkillItem = GameTooltip.SetTradeSkillItem
  function GameTooltip.SetTradeSkillItem(self, skillIndex, reagentIndex)
    if reagentIndex then
      GameTooltip.itemLink = GetTradeSkillReagentItemLink(skillIndex, reagentIndex)
    else
      GameTooltip.itemLink = GetTradeSkillItemLink(skillIndex)
    end
    GameTooltip.ignoreMerchant = true
    return HookSetTradeSkillItem(self, skillIndex, reagentIndex)
  end

  local HookSetAuctionItem = GameTooltip.SetAuctionItem
  function GameTooltip.SetAuctionItem(self, atype, index)
    _, _, GameTooltip.itemCount = GetAuctionItemInfo(atype, index)
    GameTooltip.itemLink = GetAuctionItemLink(atype, index)
    GameTooltip.ignoreMerchant = true
    return HookSetAuctionItem(self, atype, index)
  end

  local HookSetAuctionSellItem = GameTooltip.SetAuctionSellItem
  function GameTooltip.SetAuctionSellItem(self)
    local itemName, _, itemCount = GetAuctionSellItemInfo()
    GameTooltip.itemCount = itemCount
    GameTooltip.itemLink = GetItemLinkByName and itemName and GetItemLinkByName(itemName)
    GameTooltip.ignoreMerchant = true
    return HookSetAuctionSellItem(self)
  end

  local HookSetTradePlayerItem = GameTooltip.SetTradePlayerItem
  function GameTooltip.SetTradePlayerItem(self, index)
    GameTooltip.itemLink = GetTradePlayerItemLink(index)
    GameTooltip.ignoreMerchant = true
    return HookSetTradePlayerItem(self, index)
  end

  local HookSetTradeTargetItem = GameTooltip.SetTradeTargetItem
  function GameTooltip.SetTradeTargetItem(self, index)
    GameTooltip.itemLink = GetTradeTargetItemLink(index)
    GameTooltip.ignoreMerchant = true
    return HookSetTradeTargetItem(self, index)
  end
end
