local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Blizzard
local MAIN_MENU_BAR_NUM_BUTTONS  = _G.MAIN_MENU_BAR_NUM_BUTTONS or 12

local PAGE_STATES = {
	-- [bonusbar:5] 11 is skyriding
	["DEFAULT"] = "[overridebar] 18; [shapeshift] 17; [vehicleui][possessbar] 16; [bonusbar:5] 11; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6;",
    -- soar
	["EVOKER"] = " [bonusbar:1] 7;",
    -- unstealthed cat, stealthed cat, bear, owl; tree form [bonusbar:2] was removed
	["DRUID"] = " [bonusbar:1,nostealth] 7; [bonusbar:1,stealth] 8; [bonusbar:3] 9; [bonusbar:4] 10;",
	-- stealth, shadow dance
	["ROGUE"] = " [bonusbar:1] 7;",
}

local AVAILABLE_PAGES = {
	["DRUID"] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 16, 17, 18 },
	["ROGUE"] = { 1, 2, 3, 4, 5, 6, 7, 11, 16, 17, 18 },
	["EVOKER"] = { 1, 2, 3, 4, 5, 6, 7, 11, 16, 17, 18 },
	["DEFAULT"] = { 1, 2, 3, 4, 5, 6, 11, 16, 17, 18 },
}

local bar_proto = {
	_num = MAIN_MENU_BAR_NUM_BUTTONS,
    _visibility = "show"
}

function bar_proto:Update()
    self:UpdateAnchor()
    self:CreateBackground(self._num, self._size, self._spacing, self._horizontal)
    self:UpdateVisibility()
    self:UpdateButtonsPosition()

    self:Execute([[
		buttons = table.new()
		for i = 1, 12 do
			table.insert(buttons, self:GetFrameRef("Button" .. i))
		end
	]])

    self:SetAttribute("_onstate-page", [[
		self:SetAttribute("state", newstate)

		if HasVehicleActionBar and HasVehicleActionBar() then
			newstate = GetVehicleBarIndex() or newstate
		elseif HasOverrideActionBar and HasOverrideActionBar() then
			newstate = GetOverrideBarIndex() or newstate
		elseif HasTempShapeshiftActionBar and HasTempShapeshiftActionBar() then
			newstate = GetTempShapeshiftBarIndex() or newstate
		elseif HasBonusActionBar and HasBonusActionBar() then
			newstate = GetBonusBarIndex() or newstate
		else
			newstate = GetActionBarPage() or newstate
		end
		
		for i, button in ipairs(buttons) do
			button:SetAttribute("actionpage", tonumber(newstate))
		end
	]])

	RegisterStateDriver(self, "page", self:getPageState())
end

function bar_proto:UpdateAnchor()
    self:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 10)
end

function bar_proto:getPageState()
	return PAGE_STATES["DEFAULT"] .. (PAGE_STATES[E.class] or "") .. " [form] 1; 1"
end

function bar_proto:getAvailablePages()
	return AVAILABLE_PAGES[E.class] or AVAILABLE_PAGES["DEFAULT"]
end

function MODULE:CreateActionBar1()
    local element = self:CreateActionBar("ActionBar1", bar_proto)
    
    for i = 1, element._num do
        local button = element:StyleActionButton(_G["ActionButton" .. i])
        button:SetParent(element)
        button:ClearAllPoints()
        button._parent = element

        element:SetFrameRef("Button" .. i, button)

        element._buttons[i] = button
    end

    element:Update()

    self.ActionBar1 = element
end
