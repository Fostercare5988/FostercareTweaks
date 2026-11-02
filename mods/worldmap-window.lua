local FT = FostercareTweaks
if not FT then return end

-- World map additions; the client's own windowed map (the map's minimize
-- button) replaced our own map window on 2026-11-01.

do
-- The client's windowed map draws at a fixed size (WORLDMAP_WINDOWED_SCALE).
-- Its size is a setting: the slider in the window, or Ctrl + mouse wheel on
-- the map. The full-screen map is never scaled.
local module = FT:register({
    title = "WorldMap Window Size",
    always = true,
    config = { worldmap_scale = 1 },
})
local MIN, MAX = 0.6, 2

-- Native Minimize/Maximize keep the frame's own scale; set it after them.
-- A size change keeps the window's centre where it is on screen.
local function Apply()
    local scale = WORLDMAP_WINDOWED == 1 and FT.GetNumber("worldmap_scale", 1, MIN, MAX) or 1
    local old = WorldMapFrame:GetScale()
    if old == scale then return end
    local x, y = WorldMapFrame:GetCenter()
    WorldMapFrame:SetScale(scale)
    if x and WORLDMAP_WINDOWED == 1 then
        WorldMapFrame:ClearAllPoints()
        WorldMapFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x * old / scale, y * old / scale)
    end
end
FT.ApplyWorldMapScale = Apply

module.enable = function()
    hooksecurefunc("WorldMapFrame_Minimize", Apply)
    hooksecurefunc("WorldMapFrame_Maximize", Apply)
    WorldMapFrame:EnableMouseWheel(true)
    FT.HookScript(WorldMapFrame, "OnMouseWheel", function(_, delta)
        if WORLDMAP_WINDOWED ~= 1 or not IsControlKeyDown() then return end
        local value = FT.GetNumber("worldmap_scale", 1, MIN, MAX) + (delta or 0) * 0.05
        FT.SetOverride("worldmap_scale", math.max(MIN, math.min(MAX, math.floor(value * 20 + 0.5) / 20)))
        Apply()
    end)
    Apply()
end
end

do
-- Your and the cursor's coordinates under the world map, on the map it shows:
-- GetPlayerMapPosition reads the shown map and gives 0, 0 when you are not on
-- it. The labels belong to the map, so their timer stops when it closes.
local module = FT:register({
    title = "WorldMap Coordinates",
    enabled = true,
})

module.enable = function(self)
    local function Label(name, title, point, x)
        local label = CreateFrame("Frame", name, WorldMapButton)
        label.title = "|cffffcc00" .. title .. ": |r"
        label.text = label:CreateFontString(nil, "OVERLAY", "GameFontWhite")
        label.text:SetPoint(point, WorldMapButton, point, x, -21)
        return label
    end
    local cursor = Label("FCTweaksWorldMapCursorCoords", "Cursor", "BOTTOMLEFT", 3)
    local player = Label("FCTweaksWorldMapPlayerCoords", "Player", "BOTTOMRIGHT", -3)
    -- x and y are fractions of the map, shown in percent to a tenth; the text
    -- is built only when that changes. No position shows N/A.
    local function Show(label, x, y)
        if x then x, y = math.floor(x * 1000 + 0.5) / 10, math.floor(y * 1000 + 0.5) / 10 end
        if label.fctSet and label.x == x and label.y == y then return end
        label.fctSet, label.x, label.y = true, x, y
        if x then label.text:SetText(string.format("%s%.1f / %.1f", label.title, x, y))
        else label.text:SetText(label.title .. "N/A") end
    end
    local elapsed = 0
    cursor:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed < 0.1 then return end
        elapsed = 0
        local x, y = GetPlayerMapPosition("player")
        if x == 0 and y == 0 then Show(player) else Show(player, x, y) end
        local left, top = WorldMapButton:GetLeft(), WorldMapButton:GetTop()
        if left and MouseIsOver(WorldMapButton) then
            local scale = WorldMapButton:GetEffectiveScale()
            x, y = GetCursorPosition()
            Show(cursor, (x / scale - left) / WorldMapButton:GetWidth(), (top - y / scale) / WorldMapButton:GetHeight())
        else
            Show(cursor)
        end
    end)
end
end

do
-- Group members in class colours on the world and battleground maps. The
-- native map moves its group buttons and gives them other units while it is
-- open, so a 0.2 s timer colours them, and only then.
local module = FT:register({
    title = "WorldMap Class Colors",
    enabled = true,
})

local myPartyNames = {}

-- C_PlayerCache also knows raid members that are out of range.
local function GetUnitClassToken(unit, name)
    local token
    if unit and UnitExists(unit) then
        local _, class = UnitClass(unit)
        token = FT.NormalizeClass(class)
    end
    token = token or FT.GetPlayerClass(name or (unit and UnitName(unit)))
    if token and RAID_CLASS_COLORS[token] then return token end
end

