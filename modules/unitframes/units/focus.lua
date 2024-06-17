local _, ns = ...
local E = ns.E
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Focus
--------------------------------------------------
function UnitFrames:CreateFocusFrame(frame)
    self:CreateUnitFrame(frame)
    frame.Range = self:CreateRange(frame)
    -- frame.Hightlight = self:CreateHightlight(frame)
end
