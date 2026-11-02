local FT = FostercareTweaks
if not FT then return end

-- Watched auras: chosen buffs on you and debuffs on your target, each its own
-- icon with the time left (the client's countdown, FT.Countdown), shown while
-- the aura is up and moved with Ctrl+Shift. FostercareTweaks_Config.watched
-- holds { name, spellId, unit = "player" | "target", mine, icon } in order.
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
        icon:SetFrameStrata("LOW")
        icon.texture = icon:CreateTexture(nil, "ARTWORK")
        icon.texture:SetAllPoints(icon)
        icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        icon.cooldown = CreateFrame("Cooldown", "FCTweaksWatch_" .. key .. "CD", icon, "CooldownFrameTemplate")
        icon.cooldown:SetAllPoints(icon)
        icon.cooldown:SetReverse(true)
        icon.cooldown:SetDrawBling(false)
        icon.cooldown:SetCountdownFormatter(FT.Countdown)
        icon.cooldown.noCooldownCount = true
        -- Above the sweep and its numbers.
        local text = CreateFrame("Frame", nil, icon)
        text:SetAllPoints(icon)
        text:SetFrameLevel(icon:GetFrameLevel() + 5)
        icon.count = text:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        icon.count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 2)
        -- A new icon waits in a row under the screen centre until it is moved.
        icon:SetPoint("CENTER", UIParent, "CENTER", -150 + (index - 1) * (SIZE + GAP), -150)
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

local function Show(icon, texture, count, duration, expiration)
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

-- Reads the unit's auras once and shows the watched ones it has.
function W.Update(unit)
    local found = {}
    if UnitExists(unit) then
        local _, n = C_UnitAuras.GetAuraSlots(unit, FILTER[unit], 0, nil, slots)
        for i = 1, n do
            local name, texture, count, _, duration, expiration, source, _, _, spellId =
                C_UnitAuras.UnitAuraBySlot(unit, slots[i])
            for _, entry in ipairs(List()) do
                if entry.unit == unit and not found[entry] and (entry.name == name or entry.spellId == spellId)
                    and (not entry.mine or (source and UnitIsUnit(source, "player"))) then
                    found[entry] = true
                    local icon = icons[Key(entry)]
                    if icon then Show(icon, texture, count, duration, expiration) end
                end
            end
        end
    end
    for _, entry in ipairs(List()) do
        local icon = icons[Key(entry)]
        if entry.unit == unit and not found[entry] and icon then
            icon.fctAura = nil
            if icon:IsShown() and not icon.fctForcedShown then icon:Hide() end
        end
    end
end

-- After a change to the list: icons for every entry, none for removed ones.
function W.Rebuild()
    local wanted = {}
    for index, entry in ipairs(List()) do wanted[Key(entry)] = Icon(entry, index) end
    for key, icon in pairs(icons) do
        if not wanted[key] then icon.fctRestoreShown = nil; icon:Hide() end
    end
    W.Update("player")
    W.Update("target")
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
    table.insert(List(), { name = name, spellId = id, unit = unit, mine = unit == "target" or nil })
    W.Rebuild()
end

function W.Remove(index)
    table.remove(List(), index)
    W.Rebuild()
end

function W.SetMine(index, mine)
    List()[index].mine = mine and true or nil
    W.Update("target")
end

-- Once: the buffs and target debuffs of a FostercareAuras setup, with their
-- icons and places (its offsets are from the screen centre). Weapon poisons
-- are the Weapon enchants area here.
local function ImportFostercareAuras()
    local cfg = FostercareTweaks_Config
    local db = FostercareAurasDB
    if cfg.watchedImported or type(db) ~= "table" or type(db.spells) ~= "table" then return end
    cfg.watchedImported = true
    local found = {}
    for _, spell in pairs(db.spells) do
        if (spell.type == "Buff" or spell.type == "Debuff") and spell.displayName then
            found[#found + 1] = spell
        end
    end
    table.sort(found, function(a, b) return (a.order or 0) < (b.order or 0) end)
    cfg.unitframe_positions = cfg.unitframe_positions or {}
    for _, spell in ipairs(found) do
        local aura = type(spell.conditions) == "table" and type(spell.conditions.aura) == "table" and spell.conditions.aura or {}
        local entry = { name = spell.displayName, spellId = spell.spellid, unit = spell.type == "Buff" and "player" or "target",
            icon = spell.iconTexture }
        entry.mine = entry.unit == "target" and aura.onlyMine ~= false or nil
        table.insert(List(), entry)
        local x, y = spell.offsetX or spell.x, spell.offsetY or spell.y
        if x and y and not cfg.unitframe_positions[Key(entry)] then
            cfg.unitframe_positions[Key(entry)] = { point = "CENTER", relPoint = "CENTER", x = x, y = y }
        end
    end
end

module.enable = function()
    ImportFostercareAuras()
    local events = CreateFrame("Frame")
    events:RegisterUnitEvent("UNIT_AURA_DELTA", "player", "target")
    events:RegisterEvent("PLAYER_TARGET_CHANGED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    FT.SetEventHandler(events, function(_, ev, unit)
        if ev == "UNIT_AURA_DELTA" then W.Update(unit)
        elseif ev == "PLAYER_TARGET_CHANGED" then W.Update("target")
        else W.Update("player"); W.Update("target") end
    end)
    W.Rebuild()
end
