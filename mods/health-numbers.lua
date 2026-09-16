-- FostercareTweaks: mods/health-numbers.lua
local T = FostercareTweaks.T
local Abbreviate = FostercareTweaks.Abbreviate

local module = FostercareTweaks:register({
    title = T["Real Health Numbers"],
    description = T["Shows real health numbers on player, pet, and target unit frames."],
    category = T["Unit Frames"],
    enabled = true,
})

local function GetUnitHealthValues(unit)
    if not unit or not UnitExists(unit) then return 0, 0 end
    local cur, max
    local hasXP = FostercareTweaks.HasUnitXP and FostercareTweaks.HasUnitXP()
    if hasXP then
        local ok, ch, mh = pcall(function()
            return UnitXP("health", unit), UnitXP("maxhealth", unit)
        end)
        if ok and ch and mh and mh > 0 then
            cur = ch
            max = mh
        end
    end
    if not cur or not max or max == 0 then
        cur = UnitHealth(unit) or 0
        max = UnitHealthMax(unit) or 0
    end
    return cur, max
end

module.enable = function(self)
    -- Permanently suppress native target frame dual status texts from patch-3 FrameXML
    if TargetHPText then
        TargetHPText:Hide()
        TargetHPText.Show = function() return end
    end
    if TargetHPPercText then
        TargetHPPercText:Hide()
        TargetHPPercText.Show = function() return end
    end
    if TargetFrameHealthBarText then
        TargetFrameHealthBarText:Hide()
        TargetFrameHealthBarText.Show = function() return end
    end
    if TargetHealthCheck then
        FostercareTweaks.hooksecurefunc("TargetHealthCheck", function()
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

    local function UpdateHealthTextString(sb)
        local bar = sb or this
        if not bar or not bar.GetName then return end

        local str = bar.TextString
        if str and bar.unit then
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
                if str.lastText ~= "" then
                    str.lastText = ""
                    str:SetText("")
                end
            else
                if str.lastText ~= text then
                    str.lastText = text
                    str:SetText(text)
                end
                str:Show()
            end
        end
    end

    FostercareTweaks.hooksecurefunc("TextStatusBar_UpdateTextString", UpdateHealthTextString)
end
