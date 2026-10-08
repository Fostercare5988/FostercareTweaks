local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/item-colors.lua
-- Show item rarity as border color on bags, bank, character and inspect frames

local AddBorder = FT.AddBorder
local HookAddonOrVariable = FT.HookAddonOrVariable

local module = FT:register({
    title = "Item Rarity Borders",
    description = "Show item rarity as the border color on bags, bank, character and inspect frames.",
    category = "Tooltip & Items",
    enabled = true,
})

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

module.enable = function()
    local neutral = { r = 0.5, g = 0.5, b = 0.46 }
    local function Style(button, quality, bank)
        if not button then return end
        local border = button.FCTweaks_border or button.ShaguTweaks_border or AddBorder(button, 3, neutral)
        button.FCTweaks_border = border
        if bank and quality and quality < 2 then quality = nil end
        if button.fctBorderQuality == quality then return end
        button.fctBorderQuality = quality
        if quality then
            local r, g, b = GetItemQualityColor(quality)
            border:SetBackdropBorderColor(r, g, b, 1)
        else border:SetBackdropBorderColor(neutral.r, neutral.g, neutral.b, 1) end
    end
    local function LinkQuality(link)
        local id = FT.GetItemIDFromLink(link)
        return id and C_Item.GetItemQualityByID(id)
    end
    local function RefreshPaperdoll()
        if not CharacterFrame or not CharacterFrame:IsShown() then return end
        for id, slot in pairs(paperdoll_slots) do
            Style(_G["Character" .. slot], GetInventoryItemQuality("player", id))
        end
    end
    local function RefreshInspect()
        if not InspectFrame or not InspectFrame:IsShown() then return end
        for id, slot in ipairs(inspect_slots) do
            Style(_G["Inspect" .. slot], LinkQuality(GetInventoryItemLink("target", id)))
        end
    end
    local function RefreshBag(frame)
        if not frame or not frame:IsShown() then return end
        for slot = 1, MAX_CONTAINER_ITEMS do
            local button = _G[frame:GetName() .. "Item" .. slot]
            if button and button:IsShown() then
                local info = C_Container.GetContainerItemInfo(frame:GetID(), button:GetID())
                local quality = info and (info.quality or C_Item.GetItemQualityByID(info.itemID))
                Style(button, quality)
            end
        end
    end
    local function RefreshBags()
        for i = 1, 12 do RefreshBag(_G["ContainerFrame" .. i]) end
    end
    local function RefreshBank()
        if not BankFrame or not BankFrame:IsShown() then return end
        for slot = 1, 28 do
            Style(_G["BankFrameItem" .. slot], LinkQuality(GetContainerItemLink(-1, slot)), true)
        end
    end
    local function RefreshVisible()
        RefreshPaperdoll(); RefreshInspect(); RefreshBags(); RefreshBank()
    end
    local refreshPending, refreshAll, refreshInspect
    local function QueueRefresh(all)
        if all then refreshAll = true else refreshInspect = true end
        if refreshPending then return end
        refreshPending = true
        -- Item records and native inspect slots arrive in bursts. Publish the
        -- union once after this build, reading the current views at execution.
        C_Timer.After(0, function()
            local allViews, inspectView = refreshAll, refreshInspect
            refreshPending, refreshAll, refreshInspect = nil, nil, nil
            if allViews then RefreshVisible()
            elseif inspectView then RefreshInspect() end
        end)
    end
    local controller = CreateFrame("Frame", "FCTweaksItemBorders", UIParent)
    for _, ev in ipairs({"BAG_UPDATE_DELAYED", "BAG_UPDATE", "UNIT_INVENTORY_CHANGED",
        "PLAYERBANKSLOTS_CHANGED", "GET_ITEM_INFO_RECEIVED"}) do controller:RegisterEvent(ev) end
    FT.SetEventHandler(controller, function(_, ev, unitOrBag)
        if ev == "BAG_UPDATE_DELAYED" or (ev == "BAG_UPDATE" and unitOrBag == -2) then RefreshBags()
        elseif ev == "UNIT_INVENTORY_CHANGED" then
            if unitOrBag == "player" then RefreshPaperdoll() end
            if unitOrBag == "target" then RefreshInspect() end
        elseif ev == "PLAYERBANKSLOTS_CHANGED" then RefreshBank()
        elseif ev == "GET_ITEM_INFO_RECEIVED" then QueueRefresh(true) end
    end)
    FT.HookScript(CharacterFrame, "OnShow", RefreshPaperdoll)
    FT.HookScript(BankFrame, "OnShow", RefreshBank)
    -- Native 1.12 calls this without arguments and exposes the opening bag
    -- through `this`. Existing visible bags have not changed on this path.
    hooksecurefunc("ContainerFrame_OnShow", function() RefreshBag(this) end)
    HookAddonOrVariable("Blizzard_InspectUI", function()
        FT.HookScript(InspectFrame, "OnShow", RefreshInspect)
        hooksecurefunc("InspectPaperDollItemSlotButton_Update", function() QueueRefresh(false) end)
    end)
    -- Retain borders on the four character bag buttons as before.
    for i = 0, 3 do Style(_G["CharacterBag" .. i .. "Slot"]) end
    RefreshVisible()
end
