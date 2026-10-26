local _, ns = ...
local E = ns.E
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Focus
--------------------------------------------------
function UnitFrames:CreateFocusFrame(frame)
    self:CreateUnitFrame(frame)
    if frame.__config.range then
        frame.Range = self:CreateRange(frame)
    end
    -- frame.Hightlight = self:CreateHightlight(frame)
end
