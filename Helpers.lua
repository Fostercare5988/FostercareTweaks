-- FostercareTweaks: Helpers.lua
-- Performance helpers, hardware timers, and zero-allocation recursion

FostercareTweaks = FostercareTweaks or {}

FostercareTweaks.GetExpansion = function()
    return "vanilla"
end

FostercareTweaks.GetGlobalEnv = function()
    return _G or getfenv(0)
end

-- Hardware Timer Wrapper (Zero GC overhead via C_Timer)
FostercareTweaks.TimerAfter = function(seconds, func)
    if not func then return end
    if not seconds or seconds <= 0 then
        func()
    elseif C_Timer and C_Timer.After then
        C_Timer.After(seconds, func)
    end
end
FostercareTweaks.QueueFunction = function(func, ...)
    local args = { ... }
    if C_Timer and C_Timer.After then
        C_Timer.After(0.01, function()
            func(unpack(args))
        end)
    else
        func(unpack(args))
    end
end

-- Zero-Allocation Hierarchy Iteration (Rule D1 compliance)
local function RegionWalk(idx, callback, arg1, arg2, arg3, r, ...)
    if not r then return end
    callback(r, idx, arg1, arg2, arg3)
    return RegionWalk(idx + 1, callback, arg1, arg2, arg3, ...)
end

FostercareTweaks.ForEachRegion = function(frame, callback, arg1, arg2, arg3)
    if frame and frame.GetRegions and callback then
        RegionWalk(1, callback, arg1, arg2, arg3, frame:GetRegions())
    end
end

local function ChildWalk(callback, arg1, arg2, arg3, c, ...)
    if not c then return end
    callback(c, arg1, arg2, arg3)
    return ChildWalk(callback, arg1, arg2, arg3, ...)
end

FostercareTweaks.ForEachChild = function(frame, callback, arg1, arg2, arg3)
    if frame and frame.GetChildren and callback then
        ChildWalk(callback, arg1, arg2, arg3, frame:GetChildren())
    end
end

