local FT = FostercareTweaks
if not FT then return end

-- Native plate/input ownership stays intact. Health and auras use coalesced
-- events; render callbacks repair native visuals and animate/reconcile casts.
local defaults = { nameplate_marks = 1, nameplate_raidmark_size = 20,
    nameplate_raidmark_position = "left", nameplate_target_glow = 0,
    nameplate_target_scale = 1.1, nameplate_other_alpha = 0.8,
    nameplate_health = 1, nameplate_health_target = 1, nameplate_own_auras = 1,
    nameplate_cc = 1, nameplate_enemy_buffs = 0, nameplate_aura_size = 20,
    nameplate_aura_count = 3, nameplate_combo = 1, nameplate_targeting = 0 }
local module = FT:register({ title = "Nameplate Details", category = "Nameplates", enabled = true,
    description = "Native raid marks, target emphasis, health, auras and combo points.", config = defaults })
local NP = { pending = {}, timed = {}, settings = {} }
FT.Nameplates = NP
local lib = FT.libnameplate
local ticker, queued, driver

function FT.MigrateNameplateSettings()
    local cfg = FostercareTweaks_Config
    if cfg.nameplate_layout_version == 1 then return end
    -- Existing explicit dimension settings included UIParent's scale. Preserve
    -- that appearance once, then give the player an independent size control.
    if cfg["Nameplate Scale"] ~= nil or cfg.overwrites.nameplate_scale ~= nil then
        local ui = UIParent:GetScale()
        if not ui or ui <= 0.2 or ui > 2 then ui = 1 end
        FT.SetOverride("nameplate_scale", FT.ClampNumber(cfg.overwrites.nameplate_scale, 1, 0.5, 2) * ui)
    end
    cfg.nameplate_layout_version = 1
end

local function Visible(object, shown)
    shown = shown and true or false
    if (object:IsShown() and true or false) ~= shown then if shown then object:Show() else object:Hide() end end
end

local function Text(object, value)
    if object.fctText ~= value then object.fctText = value; object:SetText(value) end
end

local function StopTimer()
    if ticker and not next(NP.timed) then ticker:Cancel(); ticker = nil end
end

local function HideAuras(plate)
    NP.timed[plate] = nil
    local row = plate.fctAuras
    if not row then return end
    for _, icon in ipairs(row.icons) do
        icon.ends = nil; Visible(icon, false)
    end
    Visible(row, false); plate.fctAuraHeight = 0
    StopTimer()
end

local function Clear(plate)
    plate.fctNeedsDetails = true
    NP.pending[plate] = nil
    HideAuras(plate)
    if plate.fctHealth then Visible(plate.fctHealth, false) end
    if plate.fctCombo then Visible(plate.fctCombo, false) end
    if plate.fctTargetGlow then Visible(plate.fctTargetGlow, false) end
    if plate.fctTargeting then Visible(plate.fctTargeting, false) end
end

function NP:LayoutMark(plate, restore)
    local icon = plate.raidicon
    if not icon then return end
    if not plate.fctNativeMark then
        local state = { width = icon:GetWidth(), height = icon:GetHeight(), points = {} }
        for i = 1, icon:GetNumPoints() do state.points[i] = { icon:GetPoint(i) } end
        plate.fctNativeMark = state
    end
    -- Old versions suppressed this native region even without a valid unit.
    if not restore and FT.OwnsNameplates() and icon:GetAlpha() ~= 1 then icon:SetAlpha(1) end
    if restore or not self.settings.marks then
        if plate.fctMarkOwned then
            local state = plate.fctNativeMark
            icon:SetWidth(state.width); icon:SetHeight(state.height); icon:ClearAllPoints()
            for _, point in ipairs(state.points) do icon:SetPoint(unpack(point)) end
            plate.fctMarkOwned = nil
        end
        return
    end
    local size, position = self.settings.markSize, self.settings.markPosition
    local anchor, point, relative, x, y = plate.healthbar or plate, "RIGHT", "LEFT", -4, 0
    if position == "above" then
        anchor, point, relative, x, y = plate.name or plate, "BOTTOM", "TOP", 0, 4
    elseif position == "right" then point, relative, x = "LEFT", "RIGHT", 18 * (plate.fctVisualScale or 1) end
    local p, a, r, ox, oy = icon:GetPoint(1)
    if p ~= point or a ~= anchor or r ~= relative or ox ~= x or oy ~= y then
        icon:ClearAllPoints(); icon:SetPoint(point, anchor, relative, x, y)
    end
    if icon:GetWidth() ~= size then icon:SetWidth(size) end
    if icon:GetHeight() ~= size then icon:SetHeight(size) end
    -- Never touch native visibility or atlas coordinates.
    plate.fctMarkOwned = true
