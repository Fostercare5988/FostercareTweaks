local FT = FostercareTweaks
if not FT then return end

-- Original 1.12 top-right auras: keep Blizzard icons, handlers and timers.
-- BuffFrame and TemporaryEnchantFrame stay active as native update controllers.
local module = FT:register({
    title = "Blizzard Aura Controls", always = true,
})
local areas

-- The poison, oil or imbue on each weapon. ClassicAPI gives the enchant ID; its
-- icon is the item of that name in the bags (the poison itself), else the
-- enchant's proc spell. handIcon[16|17] is read when the weapons or their
-- enchants change, never per frame.
local enchantIcons, bagRetry, bagItem, handIcon = {}, {}, {}, {}
local function EnchantIcon(id)
    if not id or id == 0 then return nil end
    if enchantIcons[id] then return enchantIcons[id] end
    local info = C_Item.GetEnchantInfo(id)
    if not info then return nil end
    local now = GetTime()
    if (bagRetry[id] or 0) <= now then
        for bag = 0, 4 do
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local item = C_Container.GetContainerItemInfo(bag, slot, bagItem)
                local name = item and item.itemName
                if name and item.iconFileID and string.find(name, info.name, 1, true) == 1 then
                    enchantIcons[id] = item.iconFileID
                    return item.iconFileID
                end
            end
        end
        bagRetry[id] = now + 60        -- not carried: the spell's icon, look again later
    end
    if info.spellID then
        local _, _, icon = GetSpellInfo(info.spellID)
        return icon
    end
end
local function ReadEnchants()
    local _, _, _, mainID, _, _, _, offID = C_Item.GetWeaponEnchantInfo()
    handIcon[16], handIcon[17] = EnchantIcon(mainID), EnchantIcon(offID)
end

local function StyleAuraIcon(button, weaponEnchant, force)
    local cfg = FostercareTweaks_Config
    -- Looked up once: the native enchant updater calls this every frame.
    local icon, nativeBorder = button.fctIcon, button.fctNativeBorder
    if icon == nil then
        local name = button:GetName()
        icon, nativeBorder = _G[name .. "Icon"] or false, _G[name .. "Border"] or false
        button.fctIcon, button.fctNativeBorder = icon, nativeBorder
    end
    -- The native enchant updater changes textures, duration and flashing each
    -- frame, but never texture coordinates. Apply our crop once per icon.
    if icon and (not weaponEnchant or force or button.fctAuraCropped ~= icon) then
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        if weaponEnchant then button.fctAuraCropped = icon end
    end
    if weaponEnchant then
        -- Over the weapon's icon, which the native updater rewrites each frame.
        local hand = button:GetID()
        local poison = handIcon[hand]
        if button.fctPoisonIcon ~= poison then
            button.fctPoisonIcon = poison
            if poison and not button.fctPoison then
                button.fctPoison = button:CreateTexture(nil, "OVERLAY")
                button.fctPoison:SetAllPoints(icon or button)
                button.fctPoison:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            end
            if poison then button.fctPoison:SetTexture(poison); button.fctPoison:Show()
            elseif button.fctPoison then button.fctPoison:Hide() end
        end
        -- Quality belongs to the equipped item, not the enchant spell.
        if nativeBorder and nativeBorder:GetAlpha() ~= 0 then nativeBorder:SetAlpha(0) end
        if cfg["Show Weapon Enchant Borders"] == 0 then
            if button.fctAuraBorder and button.fctAuraBorder:IsShown() then button.fctAuraBorder:Hide() end
            return
        end
        local slot = button:GetID()
        if slot ~= 16 and slot ~= 17 then return end
        if not button.fctAuraBorder then
            button.fctAuraBorder = FT.AddBorder(button, 3)
            button.fctAuraBorder:EnableMouse(false)
            force = true
        end
        -- The native enchant updater runs every frame. Read quality only when
        -- the displayed hand changes, inventory changes, or settings change.
        if force or button.fctAuraSlot ~= slot then
            local quality = GetInventoryItemQuality("player", slot)
            button.fctAuraPendingItem = nil
            if quality and quality < 0 then
                local id = FT.GetItemIDFromLink(GetInventoryItemLink("player", slot))
                quality = id and C_Item.GetItemQualityByID(id)
                if not quality or quality < 0 then button.fctAuraPendingItem = id end
            end
            local r, g, b = 0.5, 0.5, 0.5
            if quality and quality >= 0 then r, g, b = GetItemQualityColor(quality) end
            button.fctAuraBorder:SetBackdropBorderColor(r, g, b, 1)
            button.fctAuraSlot = slot
        end
        if not button.fctAuraBorder:IsShown() then button.fctAuraBorder:Show() end
    elseif button.buffFilter == "HARMFUL" then
        if nativeBorder then nativeBorder:SetAlpha(cfg["Show Debuff Borders"] == 1 and 1 or 0) end
    else
        if cfg["Show Buff Borders"] == 1 then
            if not button.fctAuraBorder then
                button.fctAuraBorder = button:CreateTexture(nil, "OVERLAY")
                button.fctAuraBorder:SetPoint("CENTER", button, "CENTER")
                button.fctAuraBorder:SetWidth(button:GetWidth() + 2)
                button.fctAuraBorder:SetHeight(button:GetHeight() + 2)
                button.fctAuraBorder:SetTexture("Interface\\AddOns\\FostercareTweaks\\img\\border-dark.tga")
                button.fctAuraBorder:SetVertexColor(0.15, 0.15, 0.15, 1)
            end
            button.fctAuraBorder:Show()
        elseif button.fctAuraBorder then button.fctAuraBorder:Hide() end
    end
