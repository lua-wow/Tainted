local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Target Indicator
--------------------------------------------------
local element_proto = {}

function element_proto:PostUpdate(parent, isTarget)
    local element = self
    element:Show()

    if isTarget then
		if (parent.Backdrop) then
			local color = C.general.highlight.color
			parent.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
		end
	else
        if (parent.Backdrop) then
			parent.Backdrop:SetBackdropBorderColor(0, 0, 0)
		end
	end
end

function UnitFrames:CreateTargetIndicator(frame)
    return Mixin(CreateFrame("Frame", frame:GetName() .. "TargetIndicator" , frame), element_proto)
end
