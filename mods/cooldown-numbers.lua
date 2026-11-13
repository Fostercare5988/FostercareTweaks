local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/cooldown-numbers.lua
-- Countdown numbers on the stock cooldown sweeps: the action, pet and stance
-- buttons' 1.12 Models (and other addons' that still use them), which have
-- none of their own. Each Model gets a native Cooldown child that draws no
-- sweep: the client counts the time down in the addon's one look
-- (FT.Countdown) while the player's countdownForCooldowns CVar is 1, as on
-- every other cooldown (ClassicAPI docs/API.md, Cooldown). No timer runs; the
-- numbers hide with their Model when its sweep ends. A native Cooldown draws
-- its own numbers and is left alone.

local module = FT:register({
    title = "Cooldown Numbers",
    always = true,
})

-- The Model's numbers, made the first time it starts; false for a native Cooldown.
local function Numbers(model)
    local numbers = model.fctNumbers
    if numbers ~= nil then return numbers end
    numbers = false
    if model:GetObjectType() ~= "Cooldown" then
        numbers = CreateFrame("Cooldown", nil, model)
        numbers:SetAllPoints(model)
        numbers:SetDrawSwipe(false)
        numbers:SetDrawBling(false)
        numbers:SetCountdownFormatter(FT.Countdown)
        local parent = model:GetParent()
        local size = parent and parent:GetHeight() or 0
        numbers:GetCountdownFontString():SetFont(STANDARD_TEXT_FONT, size > 0 and math.min(16, size * 0.64) or 12, "OUTLINE")
    end
    model.fctNumbers = numbers
    return numbers
end

-- After the stock setter (FrameXML Cooldown.lua), which shows the Model for a
-- running cooldown and hides it otherwise.
local function SetTimer(model, start, duration, enable)
    local numbers = model and Numbers(model)
    if not numbers then return end
    if start > 0 and duration > 0 and enable > 0 then
        if numbers.fctStart ~= start or numbers.fctDuration ~= duration then
            numbers.fctStart, numbers.fctDuration = start, duration
            numbers:SetCooldown(start, duration)
        end
    elseif numbers.fctStart then
        numbers.fctStart, numbers.fctDuration = nil, nil
        numbers:Clear()
    end
end

-- The stock buttons set their cooldowns again on every page, slot and world
-- change (ActionButton_Update), so the hook alone keeps them current.
module.enable = function() hooksecurefunc("CooldownFrame_SetTimer", SetTimer) end
