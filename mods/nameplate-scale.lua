local FT = FostercareTweaks
if not FT then return end

local module = FT:register({
    title = "Nameplate Scale", category = "Nameplates", enabled = true,
    description = "Adjust native nameplate size and castbar proportions.",
    config = { nameplate_scale = 1, nameplate_follow_ui = 0, nameplate_name_scale = 1,
        nameplate_cast_height = 10, nameplate_cast_gap = 3 },
})

local function Dimensions(object, width, height)
    if not object then return end
    width, height = math.max(1, math.floor(width + 0.5)), math.max(1, math.floor(height + 0.5))
    if object:GetWidth() ~= width then object:SetWidth(width) end
    if object:GetHeight() ~= height then object:SetHeight(height) end
end

local function Capture(plate)
    if not plate.fctOrigW then
        plate.fctOrigW, plate.fctOrigH = plate:GetWidth(), plate:GetHeight()
        if plate.fctOrigW <= 20 then plate.fctOrigW, plate.fctOrigH = 110, 14 end
        for _, entry in ipairs({ {"healthbar", "fctHb", 110, 14}, {"border", "fctBorder", 128, 16},
            {"glow", "fctGlow", 128, 16}, {"levelicon", "fctLevel", 11, 11}, {"dragon", "fctDragon", 128, 64} }) do
            local object, prefix = plate[entry[1]], entry[2]
            local w, h = object and object:GetWidth(), object and object:GetHeight()
            plate[prefix .. "OrigW"] = w and w > 0 and w or entry[3]
            plate[prefix .. "OrigH"] = h and h > 0 and h or entry[4]
        end
        plate.fctNameOrigScale = plate.name and plate.name:GetScale() or 1
        plate.fctLevelOrigScale = plate.level and plate.level:GetScale() or 1
    end
end

function FT.LayoutNameplateCastbar(plate)
    local cb = plate.fctCastbar
    if not cb or not FT.OwnsNameplates() then return end
    local scale = plate.fctVisualScale or 1
    local height = FT.GetNumber("nameplate_cast_height", 10, 6, 18) * scale
    local gap = FT.GetNumber("nameplate_cast_gap", 3, 0, 16) * scale
    Dimensions(cb, (plate.healthbar or plate):GetWidth() - 22 * scale, height)
    local anchor = plate.healthbar or plate
    local p, a, r, x, y = cb:GetPoint(1)
    if p ~= "TOP" or a ~= anchor or r ~= "BOTTOM" or x ~= 8 * scale or y ~= -gap then
        cb:ClearAllPoints(); cb:SetPoint("TOP", anchor, "BOTTOM", 8 * scale, -gap)
    end
    Dimensions(cb.texture, height + 8 * scale, height + 8 * scale)
    Dimensions(cb.texture.icon, height + 2 * scale, height + 2 * scale)
    Dimensions(cb.spark, 20 * scale, 20 * scale)
    local font, oldSize, flags = cb.text:GetFont()
    local size = math.max(7, math.floor(9 * scale + 0.5))
    if oldSize ~= size or flags ~= "OUTLINE" then cb.text:SetFont(font, size, "OUTLINE") end
end

local function Apply(plate, restore)
    if not plate or (not FT.OwnsNameplates() and not restore) then return end
    Capture(plate)
    local enabled = not restore and FT.IsEnabled(module.title)
    local scale, nameScale = 1, 1
    if enabled then
        scale = FT.GetNumber("nameplate_scale", 1, 0.1, 4)
        if FT.GetOverride("nameplate_follow_ui", 0) == 1 then
            scale = scale * FT.ClampNumber(UIParent:GetScale(), 1, 0.2, 2)
        end
        if plate.fctIsTarget then scale = scale * FT.GetNumber("nameplate_target_scale", 1.1, 1, 1.5) end
        nameScale = FT.GetNumber("nameplate_name_scale", 1, 0.75, 1.5)
    end
    plate.fctVisualScale, plate.fctScaleOwned = scale, enabled
    -- Check every owned component at lifecycle/settings boundaries. Native
    -- projection may reset a child while leaving the root width unchanged.
    Dimensions(plate, plate.fctOrigW * scale, plate.fctOrigH * scale)
    Dimensions(plate.healthbar, plate.fctHbOrigW * scale, plate.fctHbOrigH * scale)
    Dimensions(plate.border, plate.fctBorderOrigW * scale, plate.fctBorderOrigH * scale)
    Dimensions(plate.glow, plate.fctGlowOrigW * scale, plate.fctGlowOrigH * scale)
    Dimensions(plate.levelicon, plate.fctLevelOrigW * scale, plate.fctLevelOrigH * scale)
    Dimensions(plate.dragon, plate.fctDragonOrigW * scale, plate.fctDragonOrigH * scale)
    if plate.name and plate.name:GetScale() ~= plate.fctNameOrigScale * scale * nameScale then
        plate.name:SetScale(plate.fctNameOrigScale * scale * nameScale)
    end
    if plate.level and plate.level:GetScale() ~= plate.fctLevelOrigScale * scale then
        plate.level:SetScale(plate.fctLevelOrigScale * scale)
    end
    FT.LayoutNameplateCastbar(plate)
    if FT.Nameplates then FT.Nameplates:LayoutExtras(plate) end
end

FT.ApplyNameplateScale = Apply
function FT.RestoreNameplateScale(plate)
    if plate.fctScaleOwned then Apply(plate, true) end
end
function FT.RefreshNameplateScale()
    for plate in pairs(FT.libnameplate.plates) do
        if plate:IsShown() then Apply(plate) end
    end
end

module.enable = function(self)
    if not self.initialized then
        self.initialized = true
        table.insert(FT.libnameplate.OnInit, function(plate) Apply(plate) end)
        table.insert(FT.libnameplate.OnShow, function(plate) Apply(plate) end)
        local watcher = CreateFrame("Frame")
        watcher:RegisterEvent("UI_SCALE_CHANGED")
        FT.SetEventHandler(watcher, FT.RefreshNameplateScale)
    end
    FT.RefreshNameplateScale()
end
