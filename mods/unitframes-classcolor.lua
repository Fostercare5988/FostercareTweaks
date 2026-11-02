local FT = FostercareTweaks
if not FT then return end

-- FostercareTweaks: mods/unitframes-classcolor.lua
-- World of Warcraft 1.12.1 Enhanced Client
-- Colors standard player and target name backgrounds by class.
-- Health bars remain standard Blizzard green.

local module = FT:register({
    title = "Unit Frame Class Colors",
    enabled = true,
})

local function IsActive()
    return FostercareTweaks_Config["Unit Frame Class Colors"] ~= 0
end

-- The raid frames' (Luna) class colours; nil for a unit with no class.
local function GetClassColor(unit)
    local _, class = UnitClass(unit)
    return FT.UnitFrames.ClassColors[FT.NormalizeClass(class) or ""]
end

local ownsPlayerBackground = false
local originalPartyColors = {}

-- The player and target frames hold a 50% black square on the BACKGROUND layer
-- where the name sits. A class color on that layer is drawn above or below it
-- at random, so it looked right one session and olive the next. Class bars
-- therefore live on BORDER, always above the square and below the frame art,
-- with Blizzard's own name-bar texture at full class color. NPC targets keep
-- Blizzard's name background and its reaction colors.
local CLASS_FILL = "Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground"

local function EnsurePlayerBackground()
    if not PlayerFrameNameBackground then
        PlayerFrameNameBackground = PlayerFrame:CreateTexture(nil, "BORDER")
        PlayerFrameNameBackground:SetTexture(CLASS_FILL)
        PlayerFrameNameBackground:SetWidth(119)
        PlayerFrameNameBackground:SetHeight(19)
        PlayerFrameNameBackground:SetPoint("TOPLEFT", 106, -22)
        ownsPlayerBackground = true
    end
end

local function ColorPlayer()
    if not IsActive() then return end
    local color = GetClassColor("player")
    if color then
        EnsurePlayerBackground()
        PlayerFrameNameBackground:SetTexture(CLASS_FILL)
        PlayerFrameNameBackground:SetVertexColor(color.r, color.g, color.b, 1)
        PlayerFrameNameBackground:Show()
    end
end

local targetClassBar
local function ColorTarget()
    if not IsActive() then return end
    if not targetClassBar then
        targetClassBar = TargetFrame:CreateTexture(nil, "BORDER")
        targetClassBar:SetTexture(CLASS_FILL)
        targetClassBar:SetAllPoints(TargetFrameNameBackground)
        targetClassBar:Hide()
    end
    local color = UnitExists("target") and UnitIsPlayer("target") and GetClassColor("target")
    if color then
        targetClassBar:SetVertexColor(color.r, color.g, color.b, 1)
        targetClassBar:Show()
    else
        -- NPCs (like Scarlet Myrmidon): Blizzard's TargetFrame_CheckFaction colors
        -- its own name background red, yellow or green.
        targetClassBar:Hide()
        TargetFrameNameBackground:Show()
    end
end

local function ColorParty()
    if not IsActive() then return end
    for id = 1, MAX_PARTY_MEMBERS do
        local name = _G["PartyMemberFrame" .. id .. "Name"]
        local unit = "party" .. id
        if UnitExists(unit) then
            local color = GetClassColor(unit)
            if color and name then
                if not originalPartyColors[name] then
                    originalPartyColors[name] = { name:GetTextColor() }
                end
                name:SetTextColor(color.r, color.g, color.b, 1)
            end
        end
    end
end

local function RestoreParty()
    for name, color in pairs(originalPartyColors) do
        if name and name.SetTextColor then
            name:SetTextColor(unpack(color))
        end
    end
    originalPartyColors = {}
end

local function ApplyAll()
    if not IsActive() then return end
    ColorPlayer()
    ColorTarget()
    ColorParty()
end

local hooksInstalled = false
local function EnsureHooks()
    if hooksInstalled then return end
    hooksInstalled = true

    hooksecurefunc("TargetFrame_CheckFaction", ColorTarget)
    hooksecurefunc("TargetFrame_Update", ColorTarget)
    hooksecurefunc("PlayerFrame_Update", ColorPlayer)
    hooksecurefunc("PartyMemberFrame_UpdateMember", ColorParty)

    -- Target and party changes reach the hooks above; the player's class
    -- never changes, so the world entry repaints once.
    local worldRefresh = CreateFrame("Frame")
    worldRefresh:RegisterEvent("PLAYER_ENTERING_WORLD")
    FT.SetEventHandler(worldRefresh, ApplyAll)
end

function module:apply()
    if IsActive() then
        EnsureHooks()
        ApplyAll()
    else
        if PlayerFrameNameBackground and ownsPlayerBackground then
            PlayerFrameNameBackground:Hide()
        end
        if targetClassBar then targetClassBar:Hide() end
        if UnitExists("target") then
            TargetFrame_CheckFaction()
        end
        RestoreParty()
    end
end

module.enable = function(self)
    self:apply()
end
