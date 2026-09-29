if not FostercareTweaks then return end

-- Related modules; settings remain independent.

do
local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Reduced Actionbar Size"],
    description = T["Reduces the actionbar size by removing several items such as the bag panel and microbar."],
    category = T["Action Bar"],
    enabled = nil,
})

local function ReplaceBag()
    local id = this:GetID()
    if id ~= 0 then
        id = ContainerIDToInventoryID(id)
        if CursorHasItem() then
            PutItemInBag(id)
        else
            PickupBagFromSlot(id)
        end
    end
end

module.enable = function(self)
    local function hide(frame, mode)
        if not frame then return end
        if mode == 1 and frame.SetTexture then
            frame:SetTexture("")
        elseif mode == 2 and frame.SetNormalTexture then
            frame:SetNormalTexture("")
        else
            frame:ClearAllPoints()
            frame.Show = function() return end
            frame:Hide()
        end
    end

    local frames = {
        MainMenuBarPageNumber, ActionBarUpButton, ActionBarDownButton,
        MainMenuXPBarTexture2, MainMenuXPBarTexture3,
        ReputationWatchBarTexture2, ReputationWatchBarTexture3,
        MainMenuBarTexture2, MainMenuBarTexture3,
        MainMenuMaxLevelBar2, MainMenuMaxLevelBar3,
        CharacterMicroButton, SpellbookMicroButton, TalentMicroButton,
        QuestLogMicroButton, MainMenuMicroButton, SocialsMicroButton,
        WorldMapMicroButton, MainMenuBarPerformanceBarFrame, HelpMicroButton,
        CharacterBag3Slot, CharacterBag2Slot, CharacterBag1Slot,
        CharacterBag0Slot, MainMenuBarBackpackButton, KeyRingButton,
        ShapeshiftBarLeft, ShapeshiftBarMiddle, ShapeshiftBarRight,
    }

    local textures = {
        ReputationWatchBarTexture2, ReputationWatchBarTexture3,
        ReputationXPBarTexture2, ReputationXPBarTexture3,
        SlidingActionBarTexture0, SlidingActionBarTexture1,
    }

    local normtextures = {
        ShapeshiftButton1, ShapeshiftButton2,
        ShapeshiftButton3, ShapeshiftButton4,
        ShapeshiftButton5, ShapeshiftButton6,
        ShapeshiftButton7, ShapeshiftButton8,
        ShapeshiftButton9, ShapeshiftButton10,
        ShapeshiftButton11, ShapeshiftButton12,
    }

    local resizes = {
        MainMenuBar, MainMenuExpBar, MainMenuBarMaxLevelBar,
        ReputationWatchBar, ReputationWatchStatusBar,
    }

    for _, f in ipairs(frames) do hide(f) end
    for _, f in ipairs(textures) do hide(f, 1) end
    for _, f in ipairs(normtextures) do hide(f, 2) end
    for _, f in ipairs(resizes) do if f then f:SetWidth(511) end end

    if MainMenuXPBarTexture0 and MainMenuExpBar then MainMenuXPBarTexture0:SetPoint("LEFT", MainMenuExpBar, "LEFT") end
    if MainMenuXPBarTexture1 and MainMenuExpBar then MainMenuXPBarTexture1:SetPoint("RIGHT", MainMenuExpBar, "RIGHT") end

    if ReputationWatchBar and MainMenuExpBar then
        ReputationWatchBar:SetPoint("BOTTOM", MainMenuExpBar, "TOP", 0, 0)
        ReputationWatchBarTexture0:SetPoint("LEFT", ReputationWatchBar, "LEFT")
        ReputationWatchBarTexture1:SetPoint("RIGHT", ReputationWatchBar, "RIGHT")
    end

    if MainMenuMaxLevelBar0 and MainMenuBarArtFrame then MainMenuMaxLevelBar0:SetPoint("LEFT", MainMenuBarArtFrame, "LEFT") end
    if MainMenuBarTexture0 and MainMenuBarArtFrame then MainMenuBarTexture0:SetPoint("LEFT", MainMenuBarArtFrame, "LEFT") end
    if MainMenuBarTexture1 and MainMenuBarArtFrame then MainMenuBarTexture1:SetPoint("RIGHT", MainMenuBarArtFrame, "RIGHT") end

    if MainMenuBarLeftEndCap and MainMenuBarArtFrame then MainMenuBarLeftEndCap:SetPoint("RIGHT", MainMenuBarArtFrame, "LEFT", 29.5, 0) end
    if MainMenuBarRightEndCap and MainMenuBarArtFrame then MainMenuBarRightEndCap:SetPoint("LEFT", MainMenuBarArtFrame, "RIGHT", -31.5, 0) end

    if MultiBarBottomRight and MultiBarBottomLeft then
        MultiBarBottomRight:ClearAllPoints()
        MultiBarBottomRight:SetPoint("BOTTOM", MultiBarBottomLeft, "TOP", 0, 5)
    end

    local function ManageReducedFramePositions()
        if MultiBarBottomLeft then
            MultiBarBottomLeft:ClearAllPoints()
            if MainMenuExpBar:IsVisible() or ReputationWatchBar:IsVisible() then
                local anchor = (GetWatchedFactionInfo and GetWatchedFactionInfo() and ReputationWatchBar) or MainMenuExpBar
                MultiBarBottomLeft:SetPoint("BOTTOM", anchor, "TOP", 2, 3)
            else
                MultiBarBottomLeft:SetPoint("BOTTOM", MainMenuBar, "TOP", 2, -3)
            end
        end

        if PetActionBarFrame then
            PetActionBarFrame:ClearAllPoints()
            local anchor = MainMenuBarArtFrame
            anchor = (MultiBarBottomLeft and MultiBarBottomLeft:IsVisible() and MultiBarBottomLeft) or anchor
            anchor = (MultiBarBottomRight and MultiBarBottomRight:IsVisible() and MultiBarBottomRight) or anchor
            anchor = (ShapeshiftBarFrame and ShapeshiftBarFrame:IsVisible() and ShapeshiftBarFrame) or anchor
            PetActionBarFrame:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 20, 4)
        end

        if ShapeshiftBarFrame then
            ShapeshiftBarFrame:ClearAllPoints()
            local anchor = ActionButton1
            anchor = (MultiBarBottomLeft and MultiBarBottomLeft:IsVisible() and MultiBarBottomLeft) or anchor
            anchor = (MultiBarBottomRight and MultiBarBottomRight:IsVisible() and MultiBarBottomRight) or anchor

            local offset = (anchor == ActionButton1 and (MainMenuExpBar:IsVisible() or ReputationWatchBar:IsVisible()) and 6) or 0
            offset = (anchor == ActionButton1) and (offset + 4) or offset
            ShapeshiftBarFrame:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 8, 4 + offset)
        end

        if CastingBarFrame then
            local anchor = MainMenuBarArtFrame
            anchor = (MultiBarBottomLeft and MultiBarBottomLeft:IsVisible() and MultiBarBottomLeft) or anchor
            anchor = (MultiBarBottomRight and MultiBarBottomRight:IsVisible() and MultiBarBottomRight) or anchor
            local pet_offset = (PetActionBarFrame and PetActionBarFrame:IsVisible()) and 40 or 0
            local stance_offset = (ShapeshiftBarFrame and ShapeshiftBarFrame:IsVisible()) and 40 or 0
            CastingBarFrame:SetPoint("BOTTOM", anchor, "TOP", 0, 10 + pet_offset + stance_offset)
        end
    end

    FostercareTweaks.hooksecurefunc("UIParent_ManageFramePositions", ManageReducedFramePositions)

    local restore = CreateFrame("Frame", nil, UIParent)
    restore:SetScript("OnShow", ManageReducedFramePositions)

    FostercareTweaks.hooksecurefunc("ShowPetActionBar", function()
        PETACTIONBAR_XPOS = 36
    end)

    for i = 1, 5 do
        local portrait = _G["ContainerFrame" .. i .. "PortraitButton"]
        if portrait then
            portrait:SetScript("OnClick", ReplaceBag)
        end
    end
end
end

do
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
end

do
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
end
