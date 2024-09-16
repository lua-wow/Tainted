local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local MODULE = E:CreateModule("DataTexts")

local elements = {}

local element_proto = {}

function element_proto:GetTooltipAnchor()
	local index = self.__index
	local parent = self:GetParent()
	
	local owner, anchor, x, y = parent, "ANCHOR_TOP", 0, 0

	if (index <= 3) then
		owner = _G["TaintedChatLeft"] or parent
		anchor, y = "ANCHOR_TOPLEFT", 5
	elseif (index <= 6) then
		owner = _G["TaintedChatRight"] or parent
		anchor, y = "ANCHOR_TOPRIGHT", 5
	else
		anchor, y = "ANCHOR_NONE", -5
	end

	return owner, anchor, x, y
end

function element_proto:OnEnter()
	if not self.CreateTooltip then return end

    local tooltip = _G.GameTooltip
    if tooltip:IsForbidden() or not self:IsVisible() then return end

	local owner, anchor, x, y = self:GetTooltipAnchor()
	if anchor == "ANCHOR_NONE" then
		tooltip:SetOwner(owner, "ANCHOR_NONE")  -- Set the owner without an automatic anchor
		tooltip:SetPoint("TOPRIGHT", owner, "BOTTOMRIGHT", x, y)
	else
		tooltip:SetOwner(owner, anchor, x, y)
	end

	tooltip:ClearLines()

	local hide = self:CreateTooltip(tooltip, owner)
	if not hide then
		tooltip:Show()
	else
		tooltip:Hide()
	end
end

function element_proto:OnLeave()
    local tooltip = _G.GameTooltip
    if tooltip:IsForbidden() then return end
	if self.CloseTooltip then
		self:CloseTooltip(tooltip)
	end
	tooltip:Hide()
end

function MODULE:AddElement(name, proto)
	assert(type(name) == "string")
	assert(proto ~= nil, "element prototype is nil")
	assert(proto.Update, "element.Update do not exists")
	assert(type(proto.Update) == "function", "element.Update must be a function")
	assert(proto.Enable, "element.Enable do not exists")
	assert(type(proto.Enable) == "function", "element.Enable must be a function")
	assert(proto.Disable, "element.Disable do not exists")
	assert(type(proto.Disable) == "function", "element.Disable must be a function")
    assert(not elements[name], "element '" .. name .. "' is already registered.")

	elements[name] = Mixin({}, element_proto, proto)
end

function MODULE:Update()
	for _, frame in next, self.frames do
		if frame.__enabled then
			frame:Update()
		end
	end
end

function MODULE:CreateDataText(index, parent)
	local fontObject = E.GetFont(C.datatexts.font)
	
	local element = CreateFrame("Frame", "TaintedDataText" .. index, parent)
	element:SetFrameLevel(parent:GetFrameLevel() + 1)
	element:EnableMouse(true)
	element:SetFrameStrata("MEDIUM")
	element:Hide()
	
	local text = element:CreateFontString(nil, "OVERLAY")
	text:SetPoint("CENTER", element, "CENTER", 0, 0)
	text:SetFontObject(fontObject)

	local color = C.datatexts.colors.class 
		and E.colors.class[self.__class]
		or  C.datatexts.colors.text
	if color then
		text:SetTextColor(color:GetRGB())
	end

	element.Text = text
	element.__index = index
	element.__parent = parent

	return element
end

function MODULE:DivideFrameIntoSegments(parent, num)
	if not parent then return end

	local spacing = 1
	local segments = E.CalcSegmentsSizes(num, parent:GetWidth(), spacing)

	local prev = nil
	for _, size in next, segments do
		local index = #self.frames + 1
		
		local datatext = self:CreateDataText(index, parent)
		datatext:SetWidth(size)
		datatext:SetPoint("TOP", parent, "TOP", 0, 0)
		datatext:SetPoint("BOTTOM", parent, "BOTTOM", 0, 0)
		
		if not prev then
			datatext:SetPoint("LEFT", parent, "LEFT", 0, 0)
		else
			datatext:SetPoint("LEFT", prev, "RIGHT", spacing, 0)
		end
		
		table.insert(self.frames, datatext)

		prev = datatext
	end
end

function MODULE:CreateSegments()
	self.frames = table.wipe(self.frames or {})

	-- create datatext holders on the left chat
	self:DivideFrameIntoSegments(_G["TaintedChatLeftDataText"], 3)
	
	-- create datatext holders on the right chat
	self:DivideFrameIntoSegments(_G["TaintedChatRightDataText"], 3)
	
	self:DivideFrameIntoSegments(_G["TaintedMinimapDataText"], 2)

	-- -- create datatext bellow minimap
	-- local minimap = _G.Minimap
	-- if minimap then
	-- 	local index = #self.frames + 1

	-- 	local datatext = self:CreateDataText(index, minimap)
	-- 	datatext:ClearAllPoints()
	-- 	datatext:SetPoint("TOPLEFT", minimap, "BOTTOMLEFT", 0, -3)
	-- 	datatext:SetPoint("TOPRIGHT", minimap, "BOTTOMRIGHT", 0, -3)
	-- 	datatext:SetHeight(20)
	-- 	datatext:CreateBackdrop()

	-- 	table.insert(self.frames, datatext)
	-- end
end

function MODULE:GetTextColor()
	if C.datatexts.colors.class then
		return E.colors.class[self.class]
	end
	return C.datatexts.colors.text
end

function MODULE:SetupDataText(index, name)
	local element = elements[name]
	if not element then
		E:error("DateText element '" .. name .. "' do not exists.")
		return
	end

	local frame = self.frames[index]
	if not frame then
		E:error("DateText frame '" .. index .. "' do not exists.")
		return
	end
	
	if not frame.__enabled then
		frame = Mixin(frame, element)
		frame.unit = self.__unit
		frame.name = self.__name
		frame.guid = self.__guid
		frame.class = self.__class
		frame.color = C.datatexts.colors.value
		frame.highlight = C.datatexts.colors.highlight

		frame:Enable()
		
		if not frame:IsShown() then
			frame:Show()
		end

		hooksecurefunc(frame, "Enable", frame.Enable)
		hooksecurefunc(frame, "Disable", frame.Disable)

		frame.__enabled = true
	end
end

function MODULE:Setup()
	for index, name in next, self.__elements do
		self:SetupDataText(index, name)
	end
end

function MODULE:Init()
	if not C.datatexts.enabled then return end
	self.__elements = C.datatexts.elements or {}

	self.__unit = "player"
	self.__name = UnitName(self.__unit)
	self.__guid = UnitGUID(self.__unit)
	self.__class = select(2, UnitClass(self.__unit))

	self:CreateSegments()
	self:Setup()
end

