-- UI.lua - the callout bar: pick how many, click a node; flag calls in flag battlegrounds; the
-- team status board underneath. Frames are made once and re-laid out per battleground.

local _, ns = ...

local UI = {}
ns.UI = UI

local WIDTH = 296
local PAD = 10
local ROW = 24
local MAX_NODES = 8
local BOARD_LINES = 6

local bar, title, hereText, hint
local countButtons, nodeButtons, boardLines = {}, {}, {}
local flags
local current       -- the battleground definition laid out now
local count = "?"   -- the picked INC count

local function button(name, parent, width, text, onClick)
    local b = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    b:SetSize(width, ROW - 2)
    b:SetText(text)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnClick", onClick)
    return b
end

local function pickCount(value)
    count = value
    for i, b in ipairs(countButtons) do
        if ns.Callouts.COUNTS[i] == value then b:LockHighlight() else b:UnlockHighlight() end
    end
end

-- The picked count, reset to "?" once used so a stale number isn't repeated by accident.
function UI.TakeCount()
    local value = count
    pickCount("?")
    return value
end

local function onNodeClick(self, mouseButton)
    local node = self:GetText()
    if mouseButton == "RightButton" then
        ns.Call({ kind = "HELP", node = node })
    elseif IsShiftKeyDown() then
        ns.Call({ kind = "CLEAR", node = node })
    else
        ns.Call({ kind = "INC", node = node, count = UI.TakeCount() })
    end
end

-- Short board text for a call.
local function describe(call)
    if call.kind == "INC" then return (call.node or "?") .. ": INC " .. (call.count or "?") end
    if call.kind == "CLEAR" then return (call.node or "?") .. ": CLEAR" end
    if call.kind == "HELP" then return (call.node or "?") .. ": HELP" end
    if call.kind == "EFC" then return "EFC: " .. (call.lane or "?") end
    if call.kind == "OURFC" then return "Our FC: " .. (call.lane or "?") end
    if call.kind == "FLAGROOM" then return "INC FLAG ROOM" end
    if call.kind == "FCHELP" then return "FC NEEDS HELP" end
    return call.kind
end

local KIND_COLOR = { INC = "|cffff6040", HELP = "|cffff4040", CLEAR = "|cff40ff40", EFC = "|cffff6040",
                     OURFC = "|cff40c0ff", FLAGROOM = "|cffff6040", FCHELP = "|cffff4040" }

function UI.RefreshBoard()
    if not bar then return end
    local rows = ns.Board.Active(ns.board, GetTime())
    for i, line in ipairs(boardLines) do
        local row = rows[i]
        if row then
            line:SetText(("%s%s|r  |cff9d9d9d%s, %ds|r"):format(KIND_COLOR[row.call.kind] or "",
                describe(row.call), row.by, math.floor(row.age)))
        else
            line:SetText(i == 1 and "|cff9d9d9dNo calls yet.|r" or "")
        end
    end
end

function UI.RefreshHere(here)
    if hereText then hereText:SetText(here and ("You're at: " .. here) or "") end
end

local function makeFlags()
    flags = CreateFrame("Frame", "BGCommsFlags", bar)
    flags:SetSize(WIDTH - 2 * PAD, 3 * ROW)
    local function row(y, label, prefix, kind)
        local text = flags:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("TOPLEFT", 0, -y - 5)
        text:SetText(label)
        for i, lane in ipairs(ns.Callouts.LANES) do
            local b = button(prefix .. i, flags, 64, lane:sub(1, 1) .. lane:sub(2):lower(),
                function() ns.Call({ kind = kind, lane = lane }) end)
            b:SetPoint("TOPLEFT", 72 + (i - 1) * 66, -y)
        end
    end
    row(0, "Enemy FC", "BGCommsEFC", "EFC")
    row(ROW, "Our FC", "BGCommsOurFC", "OURFC")
    local room = button("BGCommsFlagRoom", flags, 136, "INC flag room", function() ns.Call({ kind = "FLAGROOM" }) end)
    room:SetPoint("TOPLEFT", 0, -2 * ROW)
    local help = button("BGCommsFCHelp", flags, 136, "FC needs help", function() ns.Call({ kind = "FCHELP" }) end)
    help:SetPoint("TOPLEFT", 140, -2 * ROW)
end

function UI.Create()
    bar = CreateFrame("Frame", "BGCommsBar", UIParent, "BasicFrameTemplateWithInset")
    bar:SetWidth(WIDTH)
    bar:SetFrameStrata("MEDIUM")
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function(self) if not BGCommsDB.locked then self:StartMoving() end end)
    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        BGCommsDB.position = { point, relativePoint, x, y }
    end)
    bar:Hide()

    title = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -5)

    local countLabel = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countLabel:SetPoint("TOPLEFT", PAD, -33)
    countLabel:SetText("How many")
    for i, value in ipairs(ns.Callouts.COUNTS) do
        local b = button("BGCommsCount" .. i, bar, 34, value, function() pickCount(value) end)
        b:SetPoint("TOPLEFT", 72 + (i - 1) * 35, -28)
        countButtons[i] = b
    end

    for i = 1, MAX_NODES do
        local b = button("BGCommsNode" .. i, bar, (WIDTH - 2 * PAD - 4) / 2, "", onNodeClick)
        nodeButtons[i] = b
    end
    makeFlags()

    hereText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    for i = 1, BOARD_LINES do
        local line = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        line:SetJustifyH("LEFT")
        line:SetWidth(WIDTH - 2 * PAD)
        boardLines[i] = line
    end
    hint = bar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetText("Click: INC   Shift: CLEAR   Right-click: HELP")

    local pos = BGCommsDB.position
    if pos then bar:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else bar:SetPoint("CENTER", 300, 0) end
    pickCount("?")
end

-- Lay the bar out for bg (a Battlegrounds definition).
function UI.Layout(bg)
    current = bg
    title:SetText("BG Comms: " .. bg.name)
    local y = 28 + ROW + 4
    for i, b in ipairs(nodeButtons) do
        local node = bg.nodes[i]
        if node then
            b:SetText(node)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", PAD + ((i - 1) % 2) * ((WIDTH - 2 * PAD) / 2 + 2), -(y + math.floor((i - 1) / 2) * ROW))
            b:Show()
        else
            b:Hide()
        end
    end
    y = y + math.ceil(#bg.nodes / 2) * ROW + 6
    if bg.kind == "ctf" then
        flags:ClearAllPoints()
        flags:SetPoint("TOPLEFT", PAD, -y)
        flags:Show()
        y = y + 3 * ROW + 6
    else
        flags:Hide()
    end
    hereText:ClearAllPoints()
    hereText:SetPoint("TOPLEFT", PAD, -y)
    y = y + 16
    for i, line in ipairs(boardLines) do
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", PAD, -(y + (i - 1) * 14))
    end
    y = y + BOARD_LINES * 14 + 4
    hint:ClearAllPoints()
    hint:SetPoint("TOPLEFT", PAD, -y)
    bar:SetHeight(y + 22)
    UI.RefreshBoard()
end

function UI.Show(bg)
    UI.Layout(bg)
    bar:Show()
end

function UI.Hide()
    if bar then bar:Hide() end
end

function UI.IsShown()
    return bar and bar:IsShown() or false
end

function UI.Current()
    return current
end