end

function NP:RefreshMarks()
    if not FT.OwnsNameplates() then return end
    self.settings.markSize = FT.GetNumber("nameplate_raidmark_size", 20, 12, 40)
    self.settings.markPosition = FT.GetOverride("nameplate_raidmark_position", "left")
    self.settings.marks = self.active and FT.GetOverride("nameplate_marks", 1) == 1
    for plate in pairs(lib.plates) do
        if plate:IsShown() then self:LayoutMark(plate); self:Combo(plate); self:LayoutExtras(plate) end
    end
end

function NP:TopSpace(plate)
    local space = 6
    if self.settings.marks and self.settings.markPosition == "above" then space = space + self.settings.markSize + 4 end
    if not self.settings.marks and plate.raidicon and plate.raidicon:IsShown() then space = space + plate.raidicon:GetHeight() + 4 end
    if self.settings.combo and plate.fctIsTarget then space = space + 10 end
    return space
end

function NP:LayoutExtras(plate)
    FT.SetNameplateFontSize(plate.fctHealth, math.max(7, 9 * (plate.fctVisualScale or 1)))
    if plate.fctTargeting then
        local anchor = plate.castbar or plate.healthbar
        if plate.fctTargeting.fctAnchor ~= anchor then
            plate.fctTargeting.fctAnchor = anchor
            plate.fctTargeting:ClearAllPoints()
            plate.fctTargeting:SetPoint("TOP", anchor, "BOTTOM", 0, -4)
        end
    end
    local row = plate.fctAuras
    if row then
        local y = self:TopSpace(plate)
        if row.fctLayoutY ~= y then
            row.fctLayoutY = y; row:ClearAllPoints(); row:SetPoint("BOTTOM", plate.name or plate, "TOP", 0, y)
        end
    end
    local cds = plate.fctEnemyCooldowns
    if cds then
        local y = self:TopSpace(plate) + (plate.fctAuraHeight or 0)
            + FT.GetNumber("nameplate_cd_offset", 8, 0, 60)
        if cds.fctLayoutY ~= y then
            cds.fctLayoutY = y; cds:ClearAllPoints(); cds:SetPoint("BOTTOM", plate.name or plate, "TOP", 0, y)
        end
    end
end

local function FormatHP(value)
    if value >= 1000000 then return string.format("%.1fm", value / 1000000) end
    if value >= 1000 then return string.format("%.1fk", value / 1000) end
    return tostring(math.floor(value + 0.5))
end

function NP:Health(plate, unit)
    local show = self.settings.health > 0 and unit and (not self.settings.healthTarget or plate.fctIsTarget)
    local label = plate.fctHealth
    if not show then if label then Visible(label, false) end; return end
    local hp, maximum = UnitHealth(unit) or 0, UnitHealthMax(unit)
    if not maximum or maximum <= 0 then if label then Visible(label, false) end; return end
    if not label then
        label = plate.healthbar:CreateFontString(nil, "OVERLAY")
        label:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        label:SetPoint("CENTER", plate.healthbar, "CENTER", 0, 0)
        label:SetTextColor(1, 1, 1); plate.fctHealth = label
    end
    local percent = math.floor(math.max(0, math.min(1, hp / maximum)) * 100 + 0.5) .. "%"
    local mode = self.settings.health
    Text(label, mode == 1 and percent or (mode == 2 and FormatHP(hp) or FormatHP(hp) .. "  " .. percent))
    FT.SetNameplateFontSize(label, math.max(7, 9 * (plate.fctVisualScale or 1)))
    Visible(label, true)
