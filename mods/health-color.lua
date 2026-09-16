-- FostercareTweaks: mods/health-color.lua
local T = FostercareTweaks.T
local GetColorGradient = FostercareTweaks.GetColorGradient

local module = FostercareTweaks:register({
    title = T["Unit Frame Health Colors"],
    description = T["Change health text color based on its value."],
    category = T["Unit Frames"],
    enabled = nil,
})

module.enable = function(self)
    local function UpdateManaTypeColor(uf)
        local frame = uf or this
        local str = frame and frame.manabar and frame.manabar.TextString
        if not str then return end

        if not string.find(frame.manabar:GetName(), "Health") then
            local r, g, b = frame.manabar:GetStatusBarColor()
            str:SetTextColor((r + 2) / 3, (g + 2) / 3, (b + 2) / 3, 1)
        end
    end
    FostercareTweaks.hooksecurefunc("UnitFrame_UpdateManaType", UpdateManaTypeColor)

    local function UpdateHealthGradientColor(sb)
        local bar = sb or this
        local str = bar and bar.TextString
        if str and bar.unit then
            local _, max = bar:GetMinMaxValues()
            local cur = bar:GetValue()
            local percent = max > 0 and floor(cur / max * 100) or 0

            if string.find(bar:GetName(), "Health") then
                local r, g, b = GetColorGradient(percent / 100)
                str:SetTextColor((r + 1) / 2, (g + 1) / 2, (b + 1) / 2, 0.75)
            end
        end
    end
    FostercareTweaks.hooksecurefunc("TextStatusBar_UpdateTextString", UpdateHealthGradientColor)
end
