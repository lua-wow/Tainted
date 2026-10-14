local _, ns = ...
local E, C = ns.E, ns.C
local UnitFrames = E:GetModule("UnitFrames")

--------------------------------------------------
-- Target Indicator
--------------------------------------------------
local issecretvalue = _G.issecretvalue

-- target highlight > threat color > normal border
function UnitFrames:UpdateBorderColor(frame)
	if not frame.Backdrop then return end

	local target = frame.TargetIndicator
	local threat = frame.ThreatIndicator
	if target and target.isTargeted then
		local color = C.general.highlight.color
		frame.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
	elseif threat and threat.color then
		frame.Backdrop:SetBackdropBorderColor(threat.color:GetRGB())
	else
		local color = C.general.border.color
		frame.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
	end
end

local element_proto = {}

-- isTargeted is secret on Retail while unit comparison is restricted
function element_proto:PostUpdate(isTargeted)
	local element = self
	element:Show()

	if issecretvalue and issecretvalue(isTargeted) then return end

	element.isTargeted = isTargeted
	UnitFrames:UpdateBorderColor(element.__owner)
end

function UnitFrames:CreateTargetIndicator(frame)
	return Mixin(CreateFrame("Frame", frame:GetName() .. "TargetIndicator" , frame), element_proto)
end