end

local function AuraIcon(row, index)
    local icon = row.icons[index]
    if icon then return icon end
    icon = CreateFrame("Frame", nil, row); icon:EnableMouse(false)
    icon.texture = icon:CreateTexture(nil, "ARTWORK"); icon.texture:SetAllPoints(icon)
    icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon.time = icon:CreateFontString(nil, "OVERLAY"); icon.time:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    icon.time:SetPoint("BOTTOM", icon, "BOTTOM", 0, -1)
    icon.count = icon:CreateFontString(nil, "OVERLAY"); icon.count:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    icon.count:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 1, 1)
    row.icons[index] = icon
    return icon
end

local function TickAuras()
    if not NP.active then return end
    local now = GetTime()
    for plate in pairs(NP.timed) do
        if not plate:IsShown() or not FT.GetNameplateUnit(plate) then
            HideAuras(plate)
            plate.fctNeedsDetails = true
        else
            local active
            for _, icon in ipairs(plate.fctAuras.icons) do
                if icon.ends then
                    if icon.ends <= now then
                        icon.ends = nil; Visible(icon, false); NP:Queue(plate, "auras")
                    else
                        active = true
                        local remaining = math.ceil(icon.ends - now)
                        Text(icon.time, remaining >= 60 and (math.ceil(remaining / 60) .. "m") or tostring(remaining))
                    end
                end
            end
            if not active then NP.timed[plate] = nil end
        end
    end
    StopTimer()
end

function NP:Auras(plate, unit)
    local s = self.settings
    if not unit or not UnitCanAttack("player", unit) or (not s.own and not s.cc and not s.buffs) then
        HideAuras(plate); self:LayoutExtras(plate); return
    end
    local row, count, ccID, now = plate.fctAuras, 0, nil, GetTime()
    self.timed[plate] = nil
    local function Add(name, texture, stacks, dispel, duration, expires, source, stealable, personal, id)
        if not name or not texture or (expires and expires > 0 and expires <= now) then return end
        if not row then
            row = CreateFrame("Frame", nil, plate); row:EnableMouse(false); row.icons = {}; plate.fctAuras = row
        end
        count = count + 1
        local icon = AuraIcon(row, count)
        if icon.size ~= s.auraSize then
            icon.size = s.auraSize; icon:SetWidth(s.auraSize); icon:SetHeight(s.auraSize)
            icon:ClearAllPoints(); icon:SetPoint("LEFT", row, "LEFT", (count - 1) * (s.auraSize + 3), 0)
        end
        if icon.textureID ~= texture then icon.textureID = texture; icon.texture:SetTexture(texture) end
        Text(icon.count, stacks and stacks > 1 and tostring(stacks) or "")
        icon.ends = duration and duration > 0 and expires and expires > now and expires or nil
        if icon.ends then NP.timed[plate] = true end
        local remaining = icon.ends and math.ceil(icon.ends - now)
        Text(icon.time, remaining and (remaining >= 60 and (math.ceil(remaining / 60) .. "m") or tostring(remaining)) or "")
        Visible(icon, true)
        return id
    end
    -- Engine filters classify CC and caster identity; no spell lists, combat-log
    -- inference or tooltip parsing. Query only enough results for the capped row.
    if s.cc then ccID = Add(C_UnitAuras.UnitAura(unit, 1, "HARMFUL|CROWD_CONTROL")) end
    if s.own then
        local own = 0
        for i = 1, 40 do
            if own >= s.auraCount then break end
            local name, texture, stacks, dispel, duration, expires, source, stealable, personal, id = C_UnitAuras.UnitAura(unit, i, "HARMFUL|PLAYER")
            if not name then break end
            if not ccID or id ~= ccID then
                local before = count
                Add(name, texture, stacks, dispel, duration, expires, source, stealable, personal, id)
                if count > before then own = own + 1 end
            end
        end
    end
    if s.buffs then for i = 1, 2 do Add(C_UnitAuras.UnitAura(unit, i, "HELPFUL")) end end
    if row then
        for i = count + 1, #row.icons do
            local icon = row.icons[i]; icon.ends = nil; Visible(icon, false)
        end
        row:SetWidth(math.max(1, count * (s.auraSize + 3) - 3)); row:SetHeight(s.auraSize)
        Visible(row, count > 0)
    end
    plate.fctAuraHeight = count > 0 and s.auraSize + 5 or 0
    self:LayoutExtras(plate)
    if next(self.timed) then
        if not ticker then ticker = C_Timer.NewTicker(0.2, TickAuras) end
    else StopTimer() end
