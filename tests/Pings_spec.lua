-- Pings_spec.lua - the game's own pings alongside calls, where the client has them

local helpers = dofile("tests/helpers.lua")

describe("Pings", function()
    local Pings

    before_each(function()
        Pings = helpers.load({ "Pings.lua" }).Pings
    end)

    it("pings where you stand for calls about your spot", function()
        assert.are.equal("/ping [@player] 2", Pings.Macro("INC"))        -- warning
        assert.are.equal("/ping [@player] 5", Pings.Macro("CLEAR"))      -- not a threat
        assert.are.equal("/ping [@player] 4", Pings.Macro("HELP"))       -- assist
        assert.are.equal("/ping [@player] 2", Pings.Macro("FLAGROOM"))
    end)

    it("pings your target for flag carrier calls, if it's the right side", function()
        assert.are.equal("/ping [@target,harm,nodead] 1", Pings.Macro("EFC"))     -- attack
        assert.are.equal("/ping [@target,help,nodead] 4", Pings.Macro("OURFC"))   -- assist
        assert.are.equal("/ping [@target,help,nodead] 4", Pings.Macro("FCHELP"))
    end)

    it("is available only where the client has the ping system switched on", function()
        assert.is_true(Pings.Available({ C_Ping = { IsPingSystemEnabled = function() return true end } }))
        assert.is_false(Pings.Available({ C_Ping = { IsPingSystemEnabled = function() return false end } }))
        assert.is_false(Pings.Available({}))   -- TBC Anniversary
    end)
end)
