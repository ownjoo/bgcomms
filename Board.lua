-- Board.lua - the team status board: the latest call per node (and per flag carrier), from you
-- and from teammates running BG Comms (their addon messages). Pure: times come in as numbers.

local _, ns = ...

local Board = {}
ns.Board = Board

Board.MAX_AGE = 90        -- seconds a call stays on the board
Board.DUPLICATE_WINDOW = 8 -- a teammate's identical call this recent makes yours redundant

-- Board line: one per node; flag carrier calls get one line per side.
local function lineKey(call)
    if call.kind == "EFC" then return "FC:THEIRS" end
    if call.kind == "OURFC" then return "FC:OURS" end
    if call.kind == "FLAGROOM" or call.kind == "FCHELP" then return "FLAG:" .. call.kind end
    return "NODE:" .. (call.node or "?")
end

function Board.New()
    return { lines = {} }
end

function Board.Record(board, call, by, now)
    board.lines[lineKey(call)] = { call = call, by = by, at = now }
end

-- { { call, by, age }, ... } still on the board, newest first.
function Board.Active(board, now)
    local rows = {}
    for key, line in pairs(board.lines) do
        if now - line.at > Board.MAX_AGE then
            board.lines[key] = nil
        else
            rows[#rows + 1] = { call = line.call, by = line.by, age = now - line.at, at = line.at }
        end
    end
    table.sort(rows, function(a, b) return a.at > b.at end)
    return rows
end

local function same(a, b)
    return a.kind == b.kind and a.node == b.node and a.count == b.count and a.lane == b.lane
end

-- The board line if someone else made exactly this call in the last DUPLICATE_WINDOW seconds.
function Board.JustCalled(board, call, me, now)
    local line = board.lines[lineKey(call)]
    if line and line.by ~= me and now - line.at <= Board.DUPLICATE_WINDOW and same(line.call, call) then
        return line
    end
    return nil
end
