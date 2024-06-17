local _, ns = ...
local E = ns.E
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Arena
--------------------------------------------------
function UnitFrames:CreateArenaFrame(frame)
    self:CreateUnitFrame(frame)

    -- if (frame.Castbar) then
    --     frame.Castbar:ClearAllPoints()
    --     frame.Castbar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -3)
    --     frame.Castbar:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -3)
    -- end

    -- frame.Trinket = self:CreateTrinket(frame)
    -- frame.Hightlight = self:CreateHightlight(frame)
end