end

function NP:Combo(plate)
    local count = self.active and self.settings.combo and plate.fctIsTarget and GetComboPoints() or 0
    if count <= 0 then if plate.fctCombo then Visible(plate.fctCombo, false) end; return end
    if not plate.fctCombo then
        local row = CreateFrame("Frame", nil, plate); row:EnableMouse(false); row:SetWidth(45); row:SetHeight(7)
        row.pips = {}
        for i = 1, 5 do
            local pip = row:CreateTexture(nil, "OVERLAY"); pip:SetTexture(1, 0.75, 0.15, 1)
            pip:SetWidth(6); pip:SetHeight(6); pip:SetPoint("LEFT", row, "LEFT", (i - 1) * 9, 0)
            row.pips[i] = pip
        end
        plate.fctCombo = row
    end
    local row = plate.fctCombo
    local y = self.settings.marks and self.settings.markPosition == "above" and self.settings.markSize + 8 or 4
    if not self.settings.marks and plate.raidicon and plate.raidicon:IsShown() then y = plate.raidicon:GetHeight() + 8 end
    row:ClearAllPoints(); row:SetPoint("BOTTOM", plate.name or plate, "TOP", 0, y)
    for i = 1, 5 do Visible(row.pips[i], i <= count) end
    Visible(row, true)
end

function NP:Targeting(plate, unit)
    local show = self.settings.targeting and unit and not UnitIsPlayer(unit)
        and UnitCanAttack("player", unit) and UnitIsUnit(unit .. "target", "player") and true or false
    local label = plate.fctTargeting
    if show and not label then
        label = plate:CreateFontString(nil, "OVERLAY"); label:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        label:SetPoint("TOP", plate.castbar or plate.healthbar, "BOTTOM", 0, -4)
        label:SetTextColor(1, 0.4, 0.25); label:SetText("Targeting you"); plate.fctTargeting = label
    end
    if label then Visible(label, show) end
end

local function Flush()
    queued = nil
    local pending = NP.pending; NP.pending = {}
    if not NP.active then return end
    for plate, flags in pairs(pending) do
        local unit = plate:IsShown() and FT.GetNameplateUnit(plate)
        if unit then
            plate.fctNeedsDetails = nil
            if flags.health then NP:Health(plate, unit) end
            if flags.auras then NP:Auras(plate, unit) end
            if flags.targeting then NP:Targeting(plate, unit) end
        else Clear(plate) end
    end
end

function NP:Queue(plate, kind)
    if not self.active or not plate then return end
    if not plate:IsShown() then plate.fctNeedsDetails = true; return end
    local flags = self.pending[plate]
    if not flags then flags = {}; self.pending[plate] = flags end
    flags[kind] = true
    if not queued then queued = true; C_Timer.After(0, Flush) end
end

function NP:Select(plate, selected)
    if selected then self.targetPlate = plate
    elseif self.targetPlate == plate then self.targetPlate = nil end
    if plate.fctIsTarget ~= selected then
        plate.fctIsTarget = selected
        if FT.ApplyNameplateScale then FT.ApplyNameplateScale(plate) end
    end
    self:Combo(plate); self:LayoutExtras(plate); self:LayoutMark(plate)
    self:Queue(plate, "health")
