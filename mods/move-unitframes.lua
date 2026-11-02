local FT = FostercareTweaks
if not FT then return end

-- Ctrl+Shift movers for native/custom frames and independent aura areas.
local module = FT:register({
    title = "Movable Unit Frames",
    always = true,
})
local movers = {}
local unlocker = CreateFrame("Frame", "FCTweaksUnitFrameUnlocker", UIParent)
unlocker:Hide()
unlocker.movable = false

function FT.SaveFramePosition(frame, key, relative)
    if not frame:GetLeft() or not frame:GetTop() then return end
    relative = relative or UIParent
    local positions = FostercareTweaks_Config.unitframe_positions or {}
    FostercareTweaks_Config.unitframe_positions = positions
    local point, anchor, relPoint, x, y = frame:GetPoint()
    if relative == UIParent and (not anchor or anchor == UIParent or anchor == "UIParent") then
        -- StartMoving gives native root-relative anchors; preserve their offset units.
        positions[key] = { point = point, relPoint = relPoint, x = x, y = y }
    else
        local ratio = relative:GetEffectiveScale() / frame:GetEffectiveScale()
        local rightAligned = frame.fctPositionPoint == "TOPRIGHT"
        local point = rightAligned and "TOPRIGHT" or "TOPLEFT"
        positions[key] = { point = point, relPoint = point,
            x = rightAligned and (frame:GetRight() - relative:GetRight() * ratio)
                or (frame:GetLeft() - relative:GetLeft() * ratio),
            y = frame:GetTop() - relative:GetTop() * ratio }
    end
    local p = positions[key]
    frame:ClearAllPoints()
    frame:SetPoint(p.point, relative, p.relPoint, p.x, p.y)
end

function FT.RestoreFramePosition(frame, key, relative)
    -- Where the frame stood before any saved position: a layout without one
    -- puts it back there (FT.RestoreFramePositions).
    if not frame.fctHome then
        local home = {}
        for i = 1, frame:GetNumPoints() do home[i] = { frame:GetPoint(i) } end
        frame.fctHome = home
    end
    local p = FostercareTweaks_Config.unitframe_positions
    p = p and p[key]
    if not p or not p.point or not p.relPoint or not tonumber(p.x) or not tonumber(p.y) then return false end
    frame:ClearAllPoints()
    frame:SetPoint(p.point, relative or UIParent, p.relPoint, p.x, p.y)
    return true
end

local function StopDrag(mover)
    if not mover.dragging then return end
    mover.dragging = nil
    mover.owner:StopMovingOrSizing()
    FT.SaveFramePosition(mover.owner, mover.key, mover.relative)
    if mover.onStop then mover.onStop() end
end

-- Held Ctrl+Shift shows the mover; mail, battleground and similar icons the
-- game hides until needed show too, so they can be grabbed.
local function SetMoverShown(mover, unlocked)
    local owner = mover.owner
    if unlocked then
        if owner.fctRestoreShown and not owner:IsShown() then owner.fctForcedShown = true; owner:Show() end
        mover:Show()
    else
        StopDrag(mover); mover:Hide()
        if owner.fctForcedShown then owner.fctForcedShown = nil; owner.fctRestoreShown(owner) end
    end
end

-- On every modifier key: the movers change only when Ctrl+Shift does.
function FT.UpdateFrameMovers()
    -- ClassicAPI fires from the message hook before native merged key state
    -- catches up. Its left/right queries read the bitmap updated before firing.
    local unlocked = (IsLeftShiftKeyDown() or IsRightShiftKeyDown())
        and (IsLeftControlKeyDown() or IsRightControlKeyDown()) and true or false
    if unlocked == unlocker.movable then return end
    unlocker.movable = unlocked
    if unlocker.grid then
        if unlocked then unlocker.grid:Show() else unlocker.grid:Hide() end
    end
    for _, mover in ipairs(movers) do SetMoverShown(mover, unlocked) end
end

