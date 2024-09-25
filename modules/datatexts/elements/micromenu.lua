local _, ns = ...
local E, L = ns.E, ns.L
local MODULE = E:GetModule("DataTexts")
local ActionBars = E:GetModule("ActionBars")

-- Mine
local MICRO_MENU = L.MICRO_MENU or "Micro Menu"

local micromenu_proto = {}

function micromenu_proto:OnMouseDown()
    ActionBars:ToggleMicroMenu()
end

function micromenu_proto:Update()
    -- do nothing here
end

function micromenu_proto:Enable()
    if self.Text then
        self.Text:SetText(MICRO_MENU)
    end

	self:SetScript("OnMouseDown", self.OnMouseDown)
    self:Show()
end

function micromenu_proto:Disable()
	self:SetScript("OnMouseDown", nil)
    self:Hide()
end

MODULE:AddElement("MicroMenu", micromenu_proto)