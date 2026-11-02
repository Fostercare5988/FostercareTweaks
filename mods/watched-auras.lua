local FT = FostercareTweaks
if not FT then return end

-- Watched auras: chosen buffs on you and debuffs on your target, each its own
-- icon with the time left (the client's countdown, FT.Countdown), shown while
-- the aura is up and moved with Ctrl+Shift. FostercareTweaks_Config.watched
-- holds { name, spellId, unit = "player" | "target", mine, icon, noIcon, topRight,
-- inRow, noCooldown } in order. Each aura decides where it shows: its own icon
-- (unless noIcon), and only when asked also in Blizzard's buffs at the top right
-- (topRight, your buffs) and the player or target row (inRow). When one of your
-- buffs ends, its icon shows its spell's cooldown, greyed (unless noCooldown).
-- Positions live with the other frames (unitframe_positions), so each zone
-- layout keeps its own.
local module = FT:register({
    title = "Watched Auras",
    always = true,
})

local W = {}
FT.WatchedAuras = W
local SIZE, GAP = 36, 6
local FILTER = { player = "HELPFUL", target = "HARMFUL" }
local icons, slots = {}, {}          -- icons by key; one slot buffer
local found = {}                     -- W.Update's matches, reused
local cooling                        -- a watched buff that shows its cooldown
local known = {}                     -- buff name -> your spell's ID, or false
local own = {}                       -- spell ID -> start of its own cooldown, seen
local gcdStart, gcdDuration          -- the global cooldown, as last seen

-- Names kept out of each list: Blizzard's top right, and each unit's row.
local hidden = { top = {}, player = {}, target = {} }

-- For the aura lists: true when this aura is not wanted there. place "top" is
-- Blizzard's buffs at the top right; otherwise the unit's row.
function FT.IsAuraHidden(name, unit, place)
    local set = place == "top" and hidden.top or hidden[unit]
    return name ~= nil and set ~= nil and set[name] or false
end

local function List()
    local cfg = FostercareTweaks_Config
    if type(cfg.watched) ~= "table" then cfg.watched = {} end
    return cfg.watched
end
W.List = List

local function Key(entry)
    return "watch_" .. entry.unit .. "_" .. string.gsub(entry.name, "[^%w]", "")
end

local function Icon(entry, index)
    local key = Key(entry)
    local icon = icons[key]
    if not icon then
        icon = CreateFrame("Frame", "FCTweaksWatch_" .. key, UIParent)
        icon:SetWidth(SIZE); icon:SetHeight(SIZE)
        -- Above unit frames, bars and their movers; under menus and the map.
        icon:SetFrameStrata("HIGH")
        icon.texture = icon:CreateTexture(nil, "ARTWORK")
        icon.texture:SetAllPoints(icon)
        icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        icon.cooldown = CreateFrame("Cooldown", "FCTweaksWatch_" .. key .. "CD", icon, "CooldownFrameTemplate")
        icon.cooldown:SetAllPoints(icon)
        icon.cooldown:SetReverse(true)
        icon.cooldown:SetDrawBling(false)
        icon.cooldown:SetCountdownFormatter(FT.Countdown)
        icon.cooldown.noCooldownCount = true
        -- A cooldown shown after its buff ended: gone when the spell is ready.
        icon.cooldown:SetScript("OnCooldownDone", function()
            if icon.fctCooling then W.Update("player") end
        end)
        -- Above the sweep and its numbers.
        local text = CreateFrame("Frame", nil, icon)
        text:SetAllPoints(icon)
        text:SetFrameLevel(icon:GetFrameLevel() + 5)
        icon.count = text:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        icon.count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 2)
        -- A new icon waits above the screen centre, eight to a row, clear of
        -- the unit frames, until it is moved.
        local column, row = (index - 1) % 8, math.floor((index - 1) / 8)
        icon:SetPoint("CENTER", UIParent, "CENTER", (column - 3.5) * (SIZE + GAP), 150 + row * (SIZE + GAP))
        FT.RestoreFramePosition(icon, key)
        FT.RegisterFrameMover(icon, key, entry.name)
        icon:Hide()
        icons[key] = icon
    end
    icon.entry = entry
    -- Held Ctrl+Shift shows it to be moved; after that the aura decides.
    icon.fctRestoreShown = function(frame) W.Update(frame.entry.unit) end
    if not icon.fctAura then
        local texture = entry.icon
        if not texture and entry.spellId then
            local _, _, spellIcon = GetSpellInfo(entry.spellId)
            texture = spellIcon
        end
        icon.texture:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    end
    return icon
