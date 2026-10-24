-- Callouts.lua - what a call says (Callouts), who hears it (Channel) and getting it out (Sender).
--
-- Retail (Midnight) may forbid addons from sending chat in battlegrounds; then the call is put in
-- your chat box and you press Enter, which is you sending it. Forever and TBC send directly.
--
-- Every function takes the API table explicitly (the game passes _G) so tests can fake it.

local _, ns = ...

local Callouts, Channel, Sender = {}, {}, {}
ns.Callouts, ns.Channel, ns.Sender = Callouts, Channel, Sender

-- Raid-marker icons by how many are coming: ? / 1-2 / 3-4 / 5+.
local COUNT_MARK = { ["?"] = "{square}", ["1"] = "{star}", ["2"] = "{star}", ["3"] = "{circle}",
                     ["4"] = "{circle}", ["5+"] = "{cross}" }

Callouts.COUNTS = { "?", "1", "2", "3", "4", "5+" }
Callouts.LANES = { "WEST", "MID", "EAST" }

local function at(node) return node and (": " .. node) or "" end

local TEXT = {
    INC = function(c)
        local count = c.count or "?"
        return ("%s INC %s%s"):format(COUNT_MARK[count] or "{square}", count, at(c.node))
    end,
    CLEAR = function(c) return "{triangle} CLEAR" .. at(c.node) end,
    HELP = function(c) return "{cross} HELP" .. at(c.node) end,
    EFC = function(c) return "{cross} EFC " .. (c.lane or "") end,
    OURFC = function(c) return "{star} OUR FC " .. (c.lane or "") end,
    FLAGROOM = function() return "{diamond} INC FLAG ROOM" end,
    FCHELP = function() return "{cross} FC NEEDS HELP" end,
}

-- call = { kind, node?, count?, lane? } -> chat text
function Callouts.Text(call)
    local make = TEXT[call.kind]
    return make and make(call) or nil
end

-- Addon-message form: "1|kind|node|count-or-lane" (format version 1).
local VERSION = "1"

function Callouts.Encode(call)
    return table.concat({ VERSION, call.kind, call.node or "", call.count or call.lane or "" }, "|")
end

function Callouts.Decode(message)
    if type(message) ~= "string" then return nil end
    local version, kind, node, extra = message:match("^(%d+)|(%u+)|([^|]*)|([^|]*)$")
    if version ~= VERSION or not TEXT[kind] then return nil end
    local call = { kind = kind }
    if node ~= "" then call.node = node end
    if extra ~= "" then
        if kind == "EFC" or kind == "OURFC" then call.lane = extra else call.count = extra end
    end
    return call
end

-- The chat type your team hears: the battleground's instance chat, else raid, else party;
-- nil when you're alone.
function Channel.For(api)
    if api.IsInGroup(api.LE_PARTY_CATEGORY_INSTANCE or 2) then return "INSTANCE_CHAT" end
    if api.IsInRaid() then return "RAID" end
    if api.IsInGroup() then return "PARTY" end
    return nil
end

local SLASH = { INSTANCE_CHAT = "/i ", RAID = "/raid ", PARTY = "/p ", SAY = "/s " }
local REPEAT_SECONDS = 3

local last = { text = nil, at = -math.huge }

local function lockedDown(api)
    local fn = api.C_ChatInfo and api.C_ChatInfo.InChatMessagingLockdown
    if not fn then return false end
    local ok, locked = pcall(fn)
    return ok and locked == true
end

local function typeIt(api, text, chatType)
    local open = api.ChatFrame_OpenChat or (api.ChatFrameUtil and api.ChatFrameUtil.OpenChat)
    open((SLASH[chatType] or "") .. text)
    return "typed"
end

-- Send text to chatType. Returns "sent", "typed" (in your chat box; press Enter), "preview"
-- (nobody to tell: shown to you only) or "throttled" (you said exactly that a moment ago).
-- opts.mode = "type" always types instead of sending.
function Sender.Send(api, text, chatType, opts)
    opts = opts or {}
    local now = api.GetTime()
    if text == last.text and now - last.at < REPEAT_SECONDS then return "throttled" end
    last.text, last.at = text, now

    if not chatType then
        api.print("|cff9d9d9d[BG Comms preview]|r " .. text)
        return "preview"
    end
    if opts.mode == "type" or lockedDown(api) then return typeIt(api, text, chatType) end
    local send = api.C_ChatInfo and api.C_ChatInfo.SendChatMessage or api.SendChatMessage
    local ok = send and pcall(send, text, chatType)
    if ok then return "sent" end
    return typeIt(api, text, chatType)
end
