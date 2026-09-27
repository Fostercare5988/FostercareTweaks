-- Ctrl+Shift movers for native/custom frames and independent aura areas.
local T = FostercareTweaks.T
local module = FostercareTweaks:register({
    title = T["Movable Unit Frames"],
    description = T["Hold Ctrl+Shift to move unit frames and their buff/debuff areas."],
    category = T["Unit Frames"], enabled = true,
})
local movers = {}
local unlocker = CreateFrame("Frame", "FCTweaksUnitFrameUnlocker", UIParent)
unlocker:Hide()

function FostercareTweaks.SaveFramePosition(frame, key, relative)
    if not FostercareTweaks_Config or not frame:GetLeft() or not frame:GetTop() then return end
    relative = relative or UIParent
    local positions = FostercareTweaks_Config.unitframe_positions or {}
    FostercareTweaks_Config.unitframe_positions = positions
    local point, anchor, relPoint, x, y = frame:GetPoint()
    if relative == UIParent and (not anchor or anchor == UIParent or anchor == "UIParent") then
        -- StartMoving gives native root-relative anchors; preserve their offset units.
        positions[key] = { point = point, relPoint = relPoint, x = x, y = y }
    else
        local ratio = relative:GetEffectiveScale() / frame:GetEffectiveScale()
        positions[key] = { point = "TOPLEFT", relPoint = "TOPLEFT",
            x = frame:GetLeft() - relative:GetLeft() * ratio,
            y = frame:GetTop() - relative:GetTop() * ratio }
    end
    local p = positions[key]
    frame:ClearAllPoints()
    frame:SetPoint(p.point, relative, p.relPoint, p.x, p.y)
end

function FostercareTweaks.RestoreFramePosition(frame, key, relative)
    local p = FostercareTweaks_Config and FostercareTweaks_Config.unitframe_positions
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
    FostercareTweaks.SaveFramePosition(mover.owner, mover.key, mover.relative)
    if mover.onStop then mover.onStop() end
end

function FostercareTweaks.UpdateFrameMovers()
    local cfg = FostercareTweaks_Config
    local enabled = not cfg or cfg[T["Movable Unit Frames"]] ~= 0
    -- ClassicAPI fires from the message hook before native merged key state
    -- catches up. Its left/right queries read the bitmap updated before firing.
    local shiftDown = IsLeftShiftKeyDown() or IsRightShiftKeyDown()
    local controlDown = IsLeftControlKeyDown() or IsRightControlKeyDown()
    local unlocked = enabled and shiftDown and controlDown
    unlocker.movable = unlocked and true or nil
    if unlocker.grid then
        if unlocked then unlocker.grid:Show() else unlocker.grid:Hide() end
    end
    for _, mover in ipairs(movers) do
        if unlocked then mover:Show()
        else StopDrag(mover); mover:Hide() end
    end
end

function FostercareTweaks.RegisterFrameMover(frame, key, label, relative, onStop)
    if not frame or frame.fctMover then return end
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    local mover = CreateFrame("Frame", nil, frame)
    mover.owner, mover.key, mover.relative = frame, key, relative or UIParent
    mover.onStop = onStop
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
    FostercareTweaks.UpdateFrameMovers()
end

module.enable = function()
    if unlocker.initialized then
        FostercareTweaks.UpdateFrameMovers()
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
    unlocker:SetScript("OnEvent", FostercareTweaks.UpdateFrameMovers)
    for _, entry in ipairs({
        { "PlayerFrame", "standard_player", "Player" },
        { "TargetFrame", "standard_target", "Target" },
        { "TargetofTargetFrame", "standard_targettarget", "Target of Target" },
    }) do
        local frame = _G[entry[1]]
        if frame then
            FostercareTweaks.RestoreFramePosition(frame, entry[2])
            FostercareTweaks.RegisterFrameMover(frame, entry[2], entry[3])
        end
    end
    unlocker.initialized = true
    FostercareTweaks.UpdateFrameMovers()
end
