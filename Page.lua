-- The Tweaks page in ClassicAPI's Settings window (AddOn Options, or /ft).
local _, FT = ...
if not FT.apply then return end -- no ClassicAPI: Core.lua said so

local db = TweaksDB
local category

-- In play order: a section header, then its rows. A slider is { key, name, tip, low, high }.
local PAGE = {
    "Chat",
    { "arrowKeys", "Arrow keys without Alt", "The arrow keys move through what you typed and repeat earlier lines." },
    { "history", "Chat history", "The last 30 lines of each chat window come back after a reload or login." },
    { "timestamps", "Timestamps", "The time before each chat line. Not in the combat log." },
    { "classColors", "Names in class colours", "Player names in chat in the colour of their class." },
    { "blueShaman", "Blue shamans", "Shamans in blue everywhere a class colour is shown." },
    "Minimap",
    { "minimapScale", "Minimap size", "How large the minimap is.", 0.7, 1.6 },
    { "minimapSquare", "Square minimap", "A square minimap with a thin border." },
    { "minimapClock", "Clock", "A 24-hour clock under the minimap. Hover it for server time." },
    { "minimapTidy", "Tidy minimap", "No calendar, top border or zoom buttons; the mouse wheel zooms." },
    "World map",
    { "mapScale", "Map window size", "The size of the windowed world map. Ctrl+wheel on the map changes it too.",
        FT.MAP_MIN, FT.MAP_MAX },
    "Gameplay",
    { "autoStance", "Auto Stance", "A warrior or druid spell that needs another stance or form switches to it." },
}

SettingsRegistrar:AddRegistrant(function()
    local layout
    category, layout = Settings.RegisterVerticalLayoutCategory("Tweaks")
    for _, row in ipairs(PAGE) do
        if type(row) == "string" then
            layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(row))
        else
            local key, name, tip, low, high = row[1], row[2], row[3], row[4], row[5]
            local kind = low and Settings.VarType.Number or Settings.VarType.Boolean
            local setting = Settings.RegisterAddOnSetting(category, "Tweaks_" .. key, key, db, kind, name,
                FT.DEFAULTS[key])
            if FT.apply[key] then setting:SetValueChangedCallback(FT.apply[key]) end -- else read per use
            if low then
                local options = Settings.CreateSliderOptions(low, high, 0.05)
                options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
                Settings.CreateSlider(category, setting, options, tip)
            else
                Settings.CreateCheckbox(category, setting, tip)
            end
            if key == "mapScale" then FT.mapSetting = setting end
        end
    end
    Settings.RegisterAddOnCategory(category)
end)

SLASH_TWEAKS1 = "/ft"
SlashCmdList.TWEAKS = function()
    if category then Settings.OpenToCategory(category:GetID()) end
end
