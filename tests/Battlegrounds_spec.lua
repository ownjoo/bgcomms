-- Battlegrounds_spec.lua - which battleground you're in, and where in it

local helpers = dofile("tests/helpers.lua")

local function api(opts)
    return {
        GetInstanceInfo = function()
            return opts.zone or "Arathi Basin", opts.instanceType or "pvp", 0, "", 40, 0, false, opts.instanceID or 529
        end,
        GetRealZoneText = function() return opts.zone or "Arathi Basin" end,
        GetSubZoneText = function() return opts.subzone or "" end,
        UnitFactionGroup = function() return opts.faction or "Alliance" end,
    }
end

describe("Battlegrounds", function()
    local BG

    before_each(function()
        BG = helpers.load({ "Battlegrounds.lua" }).Battlegrounds
    end)

    describe("Current", function()
        it("knows the battleground by instance ID", function()
            local bg = BG.Current(api({ instanceID = 529, zone = "Bassin d'Arathi" }))   -- any language
            assert.are.equal("AB", bg.key)
            assert.are.equal("nodes", bg.kind)
            assert.are.equal("Stables", bg.nodes[1])
        end)

        it("falls back to the zone name for an ID it doesn't know (e.g. a retail remake)", function()
            local bg = BG.Current(api({ instanceID = 99999, zone = "Warsong Gulch" }))
            assert.are.equal("WSG", bg.key)
            assert.are.equal("ctf", bg.kind)
        end)

        it("uses generic spots in a battleground it doesn't know", function()
            local bg = BG.Current(api({ instanceID = 99999, zone = "Deephaul Ravine" }))
            assert.are.equal("Deephaul Ravine", bg.name)
            assert.are.equal("nodes", bg.kind)
            assert.are.same({ "Offense", "Mid", "Defense" }, bg.nodes)
        end)

        it("is nil outside a battleground, and in arenas", function()
            assert.is_nil(BG.Current(api({ instanceType = "none" })))
            assert.is_nil(BG.Current(api({ instanceType = "arena" })))
        end)

        it("covers the classic battlegrounds", function()
            assert.are.equal("AV", BG.Current(api({ instanceID = 30 })).key)
            assert.are.equal("WSG", BG.Current(api({ instanceID = 489 })).key)
            assert.are.equal("EOTS", BG.Current(api({ instanceID = 566 })).key)
        end)
    end)

    describe("Practice", function()
        it("lays out a named battleground anywhere, marked as practice", function()
            local bg = BG.Practice("wsg")
            assert.are.equal("WSG", bg.key)
            assert.are.equal("ctf", bg.kind)
            assert.are.equal("Warsong Gulch (practice)", bg.name)
            assert.is_true(bg.practice)
            assert.are.equal("Farm", BG.Practice("AB").nodes[3])
        end)

        it("is generic without a name, and nil for one it doesn't know", function()
            assert.are.same({ "Offense", "Mid", "Defense" }, BG.Practice().nodes)
            assert.is_true(BG.Practice().practice)
            assert.is_nil(BG.Practice("arena"))
        end)

        it("doesn't change the real battleground definitions", function()
            BG.Practice("av")
            local a = api({ instanceID = 30, zone = "Alterac Valley" })
            assert.are.equal("Alterac Valley", BG.Current(a).name)
            assert.is_nil(BG.Current(a).practice)
        end)
    end)

    describe("Here", function()
        it("names the node you're standing at from the sub-zone", function()
            local a = api({ instanceID = 529, subzone = "Lumber Mill" })
            assert.are.equal("Lumber Mill", BG.Here(a, BG.Current(a)))
        end)

        it("shortens long sub-zone names to the node's callout name", function()
            local a = api({ instanceID = 30, zone = "Alterac Valley", subzone = "Stonehearth Graveyard" })
            assert.are.equal("Stonehearth GY", BG.Here(a, BG.Current(a)))
        end)

        it("says our base or their base in Warsong Gulch, by your faction", function()
            local a = api({ instanceID = 489, subzone = "Silverwing Hold", faction = "Alliance" })
            assert.are.equal("our base", BG.Here(a, BG.Current(a)))
            a = api({ instanceID = 489, subzone = "Silverwing Hold", faction = "Horde" })
            assert.are.equal("their base", BG.Here(a, BG.Current(a)))
        end)

        it("passes an unknown sub-zone through as is", function()
            local a = api({ instanceID = 529, subzone = "Trollbane Hall" })
            assert.are.equal("Trollbane Hall", BG.Here(a, BG.Current(a)))
        end)

        it("is nil with no sub-zone (open field)", function()
            local a = api({ instanceID = 529, subzone = "" })
            assert.is_nil(BG.Here(a, BG.Current(a)))
        end)
    end)
end)
