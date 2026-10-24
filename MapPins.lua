-- MapPins.lua - the team board on Blizzard's own maps: a pin on each node of the battleground,
-- marked like the chat call (raid icons) with what was called and how long ago, and clickable
-- to make a call there. Added to the world map and the small battlefield map (Shift+M) as a
-- map-canvas data provider; the pin template is in Pins.xml.

local _, ns = ...

local MapPins = {}
ns.MapPins = MapPins

local TEMPLATE = "BGCommsMapPinTemplate"
local ICON = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_"
-- raid icons: 1 star, 2 circle, 4 triangle, 6 square, 7 cross (as in the chat calls)
local COUNT_ICON = { ["?"] = 6, ["1"] = 1, ["2"] = 1, ["3"] = 2, ["4"] = 2, ["5+"] = 7 }
local KIND_ICON = { CLEAR = 4, HELP = 7 }

local function iconFor(call)
    if not call then return 6 end
    if call.kind == "INC" then return COUNT_ICON[call.count or "?"] or 6 end
    return KIND_ICON[call.kind] or 6
end

local function labelFor(row)
    if not row then return "" end
    local call = row.call
    local text = call.kind == "INC" and ("INC " .. (call.count or "?")) or call.kind
    return ("%s %ds"):format(text, math.floor(row.age))
end

BGCommsMapPinMixin = CreateFromMixins(MapCanvasPinMixin)

function BGCommsMapPinMixin:OnLoad()
    if self.UseFrameLevelType then self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI") end
    if self.SetScalingLimits then self:SetScalingLimits(1, 1.0, 1.25) end
end

-- row: the board line for this node ({ call, by, age }), or nil when nobody's called it.
function BGCommsMapPinMixin:OnAcquired(node, row, x, y)
    self.node, self.row = node, row
    self:SetPosition(x, y)
    self.Icon:SetTexture(ICON .. iconFor(row and row.call))
    self.Icon:SetDesaturated(row == nil)
    self.Icon:SetAlpha(row and 1 or 0.45)
    self.Label:SetText(labelFor(row))
end

function BGCommsMapPinMixin:OnMouseEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(self.node)
    if self.row then
        GameTooltip:AddLine(("%s, %s, %ds ago"):format(ns.Callouts.Text(self.row.call), self.row.by,
            math.floor(self.row.age)), 1, 1, 1)
    end
    GameTooltip:AddLine("Click: INC   Shift: CLEAR   Right-click: HELP", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

function BGCommsMapPinMixin:OnMouseLeave()
    GameTooltip:Hide()
end

function BGCommsMapPinMixin:OnMouseUp(mouseButton)
    if mouseButton == "RightButton" then
        ns.Call({ kind = "HELP", node = self.node })
    elseif IsShiftKeyDown() then
        ns.Call({ kind = "CLEAR", node = self.node })
    else
        ns.Call({ kind = "INC", node = self.node, count = ns.UI.TakeCount() })
    end
end

local providers = {}

local function newProvider()
    local provider = CreateFromMixins(MapCanvasDataProviderMixin)

    function provider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(TEMPLATE)
    end

    function provider:RefreshAllData()
        local map = self:GetMap()
        map:RemoveAllPinsByTemplate(TEMPLATE)
        local bg = ns.CurrentBattleground()
        if not bg then return end
        local marks = BGCommsDB.marks and BGCommsDB.marks[bg.key]
        local positions = ns.MapNodes.Positions(_G, map:GetMapID(), bg, marks)
        local rows = {}
        for _, row in ipairs(ns.Board.Active(ns.board, GetTime())) do
            if row.call.node and not rows[row.call.node] then rows[row.call.node] = row end
        end
        for node, spot in pairs(positions) do
            map:AcquirePin(TEMPLATE, node, rows[node], spot.x, spot.y)
        end
    end

    return provider
end

-- Add the pin layer to a map frame (once).
function MapPins.Attach(mapFrame)
    if not mapFrame or not mapFrame.AddDataProvider or providers[mapFrame] then return end
    local provider = newProvider()
    providers[mapFrame] = provider
    mapFrame:AddDataProvider(provider)
end

-- Redraw every attached map's pins (new calls, ages, a different battleground).
function MapPins.Refresh()
    for _, provider in pairs(providers) do
        if provider:GetMap() then provider:RefreshAllData() end
    end
end
