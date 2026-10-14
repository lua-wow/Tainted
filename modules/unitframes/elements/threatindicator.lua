local _, ns = ...
local E = ns.E
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Threat Indicator
--------------------------------------------------
local element_proto = {}

-- color is oUF's colors.threat[status], nil without threat
function element_proto:PostUpdate(_, _, color)
	if color == self.color then return end

	self.color = color
	UnitFrames:UpdateBorderColor(self.__owner)
end

-- a Frame: oUF only shows/hides it, the border carries the color
function UnitFrames:CreateThreatIndicator(frame)
	return Mixin(CreateFrame("Frame", nil, frame), element_proto)
end