end

-- An aura again after its cooldown: colour and the draining sweep back.
local function EndCooldown(icon)
    icon.fctCooling, icon.fctStart = nil, nil
    icon.texture:SetDesaturated(false)
    icon.cooldown:SetReverse(true)
end

local function Show(icon, texture, count, duration, expiration)
    if icon.fctCooling then EndCooldown(icon) end
    icon.fctAura = true
    if icon.fctTexture ~= texture then icon.fctTexture = texture; icon.texture:SetTexture(texture) end
    local stacks = count and count > 1 and count or nil
    if icon.fctCount ~= stacks then icon.fctCount = stacks; icon.count:SetText(stacks or "") end
    local timed = duration and duration > 0 and expiration and expiration > GetTime()
    local start = timed and expiration - duration or nil
    if icon.fctStart ~= start or icon.fctDuration ~= duration then
        icon.fctStart, icon.fctDuration = start, duration
        if timed then icon.cooldown:SetCooldown(start, duration) else icon.cooldown:Clear() end
    end
    if not icon:IsShown() then icon:Show() end
end

-- A spell's own cooldown (start, duration), not the global one. The stock
-- read returns numbers; ClassicAPI's isOnGCD (a new table per call) is asked
-- only for a cooldown not seen before: a spell's own, or the next GCD.
local function OwnCooldown(id)
    local slot, book = FindSpellBookSlotByID(id)
    if not slot then return end
    local start, duration = GetSpellCooldown(slot, book)
    if not start or duration == 0 or start + duration <= GetTime()
        or (start == gcdStart and duration == gcdDuration) then return end
    if own[id] == start then return start, duration end
    local info = C_Spell.GetSpellCooldown(id)
    if not info or info.isOnGCD then gcdStart, gcdDuration = start, duration; return end
    own[id] = start
    return start, duration
end

-- One of your buffs has ended: its spell's own cooldown (not the global one),
-- greyed with a filling sweep, until it is ready. Stealth after you unstealth.
local function ShowCooldown(icon, entry)
    if entry.unit ~= "player" or entry.noCooldown then return false end
    local id = known[entry.name]
    if id == nil then
        local _, _, _, _, _, _, _, _, _, spellId = GetSpellInfo(entry.name)
        id = spellId or false
        known[entry.name] = id
    end
    if not id then return false end
    local start, duration = OwnCooldown(id)
    if not start then return false end
    icon.fctAura = nil
    if not icon.fctCooling then
        icon.fctCooling, icon.fctStart = true, nil
        icon.texture:SetDesaturated(true)
        icon.cooldown:SetReverse(false)
    end
    if icon.fctCount then icon.fctCount = nil; icon.count:SetText("") end
    if icon.fctStart ~= start or icon.fctDuration ~= duration then
        icon.fctStart, icon.fctDuration = start, duration
        icon.cooldown:SetCooldown(start, duration)
    end
    if not icon:IsShown() then icon:Show() end
    return true
end

-- Reads the unit's auras once and shows the watched ones it has.
function W.Update(unit)
    table.wipe(found)
    if UnitExists(unit) then
        local _, n = C_UnitAuras.GetAuraSlots(unit, FILTER[unit], 0, nil, slots)
        for i = 1, n do
            local name, texture, count, _, duration, expiration, source, _, _, spellId =
                C_UnitAuras.UnitAuraBySlot(unit, slots[i])
            for _, entry in ipairs(List()) do
                if entry.unit == unit and not found[entry] and (entry.name == name or entry.spellId == spellId)
                    and (not entry.mine or (source and UnitIsUnit(source, "player"))) then
                    found[entry] = true
                    entry.icon = entry.icon or texture          -- for its chip in the settings
                    local icon = not entry.noIcon and icons[Key(entry)]
                    if icon then Show(icon, texture, count, duration, expiration) end
                end
            end
        end
    end
    for _, entry in ipairs(List()) do
        local icon = icons[Key(entry)]
        if entry.unit == unit and not found[entry] and icon
            and (entry.noIcon or not ShowCooldown(icon, entry)) then
            icon.fctAura = nil
            if icon:IsShown() and not icon.fctForcedShown then icon:Hide() end
        end
    end
