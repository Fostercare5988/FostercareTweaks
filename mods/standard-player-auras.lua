local FT = FostercareTweaks
if not FT then return end

-- Original 1.12 top-right auras: keep Blizzard icons, handlers and timers.
-- BuffFrame and TemporaryEnchantFrame stay active as native update controllers.
local module = FT:register({
    title = "Blizzard Aura Controls", category = "Unit Frames", enabled = true,
    description = "Separate visibility and Ctrl+Shift movement for the original player aura areas.",
})
local areas
local function StyleAuraIcon(button, weaponEnchant, force)
    local cfg = FostercareTweaks_Config or {}
    local name = button:GetName()
    local icon = _G[name .. "Icon"]
    -- The native enchant updater changes textures, duration and flashing each
    -- frame, but never texture coordinates. Apply our crop once per icon.
    if icon and (not weaponEnchant or force or button.fctAuraCropped ~= icon) then
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        if weaponEnchant then button.fctAuraCropped = icon end
    end
    local nativeBorder = _G[name .. "Border"]
    if weaponEnchant then
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
            local r, g, b = 0.5, 0.5, 0.5
            if quality then r, g, b = GetItemQualityColor(quality) end
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
local function StyleWeaponEnchants(force)
    if not areas then return end
    for _, button in ipairs(areas[3].buttons) do StyleAuraIcon(button, true, force) end
end
local function AnchorButtons()
    if not areas then return end
    for _, area in ipairs(areas) do
        for i, button in ipairs(area.buttons) do
            -- Native icons are 30px. Keep eight per row, right-to-left,
            -- including room for the original duration labels underneath.
            button:ClearAllPoints()
            button:SetPoint("TOPRIGHT", area.frame, "TOPRIGHT",
                -((i - 1) % 8) * 35,
                -math.floor((i - 1) / 8) * (SHOW_BUFF_DURATIONS == "1" and 45 or 35))
        end
    end
end

function FT.ApplyStandardAuraSettings()
    if not areas then return end
    local cfg = FostercareTweaks_Config or {}
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
                StyleAuraIcon(button)
            end
        end
    end
    this = previous
    BuffFrame_Enchant_OnUpdate(0)
    StyleWeaponEnchants(true)
    AnchorButtons()
    FT.UpdateFrameMovers()
end

module.enable = function()
    if areas then return end
    areas = {}
    FT.standardAuraAreas = areas
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
    FT.hooksecurefunc("BuffButtons_UpdatePositions", AnchorButtons)
    FT.hooksecurefunc("BuffButton_Update", function()
        if this and this.buffFilter then StyleAuraIcon(this) end
    end)
    FT.hooksecurefunc("BuffFrame_Enchant_OnUpdate", function() StyleWeaponEnchants(false) end)
    local inventory = CreateFrame("Frame", nil, UIParent)
    inventory:RegisterEvent("UNIT_INVENTORY_CHANGED")
    FT.SetEventHandler(inventory, function(_, ev, unit)
        if unit == "player" then StyleWeaponEnchants(true) end
    end)
    FT.ApplyStandardAuraSettings()
end