end

function NP:TargetChanged()
    self.targetGUID = UnitGUID("target")
    local previous, current = self.targetPlate, C_NamePlate.GetNamePlateForUnit("target")
    self.targetPlate = current and lib.plates[current] and current or nil
    if previous and previous ~= self.targetPlate then self:Select(previous, false) end
    if self.targetPlate then self:Select(self.targetPlate, true) end
end

local function Render(plate, unit)
    if not NP.active then return end
    if plate.fctDetailGUID ~= unit then
        Clear(plate); plate.fctDetailGUID = unit
        NP:Queue(plate, "health"); NP:Queue(plate, "auras"); NP:Queue(plate, "targeting")
    end
    local selected = unit and unit == NP.targetGUID and true or false
    if selected ~= plate.fctIsTarget then NP:Select(plate, selected) end
    local wanted = NP.targetGUID and not selected and NP.settings.otherAlpha or 1
    if plate.raidicon and plate.raidicon:IsShown() then
        wanted = math.max(wanted, 0.9); NP:LayoutMark(plate)
    end
    if plate:GetAlpha() ~= wanted then plate:SetAlpha(wanted) end
    local glow = plate.fctTargetGlow
    if selected and NP.settings.glow and not glow then
        glow = plate:CreateTexture(nil, "BORDER")
        glow:SetTexture("Interface\\Tooltips\\Nameplate-Glow")
        -- This stock glow uses a black background; additive blending keeps
        -- that background transparent instead of covering the name/bar.
        glow:SetBlendMode("ADD")
        glow:SetVertexColor(1, 0.8, 0.3, 0.7); glow:SetAllPoints(plate.border or plate.healthbar)
        plate.fctTargetGlow = glow
    end
    if glow then Visible(glow, selected and NP.settings.glow) end
end

function NP:Shutdown()
    self.active = false
    if driver then driver:UnregisterAllEvents() end
    if ticker then ticker:Cancel(); ticker = nil end
    self.pending, self.timed = {}, {}
    for plate in pairs(lib.plates) do
        Clear(plate); self:LayoutMark(plate, true)
    end
    self.targetPlate, self.targetGUID = nil, nil
end

function NP:ApplyConfiguration()
    self.active = FT.IsEnabled(module.title, true) and FT.OwnsNameplates()
    local s = self.settings
    s.marks = self.active and FT.GetOverride("nameplate_marks", 1) == 1
    s.markSize = FT.GetNumber("nameplate_raidmark_size", 20, 12, 40)
    s.markPosition = FT.GetOverride("nameplate_raidmark_position", "left")
    s.glow = FT.GetOverride("nameplate_target_glow", 0) == 1
    s.otherAlpha = FT.GetNumber("nameplate_other_alpha", 0.8, 0.2, 1)
    s.health = math.floor(FT.GetNumber("nameplate_health", 1, 0, 3))
    s.healthTarget = FT.GetOverride("nameplate_health_target", 1) == 1
    s.own = FT.GetOverride("nameplate_own_auras", 1) == 1
    s.cc = FT.GetOverride("nameplate_cc", 1) == 1
    s.buffs = FT.GetOverride("nameplate_enemy_buffs", 0) == 1
    s.auraSize = FT.GetNumber("nameplate_aura_size", 20, 14, 32)
    s.auraCount = math.floor(FT.GetNumber("nameplate_aura_count", 3, 1, 6))
    s.combo = FT.GetOverride("nameplate_combo", 1) == 1
    s.targeting = FT.GetOverride("nameplate_targeting", 0) == 1
    if self.active then self:TargetChanged() end
    for plate in pairs(lib.plates) do
        if self.active then
            self:LayoutMark(plate)
            if plate:IsShown() then
                self:Queue(plate, "health"); self:Queue(plate, "auras"); self:Queue(plate, "targeting")
                self:Combo(plate)
            end
        else
            plate.fctIsTarget = false
            Clear(plate); self:LayoutMark(plate, true)
            if FT.OwnsNameplates() then plate:SetAlpha(1) end
            if not FT.OwnsNameplates() and FT.RestoreNameplateScale then FT.RestoreNameplateScale(plate) end
        end
    end
    if not self.active then self.targetPlate, self.targetGUID = nil, nil; FT.RefreshNameplateScale() end
