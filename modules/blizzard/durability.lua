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
    frame:ClearAllPointsBase()
    frame:SetPointBase("TOPRIGHT", _G.TaintedMinimapDataText or _G.Minimap, "BOTTOMRIGHT", 0, -5)
end

function Durability:Init()
    local frame = _G.DurabilityFrame
    if (not frame) then return end

    hooksecurefunc(frame, "SetPoint", Reanchor)
    -- already laid out when gear is damaged at login
    Reanchor(frame)
end

MODULE.Durability = Durability
