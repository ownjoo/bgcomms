-- Core.lua - events, slash commands and keybindings: show the bar in battlegrounds, send calls
-- (chat for everyone, an addon message for teammates running BG Comms), feed the board.

local addonName, ns = ...

local PREFIX = "BGComms"   -- addon message prefix (16 characters at most)

local DEFAULTS = {
    autoShow = true,       -- show the bar when you enter a battleground
    mode = "auto",         -- "auto": send, or type it when the game won't let addons send; "type": always type
    locked = false,
    pings = true,          -- also ping (retail, Forever) from the where-you-stand and flag buttons
    minimapAngle = 200,
    minimapHidden = false,
}

ns.board = ns.Board.New()
local typedHintShown = false

local function me()
    return UnitName("player")
end

local function shortName(fullName)
    if Ambiguate then return Ambiguate(fullName, "short") end
    return (fullName:match("^[^-]+")) or fullName
end

-- Make a call: unless a teammate just made the same one, say it, tell the other addons, and put
-- it on the board.
function ns.Call(call)
    local now = GetTime()
    local dup = ns.Board.JustCalled(ns.board, call, me(), now)
    if dup then
        print(("|cffffd100BG Comms:|r %s called that %ds ago."):format(dup.by, math.floor(now - dup.at)))
        return
    end
    local chatType = ns.Channel.For(_G)
    local result = ns.Sender.Send(_G, ns.Callouts.Text(call), chatType, { mode = BGCommsDB.mode })
    if result == "throttled" then return end
    if result == "typed" and not typedHintShown then
        typedHintShown = true
        print("|cffffd100BG Comms:|r the call is in your chat box: press Enter to send it. "
            .. "(This client won't let addons send chat here; /bgc diag shows why.)")
    end
    ns.Board.Record(ns.board, call, me(), now)
    -- addon messages are blocked wherever chat is; typed calls reach players only
    if result == "sent" and chatType and C_ChatInfo and C_ChatInfo.SendAddonMessage then
        pcall(C_ChatInfo.SendAddonMessage, PREFIX, ns.Callouts.Encode(call), chatType)
    end
    ns.UI.RefreshBoard()
end

local function battleground()
    return ns.Battlegrounds.Current(_G)
end

local function here()
    return ns.Battlegrounds.Here(_G, battleground() or ns.UI.Current())
end

-- Keybindings (Bindings.xml) and the addon compartment.
function BGComms_IncHere()
    ns.Call({ kind = "INC", node = here(), count = ns.UI.TakeCount() })
end

function BGComms_ClearHere()
    ns.Call({ kind = "CLEAR", node = here() })
end

function BGComms_HelpHere()
    ns.Call({ kind = "HELP", node = here() })
end

function BGComms_Toggle()
    if ns.UI.IsShown() then
        ns.UI.Hide()
    else
        ns.UI.Show(battleground() or ns.Battlegrounds.Practice())
    end
end

-- Bindings.xml: the where-you-stand keys click the bar's secure buttons, so they can ping too.
BINDING_HEADER_BGCOMMS = "BG Comms"
_G["BINDING_NAME_CLICK BGCommsHereInc:LeftButton"] = "INC where you are"
_G["BINDING_NAME_CLICK BGCommsHereClear:LeftButton"] = "CLEAR where you are"
_G["BINDING_NAME_CLICK BGCommsHereHelp:LeftButton"] = "HELP where you are"
BINDING_NAME_BGCOMMS_TOGGLE = "Show or hide the bar"

local function applyPings()
    ns.UI.ApplyPings(BGCommsDB.pings and ns.Pings.Available(_G))
end

local function onZoneChange()
    local bg = battleground()
    if bg then
        if BGCommsDB.autoShow then ns.UI.Show(bg) end
    elseif ns.UI.Current() and ns.UI.Current().key ~= "PRACTICE" then
        ns.UI.Hide()
    end
    ns.UI.RefreshHere(here())
end

local function yesNo(v) return v and "|cffff4040yes|r" or "|cff40ff40no|r" end

