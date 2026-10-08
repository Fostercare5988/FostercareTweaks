local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/vendor-values.lua
-- Shows vendor sell values on item tooltips using ClassicAPI C_Item

local GetItemIDFromLink = FT.GetItemIDFromLink

local module = FT:register({
  title = "Vendor Values",
  description = "Shows the vendor sell values on all item tooltips.",
  category = "Tooltip & Items",
  enabled = true,
})

local function GetSellPrice(item)
  local id = tonumber(item) or (type(item) == "string" and GetItemIDFromLink(item))
  if not id then return 0 end
  -- The engine already caches item records and requests missing data. A second
  -- Lua cache and a location-based fallback provide no additional information.
  return C_Item.GetItemSellPriceByID(id) or 0
end

-- Backwards-compatible lookup table for other modules referencing SellValueDB[id]
local SellValueDB = setmetatable({}, {
  __index = function(tab, id)
    local p = GetSellPrice(id)
    return (p > 0) and p or nil
  end
})

FT.SellValueDB = SellValueDB

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
    local price = GetSellPrice(id or link)
    if price <= 0 then return end
    SetTooltipMoney(frame, price * count)
    frame:Show()
    frame.vendorValueSignature = signature
    frame.vendorValueLines = frame:NumLines()
  end

  local function ClearValue(frame)
    frame.itemLink, frame.itemCount, frame.ignoreMerchant = nil, nil, nil
    frame.vendorValueSignature, frame.vendorValueLines = nil, nil
  end
  for _, frame in ipairs({GameTooltip, ItemRefTooltip}) do
    FT.HookScript(frame, "OnHide", ClearValue)
    FT.HookScript(frame, "OnTooltipCleared", ClearValue)
  end
  local pending = CreateFrame("Frame")
  pending:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  FT.SetEventHandler(pending, function(_, ev, itemID, success)
    if success == false then return end
    for _, frame in ipairs({GameTooltip, ItemRefTooltip}) do
      if frame:IsShown() and itemID == GetItemIDFromLink(frame.itemLink) then
        ShowValue(frame, frame.itemLink, frame.itemCount, frame.ignoreMerchant)
      end
    end
  end)

  hooksecurefunc(ItemRefTooltip, "SetHyperlink", function(frame, link)
    if link and GetItemIDFromLink(link) and not IsAltKeyDown() and not IsShiftKeyDown() and not IsControlKeyDown() then
      ShowValue(frame, link, 1, true)
    end
  end)

  hooksecurefunc(GameTooltip, "SetBagItem", function(frame, bag, slot)
    local info = C_Container.GetContainerItemInfo(bag, slot)
    ShowValue(frame, info and info.hyperlink, info and info.stackCount, false)
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
    if not link then
      local _, itemLink = frame:GetItem()
      link = itemLink
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
    local _, _, count = GetAuctionSellItemInfo()
    local _, link = frame:GetItem()
    ShowValue(frame, link, count, true)
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