end

-- After a change to the list: icons for every watched entry, none for removed
-- or hidden ones; the lists drop what shows elsewhere.
function W.Rebuild(refreshLists)
    local wanted, index = {}, 0
    for _, set in pairs(hidden) do table.wipe(set) end
    cooling = nil
    for _, entry in ipairs(List()) do
        if entry.unit == "player" and not entry.noIcon and not entry.noCooldown then cooling = true end
        if not entry.noIcon then
            index = index + 1
            wanted[Key(entry)] = Icon(entry, index)
        end
        if entry.unit == "player" and not entry.topRight then hidden.top[entry.name] = true end
        if not entry.inRow then hidden[entry.unit][entry.name] = true end
    end
    for key, icon in pairs(icons) do
        if not wanted[key] then icon.fctRestoreShown = nil; icon:Hide() end
    end
    W.Update("player")
    W.Update("target")
    if refreshLists then
        FT.ApplyStandardAuraSettings()
        FT.UnitFrames.Auras:UpdateBlizzPlayerAuras()
        FT.UnitFrames.Auras:UpdateBlizzTargetAuras()
    end
end

function W.Add(text, unit)
    text = string.gsub(text or "", "^%s*(.-)%s*$", "%1")
    if text == "" then return end
    local id = tonumber(text)
    local name = id and GetSpellInfo(id) or text
    if not name then return end
    for _, entry in ipairs(List()) do
        if entry.unit == unit and entry.name == name then return end
    end
    local _, _, known = GetSpellInfo(id or name)         -- your own spells: their icon now
    table.insert(List(), { name = name, spellId = id, unit = unit, mine = unit == "target" or nil, icon = known })
    W.Rebuild(true)
end

function W.Remove(index)
    table.remove(List(), index)
    W.Rebuild(true)
end

function W.SetMine(index, mine)
    List()[index].mine = mine and true or nil
    W.Update("target")
end

-- Where an aura shows: "icon" (its own), "topRight" (Blizzard's buffs), "inRow"
-- (the player or target row), "cooldown" (its spell's cooldown after it ends).
function W.SetShown(index, place, shown)
    local entry = List()[index]
    if place == "icon" then entry.noIcon = not shown or nil
    elseif place == "cooldown" then entry.noCooldown = not shown or nil
    else entry[place] = shown and true or nil end
    W.Rebuild(true)
end

module.enable = function()
    -- 1.9.0 copied FostercareAuras setups once and kept their spell IDs as text.
    FostercareTweaks_Config.watchedImported = nil
    for _, entry in ipairs(List()) do
        entry.spellId = tonumber(entry.spellId)
        -- 1.10's Hide entries: one of your buffs with no icon of its own.
        if entry.unit == "hidden" then entry.unit, entry.noIcon = "player", true end
    end
    local events = CreateFrame("Frame")
    events:RegisterUnitEvent("UNIT_AURA_DELTA", "player", "target")
    events:RegisterEvent("PLAYER_TARGET_CHANGED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    events:RegisterEvent("SPELLS_CHANGED")
    FT.SetEventHandler(events, function(_, ev, unit)
        if ev == "UNIT_AURA_DELTA" then W.Update(unit)
        elseif ev == "PLAYER_TARGET_CHANGED" then W.Update("target")
        elseif ev == "SPELL_UPDATE_COOLDOWN" then if cooling then W.Update("player") end
        elseif ev == "SPELLS_CHANGED" then table.wipe(known)
        else W.Update("player"); W.Update("target") end
    end)
    W.Rebuild()
end
