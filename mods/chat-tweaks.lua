local FT = FostercareTweaks
if not FT then return end

-- One AddMessage wrapper per chat window (combat logs excepted) runs the line
-- filters the chat modules add, in the order they start: links, timestamps,
-- class colours. A wrapper per module cost a call and a closure per line each.
local filters
function FT.AddChatFilter(filter)
    if not filters then
        filters = {}
        for i = 1, NUM_CHAT_WINDOWS do
            local cf = _G["ChatFrame" .. i]
            if not FT.IsCombatChatFrame(cf) then
                local add = cf.AddMessage
                cf.AddMessage = function(frame, text, a1, a2, a3, a4, a5)
                    if text then
                        for f = 1, #filters do text = filters[f](text) end
                    end
                    return add(frame, text, a1, a2, a3, a4, a5)
                end
            end
        end
    end
    filters[#filters + 1] = filter
end

do
-- Mouse wheel chat scrolling and arrow key history

local module = FT:register({
    title = "Chat Tweaks",
    enabled = true,
})

local function ChatOnMouseWheel()
    if arg1 > 0 then
        if IsShiftKeyDown() then this:ScrollToTop() else this:ScrollUp() end
    elseif arg1 < 0 then
        if IsShiftKeyDown() then this:ScrollToBottom() else this:ScrollDown() end
    end
end

-- Whispers, officer chat, raid warnings and channels are sticky in the game
-- already (FrameXML ChatFrame.lua).
module.enable = function(self)
    ChatFrameEditBox:SetAltArrowKeyMode(false)
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        frame:EnableMouseWheel(true)
        frame:SetScript("OnMouseWheel", ChatOnMouseWheel)
    end
end
end

do
-- Copy website URLs from chat, transform CLINKs into real links, name links with Shift

local module = FT:register({
    title = "Chat Hyperlinks",
    always = true,
})

-- Web addresses become links to copy. In order: the first pattern that matches
-- a word makes the link. { pattern, how its captures join, [3] = gsub's function }.
local PATTERNS = {
    { " (www%d-)%.([_A-Za-z0-9-]+)%.(%S+)%s?", "%s.%s.%s" },
    { " (%a+)://(%S+)%s?", "%s://%s" },
    { " ([_A-Za-z0-9-%.:]+)@([_A-Za-z0-9-]+)(%.)([_A-Za-z0-9-]+%.?[_A-Za-z0-9-]*)%s?", "%s@%s%s%s", email = true },
    { " (%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?):(%d%d?%d?%d?%d?)%s?", "%s.%s.%s.%s:%s" },
    { " (%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%s?", "%s.%s.%s.%s" },
    { " (%a+)%.(%a+)/(%S+)%s?", "%s.%s/%s" },
    { " ([_A-Za-z0-9-]+)%.([_A-Za-z0-9-]+)%.(%S+)%:([_0-9-]+)%s?", "%s.%s.%s:%s" },
    { " ([_A-Za-z0-9-]+)%.([_A-Za-z0-9-]+)%.(%S+)%s?", "%s.%s.%s" },
}
local function Link(address) return "|cffccccff|Hurl:" .. address .. "|h[" .. address .. "]|h|r " end
for _, pattern in ipairs(PATTERNS) do
    local form, email = pattern[2], pattern.email
    pattern[3] = function(a1, a2, a3, a4, a5)
        local address = string.format(form, a1, a2, a3, a4, a5)
        -- "word.." ends a sentence; it is no address.
        if string.find(a5 or a4 or a3 or a2, "%.%.$") then return address end
        -- "Bob:me@mail.com": the name before the colon stays text.
        local colon = email and string.find(a1, ":")
        if colon and #a1 > colon and string.sub(a1, 1, 6) ~= "mailto" then
            return " " .. string.sub(address, 1, colon) .. Link(string.sub(address, colon + 1))
        end
        return " " .. Link(address)
    end
end

-- Every link pattern needs a dot or @ before a letter or digit, or "://".
-- "[1. General]", "Bob:" and the end of a sentence have none.
local function MayLink(text)
    return string.find(text, "[%.@][%w_-]") or string.find(text, "://", 1, true)
end
local function ConvertWord(word)
    if not MayLink(word) then return word end
    -- Prefixing a space also handles a URL at the start of a message;
    -- subsequent patterns cannot nest generated links.
    for _, pattern in ipairs(PATTERNS) do
        local converted, count = string.gsub(" " .. word, pattern[1], pattern[3])
        if count > 0 then return string.match(converted, "^%s*(.-)%s*$") end
    end
    return word
end
local function ConvertPlainURLs(text)
    return (string.gsub(text, "(%S+)", ConvertWord))
end
-- The line is built by concatenation: a reused table read back with
-- table.concat came out empty in game (the stored length of a wiped table).
local function HandleLink(text)
    if not MayLink(text) then return text end
    local out, cursor = "", 1
    while cursor <= #text do
        local first, last = string.find(text, "|H[^|]*|h.-|h", cursor)
        if not first then return out .. ConvertPlainURLs(string.sub(text, cursor)) end
        -- Item/player/quest links belong to their native or optional owners.
        out = out .. ConvertPlainURLs(string.sub(text, cursor, first - 1)) .. string.sub(text, first, last)
        cursor = last + 1
    end
    return out
end

local CopyLinkDialog = CreateFrame("Frame", "FCTweaksURLCopy", UIParent)
CopyLinkDialog:Hide()
CopyLinkDialog:SetWidth(300)
CopyLinkDialog:SetHeight(90)
CopyLinkDialog:SetFrameStrata("FULLSCREEN")
CopyLinkDialog:SetPoint("CENTER", 0, 0)
CopyLinkDialog:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

CopyLinkDialog:SetScript("OnShow", function()
    this.text:HighlightText()
end)

CopyLinkDialog.text = CreateFrame("EditBox", "FCTweaksURLCopyEditBox", CopyLinkDialog)
CopyLinkDialog.text:SetTextColor(1, 0.8, 0)
CopyLinkDialog.text:SetJustifyH("CENTER")
CopyLinkDialog.text:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
CopyLinkDialog.text:SetBackdropColor(0, 0, 0, 0.8)
CopyLinkDialog.text:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
CopyLinkDialog.text:SetWidth(260)
CopyLinkDialog.text:SetHeight(25)
CopyLinkDialog.text:SetPoint("TOP", CopyLinkDialog, "TOP", 0, -20)
CopyLinkDialog.text:SetFontObject(GameFontNormal)
CopyLinkDialog.text:SetScript("OnEscapePressed", function() CopyLinkDialog:Hide() end)
CopyLinkDialog.text:SetScript("OnEditFocusLost", function() CopyLinkDialog:Hide() end)

CopyLinkDialog.close = CreateFrame("Button", "FCTweaksURLCopyClose", CopyLinkDialog, "UIPanelButtonTemplate")
CopyLinkDialog.close:SetPoint("BOTTOMRIGHT", CopyLinkDialog, "BOTTOMRIGHT", -20, 20)
CopyLinkDialog.close:SetWidth(70)
CopyLinkDialog.close:SetHeight(18)
CopyLinkDialog.close:SetText(CLOSE)
CopyLinkDialog.close:SetScript("OnClick", function() CopyLinkDialog:Hide() end)

CopyLinkDialog.CopyText = function(text)
    CopyLinkDialog.text:SetText(text)
    CopyLinkDialog:Show()
end

module.enable = function(self)
    local origSetItemRef = SetItemRef
    function _G.SetItemRef(link, text, button)
        if string.sub(link, 1, 4) == "url:" then
            if #link > 4 then CopyLinkDialog.CopyText(string.sub(link, 5)) end
            return
        end
        -- Shift-click on a name with the chat box open: the name as a link.
        if string.sub(link, 1, 7) == "player:" and #link > 7 and IsShiftKeyDown() and ChatFrameEditBox:IsVisible() then
            local name = string.gsub(string.sub(link, 8), ":.*$", "")
            ChatFrameEditBox:Insert("|cffffffff|Hplayer:" .. name .. "|h[" .. name .. "]|h|r")
            return
        end
        -- Everything else is the game's, quest links too: ClassicAPI's
        -- SetHyperlink shows a quest's title and objectives.
        -- UNVERIFIED: test in game: click a quest link in chat; the tooltip shows the quest's title and objectives
        origSetItemRef(link, text, button)
    end

    FT.AddChatFilter(function(text)
        if string.find(text, "{CLINK:", 1, true) then
            text = string.gsub(text, "{CLINK:(%x+):([%d-]-:[%d-]-:[%d-]-:[%d-]-:[%d-]-:[%d-]-:[%d-]-:[%d-]-):([^}]-)}", "|c%1|Hitem:%2|h[%3]|h|r")
            text = string.gsub(text, "{CLINK:(%x+):([%d-]-:[%d-]-:[%d-]-:[%d-]-):([^}]-)}", "|c%1|Hitem:%2|h[%3]|h|r")
            text = string.gsub(text, "{CLINK:item:(%x+):([%d-]-:[%d-]-:[%d-]-:[%d-]-:[%d-]-:[%d-]-:[%d-]-:[%d-]-):([^}]-)}", "|c%1|Hitem:%2|h[%3]|h|r")
            text = string.gsub(text, "{CLINK:enchant:(%x+):([%d-]-):([^}]-)}", "|c%1|Henchant:%2|h[%3]|h|r")
            text = string.gsub(text, "{CLINK:spell:(%x+):([%d-]-):([^}]-)}", "|c%1|Hspell:%2|h[%3]|h|r")
            text = string.gsub(text, "{CLINK:quest:(%x+):([%d-]-):([%d-]-):([^}]-)}", "|c%1|Hquest:%2:%3|h[%4]|h|r")
        end
        return HandleLink(text)
    end)
end
end

do
-- Chat history of the non-combat windows. The frames keep their own lines
-- (ClassicAPI smf:GetMessageInfo): they are read once when the UI closes
-- (logout or reload) and put back behind newer lines at login
-- (smf:BackFillMessage). No wrapper runs on every chat line.

local module = FT:register({
    title = "Chat History",
    enabled = true,
})

local KEEP = 30
-- AddMessage keeps extra values; this one marks a restored, already dimmed line.
local RESTORED = "FCTweaksHistory"

module.enable = function(self)
    -- One list of lines per chat window. Before 1.20 they sat under realm and
    -- name, in a table that is the character's own anyway.
    local cache = FostercareTweaks_Cache
    if type(cache.chathistory) == "table" then
        local old = cache.chathistory[GetRealmName()]
        old = type(old) == "table" and old[UnitName("player")]
        if type(cache.chat) ~= "table" and type(old) == "table" then cache.chat = old end
        cache.chathistory = nil
    end
    if type(cache.chat) ~= "table" then cache.chat = {} end
    local histories = cache.chat

    local function Dim(text, r, g, b)
        if not (r and g and b) then return text end
        local color = string.format("|cff%02x%02x%02x", math.floor((r * 0.5 + 0.2) * 255),
            math.floor((g * 0.5 + 0.2) * 255), math.floor((b * 0.5 + 0.2) * 255))
        return color .. (string.gsub(text, "|r", "|r" .. color))
    end

    local frames = {}
    for i = 1, NUM_CHAT_WINDOWS do
        local cf = _G["ChatFrame" .. i]
        if cf and not FT.IsCombatChatFrame(cf) then
            frames[i] = cf
            -- Saved newest first; each goes behind the lines already shown.
            local history = histories[i]
            if type(history) == "table" then
                for j = 1, math.min(#history, KEEP) do
                    if type(history[j]) == "string" then cf:BackFillMessage(history[j], 0.7, 0.7, 0.7, RESTORED) end
                end
            end
        end
    end

    local saver = CreateFrame("Frame")
    saver:RegisterEvent("PLAYER_LOGOUT")
    FT.SetEventHandler(saver, function()
        for i, cf in pairs(frames) do
            local history, newest = {}, cf:GetNumMessages()
            for index = newest, math.max(1, newest - KEEP + 1), -1 do
                local text, r, g, b, mark = cf:GetMessageInfo(index)
                if text then history[#history + 1] = mark == RESTORED and text or Dim(text, r, g, b) end
            end
            histories[i] = history
        end
    end)
end
end

do
-- Adds timestamps to chat messages

local module = FT:register({
    title = "Chat Timestamps",
    enabled = false,
})

-- [HH:MM:SS] in light grey.
local STAMP = "|cffcccccc[%H:%M:%S]|r "

-- Combat log windows stay unstamped, as the other chat filters leave them:
-- every combat line would build a new string.
-- The filter joins the chat windows the first time the switch is on.
local on
module.apply = function(self, value)
    if on == nil then
        if not value then return end
        FT.AddChatFilter(function(text) return on and date(STAMP) .. text or text end)
    end
    on = value and true or false
end

module.enable = function() module:apply(true) end
end

do
-- "|Hplayer:Name:id|h[Name]|h" becomes the name in its class color (grey when
-- the class is unknown), brackets in the line's color. Lua 5.0's gsub uses the
-- empty string for a nil result, so a link left alone is returned whole.
local module = FT:register({
    title = "Chat Class Colors",
    enabled = true,
})

local function Colorize(link, shown)
    local real = string.gsub(link, ":.*$", "")
    if shown ~= real then return "|Hplayer:" .. link .. "|h[" .. shown .. "]|h" end
    local class = FT.GetPlayerClass(real)
    local classColor = class and C_ClassColor.GetClassColor(class)
    local color = classColor and classColor:GenerateHexColorMarkup() or "|cffaaaaaa"
    return "|r[" .. color .. "|Hplayer:" .. link .. "|h" .. color .. real .. "|h|r]|r"
end

local on
module.apply = function(self, value)
    if on == nil then
        if not value then return end
        FT.AddChatFilter(function(text)
            if on and string.find(text, "|Hplayer:", 1, true) then
                text = string.gsub(text, "|Hplayer:([^|]*)|h%[([^%]|]*)%]|h", Colorize)
            end
            return text
        end)
    end
    on = value and true or false
end

module.enable = function() module:apply(true) end
end
