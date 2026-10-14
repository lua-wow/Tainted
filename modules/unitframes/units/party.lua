local _, ns = ...
local E = ns.E
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Party
--------------------------------------------------
function UnitFrames:CreatePartyFrame(frame)
    self:CreateUnitFrame(frame)
    frame.LeaderIndicator = self:CreateLeaderIndicator(frame)
    frame.ReadyCheckIndicator = self:CreateReadyCheckIndicator(frame)
    frame.ResurrectIndicator = self:CreateResurrectIndicator(frame)
    frame.ThreatIndicator = self:CreateThreatIndicator(frame)
    frame.Range = self:CreateRange(frame)
end
