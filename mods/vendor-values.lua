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
  -- Vendor values are a post-call decoration. Never replace Blizzard's item
  -- methods: other tooltip owners may hook them in either load order.
  local function ShowValue(frame, link, count, ignoreMerchant)
    frame.itemLink = link
    frame.itemCount = count
    frame.ignoreMerchant = ignoreMerchant
    if not link or (not ignoreMerchant and MerchantFrame and MerchantFrame:IsShown()) then return end
    count = math.max(tonumber(count) or 1, 1)
    local signature = tostring(link) .. ":" .. count
    if frame.vendorValueSignature == signature and frame.vendorValueLines
      and frame:NumLines() >= frame.vendorValueLines then return end
    local id = GetItemIDFromLink(link)
    if GetSellPrice(id or link) <= 0 then return end
    AddVendorPrices(frame, id or link, count)
    frame.vendorValueSignature = signature
    frame.vendorValueLines = frame:NumLines()
  end

  local tooltip = CreateFrame("Frame", nil, GameTooltip)
  tooltip:SetScript("OnHide", function()
    GameTooltip.itemLink = nil
    GameTooltip.itemCount = nil
    GameTooltip.ignoreMerchant = nil
    GameTooltip.vendorValueSignature = nil
    GameTooltip.vendorValueLines = nil
  end)
  FostercareTweaks.HookScript(GameTooltip, "OnTooltipCleared", function()
    GameTooltip.vendorValueSignature = nil
    GameTooltip.vendorValueLines = nil
  end)
  FostercareTweaks.HookScript(ItemRefTooltip, "OnTooltipCleared", function()
    ItemRefTooltip.vendorValueSignature = nil
    ItemRefTooltip.vendorValueLines = nil
  end)

  hooksecurefunc(ItemRefTooltip, "SetHyperlink", function(frame, link)
    if link and GetItemIDFromLink(link) and not IsAltKeyDown() and not IsShiftKeyDown() and not IsControlKeyDown() then
      ShowValue(frame, link, 1, true)
    end
  end)

  hooksecurefunc(GameTooltip, "SetBagItem", function(frame, bag, slot)
    local _, count = GetContainerItemInfo(bag, slot)
    ShowValue(frame, GetContainerItemLink(bag, slot), count, false)
  end)
  hooksecurefunc(GameTooltip, "SetQuestLogItem", function(frame, itemType, index)
    ShowValue(frame, GetQuestLogItemLink(itemType, index), 1, true)
  end)
  hooksecurefunc(GameTooltip, "SetQuestItem", function(frame, itemType, index)
    ShowValue(frame, GetQuestItemLink(itemType, index), 1, true)
  end)
  hooksecurefunc(GameTooltip, "SetLootItem", function(frame, slot)
    ShowValue(frame, GetLootSlotLink(slot), 1, true)
  end)
  hooksecurefunc(GameTooltip, "SetInboxItem", function(frame, mailID, attachmentIndex)
    local link = GetInboxItemLink and GetInboxItemLink(mailID, attachmentIndex or 1)
    if not link and GetItemLinkByName then
      local name = GetInboxItem(mailID)
      if name then link = GetItemLinkByName(name) end
    end
    ShowValue(frame, link, 1, true)
  end)
  hooksecurefunc(GameTooltip, "SetInventoryItem", function(frame, unit, slot)
    ShowValue(frame, GetInventoryItemLink(unit, slot), 1, true)
  end)
  hooksecurefunc(GameTooltip, "SetLootRollItem", function(frame, id)
    ShowValue(frame, GetLootRollItemLink(id), 1, true)
  end)
  hooksecurefunc(GameTooltip, "SetMerchantItem", function(frame, index)
    ShowValue(frame, GetMerchantItemLink(index), 1, false)
  end)
  hooksecurefunc(GameTooltip, "SetCraftItem", function(frame, skill, slot)
    ShowValue(frame, GetCraftReagentItemLink(skill, slot), 1, true)
  end)
  hooksecurefunc(GameTooltip, "SetCraftSpell", function(frame, slot)
    ShowValue(frame, GetCraftItemLink(slot), 1, true)
  end)
  hooksecurefunc(GameTooltip, "SetTradeSkillItem", function(frame, skill, reagent)
    local link = reagent and GetTradeSkillReagentItemLink(skill, reagent) or GetTradeSkillItemLink(skill)
    ShowValue(frame, link, 1, true)
  end)
  hooksecurefunc(GameTooltip, "SetAuctionItem", function(frame, atype, index)
    local _, _, count = GetAuctionItemInfo(atype, index)
    ShowValue(frame, GetAuctionItemLink(atype, index), count, true)
  end)
  hooksecurefunc(GameTooltip, "SetAuctionSellItem", function(frame)
    local name, _, count = GetAuctionSellItemInfo()
    ShowValue(frame, name and GetItemLinkByName and GetItemLinkByName(name), count, true)
  end)
  hooksecurefunc(GameTooltip, "SetTradePlayerItem", function(frame, index)
    ShowValue(frame, GetTradePlayerItemLink(index), 1, true)
  end)
  hooksecurefunc(GameTooltip, "SetTradeTargetItem", function(frame, index)
    ShowValue(frame, GetTradeTargetItemLink(index), 1, true)
  end)
  hooksecurefunc(GameTooltip, "SetHyperlink", function(frame, link)
    if GetItemIDFromLink(link) then ShowValue(frame, link, 1, true) end
  end)
end
