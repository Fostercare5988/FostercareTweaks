local FT = FostercareTweaks
local UF = FT and FT.UnitFrames
if not UF or not GroupFrame or type(GroupFrame_OnEvent) ~= "function" or
   type(GroupFrame_Toggle) ~= "function" then return end

-- The compact grid may be baked into FrameXML or loaded as Turtle_GroupUI.
-- Keep its saved preference; suspend only the native work while our grid owns it.
local owned, initialized = false, false
local suspended
local nativeOnEvent, nativeToggle = GroupFrame_OnEvent, GroupFrame_Toggle
local coordinatorEvents = {
    "PLAYER_ENTERING_WORLD", "CHAT_MSG_ADDON", "PLAYER_TARGET_CHANGED",
    "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "RAID_TARGET_UPDATE",
    "UNIT_NAME_UPDATE", "UNIT_PET",
}
local memberEvents = {
    "UNIT_AURA", "UNIT_HEALTH", "UNIT_DISPLAYPOWER", "UNIT_ENERGY",
    "UNIT_MAXENERGY", "UNIT_MANA", "UNIT_MAXMANA", "UNIT_RAGE", "UNIT_MAXRAGE",
}

local function SuspendFrame(frame, events)
    if not frame then return end
    local state = {frame = frame, update = frame:GetScript("OnUpdate"), events = {}}
    for _, name in ipairs(events or {}) do
        if frame:IsEventRegistered(name) then
            table.insert(state.events, name)
            frame:UnregisterEvent(name)
        end
    end
    frame:SetScript("OnUpdate", nil)
    -- Native roster refresh assigns current units again on release. Avoid stale
    -- hidden-unit work if the native preference was switched off meanwhile.
    if events == memberEvents then frame.unit = nil end
    frame:Hide()
    table.insert(suspended, state)
end

local function SuspendNative()
    if suspended then return end
    suspended = {}
    SuspendFrame(GroupFrame, coordinatorEvents)
    for group = 1, 8 do
        local name = "GroupClusterFrame" .. group
        SuspendFrame(_G[name])
        for member = 1, 5 do
            SuspendFrame(_G[name .. "MemberFrame" .. member], memberEvents)
        end
    end
    SuspendFrame(GroupPetsClusterFrame)
    -- Pets are created lazily by the native roster update, at most forty.
    for pet = 1, 40 do
        SuspendFrame(_G["GroupPetsClusterFramePet" .. pet], memberEvents)
    end
end

local function InitializeNative()
    if initialized then return end
    initialized = true
    local oldThis, oldEvent = this, event
    this, event = GroupFrame, "PLAYER_ENTERING_WORLD"
    nativeOnEvent()
    this, event = oldThis, oldEvent
end

GroupFrame_OnEvent = function()
    if owned then return end
    if event == "PLAYER_ENTERING_WORLD" then
        if not initialized then
            initialized = true
            return nativeOnEvent()
        end
        -- Native initialization appends to persistent local frame lists.
        -- Reuse those lists on later world entries and refresh the current roster.
        return GroupFrame_Toggle()
    end
    return nativeOnEvent()
end

GroupFrame_Toggle = function()
    if owned then return end
    if not initialized then
        InitializeNative()
        return
    end
    nativeToggle()
    if GROUP_ENABLED == "1" then
        GroupFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    end
end

-- Native options and menus can invoke these directly, outside registered events.
for _, name in ipairs({"GroupFrame_Update", "GroupFrame_UpdateLayout",
    "GroupFrame_UpdateMemberPets", "GroupFrame_ToggleMovement"}) do
    local original = _G[name]
    if type(original) == "function" then
        _G[name] = function(...)
            if not owned then return original(...) end
        end
    end
end

function UF:SyncNativeGroupFrames(useAddonGrid)
    useAddonGrid = useAddonGrid and true or false
    if useAddonGrid == owned then return end
    owned = useAddonGrid
    if owned then
        SuspendNative()
        return
    end

    for _, state in ipairs(suspended or {}) do
        for _, name in ipairs(state.events) do state.frame:RegisterEvent(name) end
        -- Preserve an update script installed by another owner while suspended.
        if not state.frame:GetScript("OnUpdate") then
            state.frame:SetScript("OnUpdate", state.update)
        end
    end
    suspended = nil
    if initialized then GroupFrame_Toggle() else InitializeNative() end
end

-- Claim before the first world-entry event, including when only raid frames are on.
UF:SyncNativeGroupFrames(UF:GetGroupDimensions().enabled)