-- Secure Function Hooking
-- Uses native ClassicAPI engine hooksecurefunc when available, with non-destructive fallback.
local hooks = {}
FostercareTweaks.hooksecurefunc = function(tbl, name, func, prepend)
    if type(tbl) == "string" then
        prepend, func, name, tbl = func, name, tbl, _G
    end
    if not tbl or not tbl[name] or not func then return end

    if not prepend and type(hooksecurefunc) == "function" then
        if tbl == _G then
            hooksecurefunc(name, func)
        else
            hooksecurefunc(tbl, name, func)
        end
        return
    end

    local orig = tbl[name]
    if prepend then
        tbl[name] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            func(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            return orig(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
        end
    else
        tbl[name] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            local r1, r2, r3, r4, r5, r6, r7, r8, r9, r10 = orig(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            func(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            return r1, r2, r3, r4, r5, r6, r7, r8, r9, r10
        end
    end
end


-- Script Hooking
FostercareTweaks.HookScript = function(frame, script, func)
    if not frame or not func then return end
    local prev = frame.GetScript and frame:GetScript(script)
    frame:SetScript(script, function(...)
        if prev then prev(...) end
        func(...)
    end)
end

-- Delayed Addon/Variable Initialization
FostercareTweaks.HookAddonOrVariable = function(addon, func)
    if IsAddOnLoaded(addon) or _G[addon] then
        func()
        return
    end
    local lurker = CreateFrame("Frame", nil)
    lurker.func = func
    lurker:RegisterEvent("ADDON_LOADED")
    lurker:RegisterEvent("VARIABLES_LOADED")
    lurker:RegisterEvent("PLAYER_ENTERING_WORLD")
    lurker:SetScript("OnEvent", function()
        if IsAddOnLoaded(addon) or _G[addon] then
            this:func()
            this:UnregisterAllEvents()
        end
    end)
end

-- Math & Color Utilities
local gradientcolors = {}
FostercareTweaks.GetColorGradient = function(perc)
    perc = perc > 1 and 1 or perc
    perc = perc < 0 and 0 or perc
    perc = floor(perc * 100) / 100

    local index = perc
    if not gradientcolors[index] then
        local r1, g1, b1, r2, g2, b2
        if perc <= 0.5 then
            perc = perc * 2
            r1, g1, b1 = 1, 0, 0
            r2, g2, b2 = 1, 1, 0
        else
            perc = perc * 2 - 1
            r1, g1, b1 = 1, 1, 0
            r2, g2, b2 = 0, 1, 0
        end

        local r = FostercareTweaks.round(r1 + (r2 - r1) * perc, 4)
        local g = FostercareTweaks.round(g1 + (g2 - g1) * perc, 4)
        local b = FostercareTweaks.round(b1 + (b2 - b1) * perc, 4)
        local h = FostercareTweaks.rgbhex(r, g, b)

        gradientcolors[index] = { r = r, g = g, b = b, h = h }
    end

    return gradientcolors[index].r,
           gradientcolors[index].g,
           gradientcolors[index].b,
           gradientcolors[index].h
end

FostercareTweaks.rgbhex = function(r, g, b, a)
    local _r, _g, _b, _a
    if type(r) == "table" then
        if r.r then
            _r, _g, _b, _a = r.r, r.g, r.b, (r.a or 1)
        elseif #r >= 3 then
            _r, _g, _b, _a = r[1], r[2], r[3], (r[4] or 1)
        end
    elseif tonumber(r) then
        _r, _g, _b, _a = r, g, b, (a or 1)
    end

    if _r and _g and _b and _a then
        _r = _r > 1 and 1 or _r < 0 and 0 or _r
        _g = _g > 1 and 1 or _g < 0 and 0 or _g
        _b = _b > 1 and 1 or _b < 0 and 0 or _b
        _a = _a > 1 and 1 or _a < 0 and 0 or _a
        return string.format("|c%02x%02x%02x%02x", _a * 255, _r * 255, _g * 255, _b * 255)
    end
    return ""
end

FostercareTweaks.round = function(input, places)
    places = places or 0
    if type(input) == "number" then
        local pow = 10 ^ places
        return floor(input * pow + 0.5) / pow
    end
end

FostercareTweaks.Abbreviate = function(number, eachk)
    if type(number) ~= "number" then return number or "" end
    local sign = number < 0 and -1 or 1
    local num = math.abs(number)

    if num >= 1000000 then
        return FostercareTweaks.round(num / 1000000 * sign, 2) .. "m"
    elseif not eachk and num >= 10000 then
        return FostercareTweaks.round(num / 1000 * sign, 2) .. "k"
    elseif eachk and num >= 1000 then
        return FostercareTweaks.round(num / 1000 * sign, 2) .. "k"
    end
    return number
end

FostercareTweaks.TimeConvert = function(remaining)
    local color = "|cffffffff"
    if remaining < 5 then
        color = "|cffff5555"
    elseif remaining < 10 then
        color = "|cffffff55"
    end

    if remaining < 60 then
        return color .. ceil(remaining)
    elseif remaining < 3600 then
        return color .. ceil(remaining / 60) .. "m"
    elseif remaining < 86400 then
        return color .. ceil(remaining / 3600) .. "h"
    else
        return color .. ceil(remaining / 86400) .. "d"
    end
end

local borderDef = {
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 16,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

FostercareTweaks.AddBorder = function(frame, inset, color)
    if not frame then return end
    if frame.FostercareTweaks_border then return frame.FostercareTweaks_border end

    local top, right, bottom, left
    if type(inset) == "table" then
        top, right, bottom, left = unpack(inset)
        left, bottom = -left, -bottom
    end

    local b = CreateFrame("Frame", nil, frame)
    b:SetPoint("TOPLEFT", frame, "TOPLEFT", (left or -inset), (top or inset))
    b:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", (right or inset), (bottom or -inset))
    b:SetBackdrop(borderDef)

    if color then
        b:SetBackdropBorderColor(color.r, color.g, color.b, color.a or 1)
    end

    frame.FostercareTweaks_border = b
    frame.ShaguTweaks_border = b
    return b
end

-- Sorted Key Iteration
local function __genOrderedIndex(t, sortFunc)
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert(orderedIndex, key)
    end
    table.sort(orderedIndex, sortFunc)
    return orderedIndex
end

local function orderedNext(t, state)
    local key = nil
    if state == nil then
        key = t.__orderedIndex[1]
    else
        for i = 1, #t.__orderedIndex do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i + 1]
            end
        end
    end

    if key then
        return key, t[key]
    end
    t.__orderedIndex = nil
    return nil
end

FostercareTweaks.spairs = function(t, sortFunc)
    t.__orderedIndex = __genOrderedIndex(t, sortFunc)
    return orderedNext, t, nil
end

-- Item Identification & Counting
FostercareTweaks.GetItemIDFromLink = function(itemLink)
    if not itemLink then return nil end
    local _, _, itemID = string.find(itemLink, "item:(%d+)")
    return itemID and tonumber(itemID) or nil
end

FostercareTweaks.GetItemCount = function(itemNameOrID)
    if not itemNameOrID then return 0 end

    -- 1. Native ClassicAPI C_Item.GetItemCount
    if C_Item and C_Item.GetItemCount then
        local ok, count = pcall(C_Item.GetItemCount, itemNameOrID)
        if ok and type(count) == "number" and count >= 0 then
            return count
        end
    end

    -- 2. Container scanning fallback
    local count = 0
    local targetID = tonumber(itemNameOrID)
    for bag = 4, 0, -1 do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local texture, itemCount = GetContainerItemInfo(bag, slot)
            if texture then
                local num = (itemCount and itemCount > 0) and itemCount or 1
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local id = FostercareTweaks.GetItemIDFromLink(link)
                    local _, _, linkName = string.find(link, "%[(.+)%]")
                    if targetID and id and id == targetID then
                        count = count + num
                    elseif itemNameOrID and linkName and linkName == itemNameOrID then
                        count = count + num
                    elseif not targetID and id then
                        local qName = GetItemInfo(id)
                        if qName and qName == itemNameOrID then
                            count = count + num
                        end
                    end
                end
            end
        end
    end
    return count
end

local itemLinkByNameCache = {}
FostercareTweaks.GetItemLinkByName = function(name)
    if not name then return nil end
    if itemLinkByNameCache[name] then
        return itemLinkByNameCache[name]
    end

    -- Fast-path: ClassicAPI / modern environment where GetItemInfo accepts item name
    local testName, testLink, testQuality = GetItemInfo(name)
    if testName and testLink then
        local _, _, _, hex = GetItemQualityColor(tonumber(testQuality) or 1)
        local hyperLink = (hex or "|cffffffff") .. "|H" .. testLink .. "|h[" .. testName .. "]|h|r"
        itemLinkByNameCache[name] = hyperLink
        return hyperLink
    end

    -- Fallback scan across standard item IDs
    for itemID = 1, 25818 do
        local itemName, itemLink, itemQuality = GetItemInfo(itemID)
        if itemName and itemName == name then
            local _, _, _, hex = GetItemQualityColor(tonumber(itemQuality) or 1)
            local hyperLink = (hex or "|cffffffff") .. "|H" .. itemLink .. "|h[" .. itemName .. "]|h|r"
            itemLinkByNameCache[name] = hyperLink
            return hyperLink
        end
    end
end
ShaguTweaks.GetItemLinkByName = FostercareTweaks.GetItemLinkByName

-- Pattern Sanitization and Captures
local sanitize_cache = {}
FostercareTweaks.SanitizePattern = function(pattern)
    if not sanitize_cache[pattern] then
        local ret = pattern
        ret = gsub(ret, "([%+%-%*%(%)%?%[%]%^])", "%%%1")
        ret = gsub(ret, "%d%$", "")
        ret = gsub(ret, "(%%%a)", "%(%1+%)")
        ret = gsub(ret, "%%s%+", ".+")
        ret = gsub(ret, "%(.%+%)%(%%d%+%)", "%(.-%)%(%%d%+%)")
        sanitize_cache[pattern] = ret
    end
    return sanitize_cache[pattern]
end

local capture_cache = {}
FostercareTweaks.GetCaptures = function(pat)
    if not capture_cache[pat] then
        local gfind = string.gmatch or string.gfind
        for a, b, c, d, e in gfind(gsub(pat, "%((.+)%)", "%1"), gsub(pat, "%d%$", "%%(.-)$")) do
            capture_cache[pat] = { a, b, c, d, e }
        end
        capture_cache[pat] = capture_cache[pat] or {}
    end
    local r = capture_cache[pat]
    return r[1], r[2], r[3], r[4], r[5]
end

FostercareTweaks.cmatch = function(str, pat)
    local a, b, c, d, e = FostercareTweaks.GetCaptures(pat)
    local _, _, va, vb, vc, vd, ve = string.find(str, FostercareTweaks.SanitizePattern(pat))

    local ra = e == "1" and ve or d == "1" and vd or c == "1" and vc or b == "1" and vb or va
    local rb = e == "2" and ve or d == "2" and vd or c == "2" and vc or a == "2" and va or vb
    local rc = e == "3" and ve or d == "3" and vd or a == "3" and va or b == "3" and vb or vc
    local rd = e == "4" and ve or a == "4" and va or c == "4" and vc or b == "4" and vb or vd
    local re = a == "5" and va or d == "5" and vd or c == "5" and vc or b == "5" and vb or ve

    return ra, rb, rc, rd, re
end

-- Unit Data Tracker (Players & Mobs)
local unit_mobs = {}

local function GetPlayerDB()
    if not FostercareTweaks_Cache then FostercareTweaks_Cache = {} end
    if not FostercareTweaks_Cache.players then FostercareTweaks_Cache.players = {} end
    return FostercareTweaks_Cache.players
end

local function NormalizeClass(class)
    if not class then return nil end
    local L = FostercareTweaks.L
    if L and L.class and L.class[class] then
        return L.class[class]
    end
    return string.upper(tostring(class))
end
FostercareTweaks.NormalizeClass = NormalizeClass

local function StripRealm(name)
    if not name then return "" end
    local p = string.find(name, "-", 1, true)
    return p and string.sub(name, 1, p - 1) or name
end

local function AddUnitData(db, name, class, level, elite)
    if not name then return end
    if db == "players" then
        local pdb = GetPlayerDB()
        pdb[name] = pdb[name] or {}
        if class then pdb[name].class = NormalizeClass(class) or pdb[name].class end
        if level then pdb[name].level = level or pdb[name].level end
        if elite then pdb[name].elite = elite or pdb[name].elite end
    else
        unit_mobs[name] = unit_mobs[name] or {}
        if class then unit_mobs[name].class = class or unit_mobs[name].class end
        if level then unit_mobs[name].level = level or unit_mobs[name].level end
        if elite then unit_mobs[name].elite = elite or unit_mobs[name].elite end
    end
end
FostercareTweaks.AddUnitData = AddUnitData

local unitScanFrame = CreateFrame("Frame", "FCTweaksUnitScan", UIParent)

FostercareTweaks.GetUnitData = function(name, active)
    if not name then return nil end

    -- 1. Live target check (instant authoritative live data)
    if UnitExists("target") and UnitName("target") == name and UnitIsPlayer("target") then
        local ok, c1, c2 = pcall(UnitClass, "target")
        local raw = ok and ((type(c2) == "string" and c2 ~= "" and c2) or (type(c1) == "string" and c1 ~= "" and c1))
        local l = UnitLevel("target")
        if raw then
            local c = NormalizeClass(raw)
            AddUnitData("players", name, c, l)
            return c, l, nil, true
        end
    end

    -- 2. Live mouseover check (instant authoritative live data)
    if UnitExists("mouseover") and UnitName("mouseover") == name and UnitIsPlayer("mouseover") then
        local ok, c1, c2 = pcall(UnitClass, "mouseover")
        local raw = ok and ((type(c2) == "string" and c2 ~= "" and c2) or (type(c1) == "string" and c1 ~= "" and c1))
        local l = UnitLevel("mouseover")
        if raw then
            local c = NormalizeClass(raw)
            AddUnitData("players", name, c, l)
            return c, l, nil, true
        end
    end

    -- 3. AutoBG / BattlegroundTargets live roster lookup
    if type(AutoBG_FindPlayerClass) == "function" then
        local bgClass = AutoBG_FindPlayerClass(name)
        if bgClass then
            local c = NormalizeClass(bgClass)
            if c then
                AddUnitData("players", name, c)
                return c, nil, nil, true
            end
        end
    end

    -- 4. Check persistent database
    local pdb = GetPlayerDB()
    if pdb[name] and pdb[name].class then
        local ret = pdb[name]
        return ret.class, ret.level, ret.elite, true
    elseif unit_mobs[name] and unit_mobs[name].class then
        local ret = unit_mobs[name]
        return ret.class, ret.level, ret.elite, nil
    end

    -- 5. Fast-path party check
    for i = 1, GetNumPartyMembers() do
        local uid = "party" .. i
        if UnitExists(uid) and UnitName(uid) == name then
            local ok, c1, c2 = pcall(UnitClass, uid)
            local raw = ok and ((type(c2) == "string" and c2 ~= "" and c2) or (type(c1) == "string" and c1 ~= "" and c1))
            local l = UnitLevel(uid)
            if raw then
                local c = NormalizeClass(raw)
                AddUnitData("players", name, c, l)
                return c, l, nil, true
            end
        end
    end

    -- 6. SuperWoW GUID query (only if identifier is a valid hex GUID)
    if type(name) == "string" and string.sub(name, 1, 2) == "0x" then
        pcall(function()
            if UnitExists(name) and UnitIsPlayer(name) then
                local ok, c1, c2 = pcall(UnitClass, name)
                local raw = ok and ((type(c2) == "string" and c2 ~= "" and c2) or (type(c1) == "string" and c1 ~= "" and c1))
                local l = UnitLevel(name)
                if raw then
                    local c = NormalizeClass(raw)
                    local realName = UnitName(name)
                    if realName and realName ~= "" then
                        AddUnitData("players", realName, c, l)
                    end
                    AddUnitData("players", name, c, l)
                end
            end
        end)
    end
    if pdb[name] and pdb[name].class then
        local ret = pdb[name]
        return ret.class, ret.level, ret.elite, true
    end
end
ShaguTweaks.GetUnitData = FostercareTweaks.GetUnitData

unitScanFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
unitScanFrame:RegisterEvent("VARIABLES_LOADED")
unitScanFrame:RegisterEvent("PLAYER_LOGIN")
unitScanFrame:RegisterEvent("FRIENDLIST_UPDATE")
unitScanFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
unitScanFrame:RegisterEvent("RAID_ROSTER_UPDATE")
unitScanFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
unitScanFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
unitScanFrame:RegisterEvent("WHO_LIST_UPDATE")
unitScanFrame:RegisterEvent("CHAT_MSG_SYSTEM")
unitScanFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
unitScanFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
unitScanFrame:RegisterEvent("UNIT_CASTEVENT")

unitScanFrame:SetScript("OnEvent", function(arg1_param, arg2_param, arg3_param)
    local ev = (type(arg1_param) == "table" and (arg2_param or event)) or (type(arg1_param) == "string" and arg1_param) or arg2_param or event
    if not ev then return end

    if ev == "PLAYER_ENTERING_WORLD" or ev == "VARIABLES_LOADED" or ev == "PLAYER_LOGIN" then
        if UnitExists("player") then
            local name = UnitName("player")
            local _, class = UnitClass("player")
            local level = UnitLevel("player")
            AddUnitData("players", name, class, level)
        end
        if RequestBattlefieldScoreData then
            RequestBattlefieldScoreData()
        end
    elseif ev == "FRIENDLIST_UPDATE" then
        for i = 1, GetNumFriends() do
            local name, level, class = GetFriendInfo(i)
            level = (level and level > 0) and level or nil
            AddUnitData("players", name, class, level)
        end
    elseif ev == "GUILD_ROSTER_UPDATE" then
        for i = 1, GetNumGuildMembers() do
            local name, _, _, level, class = GetGuildRosterInfo(i)
            AddUnitData("players", name, class, level)
        end
    elseif ev == "RAID_ROSTER_UPDATE" then
        for i = 1, GetNumRaidMembers() do
            local name, _, _, level, class = GetRaidRosterInfo(i)
            AddUnitData("players", name, class, level)
        end
    elseif ev == "PARTY_MEMBERS_CHANGED" then
        for i = 1, GetNumPartyMembers() do
            local unit = "party" .. i
            local _, class = UnitClass(unit)
            local name = UnitName(unit)
            local level = UnitLevel(unit)
            AddUnitData("players", name, class, level)
        end
    elseif ev == "WHO_LIST_UPDATE" or ev == "CHAT_MSG_SYSTEM" then
        for i = 1, GetNumWhoResults() do
            local name, _, level, _, class = GetWhoInfo(i)
            AddUnitData("players", name, class, level)
        end
    elseif ev == "UPDATE_BATTLEFIELD_SCORE" then
        local num = (GetNumBattlefieldScores and GetNumBattlefieldScores()) or 0
        for i = 1, num do
            local name, _, _, _, _, _, _, _, c9, c10 = GetBattlefieldScore(i)
            local raw = (type(c10) == "string" and c10 ~= "" and c10) or (type(c9) == "string" and c9 ~= "" and c9)
            if name and raw then
                local c = NormalizeClass(raw)
                if c and RAID_CLASS_COLORS and RAID_CLASS_COLORS[c] then
                    AddUnitData("players", name, c)
                    local clean = StripRealm(name)
                    if clean ~= "" and clean ~= name then
                        AddUnitData("players", clean, c)
                    end
                end
            end
        end
    elseif ev == "UNIT_CASTEVENT" then
        local guid = (type(arg1_param) == "table" and arg3_param) or _G.arg1
        if guid and type(guid) == "string" and string.sub(guid, 1, 2) == "0x" then
            pcall(function()
                if UnitExists(guid) and UnitIsPlayer(guid) then
                    local name = UnitName(guid)
                    local ok, c1, c2 = pcall(UnitClass, guid)
                    local raw = ok and ((type(c2) == "string" and c2 ~= "" and c2) or (type(c1) == "string" and c1 ~= "" and c1))
                    local level = UnitLevel(guid)
                    if name and raw then
                        local class = NormalizeClass(raw)
                        if class then
                            AddUnitData("players", name, class, level)
                        end
                    end
                end
            end)
        end
    elseif ev == "UPDATE_MOUSEOVER_UNIT" or ev == "PLAYER_TARGET_CHANGED" then
        local scan = (ev == "PLAYER_TARGET_CHANGED") and "target" or "mouseover"
        if UnitExists(scan) then
            local name = UnitName(scan)
            local _, class = UnitClass(scan)
            local level = UnitLevel(scan)
            if UnitIsPlayer(scan) then
                AddUnitData("players", name, class, level)
            else
                local elite = UnitClassification(scan)
                AddUnitData("mobs", name, class, level, elite)
            end
        end
    end
end)

-- Zero-Allocation Nameplate Engine (Rule D1 compliant)
local NAMEPLATE_OBJECTORDER = { "border", "glow", "name", "level", "levelicon", "raidicon", "dragon" }

local function IsNamePlate(frame)
    if not frame or frame:GetObjectType() ~= "Button" then return false end
    local regions = frame:GetRegions()
    if not regions or not regions.GetObjectType or not regions.GetTexture then return false end
    if regions:GetObjectType() ~= "Texture" then return false end
    return regions:GetTexture() == "Interface\\Tooltips\\Nameplate-Border"
end

local libnameplate = CreateFrame("Frame", "FCTweaksLibNameplate", UIParent)
libnameplate.OnInit = {}
libnameplate.OnShow = {}
libnameplate.OnUpdate = {}
local plateRegistry = {}
local initializedCount = 0

local function InitPlate(plate, unit)
    if not plate or plateRegistry[plate] then
        if plate and unit then plate.unit = unit end
        return
    end
    if not IsNamePlate(plate) then return end

    if unit then plate.unit = unit end
    plate.healthbar = plate:GetChildren()
    FostercareTweaks.ForEachRegion(plate, function(region, regIdx)
        local key = NAMEPLATE_OBJECTORDER[regIdx]
        if key then
            plate[key] = region
        end
    end)

    for _, func in ipairs(libnameplate.OnInit) do
        func(plate)
    end

    local oldUpdate = plate:GetScript("OnUpdate")
    plate:SetScript("OnUpdate", function()
        if oldUpdate then oldUpdate() end
        for _, func in ipairs(libnameplate.OnUpdate) do
            func(plate or this)
        end
    end)

    local oldShow = plate:GetScript("OnShow")
    plate:SetScript("OnShow", function()
        if oldShow then oldShow() end
        for _, func in ipairs(libnameplate.OnShow) do
            func(plate or this)
        end
    end)

    plateRegistry[plate] = plate
end

local function ScanWorldFramePlates()
    local parentCount = WorldFrame:GetNumChildren()
    if initializedCount < parentCount then
        local currentIdx = 0
        FostercareTweaks.ForEachChild(WorldFrame, function(plate)
            currentIdx = currentIdx + 1
            if currentIdx > initializedCount then
                InitPlate(plate)
            end
        end)
        initializedCount = parentCount
    end
end

libnameplate:RegisterEvent("NAME_PLATE_CREATED")
libnameplate:RegisterEvent("NAME_PLATE_UNIT_ADDED")
libnameplate:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
libnameplate:RegisterEvent("PLAYER_ENTERING_WORLD")

libnameplate:SetScript("OnEvent", function(arg1_param, arg2_param)
    local ev = (type(arg1_param) == "string" and arg1_param) or arg2_param or event or _G.event
    local a1 = (type(arg1_param) == "string" and arg2_param) or arg1 or _G.arg1

    if ev == "NAME_PLATE_CREATED" and a1 then
        InitPlate(a1)
    elseif ev == "NAME_PLATE_UNIT_ADDED" and a1 then
        local unit = a1
        local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
        if plate then
            InitPlate(plate, unit)
        end
    elseif ev == "NAME_PLATE_UNIT_REMOVED" and a1 then
        local unit = a1
        local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
        if plate then
            plate.unit = nil
        end
    elseif ev == "PLAYER_ENTERING_WORLD" then
        if C_NamePlate and C_NamePlate.GetNamePlates then
            local plates = C_NamePlate.GetNamePlates()
            if plates then
                for _, p in ipairs(plates) do
                    InitPlate(p)
                end
            end
        end
        ScanWorldFramePlates()
    end
end)

libnameplate.tick = 0
libnameplate:SetScript("OnUpdate", function()
    local now = GetTime()
    if (this.tick or 0) > now then return end
    this.tick = now + 0.5

    ScanWorldFramePlates()
end)

FostercareTweaks.libnameplate = libnameplate
ShaguTweaks.libnameplate = libnameplate

-- UnitXP SP3 Extension Detection (Distinguishes UnitXP SP3 DLL from native Blizzard UnitXP(unit))
local hasUnitXPSP3 = nil
FostercareTweaks.HasUnitXP = function()
    if hasUnitXPSP3 == nil then
        if type(UnitXP) == "function" then
            hasUnitXPSP3 = (pcall(UnitXP, "nop", "nop") == true)
        else
            hasUnitXPSP3 = false
        end
    end
    return hasUnitXPSP3
end
if ShaguTweaks then
    ShaguTweaks.HasUnitXP = FostercareTweaks.HasUnitXP
end
