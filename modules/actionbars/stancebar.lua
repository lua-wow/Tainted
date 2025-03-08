local _, ns = ...
local E, C = ns.E, ns.C
local MODULE = E:GetModule("ActionBars")

-- Blizzard
local NUM_SPECIAL_BUTTONS  = _G.NUM_SPECIAL_BUTTONS  or 10

local InCombatLockdown = _G.InCombatLockdown
local GetNumShapeshiftForms = _G.GetNumShapeshiftForms
local GetShapeshiftFormInfo = _G.GetShapeshiftFormInfo
local GetShapeshiftFormCooldown = _G.GetShapeshiftFormCooldown

-- Mine
local StyleActionButton = MODULE.StyleActionButton

local element_proto = {
	name = "StanceButton",
	num = NUM_SPECIAL_BUTTONS,
	size = C.actionbars.stance.size,
    spacing = C.actionbars.stance.spacing,
    horizontal = C.actionbars.stance.horizontal,
	visibility = "[vehicleui][petbattle][overridebar][possessbar] hide; show",
}

do
	function element_proto:UpdateAnchor()
		local element = self
		element:ClearAllPoints()
		element:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -10)
	end

	function element_proto:PostCreate()
		local element = self

		if _G.StanceBarFrame then
			element:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
			element:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
			element:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
			element:RegisterEvent("UPDATE_SHAPESHIFT_USABLE")
			element:SetScript("OnEvent", element.OnEvent)
		end

		local frame = _G.StanceBar or _G.StanceBarFrame
		if frame then
			frame:StripTextures()
			frame:EnableMouse(false)
			frame.ignoreFramePositionManager = true
			frame.ignoreInLayout = true
		end

		if _G.StanceBar then
			hooksecurefunc(StanceBar, "UpdateGridLayout", function(self)
				element:UpdateForms()
			end)
		end
	end

	function element_proto:Update()
		if InCombatLockdown() then return end

		local element = self

		local numForms = GetNumShapeshiftForms() or 0
		if numForms == 0 then
			element:SetAlpha(0)
			element:Hide()
		else
			element:SetAlpha(1)
			element:Show(true)

			-- resize backdrop
			element:CreateBackground(numForms)

			for index = 1, numForms do
				local button = _G[element.name .. index]
				if button then
					local texture, isActive, isCastable = GetShapeshiftFormInfo(index)
					local start, duration, enable =  GetShapeshiftFormCooldown(index)
					
					local icon = _G[button:GetName() .. "Icon"]
					if icon then
						icon:SetTexture(texture)

						if isCastable then
							icon:SetVertexColor(1.0, 1.0, 1.0)
						else
							icon:SetVertexColor(0.4, 0.4, 0.4)
						end
					end

					local cd = _G[button:GetName() .. "Cooldown"]
					if cd then
						CooldownFrame_Set(cd, start, duration, enable)
					end

					button:SetChecked(isActive)

					if button.Backdrop then
						if isActive then
							button.Backdrop:SetBackdropBorderColor(C.general.highlight.color:GetRGB())
						else
							button.Backdrop:SetBackdropBorderColor(C.general.border.color:GetRGB())
						end
					end
				end
			end
		end
	end

	function element_proto:OnEvent()
		self:Update()
	end
end

function MODULE:CreateStanceBar()
	local element = self:CreateActionBar("StanceBar", element_proto)
	
	element:Update()
	-- element:SkinStanceButtons()

	return element
end
