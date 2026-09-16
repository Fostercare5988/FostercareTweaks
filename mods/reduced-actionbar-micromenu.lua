-- FostercareTweaks: mods/reduced-actionbar-micromenu.lua
local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Show Micro Menu"],
    description = T["Shows micro menu buttons when using the reduced actionbar layout. Hold Ctrl+Shift to move the micro menu."],
    category = T["Action Bar"],
    config = {
        ["panelmicro.scale"] = 1,
    },
    enabled = nil,
})

module.enable = function(self)
    if FostercareTweaks_Config[T["Reduced Actionbar Size"]] == 0 then return end

    local frames = {
        CharacterMicroButton, SpellbookMicroButton, TalentMicroButton,
        QuestLogMicroButton, MainMenuMicroButton, SocialsMicroButton,
        WorldMapMicroButton, HelpMicroButton
    }

    local microframe = CreateFrame("Button", "FCTweaksReducedActionBarMicroMenu", UIParent)
    microframe:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -8, 8)
    microframe:SetWidth(225)
    microframe:SetHeight(44)
    microframe:SetScale(module.config["panelmicro.scale"] or 1)
    microframe:SetFrameStrata("MEDIUM")

    microframe:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    microframe:SetBackdropBorderColor(0.9, 0.8, 0.5, 1)
    microframe:SetBackdropColor(0.4, 0.4, 0.4, 1)

    microframe:SetClampedToScreen(true)
    microframe:SetMovable(true)
    microframe:EnableMouse(true)
    microframe:RegisterForDrag("LeftButton")
    microframe:SetUserPlaced(true)

    microframe:SetScript("OnDragStart", function()
        if not IsShiftKeyDown() or not IsControlKeyDown() then return end
        this:StartMoving()
    end)

    microframe:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)

    local function CheckMouseOver()
        if MouseIsOver(microframe) and IsShiftKeyDown() and IsControlKeyDown() then
            if not microframe.mousedisabled then
                microframe.mousedisabled = true
                for _, f in ipairs(frames) do
                    if f then f:EnableMouse(false) end
                end
            end
        else
            if microframe.mousedisabled then
                microframe.mousedisabled = false
                for _, f in ipairs(frames) do
                    if f then f:EnableMouse(true) end
                end
            end
        end
    end

    local function LayoutMicro()
        for id, f in ipairs(frames) do
            if f then
                local anchor = frames[id - 1] or microframe
                f:ClearAllPoints()
                f:SetPoint("BOTTOMLEFT", anchor, id == 1 and "BOTTOMLEFT" or "BOTTOMRIGHT", id == 1 and 5 or -4, id == 1 and 2 or 0)
                f:SetParent(microframe)
                f.Show = nil
                f:Show()
            end
        end
    end

    microframe:RegisterEvent("MODIFIER_STATE_CHANGED")
    microframe:RegisterEvent("PLAYER_ENTERING_WORLD")
    microframe:SetScript("OnEvent", function(arg1_param, arg2_param)
        local ev = (type(arg1_param) == "table" and (arg2_param or event)) or (type(arg1_param) == "string" and arg1_param) or arg2_param or event
        if ev == "MODIFIER_STATE_CHANGED" then
            if IsShiftKeyDown() and IsControlKeyDown() then
                microframe:SetScript("OnUpdate", CheckMouseOver)
                CheckMouseOver()
            else
                microframe:SetScript("OnUpdate", nil)
                if microframe.mousedisabled then
                    microframe.mousedisabled = false
                    for _, f in ipairs(frames) do
                        if f then f:EnableMouse(true) end
                    end
                end
            end
        elseif ev == "PLAYER_ENTERING_WORLD" then
            LayoutMicro()
        end
    end)
    LayoutMicro()
end
