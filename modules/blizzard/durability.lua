local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("Blizzard")

--------------------------------------------------
-- Durability
--------------------------------------------------
if (not C.blizzard.durability) then return end

local Durability = {}

-- DurabilityFrame is an Edit Mode system: SetPoint/ClearAllPoints are overrides, the originals
-- are kept as *Base. Blizzard places it through the override (right container layout, Edit Mode);
-- calling the originals skips our hook.
local function Reanchor(frame)
    local strip = _G.TaintedMinimapDataText or _G.Minimap
    local widgets = C.blizzard.uiwidgets and _G.UIWidgetBelowMinimapContainerFrame
    frame:ClearAllPointsBase()
    if widgets then
        -- below the capture bars; the widget container is centered under the strip, so half the
        -- strip's width reaches its right edge. Empty, the container is 1x1.
        frame:SetPointBase("TOPRIGHT", widgets, "BOTTOM", strip:GetWidth() / 2, -5)
    else
        frame:SetPointBase("TOPRIGHT", strip, "BOTTOMRIGHT", 0, -5)
    end
end

function Durability:Init()
    local frame = _G.DurabilityFrame
    if (not frame) then return end

    hooksecurefunc(frame, "SetPoint", Reanchor)
    -- already laid out when gear is damaged at login
    Reanchor(frame)
end

MODULE.Durability = Durability
