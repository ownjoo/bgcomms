-- MapNodes.lua - where each of the bar's nodes sits on the battleground map (0-1 coordinates),
-- for the map pins. From the game's own base markers (area POIs) where it has them, else from
-- spots marked with /bgc mark (Warsong Gulch has no markers). Marks are stored under the
-- sub-zone name (e.g. "Silverwing Hold"), so "our base" means the right one for either faction.
--
-- Every function takes the API table explicitly (the game passes _G) so tests can fake it.

local _, ns = ...

local MapNodes = {}
ns.MapNodes = MapNodes

-- The bar's node for a marker or mark name (via the battleground's aliases), if it has one.
local function nodeFor(api, bg, name)
    local alias = bg.aliases[name]
    if type(alias) == "table" then alias = alias[api.UnitFactionGroup("player")] end
    local node = (alias or name):lower()
    for _, n in ipairs(bg.nodes) do
        if n:lower() == node then return n end   -- the bar's spelling, however it was typed
    end
    return nil
end

-- { [node] = { x, y } } on uiMapID for bg; marks = { [markName] = { x, y } } win over markers.
function MapNodes.Positions(api, uiMapID, bg, marks)
    local positions = {}
    local poi = api.C_AreaPoiInfo
    if poi and poi.GetAreaPOIForMap and uiMapID then
        local ok, ids = pcall(poi.GetAreaPOIForMap, uiMapID)
        for _, id in ipairs(ok and ids or {}) do
            local info = poi.GetAreaPOIInfo(uiMapID, id)
            local node = info and info.name and nodeFor(api, bg, info.name)
            if node and info.position then
                local x, y = info.position:GetXY()
                positions[node] = { x = x, y = y }
            end
        end
    end
    for name, spot in pairs(marks or {}) do
        local node = nodeFor(api, bg, name)
        if node then positions[node] = { x = spot.x, y = spot.y } end
    end
    return positions
end

-- The name to store a mark for node under: the sub-zone it stands for, so both factions agree
-- ("our base" for an Alliance player is "Silverwing Hold"); the node itself otherwise. nil when
-- node isn't one of bg's.
function MapNodes.MarkName(api, bg, typed)
    local node = nodeFor(api, bg, typed)
    if not node then return nil end
    local faction = api.UnitFactionGroup("player")
    for subzone, alias in pairs(bg.aliases) do
        if type(alias) == "table" and alias[faction] == node then return subzone end
    end
    return node
end
