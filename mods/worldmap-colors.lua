-- FostercareTweaks: mods/worldmap-colors.lua
-- Show class colored circles on world and battlefield map (Rule AP-10, Rule C3 compliant)

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["WorldMap Class Colors"],
    description = T["Show class colored circles on world and battlefield map."],
    expansions = { ["vanilla"] = true, ["tbc"] = true },
    category = T["World & MiniMap"],
    enabled = true,
})

local function SetAllPointsOffset(frame, parent, offset)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", offset, -offset)
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -offset, offset)
end

-- Preallocate button name-to-unit mappings at load time to avoid runtime table churn
local worldmapButtons = {}
local battlefieldButtons = {}

for i = 1, 4 do
    worldmapButtons[string.format("WorldMapParty%d", i)] = string.format("party%d", i)
    battlefieldButtons[string.format("BattlefieldMinimapParty%d", i)] = string.format("party%d", i)
end
for i = 1, 40 do
    worldmapButtons[string.format("WorldMapRaid%d", i)] = string.format("raid%d", i)
    battlefieldButtons[string.format("BattlefieldMinimapRaid%d", i)] = string.format("raid%d", i)
end

local myPartyNames = {}

local function UpdateMapButtons(buttons)
    for name, unitstr in pairs(buttons) do
        local frame = _G[name]
        if frame and UnitExists(unitstr) then
            local icon = _G[name .. "Icon"]
            if icon then icon:SetTexture(nil) end

            if not frame.texture then
                frame.texture = frame:CreateTexture(nil, "OVERLAY")
                SetAllPointsOffset(frame.texture, frame, 12)
            end

            local uname = UnitName(unitstr)
            local ingroup = uname and myPartyNames[uname]

            if ingroup and frame.texture.ingroup ~= "PARTY" then
                frame.texture:SetTexture("Interface\\AddOns\\FostercareTweaks\\img\\circleparty")
                frame.texture.ingroup = "PARTY"
            elseif not ingroup and frame.texture.ingroup ~= "RAID" then
                frame.texture:SetTexture("Interface\\AddOns\\FostercareTweaks\\img\\circleraid")
                frame.texture.ingroup = "RAID"
            end

            local _, class = UnitClass(unitstr)
            if class and frame.texture.class ~= class then
                local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
                if color then
                    frame.texture:SetVertexColor(color.r, color.g, color.b)
                else
                    frame.texture:SetVertexColor(0.5, 1, 0.5)
                end
                frame.texture.class = class
            end
        end
    end
end

local function UpdateWorldMapColors()
    local showWorld = WorldMapFrame and WorldMapFrame:IsShown()
    local showBattlefield = BattlefieldMinimap and BattlefieldMinimap:IsShown()

    -- Immediate short-circuit: do zero work when maps are closed (eliminates combat stutter)
    if not showWorld and not showBattlefield then
        return
    end

    -- Pre-calculate party roster names once per tick for O(1) membership lookups
    if table.wipe then
        table.wipe(myPartyNames)
    elseif wipe then
        wipe(myPartyNames)
    else
        for k in pairs(myPartyNames) do myPartyNames[k] = nil end -- linter-ignore: B10
    end

    for i = 1, 4 do
        local pname = UnitName("party" .. i)
        if pname then myPartyNames[pname] = true end
    end
    local playerName = UnitName("player")
    if playerName then myPartyNames[playerName] = true end

    if showWorld then
        UpdateMapButtons(worldmapButtons)
    end
    if showBattlefield then
        UpdateMapButtons(battlefieldButtons)
    end
end

local function StartMapTicker(interval, callback)
    if C_Timer and C_Timer.NewTicker then
        return C_Timer.NewTicker(interval, callback)
    end

    local timerFrame = CreateFrame("Frame")
    local elapsedTotal = 0
    timerFrame:SetScript("OnUpdate", function()
        local elapsed = arg1 or 0
        elapsedTotal = elapsedTotal + elapsed
        if elapsedTotal >= interval then
            elapsedTotal = 0
            callback()
        end
    end)
    return timerFrame
end

module.enable = function(self)
    StartMapTicker(0.2, UpdateWorldMapColors)
end
