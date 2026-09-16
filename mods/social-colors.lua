-- FostercareTweaks: mods/social-colors.lua
-- Show class colors in Who, Guild, Friends and Chat

local T = FostercareTweaks.T
local L = FostercareTweaks.L
local gfind = string.gmatch or string.gfind
local GetUnitData = FostercareTweaks.GetUnitData
local hooksecurefunc = FostercareTweaks.hooksecurefunc
local cmatch = FostercareTweaks.cmatch
local rgbhex = FostercareTweaks.rgbhex
local friendinfo = FRIENDS_LEVEL_TEMPLATE and gsub(gsub(FRIENDS_LEVEL_TEMPLATE, "%%s", "%%s %%s"), "%%d", "%%s") or "%s %s %s"

local module = FostercareTweaks:register({
    title = T["Social Colors"],
    description = T["Show class colors in Who, Guild, Friends and Chat."],
    expansions = { ["vanilla"] = true, ["tbc"] = true },
    category = T["Social & Chat"],
    enabled = true,
})

module.enable = function(self)
    do -- add class colors to chat
        for i = 1, NUM_CHAT_WINDOWS do
            local cf = _G["ChatFrame" .. i]
            local isCombat = 0
            if cf and cf.messageTypeList then
                for _, msg in pairs(cf.messageTypeList) do
                    if strfind(msg, "SPELL", 1) or strfind(msg, "COMBAT", 1) then
                        isCombat = isCombat + 1
                    end
                end
            end

            if cf and not cf.FCTweaks_HookAddMessageColor and not Prat and isCombat < 5 then
                cf.FCTweaks_HookAddMessageColor = cf.AddMessage
                cf.AddMessage = function(frame, text, a1, a2, a3, a4, a5)
                    if text then
                        for name in gfind(text, "|Hplayer:(.-)|h") do
                            local real = string.gsub(name, ":.*$", "")
                            local color = "|cffaaaaaa"
                            local class = GetUnitData and GetUnitData(real)
                            local classToken = (L and L["class"] and L["class"][class]) or (class and string.upper(tostring(class)))

                            if classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
                                color = rgbhex(RAID_CLASS_COLORS[classToken])
                            end

                            local escaped_name = string.gsub(name, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
                            local escaped_real = string.gsub(real, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")

                            local pattern1 = "|Hplayer:" .. escaped_name .. "|h%[" .. escaped_real .. "%]|h(.-:-)"
                            local repl1 = "|r[" .. color .. "|Hplayer:" .. name .. "|h" .. color .. real .. "|h|r" .. "]|r" .. "%1"
                            local new_text, count = string.gsub(text, pattern1, repl1)
                            if count == 0 then
                                local pattern2 = "(|Hplayer:" .. escaped_name .. "|h)%[" .. escaped_real .. "%](|h)"
                                local repl2 = "|r[" .. color .. "%1" .. color .. real .. "%2|r]"
                                text = string.gsub(text, pattern2, repl2)
                            else
                                text = new_text
                            end
                        end
                    end

                    cf.FCTweaks_HookAddMessageColor(frame, text, a1, a2, a3, a4, a5)
                end
            end
        end
    end

    FostercareTweaks_Cache = FostercareTweaks_Cache or {}
    FostercareTweaks_Cache["players"] = FostercareTweaks_Cache["players"] or {}

    local playerdb = FostercareTweaks_Cache["players"]
    local socialmod = CreateFrame("Frame", "FCTweaksSocialMod", UIParent)
    socialmod:RegisterEvent("CHAT_MSG_SYSTEM")
    socialmod:SetScript("OnEvent", function(arg1_param, arg2_param, arg3_param)
        local sysMsg = (type(arg1_param) == "table" and (arg3_param or _G.arg1)) or arg2_param or _G.arg1
        if not sysMsg or not cmatch then return end

        local name = cmatch(sysMsg, _G.ERR_FRIEND_ONLINE_SS)
        if not name then
            name = cmatch(sysMsg, _G.ERR_FRIEND_OFFLINE_S)
        end
        local pdb = (FostercareTweaks_Cache and FostercareTweaks_Cache["players"]) or playerdb
        if name and pdb[name] and pdb[name].cname then
            pdb[name].lastseen = date("%a %d-%b-%Y")
        end
    end)

    do -- add colors to guild list
        hooksecurefunc("GuildStatus_Update", function()
            local playerzone = GetRealZoneText()
            local off = FauxScrollFrame_GetOffset(GuildListScrollFrame)
            local _, _, playerrankindex = GetGuildInfo("player")

            for i = 1, GUILDMEMBERS_TO_DISPLAY do
                local name, _, rankindex, level, class, zone, _, _, online = GetGuildRosterInfo(off + i)
                local classToken = class and L and L["class"] and L["class"][class] or class

                if name then
                    if classToken and RAID_CLASS_COLORS[classToken] then
                        local color = RAID_CLASS_COLORS[classToken]
                        local alpha = online and 1 or 0.5
                        if _G["GuildFrameButton" .. i .. "Name"] then
                            _G["GuildFrameButton" .. i .. "Name"]:SetTextColor(color.r, color.g, color.b, alpha)
                        end
                        if _G["GuildFrameButton" .. i .. "Class"] then
                            _G["GuildFrameButton" .. i .. "Class"]:SetTextColor(color.r, color.g, color.b, alpha)
                        end
                        if _G["GuildFrameGuildStatusButton" .. i .. "Name"] then
                            _G["GuildFrameGuildStatusButton" .. i .. "Name"]:SetTextColor(color.r, color.g, color.b, alpha)
                        end
                    end

                    if level then
                        local color = GetDifficultyColor(level)
                        local alpha = online and 1 or 0.5
                        if _G["GuildFrameButton" .. i .. "Level"] then
                            _G["GuildFrameButton" .. i .. "Level"]:SetTextColor(color.r + 0.2, color.g + 0.2, color.b + 0.2, alpha)
                        end
                    end

                    if zone and zone == playerzone then
                        local alpha = online and 1 or 0.5
                        if _G["GuildFrameButton" .. i .. "Zone"] then
                            _G["GuildFrameButton" .. i .. "Zone"]:SetTextColor(0.5, 1, 1, alpha)
                        end
                    end

                    if rankindex and rankindex == playerrankindex then
                        local alpha = online and 1 or 0.5
                        if _G["GuildFrameGuildStatusButton" .. i .. "Rank"] then
                            _G["GuildFrameGuildStatusButton" .. i .. "Rank"]:SetTextColor(0.5, 1, 1, alpha)
                        end
                    end
                end
            end
        end)
    end

    do -- add colors to friend list
        hooksecurefunc("FriendsList_Update", function()
            if GetNumFriends() == 0 then return end

            local playerzone = GetRealZoneText()
            local off = FauxScrollFrame_GetOffset(FriendsFrameFriendsScrollFrame)

            for i = 1, FRIENDS_TO_DISPLAY do
                local name, level, class, zone, connected, status = GetFriendInfo(off + i)
                if not name or name == _G.UNKNOWN then break end
                local friendName = _G["FriendsFrameFriendButton" .. i .. "ButtonTextName"]
                local friendLoc = _G["FriendsFrameFriendButton" .. i .. "ButtonTextNameLocation"] or _G["FriendsFrameFriendButton" .. i .. "ButtonTextLocation"]
                local friendInfo = _G["FriendsFrameFriendButton" .. i .. "ButtonTextInfo"]
                local caption = friendName or friendLoc

                if connected then
                    if not class or class == _G.UNKNOWN then break end
                    local classToken = class and L and L["class"] and L["class"][class] or class
                    local ccolor = (classToken and RAID_CLASS_COLORS[classToken]) or { r = 1, g = 1, b = 1 }
                    local lcolor = GetDifficultyColor(tonumber(level) or 1) or { r = 1, g = 1, b = 1 }

                    local zoneColor = (zone == playerzone) and "|cffffffff" or "|cffcccccc"
                    zone = zoneColor .. (zone or "") .. "|r"
                    local cname = rgbhex(ccolor) .. name .. "|r"
                    local clevel = rgbhex(lcolor) .. (level or "") .. "|r"

                    if playerdb[name] then
                        playerdb[name].lastseen = date("%a %d-%b-%Y")
                        playerdb[name].cname = cname
                        playerdb[name].clevel = clevel
                        playerdb[name].cclass = ccolor
                    end

                    if friendName and friendLoc then
                        friendName:SetText(cname)
                        friendLoc:SetText(format(TEXT(FRIENDS_LIST_TEMPLATE), zone, status or ""))
                    elseif friendLoc then
                        friendLoc:SetText(format(TEXT(FRIENDS_LIST_TEMPLATE), cname, zone, status or ""))
                    end

                    if friendInfo then
                        friendInfo:SetText(format(TEXT(friendinfo), clevel, class, ""))
                        friendInfo:SetVertexColor(1, 1, 1, 0.9)
                    end
                    if caption then
                        caption:SetVertexColor(1, 1, 1, 0.9)
                    end
                else
                    if playerdb[name] and playerdb[name].cname and playerdb[name].clevel and playerdb[name].lastseen then
                        if caption then caption:SetText(format(TEXT(FRIENDS_LIST_OFFLINE_TEMPLATE), playerdb[name].cname)) end
                        if friendInfo then friendInfo:SetText(format(TEXT(friendinfo), playerdb[name].clevel, playerdb[name].lastseen, "")) end
                    else
                        if caption then caption:SetText(format(TEXT(FRIENDS_LIST_OFFLINE_TEMPLATE), name .. "|r")) end
                        if friendInfo then friendInfo:SetText(TEXT(UNKNOWN)) end
                    end

                    if caption then caption:SetVertexColor(1, 1, 1, 0.4) end
                    if friendInfo then friendInfo:SetVertexColor(1, 1, 1, 0.4) end
                end
            end
        end)
    end

    do -- add colors to who list
        hooksecurefunc("WhoList_Update", function()
            local num, max = GetNumWhoResults()
            local off = FauxScrollFrame_GetOffset(WhoListScrollFrame)

            local playerzone = GetRealZoneText()
            local playerrace = UnitRace("player")
            local playerguild = GetGuildInfo("player")

            for i = 1, WHOS_TO_DISPLAY do
                local name, guild, level, race, class, zone = GetWhoInfo(off + i)

                if WhoFrameTotals then
                    local displayedText
                    if num + 1 >= MAX_WHOS_FROM_SERVER then
                        displayedText = format(WHO_FRAME_SHOWN_TEMPLATE, MAX_WHOS_FROM_SERVER)
                        WhoFrameTotals:SetText("|cffffffff" .. format(GetText("WHO_FRAME_TOTAL_TEMPLATE", nil, num), max) .. "  |cffaaaaaa" .. displayedText)
                    else
                        displayedText = format(WHO_FRAME_SHOWN_TEMPLATE, num)
                        WhoFrameTotals:SetText("|cffffffff" .. format(GetText("WHO_FRAME_TOTAL_TEMPLATE", nil, num), num) .. "  |cffaaaaaa" .. displayedText)
                    end
                end

                local classToken = class and L and L["class"] and L["class"][class] or class

                if _G["WhoFrameButton" .. i .. "Name"] then
                    _G["WhoFrameButton" .. i .. "Name"]:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
                end

                local selected = UIDropDownMenu_GetSelectedID(WhoFrameDropDown)
                local varBtn = _G["WhoFrameButton" .. i .. "Variable"]
                if varBtn then
                    if selected == 1 then
                        varBtn:SetTextColor(zone == playerzone and 0.5 or 1, 1, zone == playerzone and 1 or 1)
                    elseif selected == 2 then
                        varBtn:SetTextColor(guild == playerguild and 0.5 or 1, 1, guild == playerguild and 1 or 1)
                    elseif selected == 3 then
                        varBtn:SetTextColor(race == playerrace and 0.5 or 1, 1, race == playerrace and 1 or 1)
                    end
                end

                if classToken and RAID_CLASS_COLORS[classToken] and _G["WhoFrameButton" .. i .. "Class"] then
                    local color = RAID_CLASS_COLORS[classToken]
                    _G["WhoFrameButton" .. i .. "Class"]:SetTextColor(color.r, color.g, color.b, 1)
                end

                if level and _G["WhoFrameButton" .. i .. "Level"] then
                    local color = GetDifficultyColor(level)
                    _G["WhoFrameButton" .. i .. "Level"]:SetTextColor(color.r, color.g, color.b)
                end
            end
        end)
    end
end
