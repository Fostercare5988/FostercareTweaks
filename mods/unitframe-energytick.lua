-- FostercareTweaks: mods/unitframe-energytick.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Dynamic Energy & Mana Ticks across Modern or Stock Unit Frames

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Show Energy Ticks"],
    description = T["Show energy and mana ticks on the player unit frame."],
    category = T["Unit Frames"],
    enabled = true,
})

local function GetActivePowerBar()
    local UF = FostercareTweaks.UnitFrames
    if UF and UF.playerFrame and UF.playerFrame.powerBar and UF.playerFrame:IsShown() then
        return UF.playerFrame.powerBar
    end
    return PlayerFrameManaBar
end

module.enable = function(self)
    local energytick = CreateFrame("Frame", "FCTweaksEnergyTick", UIParent)
    energytick:EnableMouse(false)

    energytick.spark = energytick:CreateTexture(nil, "OVERLAY")
    energytick.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    energytick.spark:SetWidth(16)
    energytick.spark:SetHeight(16)
    energytick.spark:SetBlendMode("ADD")

    energytick:RegisterEvent("PLAYER_ENTERING_WORLD")
    energytick:RegisterEvent("UNIT_DISPLAYPOWER")
    energytick:RegisterEvent("UNIT_ENERGY")
    energytick:RegisterEvent("UNIT_MANA")

    energytick:SetScript("OnEvent", function(arg1_param, arg2_param)
        local ev = (type(arg1_param) == "string" and arg1_param) or arg2_param or event
        local a1 = (type(arg1_param) == "string" and (arg2_param or arg1)) or arg1

        local power = UnitPowerType("player")
        if power == 0 then
            this.mode = "MANA"
            this:Show()
        elseif power == 3 then
            this.mode = "ENERGY"
            this:Show()
        else
            this:Hide()
        end

        if ev == "PLAYER_ENTERING_WORLD" then
            this.lastMana = UnitMana("player")
        end

        if (ev == "UNIT_MANA" or ev == "UNIT_ENERGY") and a1 == "player" then
            this.currentMana = UnitMana("player")
            local diff = 0
            if this.lastMana then
                diff = this.currentMana - this.lastMana
            end

            if this.mode == "MANA" and diff < 0 then
                this.target = 5
            elseif this.mode == "MANA" and diff > 0 then
                if this.max ~= 5 and diff > (this.badtick and this.badtick * 1.2 or 5) then
                    this.target = 2
                else
                    this.badtick = diff
                end
            elseif this.mode == "ENERGY" and diff > 0 then
                this.target = 2
            end
            this.lastMana = this.currentMana
        end
    end)

    energytick:SetScript("OnUpdate", function()
        local bar = GetActivePowerBar()
        if not bar or not bar:IsShown() then
            if this.spark:IsShown() then this.spark:Hide() end
            return
        end

        local width = bar:GetWidth() or 0
        if width <= 0 then return end

        if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then
            if this.spark:IsShown() then this.spark:Hide() end
            return
        elseif not this.spark:IsShown() then
            this.spark:Show()
        end

        local barH = bar:GetHeight() or 10
        this.spark:SetHeight(barH + 8)

        if this.target then
            this.start, this.max = GetTime(), this.target
            this.target = nil
        end

        if this.start and this.max then
            local progress = (GetTime() - this.start) / this.max

            if progress > 1 then
                this.start = GetTime()
                this.max = 2
                progress = 0
            end

            local x = math.floor(width * progress)
            if this.lastX ~= x or this.currentBar ~= bar then
                this.lastX = x
                this.currentBar = bar
                this.spark:ClearAllPoints()
                this.spark:SetPoint("CENTER", bar, "LEFT", x, 0)
            end
        end
    end)
end