local function UpdateButton(frame, defaultUnit)
    if not frame:IsShown() then
        if frame.texture then frame.texture:Hide() end
        return
    end

    local unit = frame.unit or defaultUnit
    local name = frame.name or (unit and UnitExists(unit) and UnitName(unit))
    if not unit and not name then
        if frame.texture then frame.texture:Hide() end
        return
    end

    -- Looked up once: building the name every tick fed the garbage collector,
    -- whose full pass took over 100 ms in raids (/lag, 2026-10-25).
    local icon = frame.fctIcon
    if icon == nil then icon = _G[frame:GetName() .. "Icon"] or false; frame.fctIcon = icon end
    if icon and icon:GetTexture() then icon:SetTexture(nil) end

    if not frame.texture then
        frame.texture = frame:CreateTexture(nil, "OVERLAY")
        -- Keep the native hover area, with a smaller dot centered inside it.
        frame.texture:SetPoint("CENTER", frame, "CENTER", 0, 0)
        frame.texture:SetWidth(frame:GetWidth() / 2)
        frame.texture:SetHeight(frame:GetHeight() / 2)
    end
    frame.texture:Show()

    local ingroup = name and myPartyNames[name]
    if ingroup and frame.texture.ingroup ~= "PARTY" then
        frame.texture:SetTexture("Interface\\AddOns\\FostercareTweaks\\img\\circleparty")
        frame.texture.ingroup = "PARTY"
    elseif not ingroup and frame.texture.ingroup ~= "RAID" then
        frame.texture:SetTexture("Interface\\AddOns\\FostercareTweaks\\img\\circleraid")
        frame.texture.ingroup = "RAID"
    end

    local class = GetUnitClassToken(unit, name)
    local color = class and RAID_CLASS_COLORS[class]
    if color then frame.texture:SetVertexColor(color.r, color.g, color.b)
    else frame.texture:SetVertexColor(0.5, 1, 0.5) end
end

local PARTY_UNITS = { "party1", "party2", "party3", "party4" }
local groupButtons = {}

-- The map's party and raid buttons, collected once per map.
local function GroupButtons(prefix)
    local list = groupButtons[prefix]
    if list then return list end
    list = { party = {}, raid = {} }
    for i = 1, 4 do list.party[i] = _G[prefix .. "Party" .. i] or false end
    for i = 1, 40 do list.raid[i] = _G[prefix .. "Raid" .. i] or false end
    groupButtons[prefix] = list
    return list
end

local function UpdateGroupButtons(prefix)
    local list = GroupButtons(prefix)
    for i = 1, 4 do
        if list.party[i] then UpdateButton(list.party[i], PARTY_UNITS[i]) end
    end
    for i = 1, 40 do
        if list.raid[i] then UpdateButton(list.raid[i], nil) end
    end
end

local function UpdateWorldMapColors()
    -- Party names once per tick, for the party and raid dots.
    table.wipe(myPartyNames)
    for i = 1, 4 do
        local pname = UnitName(PARTY_UNITS[i])
        if pname then myPartyNames[pname] = true end
    end
    myPartyNames[UnitName("player")] = true

    if WorldMapFrame:IsShown() then UpdateGroupButtons("WorldMap") end
    if BattlefieldMinimap and BattlefieldMinimap:IsShown() then UpdateGroupButtons("BattlefieldMinimap") end
end

-- The map's tooltip names the members under the cursor in their class colours.
local function AddName(lines, unit, name)
    if not name then return end
    local class = GetUnitClassToken(unit, name)
    lines[#lines + 1] = class and (FT.rgbhex(RAID_CLASS_COLORS[class]) .. name .. "|r") or name
end

local function ColorTooltip()
    if not WorldMapTooltip:IsShown() then return end
    local lines, list = {}, GroupButtons("WorldMap")
    if WorldMapPlayer:IsVisible() and MouseIsOver(WorldMapPlayer) then AddName(lines, "player", UnitName("player")) end
    for i, btn in ipairs(list.party) do
        if btn and btn:IsVisible() and MouseIsOver(btn) then
            local unit = btn.unit or PARTY_UNITS[i]
            AddName(lines, unit, UnitName(unit))
        end
    end
    for _, btn in ipairs(list.raid) do
        if btn and btn:IsVisible() and MouseIsOver(btn) then
            AddName(lines, btn.unit, btn.name or (btn.unit and UnitName(btn.unit)))
        end
    end
    if #lines > 0 then
        WorldMapTooltip:SetText(table.concat(lines, "\n"))
        WorldMapTooltip:Show()
    end
end

local ticker
local function SyncTicker()
    local open = WorldMapFrame:IsShown() or (BattlefieldMinimap and BattlefieldMinimap:IsShown())
    if open and not ticker then
        ticker = C_Timer.NewTicker(0.2, UpdateWorldMapColors)
        UpdateWorldMapColors()
    elseif not open and ticker then
        ticker:Cancel(); ticker = nil
    end
end

module.enable = function(self)
    hooksecurefunc("WorldMapUnit_OnEnter", ColorTooltip)
    FT.HookScript(WorldMapFrame, "OnShow", SyncTicker)
    FT.HookScript(WorldMapFrame, "OnHide", SyncTicker)
    -- The battleground map loads on demand.
    FT.HookAddonOrVariable("Blizzard_BattlefieldMinimap", function()
        FT.HookScript(BattlefieldMinimap, "OnShow", SyncTicker)
        FT.HookScript(BattlefieldMinimap, "OnHide", SyncTicker)
    end)
    SyncTicker()
end
end
