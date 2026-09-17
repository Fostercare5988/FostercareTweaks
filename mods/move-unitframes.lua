-- FostercareTweaks: mods/move-unitframes.lua
local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Movable Unit Frames"],
    description = T["Player and Target unit frames can be moved while <Shift> and <Ctrl> are pressed together."],
    category = T["Unit Frames"],
    enabled = true,
})

local movables = { "PlayerFrame", "TargetFrame", "FCTweaksPlayerFrame", "FCTweaksTargetFrame", "FCTweaksRaidFrame" }

module.enable = function(self)
    local unlocker = CreateFrame("Frame", "FCTweaksUnitFrameUnlocker", UIParent)
    unlocker:SetAllPoints(UIParent)

    for _, frame in ipairs(movables) do
        if _G[frame] then
            _G[frame]:SetClampedToScreen(true)
        end
    end

    local leftShiftDown = false
    local rightShiftDown = false
    local leftCtrlDown = false
    local rightCtrlDown = false

    unlocker.movable = nil
    unlocker:RegisterEvent("MODIFIER_STATE_CHANGED")
    unlocker:SetScript("OnEvent", function()
        local key = arg1
        local state = arg2
        if key == "LSHIFT" then
            leftShiftDown = (state == 1)
        elseif key == "RSHIFT" then
            rightShiftDown = (state == 1)
        elseif key == "LCTRL" then
            leftCtrlDown = (state == 1)
        elseif key == "RCTRL" then
            rightCtrlDown = (state == 1)
        else
            return
        end

        local shiftDown = leftShiftDown or rightShiftDown
        local ctrlDown = leftCtrlDown or rightCtrlDown

        if shiftDown and ctrlDown then
            if not unlocker.movable then
                for _, frame in ipairs(movables) do
                    local f = _G[frame]
                    if f then
                        f:SetUserPlaced(true)
                        f:SetMovable(true)
                        f:EnableMouse(true)
                        f:RegisterForDrag("LeftButton")
                        f:SetScript("OnDragStart", function() this:StartMoving() end)
                        f:SetScript("OnDragStop", function()
                            this:StopMovingOrSizing()
                            local saveKey = this.unit or (this.GetName and this:GetName() == "FCTweaksRaidFrame" and "raid")
                            if saveKey and FostercareTweaks_Config then
                                if not FostercareTweaks_Config.unitframe_positions then
                                    FostercareTweaks_Config.unitframe_positions = {}
                                end
                                local point, _, relPoint, x, y = this:GetPoint()
                                FostercareTweaks_Config.unitframe_positions[saveKey] = {
                                    point = point or "CENTER",
                                    relPoint = relPoint or "CENTER",
                                    x = x or 0,
                                    y = y or 0
                                }
                            end
                        end)
                    end
                end

                unlocker.movable = true
                unlocker.grid:Show()
            end
        elseif unlocker.movable then
            for _, frame in ipairs(movables) do
                local f = _G[frame]
                if f then
                    f:SetScript("OnDragStart", function() end)
                    f:SetScript("OnDragStop", function() end)
                    f:StopMovingOrSizing()
                    local saveKey = f.unit or (f.GetName and f:GetName() == "FCTweaksRaidFrame" and "raid")
                    if saveKey and FostercareTweaks_Config then
                        if not FostercareTweaks_Config.unitframe_positions then
                            FostercareTweaks_Config.unitframe_positions = {}
                        end
                        local point, _, relPoint, x, y = f:GetPoint()
                        FostercareTweaks_Config.unitframe_positions[saveKey] = {
                            point = point or "CENTER",
                            relPoint = relPoint or "CENTER",
                            x = x or 0,
                            y = y or 0
                        }
                    end
                    if f.GetName and f:GetName() == "FCTweaksRaidFrame" then
                        f:EnableMouse(false)
                    end
                end
            end

            unlocker.movable = nil
            unlocker.grid:Hide()
        end
    end)

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

    for i = 1, floor(height / hStep) do
        local line
        if i == floor(height / hStep / 2) then
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
