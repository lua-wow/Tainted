local _, ns = ...
local E = ns.E
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- MONK
--------------------------------------------------
function UnitFrames:MONK(frame)
    frame.Stagger = self:CreateStagger(frame)
end
