local _, ns = ...
local E = ns.E
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- DRUID
--------------------------------------------------
function UnitFrames:DRUID(frame)
    frame.EclipseBar = self:CreateEclipseBar(frame)
end
