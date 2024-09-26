local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local CHAT = E:GetModule("Chat")

local button_proto = {}

function button_proto:OnEnter()
	self:SetAlpha(1)
	if self.Backdrop then
		local color = C.general.highlight.color
		self.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b, color.a or 1)
	end
end

function button_proto:OnLeave()
	-- self:SetAlpha(0)
	if self.Backdrop then
		local color = C.general.border.color
		self.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b, color.a or 1)
	end
end

function button_proto:OnMouseUp()
	local frame = SELECTED_CHAT_FRAME
	if frame.__copying then
		self:OnCopiedText(frame)
		return
	else
		self:OnCopyingText(frame)
	end
end

function button_proto:Update(frame, state)
	local color = state and E.colors.class[E.class] or C.general.border.color

	frame:SetTextCopyable(state)
	frame:EnableMouse(true)
	if state then
		frame:SetOnTextCopiedCallback(function()
			self:OnCopiedText(frame)
		end)
	else
		frame:SetOnTextCopiedCallback(nil)
	end
	frame._copying = state

	local left = CHAT.Left
	if left and left.Backdrop then
		left.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b, color.a or 1)
	end

	local right = CHAT.Right
	if right and right.Backdrop then
		right.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b, color.a or 1)
	end
end

function button_proto:OnCopiedText(frame)
	self:Update(frame, false)
end

function button_proto:OnCopyingText(frame)
	self:Update(frame, true)
end

function CHAT:CreateCopyButton()
	local parent = self.Left

	local element = Mixin(CreateFrame("Button", "TaintedCopy Button", parent), button_proto)
	element:SetPoint("TOPRIGHT", parent.Tab, "BOTTOMRIGHT", 0, -5)
	element:SetSize(20, 20)
	element:SetNormalTexture(A.icons.copy)
	element:SetAlpha(0)
	element:CreateBackdrop()
	element:SetScript("OnEnter", element.OnEnter)
	element:SetScript("OnLeave", element.OnLeave)
	element:SetScript("OnMouseUp", element.OnMouseUp)
	
	self.CopyButton = element
end
