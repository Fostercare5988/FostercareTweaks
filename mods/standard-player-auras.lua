-- Original 1.12 top-right auras: keep Blizzard icons, handlers and timers.
-- BuffFrame and TemporaryEnchantFrame stay active as native update controllers.
local T = FostercareTweaks.T
local module = FostercareTweaks:register({
    title = T["Blizzard Aura Controls"], category = T["Unit Frames"], enabled = true,
    description = "Separate visibility and Ctrl+Shift movement for the original player aura areas.",
})
local areas
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

function FostercareTweaks.ApplyStandardAuraSettings()
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
            end
        end
    end
    this = previous
    BuffFrame_Enchant_OnUpdate(0)
    AnchorButtons()
    FostercareTweaks.UpdateFrameMovers()
end

module.enable = function()
    if areas then return end
    areas = {}
    FostercareTweaks.standardAuraAreas = areas
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
        FostercareTweaks.RestoreFramePosition(frame, spec[3])
        FostercareTweaks.RegisterFrameMover(frame, spec[3], spec[1])
    end
    -- Use the native filter, not a guessed split between BuffButton indices.
    local i = 0
    while _G["BuffButton" .. i] do
        local button = _G["BuffButton" .. i]
        local area = button.buffFilter == "HARMFUL" and areas[2] or areas[1]
        table.insert(area.buttons, button)
        button:SetParent(area.frame)
        local duration = _G[button:GetName() .. "Duration"]
        if duration then table.insert(area.durations, duration) end
        i = i + 1
    end
    for i = 1, 2 do
        local button = _G["TempEnchant" .. i]
        table.insert(areas[3].buttons, button)
        button:SetParent(areas[3].frame)
        table.insert(areas[3].durations, _G[button:GetName() .. "Duration"])
    end
    -- This native function reanchors BuffButton8 and BuffButton16 whenever
    -- duration display changes. Restore only icon anchors, never mover positions.
    FostercareTweaks.hooksecurefunc("BuffButtons_UpdatePositions", AnchorButtons)
    FostercareTweaks.ApplyStandardAuraSettings()
end
