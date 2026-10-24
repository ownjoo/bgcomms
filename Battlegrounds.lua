-- Battlegrounds.lua - which battleground you're in, its callout spots, and which one you're at.
-- Known by instance ID (any client language), else by English zone name (retail remakes have
-- new IDs). Unknown battlegrounds get generic spots, so the bar always works.
--
-- Every function takes the API table explicitly (the game passes _G) so tests can fake it.

local _, ns = ...

local Battlegrounds = {}
ns.Battlegrounds = Battlegrounds

-- kind: "nodes" (capture points: INC / CLEAR per node) or "ctf" (flag calls).
-- aliases: sub-zone name -> callout name; "OUR_BASE"/"THEIR_BASE" by the faction it belongs to.
local LIST = {
    {
        key = "AB", name = "Arathi Basin", kind = "nodes", instanceIDs = { 529, 2107, 2177 },
        nodes = { "Stables", "Blacksmith", "Farm", "Lumber Mill", "Gold Mine" },
        aliases = {},
    },
    {
        key = "WSG", name = "Warsong Gulch", kind = "ctf", instanceIDs = { 489, 2106 },
        nodes = { "our base", "mid", "their base" },
        aliases = { ["Silverwing Hold"] = { Alliance = "our base", Horde = "their base" },
                    ["Warsong Lumber Mill"] = { Horde = "our base", Alliance = "their base" } },
    },
    {
        key = "AV", name = "Alterac Valley", kind = "nodes", instanceIDs = { 30 },
        nodes = { "Dun Baldar", "Stormpike GY", "Stonehearth GY", "Snowfall GY", "Iceblood",
                  "Tower Point", "Frostwolf GY", "Frostwolf Keep" },
        aliases = {
            ["Stormpike Graveyard"] = "Stormpike GY",
            ["Stonehearth Graveyard"] = "Stonehearth GY",
            ["Stonehearth Outpost"] = "Stonehearth GY",
            ["Snowfall Graveyard"] = "Snowfall GY",
            ["Iceblood Tower"] = "Iceblood",
            ["Iceblood Garrison"] = "Iceblood",
            ["Iceblood Graveyard"] = "Iceblood",
            ["Frostwolf Graveyard"] = "Frostwolf GY",
        },
    },
    {
        key = "EOTS", name = "Eye of the Storm", kind = "nodes", instanceIDs = { 566, 968 },
        nodes = { "Blood Elf Tower", "Fel Reaver Ruins", "Mage Tower", "Draenei Ruins", "Flag" },
        aliases = {},
    },
}

local GENERIC = { kind = "nodes", nodes = { "Offense", "Mid", "Defense" }, aliases = {} }

local byID, byName = {}, {}
for _, bg in ipairs(LIST) do
    for _, id in ipairs(bg.instanceIDs) do byID[id] = bg end
    byName[bg.name] = bg
end

Battlegrounds.LIST = LIST

-- The battleground you're in (a definition from LIST, or a generic one named after the zone),
-- or nil outside battlegrounds (arenas included).
function Battlegrounds.Current(api)
    local zone, instanceType, _, _, _, _, _, instanceID = api.GetInstanceInfo()
    if instanceType ~= "pvp" then return nil end
    local bg = byID[instanceID] or byName[zone] or byName[api.GetRealZoneText and api.GetRealZoneText() or ""]
    if bg then return bg end
    return { key = "OTHER", name = zone, kind = GENERIC.kind, nodes = GENERIC.nodes, aliases = GENERIC.aliases }
end

-- Generic spots for trying the bar out of a battleground (calls go to your party or raid).
function Battlegrounds.Practice()
    return { key = "PRACTICE", name = "practice", kind = GENERIC.kind, nodes = GENERIC.nodes, aliases = GENERIC.aliases }
end

-- The callout name for where you stand: the node your sub-zone belongs to, else the sub-zone
-- itself; nil in open ground with no sub-zone.
function Battlegrounds.Here(api, bg)
    local subzone = api.GetSubZoneText and api.GetSubZoneText() or ""
    if subzone == "" then return nil end
    local alias = bg and bg.aliases[subzone]
    if type(alias) == "table" then
        return alias[api.UnitFactionGroup("player")] or subzone
    end
    return alias or subzone
end
