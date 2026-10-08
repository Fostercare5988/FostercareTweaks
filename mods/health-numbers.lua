local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/health-numbers.lua
local Abbreviate = FT.Abbreviate

local module = FT:register({
    title = "Real Health Numbers",
    description = "Shows real health numbers on player, pet, and target unit frames.",
    category = "Unit Frames",
    enabled = true,
})

local GetUnitHealthValues = FT.GetUnitHealthValues

module.enable = function(self)
    -- Native redraws may show these FontStrings again. Suppress their pixels
    -- without replacing widget methods or native lifecycle handlers.
    if TargetHPText then TargetHPText:SetAlpha(0) end
    if TargetHPPercText then TargetHPPercText:SetAlpha(0) end
    if TargetFrameHealthBarText then TargetFrameHealthBarText:SetAlpha(0) end
    if TargetHealthCheck then
        FT.hooksecurefunc("TargetHealthCheck", function()
            if TargetHPText then TargetHPText:Hide() end
            if TargetHPPercText then TargetHPPercText:Hide() end
        end)
    end

    TargetFrame.StatusTexts = CreateFrame("Frame", nil, TargetFrame)
    TargetFrame.StatusTexts:SetAllPoints(TargetFrame)

    TargetFrameHealthBar.TextString = TargetFrame.StatusTexts:CreateFontString("FCTweaksTargetHealthBarText", "OVERLAY")
    TargetFrameHealthBar.TextString:SetPoint("TOP", TargetFrameHealthBar, "BOTTOM", -2, 23)

    TargetFrameManaBar.TextString = TargetFrame.StatusTexts:CreateFontString("FCTweaksTargetManaBarText", "OVERLAY")
    TargetFrameManaBar.TextString:SetPoint("TOP", TargetFrameManaBar, "BOTTOM", -2, 22)

    PetFrameHealthBar.TextString:SetPoint("CENTER", PetFrameHealthBar, "CENTER", -2, 0)
    PetFrameManaBar.TextString:SetPoint("CENTER", PetFrameManaBar, "CENTER", -2, -2)

    if PlayerFrameHealthBar and not PlayerFrameHealthBar.unit then PlayerFrameHealthBar.unit = "player" end
    if PlayerFrameManaBar and not PlayerFrameManaBar.unit then PlayerFrameManaBar.unit = "player" end

    local targetPlayerBars = { TargetFrameHealthBar, TargetFrameManaBar, PlayerFrameHealthBar, PlayerFrameManaBar }
    for _, frame in ipairs(targetPlayerBars) do
        frame.TextString:SetFontObject("GameFontWhite")
        frame.TextString:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        frame.TextString:SetHeight(32)
    end

    local petBars = { PetFrameHealthBar, PetFrameManaBar }
    for _, frame in ipairs(petBars) do
        frame.TextString:SetFontObject("GameFontWhite")
        frame.TextString:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        frame.TextString:SetHeight(32)
        frame.TextString:SetJustifyH("LEFT")
    end

    local ownedBars = {}
    for _, bar in ipairs(targetPlayerBars) do ownedBars[bar] = true end
    for _, bar in ipairs(petBars) do ownedBars[bar] = true end

    local function UpdateHealthTextString(sb)
        local bar = sb or this
        if not ownedBars[bar] then return end

        local str = bar.TextString
        local unit = bar.unit or ((bar == PlayerFrameHealthBar or bar == PlayerFrameManaBar) and "player")
        if str and unit then
            bar.lockShow = 42
            bar:Show()

            local cur, max, minVal
            if bar:GetName() == "TargetFrameHealthBar" then
                cur, max = GetUnitHealthValues(bar.unit)
            else
                minVal, max = bar:GetMinMaxValues()
                cur = bar:GetValue()
            end

            local percent = (max > 0) and floor(cur / max * 100) or 0

            local text
            if cur == percent and string.find(bar:GetName(), "Health") and max <= 100 then
                text = percent .. "%"
            elseif bar:GetName() == "TargetFrameHealthBar" and cur < max then
                text = Abbreviate(cur) .. " - " .. percent .. "%"
            else
                text = Abbreviate(cur)
            end

            if max == 0 or (bar.unit == "target" and (UnitIsDead("target") or UnitIsGhost("target"))) then
                str:Hide()
                if str:GetText() ~= "" then
                    str:SetText("")
                end
            else
                -- Native redraws also write this FontString, even at unchanged health.
                if str:GetText() ~= tostring(text) then
                    str:SetText(text)
                end
                str:Show()
            end
        end
    end

    FT.hooksecurefunc("TextStatusBar_UpdateTextString", UpdateHealthTextString)
end
