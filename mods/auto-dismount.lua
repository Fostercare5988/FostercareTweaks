-- FostercareTweaks: mods/auto-dismount.lua
-- Automatically dismounts or cancels shapeshift on spell casting attempts

local T = FostercareTweaks.T

local module = FostercareTweaks:register({
    title = T["Auto Dismount"],
    description = T["Automatically dismounts whenever a spell is casted."],
    expansions = { ["vanilla"] = true, ["tbc"] = nil },
    category = T["General"],
    enabled = true,
})

local shapeshifts = {
    "ability_racial_bearform", "ability_druid_catform", "ability_druid_travelform",
    "spell_nature_forceofnature", "ability_druid_aquaticform", "spell_nature_spiritwolf",
    "ability_druid_treeoflife", "ability_druid_stagform"
}

local errors = {
    SPELL_FAILED_NOT_MOUNTED, ERR_ATTACK_MOUNTED, ERR_TAXIPLAYERALREADYMOUNTED,
    SPELL_FAILED_NOT_SHAPESHIFT, SPELL_FAILED_NO_ITEMS_WHILE_SHAPESHIFTED, SPELL_NOT_SHAPESHIFTED,
    SPELL_NOT_SHAPESHIFTED_NOSPACE, ERR_CANT_INTERACT_SHAPESHIFTED, ERR_NOT_WHILE_SHAPESHIFTED,
    ERR_NO_ITEMS_WHILE_SHAPESHIFTED, ERR_TAXIPLAYERSHAPESHIFTED, ERR_MOUNT_SHAPESHIFTED
}

local errorMap = {}
for _, err in ipairs(errors) do
    if err then errorMap[err] = true end
end

module.enable = function(self)
    local dismount = CreateFrame("Frame")
    FostercareTweaks.dismount = dismount
    dismount:RegisterEvent("UI_ERROR_MESSAGE")
    dismount:SetScript("OnEvent", function(arg1_param)
        local msg = (type(arg1_param) == "string" and arg1_param) or arg1 or _G.arg1
        if msg == SPELL_FAILED_NOT_STANDING then
            SitOrStand()
            return
        end

        if errorMap[msg] then
            if Dismount then
                Dismount()
            end
            if CancelShapeshiftForm then
                CancelShapeshiftForm()
            end

            local stillMounted = (IsMounted and IsMounted()) or (not IsMounted)
            local stillShapeshifted = (GetShapeshiftFormID and GetShapeshiftFormID() > 0) or (not GetShapeshiftFormID)

            if stillMounted or stillShapeshifted then
                for i = 0, 31 do
                    local buff = GetPlayerBuffTexture(i)
                    if buff then
                        local lbuff = string.lower(buff)
                        for _, bufftype in ipairs(shapeshifts) do
                            if string.find(lbuff, bufftype) then
                                CancelPlayerBuff(i)
                                return
                            end
                        end
                        if string.find(lbuff, "mount") or string.find(lbuff, "spell_nature_swiftness") then
                            CancelPlayerBuff(i)
                            return
                        end
                    end
                end
            end
        end
    end)
end
