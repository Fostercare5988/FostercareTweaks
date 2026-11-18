-- Auto Stance: a spell that needs another stance or form switches to it.
local _, FT = ...
if not FT.apply then return end
local db = TweaksDB

local _, class = UnitClass("player")
if class ~= "WARRIOR" and class ~= "DRUID" then return end -- no row on the page either

-- "Must be in Battle Stance, Defensive Stance" (GlobalStrings.lua) as a pattern.
local NEEDS = "^" .. string.gsub(string.gsub(SPELL_FAILED_ONLY_SHAPESHIFT, "([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1"),
    "%%s", "(.+)") .. "$"

-- GAP: a structured result that names the stance or form a spell needs
-- (ClassicAPI's autoUnshift leaves a form, but "Must be in ..." still fails:
-- ### Stand, dismount and form settings). Until then, the error's text.
local function Needed(message)
    local forms = type(message) == "string" and string.match(message, NEEDS)
    return forms and ", " .. forms .. ","
end

local stance = CreateFrame("Frame")
stance:SetScript("OnEvent", function()
    local forms = Needed(arg1)
    if not forms then return end
    for i = 1, GetNumShapeshiftForms() do
        local _, name, active, castable = GetShapeshiftFormInfo(i)
        if not active and castable and string.find(forms, ", " .. name .. ",", 1, true) then
            return CastShapeshiftForm(i)
        end
    end
end)

function FT.apply.autoStance()
    if db.autoStance then stance:RegisterEvent("UI_ERROR_MESSAGE") else stance:UnregisterEvent("UI_ERROR_MESSAGE") end
end
FT.apply.autoStance()
