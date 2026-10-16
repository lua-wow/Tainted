local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Range
--------------------------------------------------
function UnitFrames:CreateRange(frame)
    return {
        insideAlpha = 1,
        outsideAlpha = C.unitframes.rangeAlpha,
    }
end

