-- MinimapButton.lua - a draggable button on the minimap edge that shows or hides the bar.
-- Hand-rolled instead of LibDBIcon: one button doesn't justify vendoring two libraries. It sits
-- where LibDBIcon would put it, so it lines up with every other addon's button: it follows the
-- minimap's shape (UIs that make it square report that through the global GetMinimapShape()),
-- uses LibDBIcon's padding when a UI sets it, and moves when the shape changes.

local _, ns = ...

local MinimapButton = {}
ns.MinimapButton = MinimapButton

local ICON = "Interface\\Icons\\Ability_Warrior_BattleShout"
local EDGE_PADDING = 5          -- LibDBIcon's default distance outside the minimap's edge

-- GetMinimapShape() name -> which quarters are round: { topLeft, topRight, bottomLeft, bottomRight }.
-- CORNER-X: only X is round; SIDE-X: the two quarters on side X; TRICORNER-X: all but the corner
-- opposite X.
local SHAPES = {
    ["ROUND"] = { true, true, true, true },
    ["SQUARE"] = { false, false, false, false },
    ["CORNER-TOPLEFT"] = { true, false, false, false },
    ["CORNER-TOPRIGHT"] = { false, true, false, false },
    ["CORNER-BOTTOMLEFT"] = { false, false, true, false },
    ["CORNER-BOTTOMRIGHT"] = { false, false, false, true },
    ["SIDE-TOP"] = { true, true, false, false },
    ["SIDE-BOTTOM"] = { false, false, true, true },
    ["SIDE-LEFT"] = { true, false, true, false },
    ["SIDE-RIGHT"] = { false, true, false, true },
    ["TRICORNER-TOPLEFT"] = { true, true, true, false },
    ["TRICORNER-TOPRIGHT"] = { true, true, false, true },
    ["TRICORNER-BOTTOMLEFT"] = { true, false, true, true },
    ["TRICORNER-BOTTOMRIGHT"] = { false, true, true, true },
}

local CORNER_TUCK = 10   -- how far inside the corner a button on a square quarter sits (LibDBIcon's)

-- x, y offset from the minimap centre for an angle in degrees (0 = right, 90 = up), w and h the
-- distances to the left/right and top/bottom edges. A round quarter puts the button on the
-- circle (an ellipse if the minimap isn't square). A square one, as LibDBIcon does it: along a
-- circle through the corner (less CORNER_TUCK), held to the edges.
function MinimapButton.Offset(angle, w, h, shape)
    local rad = math.rad(angle)
    local cx, cy = math.cos(rad), math.sin(rad)
    local quarters = SHAPES[shape or "ROUND"] or SHAPES.ROUND
    local quarter = (cy >= 0 and 0 or 2) + (cx < 0 and 1 or 2)
    if quarters[quarter] then
        return cx * w, cy * h
    end
    local rw, rh = math.sqrt(2 * w * w) - CORNER_TUCK, math.sqrt(2 * h * h) - CORNER_TUCK
    return math.max(-w, math.min(cx * rw, w)), math.max(-h, math.min(cy * rh, h))
end

-- Distance outside the minimap's edge: LibDBIcon's (a UI like JUI sets it, 0 on a square map), or
-- its default. libDBIcon: the loaded library, or nil.
function MinimapButton.Padding(libDBIcon)
    return libDBIcon and type(libDBIcon.radius) == "number" and libDBIcon.radius or EDGE_PADDING
end

local function libDBIcon()
    return type(LibStub) == "function" and LibStub("LibDBIcon-1.0", true) or nil
end

-- Angle in degrees [0, 360) from the centre (cx, cy) to the point (x, y).
function MinimapButton.AngleTo(cx, cy, x, y)
    return math.deg(math.atan2(y - cy, x - cx)) % 360
end

local button

local function place()
    local shape = type(GetMinimapShape) == "function" and GetMinimapShape() or "ROUND"
    local padding = MinimapButton.Padding(libDBIcon())
    local x, y = MinimapButton.Offset(BGCommsDB.minimapAngle, Minimap:GetWidth() / 2 + padding,
        Minimap:GetHeight() / 2 + padding, shape)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function followCursor()
    local scale = Minimap:GetEffectiveScale()
    local x, y = GetCursorPosition()
    local cx, cy = Minimap:GetCenter()
    BGCommsDB.minimapAngle = MinimapButton.AngleTo(cx, cy, x / scale, y / scale)
    place()
end

function MinimapButton.Create(onClick)
    button = CreateFrame("Button", "BGCommsMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetPoint("TOPLEFT", 7, -5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetTexture(ICON)
    icon:SetPoint("TOPLEFT", 7, -6)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT")

    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnClick", function() onClick() end)
    -- Shift+drag to move, like most minimap buttons; a plain drag can't knock it out of place
    button:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then self:SetScript("OnUpdate", followCursor) end
    end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("BG Comms")
        GameTooltip:AddLine("Click to show or hide the callout bar.", 1, 1, 1)
        GameTooltip:AddLine("Shift+drag to move. /bgc minimap hides this button.", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    place()
    -- UIs reshape the minimap whenever their settings change, not just at login: follow its size,
    -- its mask (a new shape; the UI sets GetMinimapShape just after, so place on the next frame),
    -- and LibDBIcon's padding (the UI tells LibDBIcon when the shape changes)
    Minimap:HookScript("OnSizeChanged", place)
    local function placeSoon()
        if C_Timer and C_Timer.After then C_Timer.After(0, place) else place() end
    end
    if hooksecurefunc then hooksecurefunc(Minimap, "SetMaskTexture", placeSoon) end
    local hooked
    local function watchLibDBIcon()
        local lib = libDBIcon()
        if lib and not hooked and hooksecurefunc and type(lib.SetButtonRadius) == "function" then
            hooksecurefunc(lib, "SetButtonRadius", placeSoon)
            hooked = true
        end
        place()
    end
    watchLibDBIcon()
    -- LibDBIcon may come with an addon that loads after this one
    if C_Timer and C_Timer.After then C_Timer.After(1, watchLibDBIcon) end
    MinimapButton.Refresh()
end

function MinimapButton.Refresh()
    if BGCommsDB.minimapHidden then button:Hide() else button:Show() end
end
