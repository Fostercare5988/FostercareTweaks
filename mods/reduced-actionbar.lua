local FT = FostercareTweaks
if not FT then return end

do

local module = FT:register({
    title = "Reduced Actionbar Size",
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

-- The highest of the two bottom bars that shows, else `base`.
local function TopBar(base)
    return MultiBarBottomRight:IsVisible() and MultiBarBottomRight
        or MultiBarBottomLeft:IsVisible() and MultiBarBottomLeft or base
end

local function ManageReducedFramePositions()
    local experience = MainMenuExpBar:IsVisible() or ReputationWatchBar:IsVisible()
    if not FT.ActionBars.enabled then
        MultiBarBottomLeft:ClearAllPoints()
        if experience then
            local anchor = (GetWatchedFactionInfo() and ReputationWatchBar) or MainMenuExpBar
            MultiBarBottomLeft:SetPoint("BOTTOM", anchor, "TOP", 2, 3)
        else
            MultiBarBottomLeft:SetPoint("BOTTOM", MainMenuBar, "TOP", 2, -3)
        end
    end

    PetActionBarFrame:ClearAllPoints()
    PetActionBarFrame:SetPoint("BOTTOMLEFT",
        ShapeshiftBarFrame:IsVisible() and ShapeshiftBarFrame or TopBar(MainMenuBarArtFrame), "TOPLEFT", 20, 4)

    local anchor = TopBar(ActionButton1)
    ShapeshiftBarFrame:ClearAllPoints()
    ShapeshiftBarFrame:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 8,
        4 + (anchor == ActionButton1 and (experience and 10 or 4) or 0))

    CastingBarFrame:SetPoint("BOTTOM", TopBar(MainMenuBarArtFrame), "TOP", 0,
        10 + (PetActionBarFrame:IsVisible() and 40 or 0) + (ShapeshiftBarFrame:IsVisible() and 40 or 0))
end

module.enable = function(self)
    -- Hidden for good: a frame the game shows again hides again; art and text
    -- have no scripts and are made clear as well.
    for _, region in ipairs({
        MainMenuBarPageNumber, ActionBarUpButton, ActionBarDownButton,
        MainMenuXPBarTexture2, MainMenuXPBarTexture3,
        MainMenuBarTexture2, MainMenuBarTexture3,
        MainMenuMaxLevelBar2, MainMenuMaxLevelBar3,
        CharacterMicroButton, SpellbookMicroButton, TalentMicroButton,
        QuestLogMicroButton, MainMenuMicroButton, SocialsMicroButton,
        WorldMapMicroButton, MainMenuBarPerformanceBarFrame, HelpMicroButton,
        CharacterBag3Slot, CharacterBag2Slot, CharacterBag1Slot,
        CharacterBag0Slot, MainMenuBarBackpackButton, KeyRingButton,
        ShapeshiftBarLeft, ShapeshiftBarMiddle, ShapeshiftBarRight,
    }) do
        region:Hide()
        if region.GetScript then FT.HookScript(region, "OnShow", region.Hide) else region:SetAlpha(0) end
    end
    for _, texture in ipairs({
        ReputationWatchBarTexture2, ReputationWatchBarTexture3,
        ReputationXPBarTexture2, ReputationXPBarTexture3,
        SlidingActionBarTexture0, SlidingActionBarTexture1,
    }) do texture:SetTexture("") end
    for i = 1, NUM_SHAPESHIFT_SLOTS do _G["ShapeshiftButton" .. i]:SetNormalTexture("") end
    for _, bar in ipairs({ MainMenuBar, MainMenuExpBar, MainMenuBarMaxLevelBar,
        ReputationWatchBar, ReputationWatchStatusBar }) do bar:SetWidth(511) end

    MainMenuXPBarTexture0:SetPoint("LEFT", MainMenuExpBar, "LEFT")
    MainMenuXPBarTexture1:SetPoint("RIGHT", MainMenuExpBar, "RIGHT")
    ReputationWatchBar:SetPoint("BOTTOM", MainMenuExpBar, "TOP", 0, 0)
    ReputationWatchBarTexture0:SetPoint("LEFT", ReputationWatchBar, "LEFT")
    ReputationWatchBarTexture1:SetPoint("RIGHT", ReputationWatchBar, "RIGHT")
    MainMenuMaxLevelBar0:SetPoint("LEFT", MainMenuBarArtFrame, "LEFT")
    MainMenuBarTexture0:SetPoint("LEFT", MainMenuBarArtFrame, "LEFT")
    MainMenuBarTexture1:SetPoint("RIGHT", MainMenuBarArtFrame, "RIGHT")
    MainMenuBarLeftEndCap:SetPoint("RIGHT", MainMenuBarArtFrame, "LEFT", 29.5, 0)
    MainMenuBarRightEndCap:SetPoint("LEFT", MainMenuBarArtFrame, "RIGHT", -31.5, 0)
    MultiBarBottomRight:ClearAllPoints()
    MultiBarBottomRight:SetPoint("BOTTOM", MultiBarBottomLeft, "TOP", 0, 5)

    hooksecurefunc("UIParent_ManageFramePositions", ManageReducedFramePositions)
    hooksecurefunc("ShowPetActionBar", function() PETACTIONBAR_XPOS = 36 end)

    for i = 1, 5 do _G["ContainerFrame" .. i .. "PortraitButton"]:SetScript("OnClick", ReplaceBag) end
end
end

