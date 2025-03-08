local _, ns = ...
local E = ns.E
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- PRIEST
--------------------------------------------------
function UnitFrames:PRIEST(frame)
    if E.isRetail then
        frame.Atonement = self:CreateAtonement(frame)
    end
end
