-- FostercareTweaks: mods/reduced-actionbar.lua
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
