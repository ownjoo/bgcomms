-- Pings.lua - the game's own pings (retail and Forever) alongside a call. Addons can't ping
-- directly (C_Ping.SendMacroPing is restricted); a secure button running the /ping macro can,
-- from your click or keybinding. Pings are your own action, so they still work where Midnight
-- stops addons from sending chat.
--
-- /ping types by number (locale-proof): 1 attack, 2 warning, 3 on my way, 4 assist,
-- 5 not a threat, 6 threat.

local _, ns = ...

local Pings = {}
ns.Pings = Pings

local MACRO = {
    INC = "/ping [@player] 2",        -- warning, on you: where it's happening
    CLEAR = "/ping [@player] 5",      -- not a threat
    HELP = "/ping [@player] 4",       -- assist
    FLAGROOM = "/ping [@player] 2",
    EFC = "/ping [@target,harm,nodead] 1",    -- attack the enemy flag carrier you've targeted
    OURFC = "/ping [@target,help,nodead] 4",  -- assist ours
    FCHELP = "/ping [@target,help,nodead] 4",
}

-- The /ping macro for a call kind, or nil.
function Pings.Macro(kind)
    return MACRO[kind]
end

-- Does this client have pings, switched on? (TBC Anniversary has none.)
function Pings.Available(api)
    local ping = api.C_Ping
    if not (ping and ping.IsPingSystemEnabled) then return false end
    local ok, enabled = pcall(ping.IsPingSystemEnabled)
    return ok and enabled == true
end