end

module.enable = function(self)
    if not driver then
        driver = CreateFrame("Frame", "FCTweaksNameplateDetailsEvents")
        for _, ev in ipairs({ "PLAYER_TARGET_CHANGED", "PLAYER_COMBO_POINTS", "UNIT_HEALTH", "UNIT_MAXHEALTH",
            "UNIT_AURA", "UNIT_TARGET", "UNIT_FACTION", "RAID_TARGET_UPDATE", "PLAYER_ENTERING_WORLD", "ADDON_LOADED" }) do driver:RegisterEvent(ev) end
        FT.SetEventHandler(driver, function(_, ev, unit)
            if ev == "ADDON_LOADED" then
                if NP.active and not FT.OwnsNameplates() then
                    NP:ApplyConfiguration()
                    FT.mods["Nameplate Castbar"]:enable()
                    FT.mods["Nameplate Class Colors"]:enable()
                end
                return
            end
            if not NP.active then return end
            if ev == "PLAYER_TARGET_CHANGED" then NP:TargetChanged()
            elseif ev == "PLAYER_COMBO_POINTS" then if NP.targetPlate then NP:Combo(NP.targetPlate) end
            elseif ev == "RAID_TARGET_UPDATE" then NP:RefreshMarks()
            elseif ev == "PLAYER_ENTERING_WORLD" then
                for plate in pairs(lib.plates) do
                    Clear(plate); NP:Queue(plate, "health"); NP:Queue(plate, "auras"); NP:Queue(plate, "targeting")
                end
                NP:TargetChanged()
            elseif unit then
                if ev == "UNIT_FACTION" then
                    local plate = C_NamePlate.GetNamePlateForUnit(unit)
                    if plate and lib.plates[plate] then NP:Queue(plate, "auras"); NP:Queue(plate, "targeting") end
                    return
                end
                local kind = ev == "UNIT_AURA" and "auras" or (ev == "UNIT_TARGET" and "targeting" or "health")
                if (kind == "auras" and not NP.settings.own and not NP.settings.cc and not NP.settings.buffs)
                    or (kind == "targeting" and not NP.settings.targeting) or (kind == "health" and NP.settings.health == 0) then return end
                local plate = C_NamePlate.GetNamePlateForUnit(unit)
                if plate and lib.plates[plate] then
                    if kind ~= "health" or not NP.settings.healthTarget or plate.fctIsTarget then NP:Queue(plate, kind) end
                end
            end
        end)
        table.insert(lib.OnUpdate, Render)
        table.insert(lib.OnAdded, function(plate, unit)
            if not NP.active then return end
            Clear(plate); plate.fctDetailGUID = unit; NP:Select(plate, unit and unit == NP.targetGUID and true or false)
            NP:Queue(plate, "auras"); NP:Queue(plate, "targeting")
        end)
        local function Removed(plate)
            Clear(plate); plate.fctDetailGUID = nil
            if NP.targetPlate == plate then NP.targetPlate = nil end
            if plate.fctIsTarget then plate.fctIsTarget = false; FT.ApplyNameplateScale(plate) end
        end
        table.insert(lib.OnRemoved, Removed)
        table.insert(lib.OnShow, function(plate)
            -- Native z-order rebuilds can hide/show the same bound frame.
            -- Lifecycle events own identity; do not rescan on transient shows.
            if NP.active then
                NP:LayoutMark(plate)
                if plate.fctNeedsDetails or not plate.fctDetailGUID then
                    NP:Queue(plate, "health"); NP:Queue(plate, "auras"); NP:Queue(plate, "targeting")
                end
            end
        end)
    end
    NP:ApplyConfiguration()
end
