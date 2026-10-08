local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A
local ActionBars = E:GetModule("ActionBars")

-- Blizzard
local NUM_ACTIONBAR_BUTTONS = _G.NUM_ACTIONBAR_BUTTONS or 12

-- local ACTION_BARS = {
--     ["bar1"] = { visibility = "[petbattle] hide; show" },
--     ["bar2"] = { visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show" },
--     ["bar3"] = { visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show" },
--     ["bar4"] = { visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show" },
--     ["bar5"] = { visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show" },
--     ["bar6"] = { visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show" },
--     ["bar7"] = { visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show" },
--     ["bar8"] = { visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show" },
--     ["pet"] = { visibility = "[pet,nopetbattle,nooverridebar,nopossessbar] show; hide" },
--     ["petbattle"] = { visibility = "[petbattle] show; hide" },
--     ["stance"] = { visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show" },
-- }

-- Mine
local StyleActionButton = ActionBars.StyleActionButton

-- "showgrid" is a bit field of show reasons (Blizzard uses 1, 2, 4). Edit Mode's "Always show buttons"
-- (off in Blizzard's presets) clears bit 1, which hides empty buttons; Blizzard never clears this bit.
local SHOW_GRID_REASON_TAINTED = 0x100

local actionbar_proto = {
	enabled = true,
	num = NUM_ACTIONBAR_BUTTONS,
	size = C.actionbars.size or 32,
	spacing = C.actionbars.spacing or 5,
	horizontal = true,
	visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show",
}

do 
	function actionbar_proto:GetButton(index)
		return _G[self.name .. (index or 0)]
	end

	function actionbar_proto:UpdateAnchor()
		local element = self
		element:ClearAllPoints()
		element:SetPoint("CENTER")
	end

	function actionbar_proto:CreateBackground(num)
		local element = self

		num = num or element.num

		local size = element.size
		local spacing = element.spacing
		local horizontal = element.horizontal

		local rows = horizontal and 1 or num
		local cols = horizontal and num or 1

		self:SetWidth((cols * size) + ((cols + 1) * spacing))
		self:SetHeight((rows * size) + ((rows + 1) * spacing))
		self:CreateBackdrop("transparent")
	end

	function actionbar_proto:SetBackgroundShown(shown)
		if self.Backdrop then
			self.Backdrop:SetShown(shown)
		end
	end

	-- the background follows the Blizzard bar it holds, which hides when the bar is disabled in game options
	function actionbar_proto:FollowBar(bar)
		local element = self
		bar:HookScript("OnShow", function() element:SetBackgroundShown(true) end)
		bar:HookScript("OnHide", function() element:SetBackgroundShown(false) end)
		element:SetBackgroundShown(bar:IsShown())
	end

	function actionbar_proto:Enable()
		RegisterStateDriver(self, "visibility", self.visibility or "show")
		self:Show()
	end

	function actionbar_proto:Disable()
		UnregisterStateDriver(self, "visibility")
		self:Hide()
	end

	function actionbar_proto:UpdateVisibility()
		if self.enabled then
			self:Enable()
		else
			self:Disable()
		end
	end

	function actionbar_proto:UpdateButtonPosition(button, index)
		local element = self
	
		local size = element.size
		local spacing = element.spacing
		local horizontal = element.horizontal
	
		if index == 1 then
			button:SetPoint("TOPLEFT", element, "TOPLEFT", spacing, -spacing)
		else
			local previous = element:GetButton(index - 1)
			if element.horizontal then
				button:SetPoint("LEFT", previous, "RIGHT", spacing, 0)
			else
				button:SetPoint("TOP", previous, "BOTTOM", 0, -spacing)
			end
		end
	end

	function actionbar_proto:UpdateButtons()
		local element = self

		local size = element.size or 32

		for index = 1, element.num do
			local button = StyleActionButton(element:GetButton(index))

			button:ClearAllPoints()
			button:SetSize(size, size)
			button:SetAttribute("showgrid", SHOW_GRID_REASON_TAINTED)

			if element.name == "ActionButton" or element.name == "StanceButton" or element.name == "PetActionButton" then
				button:SetParent(element)
			end

			-- Blizzard hid the empty action buttons before the grid bit was set; show them as its UpdateShownButtons
			-- now would, without running it from addon code (stance and pet keep Blizzard's own button count)
			if element.name ~= "StanceButton" and element.name ~= "PetActionButton" and button.container
				and button.index <= button.bar.numButtonsShowable and not button:GetAttribute("statehidden") then
				button.container:Show() -- multi-bar buttons are still inside it
				button:Show()
			end

			-- actionpage is owned by the page state driver (bar1 PostCreate)
			if element.name == "ActionButton" then
				button:SetAttribute("action", index)
			end

			button._parent = element
			
			-- Don't override SetFrameRef for ActionButton - it's handled in PostCreate
			if element.name ~= "ActionButton" then
				element:SetFrameRef("button" .. index, button)
			end

			if element.name == "PetActionButton" then
				element:SetAttribute("addchild", button)
			end

			element:UpdateButtonPosition(button, index)
	
			element._buttons[index] = button
		end
	end
end

function ActionBars:CreateActionBar(name, element_proto)
	local element = Mixin(CreateFrame("Frame", "Tainted" .. name, E.PetHider, "SecureHandlerStateTemplate"), actionbar_proto, element_proto)
	element:SetPoint("CENTER")
	element:SetSize(0, 0)
	element:SetFrameStrata("LOW")
	element:SetFrameLevel(10)
	element:UpdateAnchor()
	element:CreateBackground()

	element._buttons = table.wipe(element._buttons or {})

	if element.PostCreate then
		element:PostCreate()
	end

	element:UpdateButtons()

	if element.UpdateVisibility then
		element:UpdateVisibility()
	end

	self[name] = element

	return element
end
