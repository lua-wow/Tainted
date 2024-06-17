local _, ns = ...
local E = ns.E
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Target
--------------------------------------------------
function UnitFrames:CreateTargetFrame(frame)
    self:CreateUnitFrame(frame)

    if (frame.Castbar) then
        frame.Castbar:ClearAllPoints()
        frame.Castbar:SetSize(350, 20)
        frame.Castbar:SetPoint("CENTER", UIParent, "CENTER", 0, 300)
        frame.Castbar:CreateBackdrop()

        if (frame.Castbar.IconBG) then
            frame.Castbar.IconBG:ClearAllPoints()
            frame.Castbar.IconBG:SetSize(20, 20)
            frame.Castbar.IconBG:SetPoint("RIGHT", frame.Castbar, "LEFT", -3, 0)
        end
    end

    frame.AlternativePower = self:CreateAlternativePower(frame)
    frame.LeaderIndicator = self:CreateLeaderIndicator(frame)
    frame.AssistantIndicator = self:CreateAssistantIndicator(frame)
end