end
-- The native updater gives TempEnchant1 to the off hand whenever it has an
-- enchant. Place each button by the hand it shows: main hand left, off hand
-- right, whichever weapons are enchanted.
local function AnchorWeapon(button)
    local hand = button:GetID()
    button.fctAnchorHand = hand
    button:ClearAllPoints()
    button:SetPoint("TOPRIGHT", areas[3].frame, "TOPRIGHT", hand == 17 and 0 or -35, 0)
end
local function StyleWeaponEnchants(force)
    if not areas then return end
    for _, button in ipairs(areas[3].buttons) do
        -- A hand that just got its enchant: read what it is.
        local shown = button:IsShown()
        if button.fctEnchantShown ~= shown then
            button.fctEnchantShown = shown
            if shown then ReadEnchants() end
        end
        if button.fctAnchorHand ~= button:GetID() then AnchorWeapon(button) end
        StyleAuraIcon(button, true, force)
    end
end

local function AnchorButtons()
    if not areas then return end
    for _, button in ipairs(areas[3].buttons) do AnchorWeapon(button) end
    for index = 1, 2 do
        local area = areas[index]
        -- Buffs and debuffs close up around hidden ones.
        local i = 0
        for _, button in ipairs(area.buttons) do
            if button:IsShown() then
                i = i + 1
                -- Native icons are 30px. Keep eight per row, right-to-left,
                -- including room for the original duration labels underneath.
                button:ClearAllPoints()
                button:SetPoint("TOPRIGHT", area.frame, "TOPRIGHT",
                    -((i - 1) % 8) * 35,
                    -math.floor((i - 1) / 8) * (SHOW_BUFF_DURATIONS == "1" and 45 or 35))
            end
        end
    end
end

-- One layout per frame after native buttons change what they show.
local anchorPending
local function AnchorNow() anchorPending = nil; AnchorButtons() end
local function AnchorSoon()
    if anchorPending then return end
    anchorPending = true
    C_Timer.After(0, AnchorNow)
end

-- Native BuffButton_Update has shown the button: hide it when its aura shows
-- elsewhere (watched or hidden). SuperWoW names the aura behind the index.
local function HideIfElsewhere(button)
    if button.buffIndex and button.buffIndex >= 0 and button:IsShown()
        and FT.IsAuraHidden(GetSpellInfo(GetPlayerBuffID(button.buffIndex)), "player", "top") then
        button:Hide()
    end
    local shown = button:IsShown()
    if button.fctShown ~= shown then button.fctShown = shown; AnchorSoon() end
