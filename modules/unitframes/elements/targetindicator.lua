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

	if parent.Backdrop then
		if isTarget then
			local color = C.general.highlight.color
			parent.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
		else
			local color = C.general.border.color
			parent.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
		end
	end
end

function UnitFrames:CreateTargetIndicator(frame)
	return Mixin(CreateFrame("Frame", frame:GetName() .. "TargetIndicator" , frame), element_proto)
end
