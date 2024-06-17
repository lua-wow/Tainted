local _, ns = ...
local E = ns.E
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- DEATH KNIGHT
--------------------------------------------------
function UnitFrames:DEATHKNIGHT(frame)
    frame.Runes = self:CreateRunes(frame)
end
