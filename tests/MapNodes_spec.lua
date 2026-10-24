-- MapNodes_spec.lua - where each node sits on the battleground map

local helpers = dofile("tests/helpers.lua")

local function vec(x, y) return { GetXY = function() return x, y end } end

-- pois = { { name, x, y }, ... } on map 1461
local function api(pois, faction)
    return {
        UnitFactionGroup = function() return faction or "Alliance" end,
        C_AreaPoiInfo = pois and {
            GetAreaPOIForMap = function(mapID)
                if mapID ~= 1461 then return {} end
                local ids = {}
                for i in ipairs(pois) do ids[i] = 100 + i end
                return ids
            end,
            GetAreaPOIInfo = function(_, id)
                local p = pois[id - 100]
                return { areaPoiID = id, name = p[1], position = vec(p[2], p[3]) }
            end,
        } or nil,
    }
end

describe("MapNodes", function()
    local BG, MapNodes

    before_each(function()
        local ns = helpers.load({ "Battlegrounds.lua", "MapNodes.lua" })
        BG, MapNodes = ns.Battlegrounds, ns.MapNodes
    end)

    local function bg(key) return BG.Practice(key) end

    it("places nodes at the game's own map markers", function()
        local positions = MapNodes.Positions(api({ { "Farm", 0.5, 0.6 }, { "Trollbane Hall", 0.1, 0.1 } }), 1461, bg("ab"))
        assert.are.same({ x = 0.5, y = 0.6 }, positions["Farm"])
        assert.is_nil(positions["Trollbane Hall"])        -- not one of the bar's nodes
        assert.is_nil(positions["Stables"])               -- no marker for it
    end)

    it("matches markers by their long names", function()
        local positions = MapNodes.Positions(api({ { "Stonehearth Graveyard", 0.4, 0.2 } }), 1461, bg("av"))
        assert.are.same({ x = 0.4, y = 0.2 }, positions["Stonehearth GY"])
    end)

    it("uses marked spots, by your faction in Warsong Gulch", function()
        local marks = { ["Silverwing Hold"] = { x = 0.5, y = 0.1 }, mid = { x = 0.5, y = 0.5 } }
        local positions = MapNodes.Positions(api(nil, "Horde"), 1461, bg("wsg"), marks)
        assert.are.same({ x = 0.5, y = 0.1 }, positions["their base"])
        assert.are.same({ x = 0.5, y = 0.5 }, positions["mid"])
    end)

    it("lets a marked spot override the game's marker", function()
        local positions = MapNodes.Positions(api({ { "Farm", 0.5, 0.6 } }), 1461, bg("ab"), { Farm = { x = 0.52, y = 0.61 } })
        assert.are.same({ x = 0.52, y = 0.61 }, positions["Farm"])
    end)

    it("names a node's spot the same for both factions when marking", function()
        local wsg = bg("wsg")
        assert.are.equal("Silverwing Hold", MapNodes.MarkName(api(nil, "Alliance"), wsg, "our base"))
        assert.are.equal("Silverwing Hold", MapNodes.MarkName(api(nil, "Horde"), wsg, "their base"))
        assert.are.equal("mid", MapNodes.MarkName(api(nil, "Horde"), wsg, "mid"))
        assert.is_nil(MapNodes.MarkName(api(nil, "Horde"), wsg, "the moon"))   -- not a node here
        assert.are.equal("Gold Mine", MapNodes.MarkName(api(), bg("ab"), "gold mine"))  -- however it's typed
    end)
end)
