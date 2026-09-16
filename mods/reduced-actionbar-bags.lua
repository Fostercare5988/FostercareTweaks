-- FostercareTweaks: mods/reduced-actionbar-bags.lua
local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Show Bags"],
    description = T["Shows bag and keyring buttons when using the reduced actionbar layout. Hold Ctrl+Shift to move the bag bar."],
    category = T["Action Bar"],
    config = {
        ["panelbag.scale"] = 1,
    },
    enabled = nil,
})

module.enable = function(self)
    if FostercareTweaks_Config[T["Reduced Actionbar Size"]] == 0 then return end

    local frames = {
        KeyRingButton, CharacterBag3Slot, CharacterBag2Slot, CharacterBag1Slot,
        CharacterBag0Slot, MainMenuBarBackpackButton,
    }

    local bagframe = CreateFrame("Button", "FCTweaksReducedActionBarBags", UIParent)
    bagframe:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -8, 48)
    bagframe:SetWidth(180)
    bagframe:SetHeight(42)
    bagframe:SetScale(module.config["panelbag.scale"] or 1)
    bagframe:SetFrameStrata("MEDIUM")

    bagframe:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    bagframe:SetBackdropBorderColor(0.9, 0.8, 0.5, 1)
    bagframe:SetBackdropColor(0.4, 0.4, 0.4, 1)

    bagframe:SetClampedToScreen(true)
    bagframe:SetMovable(true)
    bagframe:EnableMouse(true)
    bagframe:RegisterForDrag("LeftButton")
    bagframe:SetUserPlaced(true)

    bagframe:SetScript("OnDragStart", function()
        if not IsShiftKeyDown() or not IsControlKeyDown() then return end
        this:StartMoving()
    end)

    bagframe:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)

    local function CheckMouseOver()
        if MouseIsOver(bagframe) and IsShiftKeyDown() and IsControlKeyDown() then
            if not bagframe.mousedisabled then
                bagframe.mousedisabled = true
                for _, f in ipairs(frames) do
                    if f then f:EnableMouse(false) end
                end
            end
        else
            if bagframe.mousedisabled then
                bagframe.mousedisabled = false
                for _, f in ipairs(frames) do
                    if f then f:EnableMouse(true) end
                end
            end
        end
    end

    local function LayoutBags()
        for id, f in ipairs(frames) do
            if f then
                local anchor = frames[id - 1] or bagframe
                f:ClearAllPoints()
                f:SetPoint("LEFT", anchor, id == 1 and "LEFT" or "RIGHT", id == 1 and 5 or 2, 0)
                f:SetParent(bagframe)
                f:SetScale(0.8)
                f.Show = nil
                f:Show()
            end
        end
    end

    bagframe:RegisterEvent("MODIFIER_STATE_CHANGED")
    bagframe:RegisterEvent("PLAYER_ENTERING_WORLD")
    bagframe:SetScript("OnEvent", function(arg1_param, arg2_param)
        local ev = (type(arg1_param) == "table" and (arg2_param or event)) or (type(arg1_param) == "string" and arg1_param) or arg2_param or event
        if ev == "MODIFIER_STATE_CHANGED" then
            if IsShiftKeyDown() and IsControlKeyDown() then
                bagframe:SetScript("OnUpdate", CheckMouseOver)
                CheckMouseOver()
            else
                bagframe:SetScript("OnUpdate", nil)
                if bagframe.mousedisabled then
                    bagframe.mousedisabled = false
                    for _, f in ipairs(frames) do
                        if f then f:EnableMouse(true) end
                    end
                end
            end
        elseif ev == "PLAYER_ENTERING_WORLD" then
            LayoutBags()
        end
    end)
    LayoutBags()
end
