local _, ns = ...
local E = ns.E
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Pet
--------------------------------------------------
function UnitFrames:CreatePetFrame(frame)
    self:CreateUnitFrame(frame)
    frame.Happiness = self:CreateHappinessIndicator(frame)
end
