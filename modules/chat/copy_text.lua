local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local CHAT = E:GetModule("Chat")

-- Blizzard
local issecretvalue = _G.issecretvalue
local RGBToColorCode = _G.RGBToColorCode

-- Lua
local gsub = string.gsub
local tconcat = table.concat

-- Mine
local BAR_WIDTH = 8
local BOX_OFFSET = 30

-- Chat text goes into an edit box: copying from it is native, while CopyToClipboard
-- (Blizzard's SetTextCopyable path) is blocked for addons.
local lines = {}

-- Keep colours; drop textures and hyperlink data, keeping the visible text of links.
local StripEscapes = function(text)
	text = gsub(text, "|H.-|h(.-)|h", "%1")
	text = gsub(text, "|[TA].-|[ta]", "")
	return text
end

local GetChatText = function(frame)
	local count = 0
	for i = 1, frame:GetNumMessages() do
		local text, r, g, b = frame:GetMessageInfo(i)
		if text and (not issecretvalue(text)) then
			count = count + 1
			lines[count] = RGBToColorCode(r or 1, g or 1, b or 1) .. StripEscapes(text) .. "|r"
		end
	end
	return tconcat(lines, "\n", 1, count)
end

local SetPanelsBorderColor = function(color)
	for _, panel in next, { CHAT.Left, CHAT.Right } do
		if panel.Backdrop then
			panel.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b, color.a or 1)
		end
	end
end

local box_proto = {}

function box_proto:OnShow()
	SetPanelsBorderColor(E.colors.class[E.class])
end

function box_proto:OnHide()
	self.EditBox:ClearFocus()
	SetPanelsBorderColor(C.general.border.color)
end

function box_proto:Close()
	CHAT.CopyButton.Box:Hide()
end

-- the scroll bar drives the scroll frame; keep the newest lines in view when the text changes
function box_proto:OnScrollRangeChanged(_, yrange)
	local bar = self.Bar
	bar:SetMinMaxValues(0, yrange)
	bar:SetValue(yrange)
	bar:SetShown(yrange > 0)
end

function box_proto:OnMouseWheel(delta)
	local bar = self.Bar
	bar:SetValue(bar:GetValue() - delta * self.step)
end

function box_proto:OnBarValueChanged(value)
	self:GetParent().Scroll:SetVerticalScroll(value)
end

-- close after Ctrl+C; deferred so the native copy runs first
function box_proto:OnKeyDown(key)
	if (key == "C") and IsControlKeyDown() then
		C_Timer.After(0, box_proto.Close)
	end
end

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
	local box = self.Box
	if box:IsShown() then
		box:Hide()
		return
	end

	-- above the selected chat's panel; popouts use the left one
	local frame = SELECTED_CHAT_FRAME
	local panel = (frame:GetParent() == CHAT.Right) and CHAT.Right or CHAT.Left
	box:ClearAllPoints()
	box:SetPoint("BOTTOMLEFT", panel, "TOPLEFT", 0, BOX_OFFSET)
	box:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", 0, BOX_OFFSET)
	box:Show()

	local editBox = box.EditBox
	editBox:SetWidth(box.Scroll:GetWidth())
	editBox:SetText(GetChatText(frame))
	editBox:SetFocus()
	editBox:HighlightText()
end

function CHAT:CreateCopyBox()
	local margin = C.chat.margin or 5
	local fontObject = E.GetFont(C.chat.font)
	local _, fontSize = fontObject:GetFont()

	local box = Mixin(CreateFrame("Frame", "TaintedCopyBox", UIParent), box_proto)
	box:SetHeight(2 * (C.chat.height or 205))
	box:SetFrameStrata("DIALOG")
	box:EnableMouse(true)
	box:CreateBackdrop()
	box:Hide()
	box:SetScript("OnShow", box.OnShow)
	box:SetScript("OnHide", box.OnHide)

	local scroll = Mixin(CreateFrame("ScrollFrame", nil, box), box_proto)
	scroll:SetPoint("TOPLEFT", margin, -margin)
	scroll:SetPoint("BOTTOMRIGHT", -(2 * margin + BAR_WIDTH), margin)
	scroll:EnableMouseWheel(true)
	scroll.step = fontSize * (C.chat.ScrollByX or 3)
	scroll:SetScript("OnScrollRangeChanged", scroll.OnScrollRangeChanged)
	scroll:SetScript("OnMouseWheel", scroll.OnMouseWheel)

	local bar = Mixin(CreateFrame("Slider", nil, box), box_proto)
	bar:SetPoint("TOPRIGHT", -margin, -margin)
	bar:SetPoint("BOTTOMRIGHT", -margin, margin)
	bar:SetWidth(BAR_WIDTH)
	bar:SetOrientation("VERTICAL")
	bar:SetMinMaxValues(0, 0)
	bar:SetThumbTexture(A.textures.blank)
	bar:CreateBackdrop()
	bar:Hide()
	bar:SetScript("OnValueChanged", bar.OnBarValueChanged)

	local color = E.colors.class[E.class]
	local thumb = bar:GetThumbTexture()
	thumb:SetSize(BAR_WIDTH, 24)
	thumb:SetVertexColor(color.r, color.g, color.b)

	local editBox = Mixin(CreateFrame("EditBox", nil, scroll), box_proto)
	editBox:SetMultiLine(true)
	editBox:SetMaxLetters(0)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject(fontObject)
	editBox:SetScript("OnEscapePressed", box_proto.Close)
	editBox:SetScript("OnKeyDown", editBox.OnKeyDown)
	scroll:SetScrollChild(editBox)

	scroll.Bar = bar
	box.Scroll = scroll
	box.EditBox = editBox
	return box
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
	element.Box = self:CreateCopyBox()

	self.CopyButton = element
end
