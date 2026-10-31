-- MinimapButton.lua - a draggable button on the minimap edge that shows or hides the bar.
-- Hand-rolled instead of LibDBIcon: one button doesn't justify vendoring two libraries. Like
-- LibDBIcon it follows the minimap's shape: addons that make it square (or round only some
-- corners) report that through the global GetMinimapShape().

local _, ns = ...

local MinimapButton = {}
ns.MinimapButton = MinimapButton

local ICON = "Interface\\Icons\\Ability_Warrior_BattleShout"
local EDGE_PADDING = 5

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

-- x, y offset from the minimap centre for an angle in degrees (0 = right, 90 = up), w and h the
-- distances to the left/right and top/bottom edges. A round quarter puts the button on the
-- circle (an ellipse if the minimap isn't square); a square one on the rectangle's edge.
function MinimapButton.Offset(angle, w, h, shape)
    local rad = math.rad(angle)
    local cx, cy = math.cos(rad), math.sin(rad)
    local quarters = SHAPES[shape or "ROUND"] or SHAPES.ROUND
    local quarter = (cy >= 0 and 0 or 2) + (cx < 0 and 1 or 2)
    if quarters[quarter] then
        return cx * w, cy * h
    end
    -- the point in this direction where the rectangle's nearer edge is
    local scale = 1 / math.max(math.abs(cx) / w, math.abs(cy) / h)
    return cx * scale, cy * scale
end

-- Angle in degrees [0, 360) from the centre (cx, cy) to the point (x, y).
function MinimapButton.AngleTo(cx, cy, x, y)
    return math.deg(math.atan2(y - cy, x - cx)) % 360
end

local button

local function place()
    local shape = type(GetMinimapShape) == "function" and GetMinimapShape() or "ROUND"
    local x, y = MinimapButton.Offset(BGCommsDB.minimapAngle, Minimap:GetWidth() / 2 + EDGE_PADDING,
        Minimap:GetHeight() / 2 + EDGE_PADDING, shape)
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
    -- minimap addons may reshape or resize it after we're loaded
    Minimap:HookScript("OnSizeChanged", place)
    if C_Timer and C_Timer.After then C_Timer.After(1, place) end
    MinimapButton.Refresh()
end

function MinimapButton.Refresh()
    if BGCommsDB.minimapHidden then button:Hide() else button:Show() end
end
