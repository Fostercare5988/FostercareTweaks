-- Chat: the arrow keys without Alt, web addresses as links, Shift-click names,
-- the last lines back after a reload, timestamps, names in class colours.
local _, FT = ...
if not FT.apply then return end
local db = TweaksDB
local find, gsub, match, sub = string.find, string.gsub, string.match, string.sub

function FT.apply.arrowKeys() ChatFrameEditBox:SetAltArrowKeyMode(not db.arrowKeys) end
FT.apply.arrowKeys()

-- Shamans blue in every class colour (C_ClassColor returns the same table,
-- ### C_ClassColor.GetClassColor). Names already drawn keep their colour.
local shaman = RAID_CLASS_COLORS.SHAMAN
local stock, blue = { shaman.r, shaman.g, shaman.b, shaman.colorStr }, { 0.14, 0.35, 1, "ff2459ff" }
function FT.apply.blueShaman()
    local c = db.blueShaman and blue or stock
    shaman.r, shaman.g, shaman.b, shaman.colorStr = c[1], c[2], c[3], c[4]
end
FT.apply.blueShaman()

-- Web addresses ---------------------------------------------------------------

-- A word is an address when one of these matches it whole, once the
-- punctuation that ends a sentence is taken off.
local ADDRESSES = { "^%a+://%S+$", "^www%d-%.[%w_-]+%.%S+$", "^[%w_.%-]+@[%w_-]+%.[%w_.%-]+$",
    "^%d+%.%d+%.%d+%.%d+:?%d*$", "^%a+%.%a+/%S+$", "^[%w_-]+%.[%w_-]+%.%a%S*$" }

local function IsAddress(word)
    for i = 1, #ADDRESSES do
        if find(word, ADDRESSES[i]) then return true end
    end
end

local function Word(word)
    local body, tail = match(word, "^(.-)([%.,;!%?%)]*)$")
    local head, address = "", body
    local name, rest = match(body, "^([^:@/]+:)([^:]+@.+)$") -- "Bob:me@mail.com": the name stays text
    if name and name ~= "mailto:" and IsAddress(rest) then head, address = name, rest end
    if not IsAddress(address) then return word end
    return head .. "|cffccccff|Hurl:" .. address .. "|h[" .. address .. "]|h|r" .. tail
end

-- Words outside the links already in the line (items, players, quests).
local function Addresses(text)
    if not (find(text, "[%.@][%w_-]") or find(text, "://", 1, true)) then return text end
    local out, at = "", 1
    while true do
        local first, last = find(text, "|H.-|h.-|h", at)
        out = out .. gsub(sub(text, at, (first or 0) - 1), "%S+", Word)
        if not first then return out end
        out = out .. sub(text, first, last)
        at = last + 1
    end
end

StaticPopupDialogs.TWEAKS_URL = {
    text = "Copy the address with Ctrl+C:",
    button1 = CLOSE,
    hasEditBox = 1, hasWideEditBox = 1, timeout = 0, whileDead = 1, hideOnEscape = 1,
    OnShow = function(address)
        local box = _G[this:GetName() .. "WideEditBox"]
        box:SetText(address)
        box:SetFocus()
        box:HighlightText()
    end,
    EditBoxOnEscapePressed = function() this:GetParent():Hide() end,
}

-- An address opens the copy box; Shift-click on a name with the chat box open
-- puts the name in as a link (the game puts plain text: FrameXML ItemRef.lua).
local stockRef = SetItemRef
function SetItemRef(link, text, button)
    if sub(link, 1, 4) == "url:" then
        StaticPopup_Show("TWEAKS_URL", nil, nil, sub(link, 5))
        return
    end
    local name = IsShiftKeyDown() and ChatFrameEditBox:IsVisible() and match(link, "^player:([^:]+)")
    if name then
        ChatFrameEditBox:Insert("|cffffffff|Hplayer:" .. name .. "|h[" .. name .. "]|h|r")
        return
    end
    return stockRef(link, text, button)
end

-- Each line --------------------------------------------------------------------

-- The sender's class comes from the line's GUID (### GetCurrentChatGUID()); any
-- other name from the players the client has seen (### C_PlayerCache).
local function Colour(link, shown)
    local name = match(link, "^[^:]+")
    local class
    local guid = GetCurrentChatGUID()
    if guid then
        local _, token, _, _, _, guidName = GetPlayerInfoByGUID(guid)
        if guidName == name then class = token end
    end
    class = class or select(2, C_PlayerCache.GetPlayerInfoByName(name))
    local color = class and C_ClassColor.GetClassColor(class)
    if shown ~= name or not color then return "|Hplayer:" .. link .. "|h[" .. shown .. "]|h" end
    return "[|Hplayer:" .. link .. "|h" .. color:WrapTextInColorCode(name) .. "|h]"
end

local function Line(text)
    if db.classColors and find(text, "|Hplayer:", 1, true) then
        text = gsub(text, "|Hplayer:([^|]*)|h%[([^%]|]*)%]|h", Colour)
    end
    text = Addresses(text)
    if db.timestamps then text = date("|cffcccccc[%H:%M:%S]|r ") .. text end
    return text
end

-- A window that shows many combat and spell messages is a combat log: it is left
-- alone, so no combat line builds a string of ours.
local function CombatLog(frame)
    local n = 0
    for _, kind in pairs(frame.messageTypeList or {}) do
        if find(kind, "COMBAT", 1, true) or find(kind, "SPELL", 1, true) then n = n + 1 end
    end
    return n > 5
end

-- History ----------------------------------------------------------------------

local KEEP = 30
local RESTORED = "Tweaks" -- kept with a restored line (### smf:GetMessageInfo)

-- A saved line keeps its colour, dimmed.
local function Dim(text, r, g, b)
    if not r then return text end
    local function Byte(v) return math.floor((v * 0.5 + 0.2) * 255) end
    local code = string.format("|cff%02x%02x%02x", Byte(r), Byte(g), Byte(b))
    return code .. gsub(text, "|r", "|r" .. code)
end

-- The windows are known once the client has read their message types.
local frames = {}
local chat = CreateFrame("Frame")
chat:RegisterEvent("PLAYER_ENTERING_WORLD")
chat:RegisterEvent("PLAYER_LOGOUT")
chat:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
        db.chat = nil
        if not db.history then return end
        db.chat = {} -- vanillaforge-ignore: D2 (once, at logout)
        for i, frame in pairs(frames) do
            local lines, newest = {}, frame:GetNumMessages() -- vanillaforge-ignore: D2 (once, at logout)
            for index = newest, math.max(1, newest - KEEP + 1), -1 do
                local text, r, g, b, mark = frame:GetMessageInfo(index)
                if text then lines[#lines + 1] = mark == RESTORED and text or Dim(text, r, g, b) end
            end
            db.chat[i] = lines
        end
        return
    end
    this:UnregisterEvent("PLAYER_ENTERING_WORLD")
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        if not CombatLog(frame) then
            frames[i] = frame
            local add = frame.AddMessage
            frame.AddMessage = function(self, text, ...)
                if type(text) == "string" then text = Line(text) end
                return add(self, text, ...)
            end
            -- Saved newest first; each goes behind the lines already there.
            local lines = db.history and db.chat and db.chat[i]
            for j = 1, lines and math.min(#lines, KEEP) or 0 do
                frame:BackFillMessage(lines[j], 0.7, 0.7, 0.7, RESTORED)
            end
        end
    end
end)
