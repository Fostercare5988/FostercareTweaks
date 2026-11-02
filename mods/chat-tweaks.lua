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
    local delta = _G.arg1 or 0
    if delta > 0 then
        if IsShiftKeyDown() then this:ScrollToTop() else this:ScrollUp() end
    elseif delta < 0 then
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
-- Copy website URLs from chat, transform CLINKs into real items, handle quest and player links

local module = FT:register({
    title = "Chat Hyperlinks",
    always = true,
})

local URLPattern = {
    WWW = {
        ["rx"] = " (www%d-)%.([_A-Za-z0-9-]+)%.(%S+)%s?",
        ["fm"] = "%s.%s.%s"
    },
    PROTOCOL = {
        ["rx"] = " (%a+)://(%S+)%s?",
        ["fm"] = "%s://%s"
    },
    EMAIL = {
        ["rx"] = " ([_A-Za-z0-9-%.:]+)@([_A-Za-z0-9-]+)(%.)([_A-Za-z0-9-]+%.?[_A-Za-z0-9-]*)%s?",
        ["fm"] = "%s@%s%s%s"
    },
    PORTIP = {
        ["rx"] = " (%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?):(%d%d?%d?%d?%d?)%s?",
        ["fm"] = "%s.%s.%s.%s:%s"
    },
    IP = {
        ["rx"] = " (%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%s?",
        ["fm"] = "%s.%s.%s.%s"
    },
    SHORTURL = {
        ["rx"] = " (%a+)%.(%a+)/(%S+)%s?",
        ["fm"] = "%s.%s/%s"
    },
    URLIP = {
        ["rx"] = " ([_A-Za-z0-9-]+)%.([_A-Za-z0-9-]+)%.(%S+)%:([_0-9-]+)%s?",
        ["fm"] = "%s.%s.%s:%s"
    },
    URL = {
        ["rx"] = " ([_A-Za-z0-9-]+)%.([_A-Za-z0-9-]+)%.(%S+)%s?",
        ["fm"] = "%s.%s.%s"
    },
}