-- /bgc diag: what this client allows here, to tell "BG Comms is broken" from "Blizzard said no".
local function diag()
    local _, _, _, interface = GetBuildInfo()
    local bg = battleground()
    local _, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
    print("|cffffd100BG Comms diag|r (client " .. tostring(interface) .. ")")
    print("  battleground: " .. (bg and (bg.name .. " (" .. bg.key .. ", instance " .. tostring(instanceID) .. ")")
        or ("none (" .. tostring(instanceType) .. ")")))
    print("  you're at: " .. (here() or "no sub-zone"))
    print("  channel: " .. (ns.Channel.For(_G) or "none (alone: calls are previewed)"))
    local lockdown = C_ChatInfo and C_ChatInfo.InChatMessagingLockdown
    if lockdown then
        local ok, locked = pcall(lockdown)
        print("  chat lockdown: " .. (ok and yesNo(locked) or "unknown"))
    else
        print("  chat lockdown: not on this client")
    end
    local kinds = Enum and Enum.AddOnRestrictionType
    local active = C_RestrictedActions and C_RestrictedActions.IsAddOnRestrictionActive
    if kinds and active then
        local parts = {}
        for name, value in pairs(kinds) do
            local ok, on = pcall(active, value)
            parts[#parts + 1] = name .. "=" .. (ok and (on and "on" or "off") or "?")
        end
        table.sort(parts)
        print("  addon restrictions: " .. table.concat(parts, ", "))
    end
    print("  send mode: " .. BGCommsDB.mode)
    print("  pings: " .. (not ns.Pings.Available(_G) and "not on this client" or (BGCommsDB.pings and "on" or "off")))
end

local function slash(msg)
    local cmd = strtrim and strtrim(msg or ""):lower() or (msg or ""):lower()
    if cmd == "" then
        BGComms_Toggle()
    elseif cmd == "diag" then
        diag()
    elseif cmd == "type" or cmd == "auto" then
        BGCommsDB.mode = cmd
        print("|cffffd100BG Comms:|r " .. (cmd == "type" and "calls go in your chat box; press Enter to send."
            or "calls are sent, or typed when the game won't let addons send."))
    elseif cmd == "lock" or cmd == "unlock" then
        BGCommsDB.locked = cmd == "lock"
    elseif cmd == "minimap" then
        BGCommsDB.minimapHidden = not BGCommsDB.minimapHidden
        ns.MinimapButton.Refresh()
    elseif cmd == "pings on" or cmd == "pings off" then
        if InCombatLockdown() then
            print("|cffffd100BG Comms:|r can't change pings in combat; try again after.")
            return
        end
        BGCommsDB.pings = cmd == "pings on"
        applyPings()
        if BGCommsDB.pings and not ns.Pings.Available(_G) then
            print("|cffffd100BG Comms:|r this client has no pings (or they're switched off in its settings).")
        end
    elseif cmd == "auto on" or cmd == "auto off" then
        BGCommsDB.autoShow = cmd == "auto on"
    else
        print("|cffffd100BG Comms:|r /bgc (show/hide), /bgc diag, /bgc type | auto, /bgc lock | unlock, "
            .. "/bgc pings on | off, /bgc minimap")
    end
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED",
                         "ZONE_CHANGED_INDOORS", "CHAT_MSG_ADDON", "PLAYER_REGEN_ENABLED" }) do
    pcall(events.RegisterEvent, events, event)
end

events:SetScript("OnEvent", function(_, event, arg1, arg2, arg3, arg4)
    if event == "ADDON_LOADED" and arg1 == addonName then
        BGCommsDB = BGCommsDB or {}
        for key, value in pairs(DEFAULTS) do
            if BGCommsDB[key] == nil then BGCommsDB[key] = value end
        end
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
        end
        ns.UI.Create()
        applyPings()
        ns.MinimapButton.Create(BGComms_Toggle)
        SLASH_BGCOMMS1 = "/bgc"
        SLASH_BGCOMMS2 = "/bgcomms"
        SlashCmdList.BGCOMMS = slash
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        if BGCommsDB then onZoneChange() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if BGCommsDB then ns.UI.AfterCombat() end
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
        if BGCommsDB then ns.UI.RefreshHere(here()) end
    elseif event == "CHAT_MSG_ADDON" and arg1 == PREFIX then
        local by = shortName(arg4 or "?")
        if by == me() then return end
        local call = ns.Callouts.Decode(arg2)
        if call then
            ns.Board.Record(ns.board, call, by, GetTime())
            ns.UI.RefreshBoard()
        end
    end
end)