-- onStop runs after a drag; onRestore(saved) after a layout change placed the
-- frame again (FT.RestoreFramePositions).
function FT.RegisterFrameMover(frame, key, label, relative, onStop, onRestore)
    if not frame or frame.fctMover then return end
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    local mover = CreateFrame("Frame", nil, frame)
    mover.owner, mover.key, mover.relative = frame, key, relative or UIParent
    mover.onStop, mover.onRestore = onStop, onRestore
    mover:SetAllPoints(frame)
    mover:SetFrameLevel(frame:GetFrameLevel() + 20)
    mover:EnableMouse(true)
    mover:RegisterForDrag("LeftButton")
    mover:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    mover:SetBackdropColor(0.08, 0.16, 0.22, 0.75)
    mover:SetBackdropBorderColor(0.4, 0.75, 1, 0.9)
    mover.label = mover:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    mover.label:SetPoint("CENTER", mover, "CENTER", 0, 0)
    mover.label:SetText(label)
    mover:SetScript("OnDragStart", function()
        if not unlocker.movable then return end
        this.dragging = true
        this.owner:StartMoving()
    end)
    mover:SetScript("OnDragStop", function() StopDrag(this) end)
    mover:SetScript("OnHide", function() StopDrag(this) end)
    frame.fctMover = mover
    table.insert(movers, mover)
    SetMoverShown(mover, unlocker.movable)
end

-- A layout change (Profiles.lua) replaces every saved position at once: each
-- frame goes to its saved place, or home.
function FT.RestoreFramePositions()
    for _, mover in ipairs(movers) do
        local owner = mover.owner
        local saved = FT.RestoreFramePosition(owner, mover.key, mover.relative)
        if not saved and owner.fctHome[1] then
            owner:ClearAllPoints()
            for _, p in ipairs(owner.fctHome) do owner:SetPoint(p[1], p[2], p[3], p[4], p[5]) end
        end
        if mover.onRestore then mover.onRestore(saved) end
    end
end

module.enable = function()
    if unlocker.initialized then
        FT.UpdateFrameMovers()
        return
    end
    if not unlocker.grid then
        unlocker.grid = CreateFrame("Frame", "FCTweaksGridFrame", WorldFrame)
        unlocker.grid:SetAllPoints(WorldFrame)
        unlocker.grid:Hide()

        local size = 1
        local width = GetScreenWidth()
        local height = GetScreenHeight()
        local ratio = width / height
        local rheight = height * ratio

        local wStep = width / 64
        local hStep = rheight / 64

        for i = 0, 64 do
            local line
            if i == 32 then
                line = unlocker.grid:CreateTexture(nil, "BORDER")
                line:SetTexture(0.8, 0.6, 0)
            else
                line = unlocker.grid:CreateTexture(nil, "BACKGROUND")
                line:SetTexture(0, 0, 0, 0.2)
            end
            line:SetPoint("TOPLEFT", unlocker.grid, "TOPLEFT", i * wStep - (size / 2), 0)
            line:SetPoint("BOTTOMRIGHT", unlocker.grid, "BOTTOMLEFT", i * wStep + (size / 2), 0)
        end

        for i = 1, math.floor(height / hStep) do
            local line
            if i == math.floor(height / hStep / 2) then
                line = unlocker.grid:CreateTexture(nil, "BORDER")
                line:SetTexture(0.8, 0.6, 0)
            else
                line = unlocker.grid:CreateTexture(nil, "BACKGROUND")
                line:SetTexture(0, 0, 0, 0.2)
            end
            line:SetPoint("TOPLEFT", unlocker.grid, "TOPLEFT", 0, -(i * hStep) + (size / 2))
            line:SetPoint("BOTTOMRIGHT", unlocker.grid, "TOPRIGHT", 0, -(i * hStep + size / 2))
        end
    end
    unlocker:RegisterEvent("MODIFIER_STATE_CHANGED")
    unlocker:RegisterEvent("PLAYER_LOGIN")
    FT.SetEventHandler(unlocker, FT.UpdateFrameMovers)
    for _, entry in ipairs({
        { "PlayerFrame", "standard_player", "Player" },
        { "TargetFrame", "standard_target", "Target" },
        { "TargetofTargetFrame", "standard_targettarget", "Target of Target" },
    }) do
        local frame = _G[entry[1]]
        if frame then
            FT.RestoreFramePosition(frame, entry[2])
            FT.RegisterFrameMover(frame, entry[2], entry[3])
        end
    end
    unlocker.initialized = true
    FT.UpdateFrameMovers()
end