local function FormatLink(formatter, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
    if not (formatter and a1) then return end
    local newtext = string.format(formatter, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)

    local lastArg = a10 or a9 or a8 or a7 or a6 or a5 or a4 or a3 or a2 or a1
    local invalidtld = lastArg and string.find(lastArg, "(%.%.)$")

    if invalidtld then return newtext end

    if formatter == URLPattern.EMAIL.fm then
        local colon = string.find(a1, ":")
        if colon and #a1 > colon then
            if string.sub(a1, 1, 6) ~= "mailto" then
                local prefix, address = string.sub(newtext, 1, colon), string.sub(newtext, colon + 1)
                return string.format(" %s|cffccccff|Hurl:%s|h[%s]|h|r ", prefix, address, address)
            end
        end
    end
    return " |cffccccff|Hurl:" .. newtext .. "|h[" .. newtext .. "]|h|r "
end

local URLFuncs = {
    ["WWW"] = function(a1, a2, a3) return FormatLink(URLPattern.WWW.fm, a1, a2, a3) end,
    ["PROTOCOL"] = function(a1, a2) return FormatLink(URLPattern.PROTOCOL.fm, a1, a2) end,
    ["EMAIL"] = function(a1, a2, a3, a4) return FormatLink(URLPattern.EMAIL.fm, a1, a2, a3, a4) end,
    ["PORTIP"] = function(a1, a2, a3, a4, a5) return FormatLink(URLPattern.PORTIP.fm, a1, a2, a3, a4, a5) end,
    ["IP"] = function(a1, a2, a3, a4) return FormatLink(URLPattern.IP.fm, a1, a2, a3, a4) end,
    ["SHORTURL"] = function(a1, a2, a3) return FormatLink(URLPattern.SHORTURL.fm, a1, a2, a3) end,
    ["URLIP"] = function(a1, a2, a3, a4) return FormatLink(URLPattern.URLIP.fm, a1, a2, a3, a4) end,
    ["URL"] = function(a1, a2, a3) return FormatLink(URLPattern.URL.fm, a1, a2, a3) end,
}

local URLKinds = {"WWW", "PROTOCOL", "EMAIL", "PORTIP", "IP", "SHORTURL", "URLIP", "URL"}
-- Every link pattern needs a dot or @ before a letter or digit, or "://".
-- "[1. General]", "Bob:" and the end of a sentence have none.
local function MayLink(text)
    return string.find(text, "[%.@][%w_-]") or string.find(text, "://", 1, true)
end
local function ConvertWord(word)
    if not MayLink(word) then return word end
    -- Prefixing a space also handles a URL at the start of a message;
    -- subsequent patterns cannot nest generated links.
    for _, kind in ipairs(URLKinds) do
        local converted, count = string.gsub(" " .. word, URLPattern[kind].rx, URLFuncs[kind])
        if count > 0 then return string.match(converted, "^%s*(.-)%s*$") end
    end
    return word
end
local function ConvertPlainURLs(text)
    return (string.gsub(text, "(%S+)", ConvertWord))
end
local parts = {}
local function HandleLink(text)
    if not MayLink(text) then return text end
    table.wipe(parts)
    local cursor = 1
    while cursor <= #text do
        local first, last = string.find(text, "|H[^|]*|h.-|h", cursor)
        if not first then parts[#parts + 1] = ConvertPlainURLs(string.sub(text, cursor)); break end
        parts[#parts + 1] = ConvertPlainURLs(string.sub(text, cursor, first - 1))
        -- Item/player/quest links belong to their native or optional owners.
        parts[#parts + 1] = string.sub(text, first, last)
        cursor = last + 1
    end
    return table.concat(parts)
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
        local questlink, _, quest_id = string.find(link, "quest:(%d+):.*")
        local playerlink = string.sub(link, 1, 6) == "player"

        if string.sub(link, 1, 3) == "url" then
            if #link > 4 and string.sub(link, 1, 4) == "url:" then
                CopyLinkDialog.CopyText(string.sub(link, 5))
            end
            return
        elseif questlink then
            local _, _, quest_title = string.find(text, ".*|h%[(.*)%]|h.*")
            if quest_title then
                HideUIPanel(ItemRefTooltip)
                ShowUIPanel(ItemRefTooltip)
                ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
                ItemRefTooltip:AddLine(quest_title, 1, 1, 0)
                ItemRefTooltip:AddDoubleLine("Quest ID", quest_id, 0.6, 0.6, 0.6, 1, 1, 1)
                ItemRefTooltip:Show()
            end
            return
        elseif playerlink then
            local name = string.sub(link, 8)
            if name and #name > 0 then
                local realName = string.gsub(name, ":.*$", "")
                realName = gsub(realName, "([^%s]*)%s+([^%s]*)%s+([^%s]*)", "%3")
                realName = gsub(realName, "([^%s]*)%s+([^%s]*)", "%2")
                if IsShiftKeyDown() and ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
                    ChatFrameEditBox:Insert("|cffffffff|Hplayer:" .. realName .. "|h[" .. realName .. "]|h|r")
                    return
                end
            end
        end
        origSetItemRef(link, text, button)
    end

    FT.AddChatFilter(function(text)
        if string.find(text, "{CLINK:", 1, true) then
            text = gsub(text, "{CLINK:(%x+):([%d-]-:[%d-]-:[%d-]-:[%d-]-:[%d-]-:[%d-]-:[%d-]-:[%d-]-):([^}]-)}", "|c%1|Hitem:%2|h[%3]|h|r")
            text = gsub(text, "{CLINK:(%x+):([%d-]-:[%d-]-:[%d-]-:[%d-]-):([^}]-)}", "|c%1|Hitem:%2|h[%3]|h|r")
            text = gsub(text, "{CLINK:item:(%x+):([%d-]-:[%d-]-:[%d-]-:[%d-]-:[%d-]-:[%d-]-:[%d-]-:[%d-]-):([^}]-)}", "|c%1|Hitem:%2|h[%3]|h|r")
            text = gsub(text, "{CLINK:enchant:(%x+):([%d-]-):([^}]-)}", "|c%1|Henchant:%2|h[%3]|h|r")
            text = gsub(text, "{CLINK:spell:(%x+):([%d-]-):([^}]-)}", "|c%1|Hspell:%2|h[%3]|h|r")
            text = gsub(text, "{CLINK:quest:(%x+):([%d-]-):([%d-]-):([^}]-)}", "|c%1|Hquest:%2:%3|h[%4]|h|r")
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

local rgbhex = FT.rgbhex

local module = FT:register({
    title = "Chat History",
    enabled = true,
})

local KEEP = 30
-- AddMessage keeps extra values; this one marks a restored, already dimmed line.
local RESTORED = "FCTweaksHistory"

module.enable = function(self)
    local realm = GetRealmName()
    local player = UnitName("player")

    local function ChildTable(parent, key)
        if type(parent[key]) ~= "table" then parent[key] = {} end
        return parent[key]
    end
    local histories = ChildTable(ChildTable(ChildTable(FostercareTweaks_Cache, "chathistory"), realm), player)

    local function Dim(text, r, g, b)
        if not (r and g and b) then return text end
        local color = rgbhex(r * 0.5 + 0.2, g * 0.5 + 0.2, b * 0.5 + 0.2)
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
module.enable = function(self)
    FT.AddChatFilter(function(text) return date(STAMP) .. text end)
end
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
    local color = class and RAID_CLASS_COLORS[class] and FT.rgbhex(RAID_CLASS_COLORS[class]) or "|cffaaaaaa"
    return "|r[" .. color .. "|Hplayer:" .. link .. "|h" .. color .. real .. "|h|r]|r"
end

module.enable = function(self)
    FT.AddChatFilter(function(text)
        if string.find(text, "|Hplayer:", 1, true) then
            text = string.gsub(text, "|Hplayer:([^|]*)|h%[([^%]|]*)%]|h", Colorize)
        end
        return text
    end)
end
end
