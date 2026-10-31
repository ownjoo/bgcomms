-- MinimapButton_spec.lua - geometry for placing/dragging the button around the minimap edge,
-- whatever its shape (a minimap addon reports it with GetMinimapShape)

local helpers = dofile("tests/helpers.lua")

local function near(expected, actual)
    assert.is_true(math.abs(expected - actual) < 1e-6, ("expected %s, got %s"):format(expected, actual))
end

describe("MinimapButton", function()
    local MinimapButton

    before_each(function()
        MinimapButton = helpers.load({ "MinimapButton.lua" }).MinimapButton
    end)

    describe("Offset", function()
        it("places the button on a circle around a round minimap", function()
            local x, y = MinimapButton.Offset(0, 80, 80, "ROUND")
            near(80, x); near(0, y)
            x, y = MinimapButton.Offset(90, 80, 80, "ROUND")
            near(0, x); near(80, y)
            x, y = MinimapButton.Offset(45, 80, 80)                       -- no shape reported: round
            near(80 * math.cos(math.rad(45)), x); near(80 * math.sin(math.rad(45)), y)
        end)

        -- Square quarters as LibDBIcon (and so every other addon's button) places them: along a
        -- circle a little bigger than the corner, clamped to the edges, so buttons line up.
        local CORNER = (math.sqrt(2) * 80 - 10) * math.cos(math.rad(45))

        it("follows the edge of a square minimap, as other addons' buttons do", function()
            local x, y = MinimapButton.Offset(45, 80, 80, "SQUARE")
            near(CORNER, x); near(CORNER, y)                              -- tucked into the corner
            x, y = MinimapButton.Offset(30, 80, 80, "SQUARE")
            near(80, x); near((math.sqrt(2) * 80 - 10) * 0.5, y)          -- on the right edge
            x, y = MinimapButton.Offset(180, 80, 80, "SQUARE")
            near(-80, x); near(0, y)
        end)

        it("rounds only the corners the shape says are round", function()
            local x, y = MinimapButton.Offset(135, 80, 80, "CORNER-TOPLEFT")  -- top-left: round
            near(-80 * math.cos(math.rad(45)), x); near(80 * math.sin(math.rad(45)), y)
            x, y = MinimapButton.Offset(315, 80, 80, "CORNER-TOPLEFT")        -- bottom-right: square
            near(CORNER, x); near(-CORNER, y)
            x, y = MinimapButton.Offset(45, 80, 80, "SIDE-TOP")               -- top side: round
            near(80 * math.cos(math.rad(45)), x)
            x, y = MinimapButton.Offset(315, 80, 80, "TRICORNER-TOPLEFT")     -- all but bottom-right
            near(CORNER, x); near(-CORNER, y)
        end)

        it("sits as far from the edge as LibDBIcon's buttons when a UI changes that", function()
            assert.are.equal(5, MinimapButton.Padding(nil))                   -- no LibDBIcon: 5
            assert.are.equal(0, MinimapButton.Padding({ radius = 0 }))        -- JUI's square map: 0
            assert.are.equal(5, MinimapButton.Padding({}))
        end)

        it("treats a shape it doesn't know as round", function()
            local x, y = MinimapButton.Offset(45, 80, 80, "STAR")
            near(80 * math.cos(math.rad(45)), x); near(80 * math.sin(math.rad(45)), y)
        end)

        it("fits a minimap that isn't square", function()
            local x, y = MinimapButton.Offset(90, 100, 60, "SQUARE")
            near(0, x); near(60, y)
            x, y = MinimapButton.Offset(0, 100, 60, "ROUND")
            near(100, x); near(0, y)
        end)
    end)

    describe("AngleTo", function()
        it("gives the angle from the centre to the cursor, 0-360", function()
            near(0, MinimapButton.AngleTo(100, 100, 150, 100))
            near(90, MinimapButton.AngleTo(100, 100, 100, 150))
            near(225, MinimapButton.AngleTo(100, 100, 50, 50))
        end)

        it("round-trips with Offset on a round minimap", function()
            local x, y = MinimapButton.Offset(137, 80, 80, "ROUND")
            near(137, MinimapButton.AngleTo(0, 0, x, y))
        end)
    end)
end)
