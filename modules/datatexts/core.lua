local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local MODULE = E:CreateModule("DataTexts")

local elements = {}

-- holders are created by their panels (chat, minimap); each owns a fixed range of 'C.datatexts.elements' indexes
local holders = {
	{ frame = "TaintedChatLeftDataText", first = 1, num = 3, owner = "TaintedChatLeft", anchor = "ANCHOR_TOPLEFT", experience = true },
	{ frame = "TaintedChatRightDataText", first = 4, num = 3, owner = "TaintedChatRight", anchor = "ANCHOR_TOPRIGHT" },
	{ frame = "TaintedMinimapDataText", first = 7, num = 2 }
}

local element_proto = {}

function element_proto:GetTooltipAnchor()
	local holder = self.__holder
	local parent = self:GetParent()

	if not holder.anchor then
		return parent, "ANCHOR_NONE", 0, -5
	end

	local owner, y = _G[holder.owner] or parent, 5
	if holder.experience then
		local exp = _G["TaintedExperience"]
		if exp and exp:IsShown() then
			y = y + 12
		end
	end

	return owner, holder.anchor, 0, y
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
		frame:Update()
	end
end

function MODULE:CreateDataText(name, parent)
	local fontObject = E.GetFont(C.datatexts.font)

	local element = CreateFrame("Frame", name, parent)
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

	return element
end

-- like oUF's EnableElement: the element is active only if its 'Enable' returns true
function MODULE:EnableSlot(slot, name)
	local element = elements[name]
	if not element then return end

	Mixin(slot, element)
	slot.unit = self.__unit
	slot.name = self.__name
	slot.guid = self.__guid
	slot.class = self.__class
	slot.color = C.datatexts.colors.value

	if slot:Enable() then
		slot:Show()
		self.frames[#self.frames + 1] = slot
	end
end

-- every slot is created, so a skipped element leaves its slot empty
function MODULE:SetupHolder(holder)
	local parent = _G[holder.frame]
	if not parent then return end

	local spacing = 1
	local segments = E.CalcSegmentsSizes(holder.num, parent:GetWidth(), spacing)

	local prev = nil
	for i, size in next, segments do
		local index = holder.first + i - 1

		local slot = self:CreateDataText("TaintedDataText" .. index, parent)
		slot:SetWidth(size)
		slot:SetPoint("TOP", parent, "TOP", 0, 0)
		slot:SetPoint("BOTTOM", parent, "BOTTOM", 0, 0)

		if not prev then
			slot:SetPoint("LEFT", parent, "LEFT", 0, 0)
		else
			slot:SetPoint("LEFT", prev, "RIGHT", spacing, 0)
		end

		slot.__holder = holder

		local name = self.__elements[index]
		if name then
			self:EnableSlot(slot, name)
		end

		prev = slot
	end
end

-- 'C.datatexts.debug': one row per registered element (label + slot); a row stays empty if its element can't run here
function MODULE:SetupDebug()
	local names = {}
	for name in next, elements do
		names[#names + 1] = name
	end
	table.sort(names)

	local height, spacing, labelWidth = 21, 1, 90

	local panel = CreateFrame("Frame", "TaintedDataTextDebug", UIParent)
	panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	panel:SetSize(270, #names * (height + spacing) - spacing)
	panel:SetFrameStrata("MEDIUM")
	panel:CreateBackdrop()

	local fontObject = E.GetFont(C.datatexts.font)
	local holder = {}

	for i, name in ipairs(names) do
		local y = -(i - 1) * (height + spacing)

		local label = panel:CreateFontString(nil, "OVERLAY")
		label:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, y)
		label:SetSize(labelWidth, height)
		label:SetJustifyH("LEFT")
		label:SetFontObject(fontObject)
		label:SetText(name)

		local slot = self:CreateDataText("TaintedDataTextDebug" .. i, panel)
		slot:SetPoint("TOPLEFT", panel, "TOPLEFT", labelWidth, y)
		slot:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
		slot:SetHeight(height)
		slot.__holder = holder

		self:EnableSlot(slot, name)
	end
end

function MODULE:Init()
	self.frames = {}
	if not C.datatexts.enabled then return end
	self.__elements = C.datatexts.elements or {}

	self.__unit = "player"
	self.__name = UnitName(self.__unit)
	self.__guid = UnitGUID(self.__unit)
	self.__class = select(2, UnitClass(self.__unit))

	for _, holder in ipairs(holders) do
		self:SetupHolder(holder)
	end

	if C.datatexts.debug then
		self:SetupDebug()
	end
end
