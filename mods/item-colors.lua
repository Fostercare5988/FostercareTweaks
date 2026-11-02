local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/item-colors.lua
-- Show item rarity as border color on bags, bank, character and inspect frames

local AddBorder = FT.AddBorder
local HookAddonOrVariable = FT.HookAddonOrVariable

local module = FT:register({
    title = "Item Rarity Borders",
    always = true,
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
    local function KnownQuality(quality)
        -- Native item APIs use -1 for unknown/special handling; it is truthy.
        if type(quality) == "number" and quality >= 0 then return quality end
    end
    local function Style(button, quality, bank)
        if not button then return end
        quality = KnownQuality(quality)
        local border = button.FCTweaks_border or AddBorder(button, 3, neutral)
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
        return id and KnownQuality(C_Item.GetItemQualityByID(id))
    end
    -- Slot buttons by inventory id, looked up once per frame set.
    local function Slots(prefix, names)
        local buttons = {}
        for id, slot in pairs(names) do buttons[id] = _G[prefix .. slot] end
        return buttons
    end
    local character, inspect = Slots("Character", paperdoll_slots)
    local function RefreshPaperdoll()
        if not CharacterFrame:IsShown() then return end
        for id, button in pairs(character) do
            local quality = KnownQuality(GetInventoryItemQuality("player", id))
            if not quality then quality = LinkQuality(GetInventoryItemLink("player", id)) end
            Style(button, quality)
        end
    end
    local function RefreshInspect()
        if not InspectFrame or not InspectFrame:IsShown() then return end
        inspect = inspect or Slots("Inspect", inspect_slots)
        for id, button in pairs(inspect) do
            Style(button, LinkQuality(GetInventoryItemLink("target", id)))
        end
    end
    -- One table for every slot read (ClassicAPI's buf), not one per slot.
    local slotInfo = {}
    local function RefreshBag(frame)
        if not frame or not frame:IsShown() then return end
        local buttons = frame.fctItemButtons
        if not buttons then
            buttons = {}
            for slot = 1, MAX_CONTAINER_ITEMS do buttons[slot] = _G[frame:GetName() .. "Item" .. slot] end
            frame.fctItemButtons = buttons
        end
        for _, button in ipairs(buttons) do
            if button:IsShown() then
                local info = C_Container.GetContainerItemInfo(frame:GetID(), button:GetID(), slotInfo)
                local quality = info and (KnownQuality(info.quality) or
                    (info.itemID and KnownQuality(C_Item.GetItemQualityByID(info.itemID))))
                Style(button, quality)
            end
        end
    end
    -- The bank has NUM_BANKGENERIC_SLOTS (24) item buttons in this client.
    local bags, bank = {}, {}
    for i = 1, NUM_CONTAINER_FRAMES do bags[i] = _G["ContainerFrame" .. i] end
    for slot = 1, NUM_BANKGENERIC_SLOTS do bank[slot] = _G["BankFrameItem" .. slot] end
    local function RefreshBags()
        for _, frame in ipairs(bags) do RefreshBag(frame) end
    end
    local function RefreshBank()
        if not BankFrame:IsShown() then return end
        for slot, button in ipairs(bank) do
            Style(button, LinkQuality(GetContainerItemLink(-1, slot)), true)
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
    for _, ev in ipairs({"BAG_UPDATE_DELAYED", "BAG_UPDATE", "PLAYERBANKSLOTS_CHANGED",
        "GET_ITEM_INFO_RECEIVED"}) do controller:RegisterEvent(ev) end
    controller:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player", "target")
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
