-- MinimapButton.lua - a draggable button on the minimap edge that shows or hides the bar.
-- Hand-rolled instead of LibDBIcon: one button doesn't justify vendoring two libraries.

local _, ns = ...

local MinimapButton = {}
ns.MinimapButton = MinimapButton

local ICON = "Interface\\Icons\\Ability_Warrior_BattleShout"
local EDGE_PADDING = 5

-- x, y offset from the minimap centre for an angle in degrees (0 = right, 90 = up).
function MinimapButton.Offset(angle, radius)
    local rad = math.rad(angle)
    return math.cos(rad) * radius, math.sin(rad) * radius
end

-- Angle in degrees [0, 360) from the centre (cx, cy) to the point (x, y).
function MinimapButton.AngleTo(cx, cy, x, y)
    return math.deg(math.atan2(y - cy, x - cx)) % 360
end

local button

local function place()
    local x, y = MinimapButton.Offset(BGCommsDB.minimapAngle, Minimap:GetWidth() / 2 + EDGE_PADDING)
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
    MinimapButton.Refresh()
end

function MinimapButton.Refresh()
    if BGCommsDB.minimapHidden then button:Hide() else button:Show() end
end
