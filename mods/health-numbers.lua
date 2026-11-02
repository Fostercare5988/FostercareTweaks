local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/health-numbers.lua
local Abbreviate = AbbreviateNumbers

local module = FT:register({
    title = "Real Health Numbers",
    enabled = true,
})

local GetUnitHealthValues = FT.GetUnitHealthValues

module.enable = function(self)
    -- Native redraws may show these FontStrings again. Suppress their pixels
    -- without replacing widget methods or native lifecycle handlers.
    TargetHPText:SetAlpha(0)
    TargetHPPercText:SetAlpha(0)
    TargetFrameHealthBarText:SetAlpha(0)
    hooksecurefunc("TargetHealthCheck", function()
        TargetHPText:Hide()
        TargetHPPercText:Hide()
    end)

    TargetFrame.StatusTexts = CreateFrame("Frame", nil, TargetFrame)
    TargetFrame.StatusTexts:SetAllPoints(TargetFrame)

    TargetFrameHealthBar.TextString = TargetFrame.StatusTexts:CreateFontString("FCTweaksTargetHealthBarText", "OVERLAY")
    TargetFrameHealthBar.TextString:SetPoint("TOP", TargetFrameHealthBar, "BOTTOM", -2, 23)

    TargetFrameManaBar.TextString = TargetFrame.StatusTexts:CreateFontString("FCTweaksTargetManaBarText", "OVERLAY")
    TargetFrameManaBar.TextString:SetPoint("TOP", TargetFrameManaBar, "BOTTOM", -2, 22)

    PetFrameHealthBar.TextString:SetPoint("CENTER", PetFrameHealthBar, "CENTER", -2, 0)
    PetFrameManaBar.TextString:SetPoint("CENTER", PetFrameManaBar, "CENTER", -2, -2)

    PlayerFrameHealthBar.unit = PlayerFrameHealthBar.unit or "player"
    PlayerFrameManaBar.unit = PlayerFrameManaBar.unit or "player"

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
    local healthBars = { [TargetFrameHealthBar] = true, [PlayerFrameHealthBar] = true, [PetFrameHealthBar] = true }

    local function UpdateHealthTextString(sb)
        local bar = sb or this
        if not ownedBars[bar] then return end

        local str = bar.TextString
        if str and bar.unit then
            bar.lockShow = 1
            bar:Show()

            local cur, max, minVal
            if bar == TargetFrameHealthBar then
                cur, max = GetUnitHealthValues(bar.unit)
            else
                minVal, max = bar:GetMinMaxValues()
                cur = bar:GetValue()
            end

            local percent = (max > 0) and floor(cur / max * 100) or 0

            local text
            if cur == percent and healthBars[bar] and max <= 100 then
                text = percent .. "%"
            elseif bar == TargetFrameHealthBar and cur < max then
                text = Abbreviate(cur) .. " - " .. percent .. "%"
            else
                text = Abbreviate(cur)
            end

            -- The native "Dead" label shows at 0 health (TargetFrame_CheckDead),
            -- which arrives before UnitIsDead turns true; hide both numbers then.
            if max == 0 or (bar.unit == "target" and (UnitIsDeadOrGhost("target") or (UnitHealth("target") or 0) <= 0)) then
                str:Hide()
                if str:GetText() ~= "" then
                    str:SetText("")
                end
            else
                -- Native redraws also write this FontString, even at unchanged health.
                if str:GetText() ~= text then
                    str:SetText(text)
                end
                str:Show()
            end
        end
    end

    hooksecurefunc("TextStatusBar_UpdateTextString", UpdateHealthTextString)
    -- Death changes no mana value, so the mana number needs this refresh too.
    hooksecurefunc("TargetFrame_CheckDead", function()
        UpdateHealthTextString(TargetFrameHealthBar)
        UpdateHealthTextString(TargetFrameManaBar)
    end)
end