end

function FT.ApplyStandardAuraSettings()
    if not areas then return end
    local cfg = FostercareTweaks_Config
    for _, area in ipairs(areas) do
        local enabled = cfg[area.setting] ~= 0
        if enabled then area.frame:Show() else area.frame:Hide() end
        -- These font strings belong to the native controller, not the icon.
        -- Hide them independently without altering native flashing/expiry logic.
        for _, duration in ipairs(area.durations) do duration:SetAlpha(enabled and 1 or 0) end
    end
    local previous = this
    for _, area in ipairs(areas) do
        if area.setting ~= "Show Weapon Enchants" then
            for _, button in ipairs(area.buttons) do
                this = button
                BuffButton_Update()
            end
        end
    end
    this = previous
    BuffFrame_Enchant_OnUpdate(0)
    StyleWeaponEnchants(true)
    AnchorButtons()
end

module.enable = function()
    if areas then return end
    areas = {}
    for _, spec in ipairs({
        { "Buffs", "Show Standard Buffs", "standard_global_buffs", BuffFrame, 0 },
        { "Debuffs", "Show Standard Debuffs", "standard_global_debuffs", TemporaryEnchantFrame, -90 },
        { "Weapon Enchants", "Show Weapon Enchants", "standard_weapon_enchants", TemporaryEnchantFrame, 0 },
    }) do
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetFrameStrata("LOW")
        frame:SetWidth(spec[1] == "Weapon Enchants" and 65 or 275)
        frame:SetHeight(spec[1] == "Buffs" and 90 or 45)
        frame:SetPoint("TOPRIGHT", spec[4], "TOPRIGHT", 0, spec[5])
        local area = { frame = frame, setting = spec[2], buttons = {}, durations = {} }
        table.insert(areas, area)
        FT.RestoreFramePosition(frame, spec[3])
        FT.RegisterFrameMover(frame, spec[3], spec[1])
    end
    -- Use the native filter, not a guessed split between BuffButton indices.
    local i = 0
    while _G["BuffButton" .. i] do
        local button = _G["BuffButton" .. i]
        StyleAuraIcon(button)
        local area = button.buffFilter == "HARMFUL" and areas[2] or areas[1]
        table.insert(area.buttons, button)
        button:SetParent(area.frame)
        local duration = _G[button:GetName() .. "Duration"]
        if duration then table.insert(area.durations, duration) end
        i = i + 1
    end
    for i = 1, 2 do
        local button = _G["TempEnchant" .. i]
        StyleAuraIcon(button, true)
        table.insert(areas[3].buttons, button)
        button:SetParent(areas[3].frame)
        table.insert(areas[3].durations, _G[button:GetName() .. "Duration"])
    end
    -- This native function reanchors BuffButton8 and BuffButton16 whenever
    -- duration display changes. Restore only icon anchors, never mover positions.
    hooksecurefunc("BuffButtons_UpdatePositions", AnchorButtons)
    hooksecurefunc("BuffButton_Update", function()
        if this and this.buffFilter then StyleAuraIcon(this); HideIfElsewhere(this) end
    end)
    hooksecurefunc("BuffFrame_Enchant_OnUpdate", function() StyleWeaponEnchants(false) end)
    local inventory = CreateFrame("Frame", nil, UIParent)
    inventory:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
    inventory:RegisterEvent("WEAPON_SLOT_CHANGED")
    inventory:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    FT.SetEventHandler(inventory, function(_, ev, unitOrItem)
        if ev == "UNIT_INVENTORY_CHANGED" or ev == "WEAPON_SLOT_CHANGED" then
            ReadEnchants()
            StyleWeaponEnchants(true)
        elseif ev == "GET_ITEM_INFO_RECEIVED" then
            for _, button in ipairs(areas[3].buttons) do
                -- Re-read the current hand: the pending item may have moved.
                if button.fctAuraPendingItem == unitOrItem then StyleAuraIcon(button, true, true) end
            end
        end
    end)
    FT.ApplyStandardAuraSettings()
end
