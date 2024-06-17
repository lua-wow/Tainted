local _, ns = ...
local E = ns.E
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Threat Indicator
--------------------------------------------------
local element_proto = {}

function UnitFrames:CreateThreatIndicator(frame)
    local element = frame.Health:CreateTexture(frame:GetName() .. "ThreatIndicator", "OVERLAY")
    element:SetSize(16, 16)
    -- element:SetPoint("TOPRIGHT", frame.Health)
    element:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    return element
end
