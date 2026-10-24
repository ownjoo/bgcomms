-- Board_spec.lua - the team status board fed by teammates' addon messages

local helpers = dofile("tests/helpers.lua")

describe("Board", function()
    local Board, board

    before_each(function()
        Board = helpers.load({ "Callouts.lua", "Board.lua" }).Board
        board = Board.New()
    end)

    it("keeps the latest call per node, newest first", function()
        Board.Record(board, { kind = "INC", node = "Farm", count = "2" }, "Ann", 100)
        Board.Record(board, { kind = "INC", node = "Stables", count = "?" }, "Bob", 105)
        Board.Record(board, { kind = "CLEAR", node = "Farm" }, "Cid", 110)
        local rows = Board.Active(board, 112)
        assert.are.equal(2, #rows)
        assert.are.equal("Farm", rows[1].call.node)
        assert.are.equal("CLEAR", rows[1].call.kind)
        assert.are.equal("Cid", rows[1].by)
        assert.are.equal(2, rows[1].age)
        assert.are.equal("Stables", rows[2].call.node)
    end)

    it("keeps flag carrier calls on one line per side", function()
        Board.Record(board, { kind = "EFC", lane = "WEST" }, "Ann", 100)
        Board.Record(board, { kind = "EFC", lane = "MID" }, "Bob", 104)
        Board.Record(board, { kind = "OURFC", lane = "EAST" }, "Cid", 105)
        local rows = Board.Active(board, 106)
        assert.are.equal(2, #rows)
        assert.are.equal("MID", rows[2].call.lane)
    end)

    it("forgets calls after a while", function()
        Board.Record(board, { kind = "INC", node = "Farm" }, "Ann", 100)
        assert.are.equal(0, #Board.Active(board, 100 + Board.MAX_AGE + 1))
    end)

    it("knows when a teammate just made the same call", function()
        Board.Record(board, { kind = "INC", node = "Farm", count = "3" }, "Ann", 100)
        local dup = Board.JustCalled(board, { kind = "INC", node = "Farm", count = "3" }, "Me", 104)
        assert.are.equal("Ann", dup.by)
        assert.is_nil(Board.JustCalled(board, { kind = "INC", node = "Farm", count = "5+" }, "Me", 104))  -- news
        assert.is_nil(Board.JustCalled(board, { kind = "INC", node = "Farm", count = "3" }, "Me", 120))   -- stale
        assert.is_nil(Board.JustCalled(board, { kind = "INC", node = "Farm", count = "3" }, "Ann", 104))  -- your own
    end)
end)
