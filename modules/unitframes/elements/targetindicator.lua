local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Target Indicator
--------------------------------------------------
local issecretvalue = _G.issecretvalue

local element_proto = {}

-- isTargeted is secret on Retail while unit comparison is restricted
function element_proto:PostUpdate(isTargeted)
	local element = self
	element:Show()

	if issecretvalue and issecretvalue(isTargeted) then return end

	local parent = element.__owner
	if parent.Backdrop then
		if isTargeted then
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
