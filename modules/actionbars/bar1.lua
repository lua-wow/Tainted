local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Blizzard
local MAIN_MENU_BAR_NUM_BUTTONS  = _G.MAIN_MENU_BAR_NUM_BUTTONS or 12

local GetActionTexture  = _G.GetActionTexture

-- Mine
local PAGE_STATE = {
	["DEFAULT"] = "[overridebar] %d; [shapeshift] %d; [vehicleui][possessbar] %d; [bonusbar:5] 11; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6;",
	-- unstealthed cat, stealthed cat, bear, owl; tree form [bonusbar:2] was removed
	["DRUID"] = E.isRetail 
		and "[bonusbar:1, stealth] 2; [bonusbar:1, nostealth] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10;"
		or "[bonusbar:1, stealth] 2; [bonusbar:1, nostealth] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10; [bonusbar:5] 10;",
	-- soar
	["EVOKER"] = " [bonusbar:1] 7;",
	-- stealth, shadow dance
	["ROGUE"] = E.isCata and "[bonusbar:1] 7; [bonusbar:2] 8;" or "[bonusbar:1] 7;",
	-- battle stance, defensive stance, berserker stance
	["WARRIOR"] = "[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9;",
	-- shadowform
	["PRIEST"] = "[bonusbar:1] 7;",
	-- ???
	["WARLOCK"] = E.isCata and "[form:1] 7;" or nil,
}

local element_proto = {
	name = "ActionButton",
    num = MAIN_MENU_BAR_NUM_BUTTONS,
	visibility = "[petbattle] hide; show"
}

do
	function element_proto:UpdateAnchor()
		local element = self

		local margin = C.general.margin or 10

		element:ClearAllPoints()
		element:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, margin)
	end

	function element_proto:GetPageState()
		local _, class = UnitClass("player")

		local vehicleBarIndex = GetVehicleBarIndex() or 16
		local shapeshiftBarIndex = GetTempShapeshiftBarIndex() or 17
		local overrideBarIndex = GetOverrideBarIndex() or 18

		local defaultPageState = PAGE_STATE["DEFAULT"]:format(overrideBarIndex, shapeshiftBarIndex, vehicleBarIndex)
		local classPageState = (PAGE_STATE[class] or "")
		return defaultPageState .. classPageState .. " [form] 1; 1"
	end

	function element_proto:OnEvent(event, ...)
		local unit = ...

		local element = self

		for index, button in next, element._buttons do
			local action = button.action
			local icon = button.icon

			if icon then
				if action and action >= 120 then
					local texture = GetActionTexture(action)
					if (texture) then
						icon:SetTexture(texture)
						if not icon:IsShown() then
							icon:Show()
						end
					else
						if icon:IsShown() then
							icon:Hide()
						end
					end
				end
			end
		end
	end

	function element_proto:PostCreate()
		local element = self

		element:SetScript("OnEvent", element.OnEvent)

		element:Execute([[
			buttons = table.new()
			for i = 1, 12 do
				table.insert(buttons, self:GetFrameRef("button" .. i))
			end
		]])

		element:SetAttribute("_onstate-page", [[
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

		local page = element:GetPageState()
		RegisterStateDriver(element, "page", page)

		if E.isRetail then
			element:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
			element:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
		end
	end
end

function MODULE:CreateActionBar1()
	return self:CreateActionBar("ActionBar1", element_proto)
end
