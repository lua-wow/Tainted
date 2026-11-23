local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Combat Feedback
--------------------------------------------------
function UnitFrames:CreateCombatFeedback(frame)
    local parent = frame.TextParent or frame.Health

    local element = parent:CreateFontString(nil, "OVERLAY")
    element:SetFontObject(E.GetFont(C.unitframes.font))
    element:SetPoint("CENTER", frame.Health, "CENTER", 0, 0)

    return element
end
