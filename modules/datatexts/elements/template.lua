local _, ns = ...
local E, L = ns.E, ns.L
local MODULE = E:GetModule("DataTexts")

-- Mine
local template_proto = {}

function template_proto:CreateTooltip(tooltip)
    tooltip:AddLine("Template")
end

function template_proto:OnEvent(event, ...)
    -- do somthing, then update text here
    -- if self.Text then
    --     self.Text:SetFormattedText("%s", "Template")
    -- end
end

function template_proto:Update()
    self:OnEvent("ForceUpdate")
end

function template_proto:Enable()
    if self.Text then
        self.Text:SetText("Template")
    end

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("UNIT_STATS")
	self:SetScript("OnEvent", self.OnEvent)
	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)
    self:Show()
end

function template_proto:Disable()
    self:UnregisterAllEvents()
	self:SetScript("OnEvent", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
    self:Hide()
end

MODULE:AddElement("Template", template_proto)
